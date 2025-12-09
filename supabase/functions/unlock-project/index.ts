// =====================================================
// UNLOCK PROJECT - Skill-Gated Project System
// =====================================================
// Endpoint: POST /functions/v1/unlock-project
// Verifies requirements and unlocks projects

// deno-lint-ignore-file

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  corsHeaders,
  errorResponse,
  successResponse,
  getAuthenticatedUser,
  createServiceClient,
  awardXP,
  createNotification,
  validateInput,
} from "../_shared/utils.ts";

interface UnlockProjectRequest {
  project_id: string;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createServiceClient();
    const { authUser, profile } = await getAuthenticatedUser(req, supabase);

    const body: UnlockProjectRequest = await req.json();
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

    // Check if project already unlocked/completed
    const { data: existingProgress } = await supabase
      .from("user_project_progress")
      .select("*")
      .eq("user_id", profile.id)
      .eq("project_id", body.project_id)
      .single();

    if (existingProgress && existingProgress.status !== "locked") {
      return successResponse({
        success: false,
        message: "Project already unlocked",
        status: existingProgress.status,
      });
    }

    // Verify user has required skills
    const requiredSkills = project.required_skills || [];
    if (requiredSkills.length > 0) {
      const { data: userSkills } = await supabase
        .from("user_skills")
        .select("skill_name, proficiency_score")
        .eq("user_id", profile.id)
        .in("skill_name", requiredSkills);

      const userSkillNames = userSkills?.map((s: any) => s.skill_name) || [];
      const missingSkills = requiredSkills.filter((s: string) => !userSkillNames.includes(s));

      if (missingSkills.length > 0) {
        return errorResponse(`Missing required skills: ${missingSkills.join(", ")}`, 403);
      }

      // Check skill proficiency (at least 30/100)
      const lowSkills =
        userSkills?.filter((s: any) => s.proficiency_score < 30).map((s: any) => s.skill_name) || [];

      if (lowSkills.length > 0) {
        return errorResponse(`Insufficient proficiency in: ${lowSkills.join(", ")}. Complete more courses first.`, 403);
      }
    }

    // Verify prerequisite projects are completed
    const prerequisites = project.prerequisites || [];
    if (prerequisites.length > 0) {
      const { data: prereqProgress } = await supabase
        .from("user_project_progress")
        .select("project_id, status")
        .eq("user_id", profile.id)
        .in("project_id", prerequisites);

      const completedPrereqs = prereqProgress?.filter((p: any) => p.status === "completed").map((p: any) => p.project_id) || [];
      const missingPrereqs = prerequisites.filter((p: string) => !completedPrereqs.includes(p));

      if (missingPrereqs.length > 0) {
        return errorResponse("Complete prerequisite projects first", 403);
      }
    }

    // Unlock project
    const { data: unlockedProgress, error: unlockError } = await supabase
      .from("user_project_progress")
      .upsert(
        {
          user_id: profile.id,
          project_id: body.project_id,
          status: "unlocked",
          progress_percentage: 0,
        },
        { onConflict: "user_id,project_id" }
      )
      .select()
      .single();

    if (unlockError) {
      return errorResponse("Failed to unlock project", 500);
    }

    // Award unlock XP
    await awardXP(supabase, profile.id, 50, `Unlocked project: ${project.title}`, "project", {
      project_id: body.project_id,
      project_title: project.title,
    });

    // Send notification
    await createNotification(
      supabase,
      profile.id,
      "🎉 New Project Unlocked!",
      `"${project.title}" is now available. Start building to earn ${project.xp_reward} XP!`,
      "unlock",
      {
        project_id: body.project_id,
        project_title: project.title,
        xp_reward: project.xp_reward,
      }
    );

    return successResponse({
      success: true,
      message: "Project unlocked successfully",
      project: {
        id: project.id,
        title: project.title,
        description: project.description,
        xp_reward: project.xp_reward,
        coin_reward: project.coin_reward,
        time_estimate_hours: project.time_estimate_hours,
      },
      xp_awarded: 50,
    });
  } catch (error) {
    console.error("Error in unlock-project:", error);
    const errorMsg = error instanceof Error ? error.message : String(error);
    return errorResponse(errorMsg || "Failed to unlock project", 500);
  }
});
