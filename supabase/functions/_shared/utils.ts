// =====================================================
// SHARED UTILITIES FOR EDGE FUNCTIONS
// =====================================================

// @deno-types="https://deno.land/x/types/index.d.ts"
// deno-lint-ignore-file

import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// Initialize Supabase client with service role
export function createServiceClient(): SupabaseClient {
  return createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    }
  );
}

// CORS headers for all responses
export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Standard error response
export function errorResponse(message: string, status = 400) {
  return new Response(
    JSON.stringify({ error: message }),
    {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    }
  );
}

// Standard success response
export function successResponse(data: any, status = 200) {
  return new Response(
    JSON.stringify(data),
    {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    }
  );
}

// Get authenticated user from request
export async function getAuthenticatedUser(req: Request, supabase: SupabaseClient) {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    throw new Error("Missing authorization header");
  }

  const token = authHeader.replace("Bearer ", "");
  const { data: { user }, error } = await supabase.auth.getUser(token);

  if (error || !user) {
    throw new Error("Invalid authentication token");
  }

  // Get user profile from database
  const { data: profile, error: profileError } = await supabase
    .from("users")
    .select("*")
    .eq("supabase_uid", user.id)
    .single();

  if (profileError || !profile) {
    throw new Error("User profile not found");
  }

  return { authUser: user, profile };
}

// Call Google Gemini API with quota protection
export async function callGemini(prompt: string, systemInstructions?: string) {
  const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
  const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") || "gemini-2.5-flash-lite";

  if (!GEMINI_API_KEY) {
    throw new Error("GEMINI_API_KEY not configured");
  }

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;

  const requestBody = {
    contents: [
      {
        parts: [
          {
            text: systemInstructions ? `${systemInstructions}\n\n${prompt}` : prompt,
          },
        ],
      },
    ],
    generationConfig: {
      temperature: 0.7,
      topK: 40,
      topP: 0.95,
      maxOutputTokens: 8192,
      responseMimeType: "application/json",
    },
  };

  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Gemini API error: ${error}`);
  }

  const data = await response.json();
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text;

  if (!text) {
    throw new Error("No response from Gemini API");
  }

  return JSON.parse(text);
}

// Calculate level from XP (exponential formula)
export function calculateLevel(xp: number): number {
  return Math.floor(Math.sqrt(xp / 1000)) + 1;
}

// Calculate XP required for next level
export function xpForNextLevel(currentLevel: number): number {
  return (currentLevel ** 2) * 1000;
}

// Award XP and handle level-ups
export async function awardXP(
  supabase: SupabaseClient,
  userId: string,
  amount: number,
  reason: string,
  source: string,
  metadata: any = {}
) {
  // Get current user data
  const { data: user, error: userError } = await supabase
    .from("users")
    .select("*")
    .eq("id", userId)
    .single();

  if (userError || !user) {
    throw new Error("User not found");
  }

  const oldXP = user.total_xp;
  const oldLevel = user.current_level;
  const newXP = oldXP + amount;
  const newLevel = calculateLevel(newXP);
  const coins = Math.floor(amount * 0.1); // 10% XP -> coins conversion

  // Update user
  const { error: updateError } = await supabase
    .from("users")
    .update({
      total_xp: newXP,
      current_level: newLevel,
      total_coins: user.total_coins + coins,
      last_activity: new Date().toISOString(),
    })
    .eq("id", userId);

  if (updateError) {
    throw new Error("Failed to update user XP");
  }

  // Log XP history
  await supabase.from("xp_history").insert({
    user_id: userId,
    amount,
    reason,
    source,
    metadata,
  });

  // Check for level up
  const leveledUp = newLevel > oldLevel;
  if (leveledUp) {
    // Award level-up achievement
    await createAchievement(
      supabase,
      userId,
      "milestone",
      `Reached Level ${newLevel}!`,
      `You've leveled up to level ${newLevel}. Keep pushing forward!`,
      "Epic",
      100,
      50
    );

    // Send level-up notification
    await createNotification(
      supabase,
      userId,
      `🎉 Level Up! You're now Level ${newLevel}`,
      `Amazing work! You've earned ${coins} coins as a bonus.`,
      "level_up",
      { oldLevel, newLevel, coinsAwarded: coins }
    );
  }

  // Update leaderboard cache
  await updateLeaderboardCache(supabase, userId);

  // Emit realtime event
  await supabase.from("users").update({ updated_at: new Date().toISOString() }).eq("id", userId);

  return {
    xpAwarded: amount,
    coinsAwarded: coins,
    newXP,
    newLevel,
    leveledUp,
    oldLevel,
  };
}

// Create achievement
export async function createAchievement(
  supabase: SupabaseClient,
  userId: string,
  type: string,
  title: string,
  description: string,
  rarity: string,
  xpBonus: number = 0,
  coinBonus: number = 0
) {
  const { data, error } = await supabase
    .from("achievements")
    .insert({
      user_id: userId,
      achievement_type: type,
      title,
      description,
      rarity,
      xp_bonus: xpBonus,
      coin_bonus: coinBonus,
    })
    .select()
    .single();

  if (error) {
    console.error("Failed to create achievement:", error);
    return null;
  }

  // Award bonus XP/coins if any
  if (xpBonus > 0) {
    await awardXP(supabase, userId, xpBonus, `Achievement: ${title}`, "achievement", { achievementId: data.id });
  }

  // Send notification
  await createNotification(
    supabase,
    userId,
    `🏆 Achievement Unlocked!`,
    title,
    "achievement",
    { achievementId: data.id, rarity }
  );

  return data;
}

// Create notification
export async function createNotification(
  supabase: SupabaseClient,
  userId: string,
  title: string,
  message: string,
  type: string,
  data: any = {}
) {
  const { error } = await supabase.from("notifications").insert({
    user_id: userId,
    title,
    message,
    type,
    data,
  });

  if (error) {
    console.error("Failed to create notification:", error);
  }
}

// Update leaderboard cache
export async function updateLeaderboardCache(supabase: SupabaseClient, userId: string) {
  const { data: user } = await supabase.from("users").select("total_xp, current_level").eq("id", userId).single();

  if (!user) return;

  const periods = ["daily", "weekly", "monthly", "all_time"];

  for (const period of periods) {
    await supabase
      .from("leaderboard_cache")
      .upsert({
        user_id: userId,
        period,
        category: "overall",
        score: user.total_xp,
        updated_at: new Date().toISOString(),
      });
  }
}

// Validate request input with schema
export function validateInput(data: any, schema: any) {
  // Simple validation - can be enhanced with Zod
  for (const [key, rules] of Object.entries(schema)) {
    const value = data[key];
    const ruleSet = rules as any;

    if (ruleSet.required && (value === undefined || value === null)) {
      throw new Error(`Missing required field: ${key}`);
    }

    if (ruleSet.type && typeof value !== ruleSet.type) {
      throw new Error(`Invalid type for ${key}: expected ${ruleSet.type}`);
    }

    if (ruleSet.minLength && value.length < ruleSet.minLength) {
      throw new Error(`${key} must be at least ${ruleSet.minLength} characters`);
    }
  }
}

// Rate limiting (simple in-memory)
const rateLimitMap = new Map<string, { count: number; resetAt: number }>();

export function checkRateLimit(identifier: string, limit = 10, windowMs = 60000): boolean {
  const now = Date.now();
  const record = rateLimitMap.get(identifier);

  if (!record || now > record.resetAt) {
    rateLimitMap.set(identifier, { count: 1, resetAt: now + windowMs });
    return true;
  }

  if (record.count >= limit) {
    return false;
  }

  record.count++;
  return true;
}

// Format date for SQL
export function formatDateForSQL(date: Date): string {
  return date.toISOString();
}

// Generate unique node positions for roadmap
export function generateNodePositions(nodeCount: number): Array<{ x: number; y: number }> {
  const positions: Array<{ x: number; y: number }> = [];
  const columns = Math.ceil(Math.sqrt(nodeCount));
  const rows = Math.ceil(nodeCount / columns);

  let index = 0;
  for (let row = 0; row < rows; row++) {
    for (let col = 0; col < columns && index < nodeCount; col++) {
      positions.push({
        x: col * 250 + Math.random() * 50,
        y: row * 200 + Math.random() * 50,
      });
      index++;
    }
  }

  return positions;
}
