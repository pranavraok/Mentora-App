import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
)

// Get user from auth header
const authHeader = req.headers.get('Authorization')!
const token = authHeader.replace('Bearer ', '')
const { data: { user } } = await supabase.auth.getUser(token)

if (!user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
    }

    // Get current user data
    const { data: userData } = await supabase
      .from('users')
      .select('*')
      .eq('supabase_uid', user.id)
      .single()

    const today = new Date().toISOString().split('T')[0]
    const lastLogin = userData.last_login_date

    let newStreak = userData.streak_days

    console.log('Streak Check:', { today, lastLogin, currentStreak: newStreak })

    // Calculate new streak
    if (!lastLogin) {
      // First login ever
      newStreak = 1
    } else if (lastLogin === today) {
      // Already logged in today, no change
      console.log('Already logged in today')
    } else {
      const lastLoginDate = new Date(lastLogin)
      const todayDate = new Date(today)
      const daysDiff = Math.floor((todayDate.getTime() - lastLoginDate.getTime()) / (1000 * 60 * 60 * 24))

      if (daysDiff === 1) {
        // Consecutive day
        newStreak = userData.streak_days + 1
        console.log('Consecutive day! New streak:', newStreak)
      } else {
        // Streak broken
        newStreak = 1
        console.log('Streak broken! Resetting to 1')
      }
    }

    // Update user
    const { data: updatedUser, error } = await supabase
      .from('users')
      .update({
        last_login_date: today,
        last_activity: new Date().toISOString(),
        streak_days: newStreak
      })
      .eq('supabase_uid', user.id)
      .select()
      .single()

    if (error) throw error

    return new Response(
      JSON.stringify({ success: true, user: updatedUser }),
      { headers: { 'Content-Type': 'application/json' } }
)
} catch (error) {
console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
)
}
})
