// =====================================================
// AWARD XP - Gamification Core
// =====================================================
// Endpoint: POST /functions/v1/award-xp
// Awards XP, handles level-ups, achievements, coins

// deno-lint-ignore-file

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  corsHeaders,
  errorResponse,
  successResponse,
  createServiceClient,
  awardXP as utilAwardXP,
  validateInput,
} from "../_shared/utils.ts";

interface AwardXPRequest {
  user_id: string;
  amount: number;
  reason: string;
  source: string; // 'project', 'course', 'daily', 'achievement', 'milestone'
  metadata?: any;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createServiceClient();
    const body: AwardXPRequest = await req.json();

    // Validate input
    validateInput(body, {
      user_id: { required: true, type: "string" },
      amount: { required: true, type: "number" },
      reason: { required: true, type: "string" },
      source: { required: true, type: "string" },
    });

    console.log(`Awarding ${body.amount} XP to user ${body.user_id} for: ${body.reason}`);

    // Award XP using shared utility
    const result = await utilAwardXP(
      supabase,
      body.user_id,
      body.amount,
      body.reason,
      body.source,
      body.metadata || {}
    );

    return successResponse({
      success: true,
      ...result,
    });
  } catch (error) {
    console.error("Error in award-xp:", error);
    const errorMsg = error instanceof Error ? error.message : String(error);
    return errorResponse(errorMsg || "Failed to award XP", 500);
  }
});
