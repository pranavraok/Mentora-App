// =====================================================
// LEADERBOARD - Realtime Rankings
// =====================================================
// Endpoint: GET /functions/v1/leaderboard?period=weekly&category=overall&limit=50
// Returns paginated leaderboard with realtime subscriptions

// deno-lint-ignore-file

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  corsHeaders,
  errorResponse,
  successResponse,
  createServiceClient,
} from "../_shared/utils.ts";

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createServiceClient();
    const url = new URL(req.url);

    // Parse query parameters
    const period = url.searchParams.get("period") || "all_time"; // daily, weekly, monthly, all_time
    const category = url.searchParams.get("category") || "overall"; // overall, projects, courses, streak
    const limit = parseInt(url.searchParams.get("limit") || "50");
    const offset = parseInt(url.searchParams.get("offset") || "0");

    console.log(`Fetching leaderboard: ${period} ${category} (limit: ${limit}, offset: ${offset})`);

    // Determine score column based on category
    let scoreColumn = "total_xp";
    let orderBy = "total_xp";

    switch (category) {
      case "streak":
        scoreColumn = "streak_days";
        orderBy = "streak_days";
        break;
      case "coins":
        scoreColumn = "total_coins";
        orderBy = "total_coins";
        break;
      case "projects":
        // Will need to join with project progress
        break;
      case "overall":
      default:
        scoreColumn = "total_xp";
        orderBy = "total_xp";
    }

    // Base query for overall leaderboard
    let query = supabase
      .from("users")
      .select(
        `
        id,
        name,
        photo_url,
        current_level,
        total_xp,
        total_coins,
        streak_days,
        college,
        major
      `,
        { count: "exact" }
      )
      .order(orderBy, { ascending: false })
      .range(offset, offset + limit - 1);

    // Apply period filter (for cached data, use leaderboard_cache table)
    if (period !== "all_time") {
      // Use cached leaderboard for period-specific rankings
      const { data: cachedData, error: cacheError, count } = await supabase
        .from("leaderboard_cache")
        .select(
          `
          user_id,
          score,
          rank,
          users (
            id,
            name,
            photo_url,
            current_level,
            total_xp,
            total_coins,
            streak_days,
            college,
            major
          )
        `,
          { count: "exact" }
        )
        .eq("period", period)
        .eq("category", category)
        .order("rank", { ascending: true })
        .range(offset, offset + limit - 1);

      if (cacheError) {
        console.error("Error fetching cached leaderboard:", cacheError);
      } else {
        const leaderboardData = cachedData.map((entry: any, index: number) => ({
          rank: entry.rank || offset + index + 1,
          user: entry.users,
          score: entry.score,
          period,
          category,
        }));

        return successResponse({
          success: true,
          leaderboard: leaderboardData,
          period,
          category,
          total: count || 0,
          limit,
          offset,
        });
      }
    }

    // Fetch all-time leaderboard
    const { data, error, count } = await query;

    if (error) {
      return errorResponse("Failed to fetch leaderboard", 500);
    }

    // Enrich with project/course counts if needed
    let enrichedData = data;
    if (category === "projects" || category === "overall") {
      const userIds = data.map((u: any) => u.id);

      const { data: projectCounts } = await supabase
        .from("user_project_progress")
        .select("user_id")
        .in("user_id", userIds)
        .eq("status", "completed");

      const projectCountMap = new Map();
      projectCounts?.forEach((p: any) => {
        projectCountMap.set(p.user_id, (projectCountMap.get(p.user_id) || 0) + 1);
      });

      enrichedData = data.map((u: any) => ({
        ...u,
        projects_completed: projectCountMap.get(u.id) || 0,
      }));

      if (category === "projects") {
        enrichedData.sort((a: any, b: any) => b.projects_completed - a.projects_completed);
      }
    }

    // Build leaderboard response
    const leaderboard = enrichedData.map((user: any, index: number) => ({
      rank: offset + index + 1,
      user: {
        id: user.id,
        name: user.name,
        photo_url: user.photo_url,
        level: user.current_level,
        college: user.college,
        major: user.major,
      },
      score: category === "streak" ? user.streak_days : category === "coins" ? user.total_coins : category === "projects" ? user.projects_completed : user.total_xp,
      xp: user.total_xp,
      coins: user.total_coins,
      streak: user.streak_days,
      projects_completed: user.projects_completed || 0,
    }));

    return successResponse({
      success: true,
      leaderboard,
      period,
      category,
      total: count || 0,
      limit,
      offset,
    });
  } catch (error) {
    console.error("Error in leaderboard:", error);
    const errorMsg = error instanceof Error ? error.message : String(error);
    return errorResponse(errorMsg || "Failed to fetch leaderboard", 500);
  }
});
