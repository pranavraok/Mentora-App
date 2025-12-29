// =====================================================
// GENERATE ROADMAP - Core AI Feature
// =====================================================
// Endpoint: POST /functions/v1/generate-roadmap
// Creates personalized career roadmap using Gemini API

// deno-lint-ignore-file

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  corsHeaders,
  errorResponse,
  successResponse,
  getAuthenticatedUser,
  createServiceClient,
  callGemini,
  awardXP,
  createNotification,
  generateNodePositions,
  validateInput,
} from "../_shared/utils.ts";

interface UserProfile {
  name: string;
  college?: string;
  major?: string;
  graduation_year?: number;
  career_goal: string;
  current_skills: Array<{ skill: string; level: string }>;
  target_skills: Array<{ skill: string; level: string }>;
  interests: string[];
  timeline_months: number;
  learning_style?: string;
}

interface RoadmapNode {
  title: string;
  type: string;
  description: string;
  xp_reward: number;
  coin_reward: number;
  time_estimate_hours: number;
  required_skills: string[];
  prerequisites: number[];
  status: string;
  position_x: number;
  position_y: number;
  background_theme: string;
  difficulty: string;
  order_index: number;
  external_url?: string;
  resource_links?: string[];
}

interface SkillGap {
  skill: string;
  category: string;
  current: string;
  target: string;
  importance: number;
}

interface GeminiRoadmapResponse {
  roadmap_title: string;
  roadmap_description: string;
  nodes: RoadmapNode[];
  skill_gaps: SkillGap[];
  recommended_projects: any[];
  recommended_courses: any[];
  estimated_completion_weeks: number;
  milestones: Array<{ week: number; title: string; description: string }>;
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createServiceClient();

    // Authenticate user
    const { authUser, profile } = await getAuthenticatedUser(req, supabase);

    // Parse request body
    const body = await req.json();
    const userProfile: UserProfile = body.user_profile;

    // Validate input
    validateInput(userProfile, {
      career_goal: { required: true, type: "string", minLength: 3 },
      current_skills: { required: true, type: "object" },
      timeline_months: { required: true, type: "number" },
    });

    console.log(`Generating roadmap for user: ${profile.id}`);

    // Check if roadmap already exists for this user
    const { data: existingNodes, error: checkError } = await supabase
      .from("roadmap_nodes")
      .select("*")
      .eq("user_id", profile.id)
      .limit(1);

    if (checkError) {
      console.error("Error checking existing roadmap:", checkError);
    }

    // If roadmap exists, return it instead of generating a new one
    if (existingNodes && existingNodes.length > 0) {
      console.log(`Roadmap already exists for user ${profile.id}, returning stored roadmap`);
      
      const { data: allNodes } = await supabase
        .from("roadmap_nodes")
        .select("*")
        .eq("user_id", profile.id)
        .order("order_index", { ascending: true });

      return successResponse({
        message: "Roadmap retrieved from cache",
        nodes: allNodes || [],
        cached: true,
      });
    }

    // Build Gemini prompt
    const prompt = buildGeminiPrompt(userProfile);

    // Call Gemini API with 429 error handling
    let geminiResponse: GeminiRoadmapResponse;
    try {
      geminiResponse = await callGemini(
        prompt,
        "You are an expert career advisor and curriculum designer. Generate personalized career roadmaps with actionable steps."
      );
    } catch (geminiError) {
      const errorMessage = geminiError instanceof Error ? geminiError.message : String(geminiError);
      
      // Check for quota exhaustion errors
      if (errorMessage.includes("429") || errorMessage.includes("RESOURCE_EXHAUSTED") || errorMessage.includes("quota")) {
        console.error("Gemini quota exhausted:", errorMessage);
        return errorResponse(
          "AI quota used up for now. Please try again in a few minutes.",
          429
        );
      }
      
      // Re-throw other errors
      throw geminiError;
    }

    console.log(`Gemini generated ${geminiResponse.nodes.length} nodes`);
    console.log(`Gemini response keys:`, Object.keys(geminiResponse));
    console.log(`Recommended projects in response:`, geminiResponse.recommended_projects ? geminiResponse.recommended_projects.length : 0);
    console.log(`Gemini response:`, JSON.stringify(geminiResponse, null, 2).substring(0, 500) + '...');

    // Generate positions for nodes
    const positions = generateNodePositions(geminiResponse.nodes.length);

    // Create roadmap nodes in database
    const createdNodes = [];
    for (let i = 0; i < geminiResponse.nodes.length; i++) {
      const node = geminiResponse.nodes[i];
      const position = positions[i];

      // Determine initial status (first few nodes unlocked)
      const initialStatus = i < 3 ? "unlocked" : "locked";

      const { data: createdNode, error: nodeError } = await supabase
        .from("roadmap_nodes")
        .insert({
          user_id: profile.id,
          node_type: node.type,
          title: node.title,
          description: node.description,
          position_x: position.x,
          position_y: position.y,
          status: initialStatus,
          progress_percentage: 0,
          xp_reward: node.xp_reward || 100,
          coin_reward: node.coin_reward || 10,
          time_estimate_hours: node.time_estimate_hours || 5,
          required_skills: node.required_skills || [],
          prerequisites: [], // Will be linked after all nodes created
          difficulty: node.difficulty || "Intermediate",
          background_theme: node.background_theme || getThemeForIndex(i),
          order_index: i,
          external_url: node.external_url,
          resource_links: node.resource_links || [],
        })
        .select()
        .single();

      if (nodeError) {
        console.error("Error creating node:", nodeError);
      } else {
        createdNodes.push(createdNode);
      }
    }

    // Create skill gaps in database
    for (const gap of geminiResponse.skill_gaps) {
      await supabase.from("user_skills").upsert({
        user_id: profile.id,
        skill_name: gap.skill,
        category: gap.category || "General",
        current_level: gap.current,
        target_level: gap.target,
        proficiency_score: getLevelScore(gap.current),
        importance_score: gap.importance || 3,
        is_gap: gap.current !== gap.target,
      });
    }

    // Create recommended projects
    console.log(`Starting to insert ${geminiResponse.recommended_projects?.length || 0} recommended projects...`);
    
    if (!geminiResponse.recommended_projects || geminiResponse.recommended_projects.length === 0) {
      console.warn('⚠️ WARNING: Gemini did not return any recommended_projects!');
    }
    
    for (const project of (geminiResponse.recommended_projects || []).slice(0, 5)) {
      try {
        const projectPayload = {
          user_id: profile.id,
          title: project.title || "Untitled Project",
          description: project.description || "",
          category: project.category || "General",
          difficulty: project.difficulty || "Intermediate",
          xp_reward: project.xp_reward || 200,
          coin_reward: project.coin_reward || 50,
          time_estimate_hours: project.time_estimate_hours || 10,
          required_skills: project.required_skills || [],
          tasks: project.tasks || [],
        };

        console.log(`Inserting project: "${projectPayload.title}" for user ${profile.id}`);
        
        const { data, error } = await supabase.from("projects").insert(projectPayload);

        if (error) {
          console.error(`❌ Error inserting project "${project.title}":`, error);
        } else {
          console.log(`✓ Project inserted: "${project.title}" (ID: ${data?.[0]?.id || 'unknown'})`);
        }
      } catch (err) {
        console.error(`Exception while inserting project:`, err);
      }
    }

    // Create recommended courses
    for (const course of geminiResponse.recommended_courses.slice(0, 5)) {
      await supabase.from("courses").insert({
        title: course.title,
        platform: course.platform || "Online",
        url: course.url || "",
        duration_hours: course.duration_hours || 10,
        difficulty: course.difficulty || "Beginner",
        is_free: course.is_free ?? true,
        skills_covered: course.skills_covered || [],
        rating: course.rating || 4.5,
      });
    }

    // Update user onboarding status
    await supabase
      .from("users")
      .update({
        onboarding_complete: true,
        onboarding_data: {
          career_goal: userProfile.career_goal,
          completed_at: new Date().toISOString(),
        },
      })
      .eq("id", profile.id);

    // Award onboarding completion XP
    await awardXP(supabase, profile.id, 100, "Completed onboarding", "onboarding", {
      roadmap_nodes_created: createdNodes.length,
    });

    // Send welcome notification
    await createNotification(
      supabase,
      profile.id,
      "🚀 Welcome to Your Career Journey!",
      `Your personalized roadmap to ${userProfile.career_goal} is ready! Complete nodes to earn XP and level up.`,
      "unlock",
      {
        roadmapNodesCount: createdNodes.length,
        estimatedWeeks: geminiResponse.estimated_completion_weeks,
      }
    );

    // Return success response
    return successResponse({
      success: true,
      roadmap: {
        title: geminiResponse.roadmap_title,
        description: geminiResponse.roadmap_description,
        nodes_created: createdNodes.length,
        estimated_weeks: geminiResponse.estimated_completion_weeks,
      },
      skill_gaps: geminiResponse.skill_gaps.length,
      recommended_projects: geminiResponse.recommended_projects.length,
      recommended_courses: geminiResponse.recommended_courses.length,
      xp_awarded: 100,
      next_steps: createdNodes.slice(0, 3).map((n) => n.title),
    });
  } catch (error) {
    console.error("Error in generate-roadmap:", error);
    const errorMsg = error instanceof Error ? error.message : String(error);
    return errorResponse(errorMsg || "Failed to generate roadmap", 500);
  }
});

// Build comprehensive Gemini prompt
function buildGeminiPrompt(profile: UserProfile): string {
  const currentSkillsList = profile.current_skills.map((s) => `${s.skill} (${s.level})`).join(", ");
  const targetSkillsList = profile.target_skills.map((s) => `${s.skill} (${s.level})`).join(", ");

  return `
Generate a highly personalized, gamified career roadmap for the following user profile:

**USER PROFILE:**
- Name: ${profile.name}
- College: ${profile.college || "N/A"}
- Major: ${profile.major || "N/A"}
- Career Goal: ${profile.career_goal}
- Current Skills: ${currentSkillsList}
- Target Skills: ${targetSkillsList}
- Interests: ${profile.interests?.join(", ") || "N/A"}
- Timeline: ${profile.timeline_months} months
- Learning Style: ${profile.learning_style || "Mixed"}

**REQUIREMENTS:**
1. Create a progressive roadmap with 15-25 actionable nodes
2. Node types: 'course', 'project', 'skill', 'challenge', 'milestone', 'checkpoint'
3. Each node should build on previous ones (prerequisites)
4. Vary difficulty: Beginner → Intermediate → Advanced
5. Include realistic time estimates and XP/coin rewards
6. Recommend specific courses (with real URLs if possible)
7. Suggest hands-on projects aligned with career goal
8. Identify skill gaps between current and target levels

**OUTPUT FORMAT (STRICT JSON):**
{
  "roadmap_title": "Personalized Career Roadmap Title",
  "roadmap_description": "Brief overview of the roadmap journey",
  "nodes": [
    {
      "title": "Complete JavaScript Fundamentals",
      "type": "course",
      "description": "Master JS basics including ES6+ features, async/await, and DOM manipulation",
      "xp_reward": 150,
      "coin_reward": 30,
      "time_estimate_hours": 20,
      "required_skills": ["HTML", "CSS"],
      "prerequisites": [],
      "status": "unlocked",
      "difficulty": "Beginner",
      "background_theme": "grassland",
      "order_index": 0,
      "external_url": "https://javascript.info",
      "resource_links": ["https://eloquentjavascript.net"]
    }
  ],
  "skill_gaps": [
    {
      "skill": "React.js",
      "category": "Web Development",
      "current": "Beginner",
      "target": "Advanced",
      "importance": 5
    }
  ],
  "recommended_projects": [
    {
      "title": "Build a Personal Portfolio Website",
      "description": "Create a responsive portfolio showcasing your projects",
      "category": "Web Dev",
      "difficulty": "Beginner",
      "xp_reward": 200,
      "coin_reward": 50,
      "time_estimate_hours": 12,
      "required_skills": ["HTML", "CSS", "JavaScript"],
      "tasks": [
        {"id": "1", "title": "Design wireframes", "completed": false},
        {"id": "2", "title": "Build HTML structure", "completed": false},
        {"id": "3", "title": "Add CSS styling", "completed": false},
        {"id": "4", "title": "Deploy to Netlify", "completed": false}
      ]
    }
  ],
  "recommended_courses": [
    {
      "title": "The Complete Web Developer Bootcamp",
      "platform": "Udemy",
      "url": "https://www.udemy.com/course/the-complete-web-development-bootcamp/",
      "duration_hours": 60,
      "difficulty": "Beginner",
      "is_free": false,
      "skills_covered": ["HTML", "CSS", "JavaScript", "Node.js", "React"],
      "rating": 4.7
    }
  ],
  "estimated_completion_weeks": 16,
  "milestones": [
    {
      "week": 4,
      "title": "Frontend Foundations Complete",
      "description": "HTML, CSS, JavaScript mastery achieved"
    }
  ]
}

**IMPORTANT:**
- Use real course URLs (Coursera, Udemy, freeCodeCamp, YouTube, etc.)
- Make projects practical and portfolio-worthy
- Balance theory (courses) with practice (projects)
- Return 18-20 roadmap nodes in total and 5-10 project nodes in total
- Ensure logical progression from beginner to advanced
- Themes: grassland, forest, mountain, ocean, space (vary throughout roadmap)
- XP rewards: Beginner (100-200), Intermediate (200-400), Advanced (400-800)

Generate the complete roadmap now:
`;
}

// Get theme based on progression
function getThemeForIndex(index: number): string {
  const themes = ["grassland", "grassland", "forest", "forest", "mountain", "mountain", "ocean", "space"];
  return themes[Math.min(index, themes.length - 1)];
}

// Convert level string to numeric score
function getLevelScore(level: string): number {
  const scores: Record<string, number> = {
    Beginner: 25,
    Intermediate: 50,
    Advanced: 75,
    Expert: 100,
  };
  return scores[level] || 0;
}
