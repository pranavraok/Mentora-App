// =====================================================
// COMPLETE PROJECT - Project Submission & Rewards
// =====================================================
// Endpoint: POST /functions/v1/complete-project
// Handles project completion, verification, and rewards

// deno-lint-ignore-file

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  corsHeaders,
  errorResponse,
  successResponse,
  getAuthenticatedUser,
  createServiceClient,
  awardXP,
  createAchievement,
  createNotification,
  validateInput,
} from "../_shared/utils.ts";

interface CompleteProjectRequest {
  project_id: string;
  github_url?: string;
  demo_url?: string;
  submission_notes?: string;
  completed_tasks?: string[];
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createServiceClient();
    const { authUser, profile } = await getAuthenticatedUser(req, supabase);

    const body: CompleteProjectRequest = await req.json();
    validateInput(body, {
      project_id: { required: true, type: "string" },
    });

    // Get project details
    const { data: project, error: projectError } = await supabase
      .from("projects")
      .select("*")
      .eq("id", body.project_id)
      .single();

    if (projectError || !project) {
      return errorResponse("Project not found", 404);
    }

    // Get user's progress
    const { data: progress } = await supabase
      .from("user_project_progress")
      .select("*")
      .eq("user_id", profile.id)
      .eq("project_id", body.project_id)
      .single();

    if (!progress || progress.status === "locked") {
      return errorResponse("Project not unlocked. Unlock it first.", 403);
    }

    if (progress.status === "completed") {
      return successResponse({
        success: false,
        message: "Project already completed",
      });
    }

    // Validate submission (at least one URL required)
    if (!body.github_url && !body.demo_url) {
      return errorResponse("Please provide at least GitHub URL or Demo URL", 400);
    }

    // Update project progress
    const { error: updateError } = await supabase
      .from("user_project_progress")
      .update({
        status: "completed",
        progress_percentage: 100,
        github_url: body.github_url,
        demo_url: body.demo_url,
        submission_data: {
          notes: body.submission_notes,
          completed_tasks: body.completed_tasks,
          submitted_at: new Date().toISOString(),
        },
        completed_at: new Date().toISOString(),
      })
      .eq("user_id", profile.id)
      .eq("project_id", body.project_id);

    if (updateError) {
      return errorResponse("Failed to complete project", 500);
    }

    // Award full XP and coins
    const xpResult = await awardXP(
      supabase,
      profile.id,
      project.xp_reward,
      `Completed project: ${project.title}`,
      "project",
      {
        project_id: body.project_id,
        project_title: project.title,
        github_url: body.github_url,
        demo_url: body.demo_url,
      }
    );

    // Update project completion count
    await supabase
      .from("projects")
      .update({
        completion_count: project.completion_count + 1,
        trending_score: project.trending_score + 1,
      })
      .eq("id", body.project_id);

    // Check for project completion milestones
    const { count: totalCompleted } = await supabase
      .from("user_project_progress")
      .select("*", { count: "exact", head: true })
      .eq("user_id", profile.id)
      .eq("status", "completed");

    const milestones = [1, 5, 10, 25, 50];
    if (milestones.includes(totalCompleted || 0)) {
      await createAchievement(
        supabase,
        profile.id,
        "project",
        `${totalCompleted} Projects Completed!`,
        `You've successfully completed ${totalCompleted} projects. Impressive portfolio!`,
        totalCompleted >= 50 ? "Legendary" : totalCompleted >= 25 ? "Epic" : totalCompleted >= 10 ? "Rare" : "Common",
        totalCompleted * 50,
        totalCompleted * 10
      );
    }

    // Unlock dependent projects (prerequisites)
    const { data: dependentProjects } = await supabase
      .from("projects")
      .select("id, title, prerequisites")
      .contains("prerequisites", [body.project_id]);

    const newlyUnlocked: any[] = [];
    if (dependentProjects) {
      for (const depProject of dependentProjects) {
        // Check if all prerequisites are met
        const allPrereqsMet = depProject.prerequisites.every(async (prereqId: string) => {
          const { data } = await supabase
            .from("user_project_progress")
            .select("status")
            .eq("user_id", profile.id)
            .eq("project_id", prereqId)
            .single();
          return data?.status === "completed";
        });

        if (await allPrereqsMet) {
          await supabase.from("user_project_progress").upsert({
            user_id: profile.id,
            project_id: depProject.id,
            status: "unlocked",
            progress_percentage: 0,
          });
          newlyUnlocked.push(depProject.title);
        }
      }
    }

    // Update related roadmap nodes
    await supabase
      .from("roadmap_nodes")
      .update({ status: "completed", progress_percentage: 100, completed_at: new Date().toISOString() })
      .eq("user_id", profile.id)
      .eq("node_type", "project")
      .eq("title", project.title);

    // Send completion notification
    await createNotification(
      supabase,
      profile.id,
      "🎊 Project Completed!",
      `Congratulations! You earned ${project.xp_reward} XP and ${project.coin_reward} coins for "${project.title}".`,
      "achievement",
      {
        project_id: body.project_id,
        project_title: project.title,
        xp_awarded: project.xp_reward,
        coins_awarded: project.coin_reward,
        newly_unlocked: newlyUnlocked,
      }
    );

    return successResponse({
      success: true,
      message: "Project completed successfully!",
      xp_awarded: project.xp_reward,
      coins_awarded: project.coin_reward,
      level_info: {
        new_level: xpResult.newLevel,
        leveled_up: xpResult.leveledUp,
      },
      newly_unlocked_projects: newlyUnlocked,
      total_projects_completed: (totalCompleted || 0) + 1,
    });
  } catch (error) {
    console.error("Error in complete-project:", error);
    const errorMsg = error instanceof Error ? error.message : String(error);
    return errorResponse(errorMsg || "Failed to complete project", 500);
  }
});
