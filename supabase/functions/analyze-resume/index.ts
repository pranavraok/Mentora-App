// =====================================================
// ANALYZE RESUME - AI Resume Scanner
// =====================================================
// Endpoint: POST /functions/v1/analyze-resume
// Analyzes resume using Gemini API for ATS optimization

// deno-lint-ignore-file

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  corsHeaders,
  errorResponse,
  successResponse,
  getAuthenticatedUser,
  createServiceClient,
  callGemini,
  validateInput,
} from "../_shared/utils.ts";

interface ResumeAnalysisRequest {
  file_url: string;
  file_name: string;
  extracted_text: string; // OCR text from client-side (Tesseract.js)
  target_role?: string;
  target_company?: string;
}

interface ResumeAnalysisResponse {
  overall_score: number;
  ats_compatibility: number;
  sections: {
    summary: SectionAnalysis;
    experience: SectionAnalysis;
    education: SectionAnalysis;
    skills: SectionAnalysis;
    projects: SectionAnalysis;
    formatting: SectionAnalysis;
  };
  improvements: string[];
  keyword_gaps: string[];
  optimized_suggestions: {
    summary: string;
    experience_bullet_examples: string[];
    skills_to_add: string[];
  };
  ats_tips: string[];
}

interface SectionAnalysis {
  score: number;
  strengths: string[];
  weaknesses: string[];
  recommendations: string[];
}

// Simple hash function for file content
function generateHash(content: string): string {
  let hash = 0;
  for (let i = 0; i < content.length; i++) {
    const char = content.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convert to 32bit integer
  }
  return Math.abs(hash).toString(16);
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createServiceClient();
    const { authUser, profile } = await getAuthenticatedUser(req, supabase);

    const body: ResumeAnalysisRequest = await req.json();

    // Validate input
    validateInput(body, {
      file_url: { required: true, type: "string" },
      extracted_text: { required: true, type: "string", minLength: 100 },
    });

    console.log(`Analyzing resume for user: ${profile.id}`);

    // Check if this resume was already analyzed (by file hash)
    const resumeHash = generateHash(body.extracted_text); // Simple hash of content
    const { data: existingAnalysis } = await supabase
      .from("resume_analyses")
      .select("*")
      .eq("user_id", profile.id)
      .eq("file_hash", resumeHash)
      .maybeSingle();

    if (existingAnalysis) {
      console.log(`Resume analysis already exists for user ${profile.id}, returning cached analysis`);
      return successResponse({
        message: "Analysis retrieved from cache",
        analysis: existingAnalysis.analysis_result,
        cached: true,
      });
    }

    // Build analysis prompt
    const prompt = buildAnalysisPrompt(body.extracted_text, body.target_role, body.target_company);

    // Call Gemini API with 429 error handling
    let analysis: ResumeAnalysisResponse;
    try {
      analysis = await callGemini(
        prompt,
        "You are an expert resume reviewer and ATS optimization specialist with 10+ years of experience in tech recruiting."
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

    // Store analysis in database
    const { data: savedAnalysis, error: saveError } = await supabase
      .from("resume_analyses")
      .insert({
        user_id: profile.id,
        file_url: body.file_url,
        file_name: body.file_name,
        file_hash: resumeHash,
        overall_score: analysis.overall_score,
        ats_compatibility: analysis.ats_compatibility,
        extracted_text: body.extracted_text,
        analysis_result: analysis,
        improvements: analysis.improvements,
        keyword_gaps: analysis.keyword_gaps,
      })
      .select()
      .single();

    if (saveError) {
      console.error("Error saving analysis:", saveError);
    }

    return successResponse({
      success: true,
      analysis_id: savedAnalysis?.id,
      overall_score: analysis.overall_score,
      ats_compatibility: analysis.ats_compatibility,
      sections: analysis.sections,
      improvements: analysis.improvements,
      keyword_gaps: analysis.keyword_gaps,
      optimized_suggestions: analysis.optimized_suggestions,
      ats_tips: analysis.ats_tips,
    });
  } catch (error) {
    console.error("Error in analyze-resume:", error);
    const errorMsg = error instanceof Error ? error.message : String(error);
    return errorResponse(errorMsg || "Failed to analyze resume", 500);
  }
});

function buildAnalysisPrompt(resumeText: string, targetRole?: string, targetCompany?: string): string {
  return `
Analyze the following resume comprehensively for ATS compatibility and content quality.

**RESUME TEXT:**
${resumeText}

${targetRole ? `**TARGET ROLE:** ${targetRole}` : ""}
${targetCompany ? `**TARGET COMPANY:** ${targetCompany}` : ""}

**ANALYSIS REQUIREMENTS:**
1. **Overall Score (0-100):** Holistic resume quality assessment
2. **ATS Compatibility (0-100):** How well it passes Applicant Tracking Systems
3. **Section-by-Section Analysis:**
   - Summary/Objective
   - Work Experience
   - Education
   - Skills
   - Projects (if present)
   - Formatting & Structure

4. **Identify:**
   - Missing keywords for ${targetRole || "the role"}
   - ATS red flags (tables, graphics, complex formatting mentions)
   - Weak action verbs
   - Quantification opportunities
   - Spelling/grammar issues

5. **Provide:**
   - Specific improvements (prioritized)
   - Optimized summary example
   - Better experience bullet examples
   - Skills to add based on target role

**OUTPUT FORMAT (STRICT JSON):**
{
  "overall_score": 75,
  "ats_compatibility": 82,
  "sections": {
    "summary": {
      "score": 70,
      "strengths": ["Clear career goal", "Relevant keywords"],
      "weaknesses": ["Too generic", "Missing quantifiable achievements"],
      "recommendations": ["Add specific metrics", "Tailor to target role", "Use power words"]
    },
    "experience": {
      "score": 80,
      "strengths": ["Strong action verbs", "Quantified results"],
      "weaknesses": ["Some bullets too long", "Missing context in older roles"],
      "recommendations": ["Use STAR method", "Add more metrics", "Remove outdated tech"]
    },
    "education": {
      "score": 85,
      "strengths": ["Relevant degree", "GPA listed"],
      "weaknesses": [],
      "recommendations": ["Add relevant coursework if recent grad"]
    },
    "skills": {
      "score": 75,
      "strengths": ["Good technical coverage"],
      "weaknesses": ["Missing trending technologies", "No proficiency levels"],
      "recommendations": ["Add cloud platforms", "Organize by category", "Include soft skills"]
    },
    "projects": {
      "score": 70,
      "strengths": ["Demonstrates practical experience"],
      "weaknesses": ["Lacks impact metrics", "No GitHub links"],
      "recommendations": ["Add live demo links", "Quantify users/impact", "Highlight tech stack"]
    },
    "formatting": {
      "score": 90,
      "strengths": ["Clean layout", "Good use of whitespace"],
      "weaknesses": ["Some inconsistent spacing"],
      "recommendations": ["Use standard section headers", "Ensure single-column layout for ATS"]
    }
  },
  "improvements": [
    "Add 3-5 quantified achievements to work experience bullets",
    "Include relevant keywords: 'Agile', 'CI/CD', 'AWS', 'React' for target role",
    "Rewrite summary to be more specific and achievement-focused",
    "Add GitHub profile link and portfolio website",
    "Remove objective statement, replace with professional summary",
    "Use consistent date formatting (MM/YYYY)",
    "Add more technical skills relevant to target role",
    "Include 2-3 measurable accomplishments in each role"
  ],
  "keyword_gaps": [
    "Cloud platforms (AWS, Azure, GCP)",
    "CI/CD pipelines",
    "Agile/Scrum methodologies",
    "RESTful API design",
    "Unit testing frameworks",
    "Docker/Kubernetes",
    "Team leadership"
  ],
  "optimized_suggestions": {
    "summary": "Results-driven Software Engineer with 5+ years building scalable web applications using React, Node.js, and AWS. Increased user engagement by 40% through performance optimization. Passionate about clean code and agile development. Seeking senior role to lead frontend architecture.",
    "experience_bullet_examples": [
      "Architected microservices backend serving 1M+ daily users, reducing API response time by 60% using Node.js and Redis caching",
      "Led team of 4 developers in migrating legacy monolith to React SPA, improving page load speed by 3x and increasing user retention by 25%",
      "Implemented CI/CD pipeline with GitHub Actions and Docker, reducing deployment time from 2 hours to 15 minutes"
    ],
    "skills_to_add": [
      "Cloud Platforms: AWS (EC2, S3, Lambda), Docker, Kubernetes",
      "Methodologies: Agile/Scrum, Test-Driven Development (TDD)",
      "Tools: Git, JIRA, Postman, Jenkins"
    ]
  },
  "ats_tips": [
    "Use standard section headers: 'Work Experience', 'Education', 'Skills'",
    "Avoid tables, text boxes, headers/footers (ATS may skip these)",
    "Use standard fonts: Arial, Calibri, Times New Roman",
    "Save as .docx or PDF (check job posting for preference)",
    "Include exact keyword matches from job description",
    "Use simple bullet points (•) rather than fancy symbols",
    "Avoid graphics, logos, photos unless requested",
    "List skills exactly as they appear in job posting"
  ]
}

**IMPORTANT:**
- Be specific and actionable in recommendations
- Reference actual content from the resume
- Prioritize improvements by impact
- Consider ${targetRole || "general tech roles"} requirements
- ATS compatibility is critical - penalize complex formatting

Analyze the resume now:
`;
}
