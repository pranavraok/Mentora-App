// =====================================================
// DAILY REWARDS - Streak & Login Bonuses
// =====================================================
// Endpoint: POST /functions/v1/daily-rewards
// Awards daily login XP and manages streaks

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
} from "../_shared/utils.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createServiceClient();
    const { authUser, profile } = await getAuthenticatedUser(req, supabase);

    const today = new Date().toISOString().split("T")[0];
    const lastLoginDate = profile.last_login_date ? new Date(profile.last_login_date).toISOString().split("T")[0] : null;

    // Check if user already claimed today
    if (lastLoginDate === today) {
      return successResponse({
        success: false,
        message: "Daily reward already claimed today",
        next_reward_in_hours: 24 - new Date().getHours(),
      });
    }

    // Calculate streak
    let newStreak = profile.streak_days;
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toISOString().split("T")[0];

    if (lastLoginDate === yesterdayStr) {
      // Consecutive day - increment streak
      newStreak = profile.streak_days + 1;
    } else if (lastLoginDate !== today) {
      // Streak broken - reset to 1
      newStreak = 1;
    }

    // Calculate XP reward (base 10 + streak bonus)
    const streakBonus = Math.min(newStreak * 2, 50); // Max 50 bonus
    const totalXP = 10 + streakBonus;

    // Update user streak and last login
    await supabase
      .from("users")
      .update({
        streak_days: newStreak,
        last_login_date: today,
      })
      .eq("id", profile.id);

    // Award XP
    const xpResult = await awardXP(supabase, profile.id, totalXP, "Daily login reward", "daily", {
      streak: newStreak,
      streak_bonus: streakBonus,
    });

    // Check for streak achievements
    const streakMilestones = [7, 14, 30, 60, 100];
    if (streakMilestones.includes(newStreak)) {
      await createAchievement(
        supabase,
        profile.id,
        "streak",
        `${newStreak} Day Streak!`,
        `Incredible dedication! You've logged in for ${newStreak} consecutive days.`,
        newStreak >= 100 ? "Legendary" : newStreak >= 30 ? "Epic" : newStreak >= 14 ? "Rare" : "Common",
        newStreak * 10,
        newStreak * 5
      );
    }

    // Send daily challenge notification
    await createNotification(
      supabase,
      profile.id,
      "🎯 Daily Challenge Ready!",
      "Complete a project task or course module to earn bonus XP today.",
      "daily",
      { streak: newStreak }
    );

    return successResponse({
      success: true,
      xp_awarded: totalXP,
      base_xp: 10,
      streak_bonus: streakBonus,
      current_streak: newStreak,
      coins_awarded: xpResult.coinsAwarded,
      message: `Welcome back! ${newStreak} day streak! 🔥`,
    });
  } catch (error) {
    console.error("Error in daily-rewards:", error);
    return errorResponse(error.message || "Failed to process daily reward", 500);
  }
});
