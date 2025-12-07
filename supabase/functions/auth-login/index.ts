import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import * as bcrypt from "https://deno.land/x/bcrypt@v0.4.1/mod.ts"

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const { phone, password } = await req.json()

        if (!phone || !password) {
            return new Response(
                JSON.stringify({ success: false, error: 'Phone and password required' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        const supabase = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        // Find user by phone
        const { data: user, error: findError } = await supabase
            .from('app_users')
            .select('*')
            .eq('phone', phone)
            .single()

        if (findError || !user) {
            return new Response(
                JSON.stringify({ success: false, error: 'User not found' }),
                { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Verify password
        const validPassword = await bcrypt.compare(password, user.password_hash)
        if (!validPassword) {
            return new Response(
                JSON.stringify({ success: false, error: 'Invalid password' }),
                { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Generate token
        const token = btoa(JSON.stringify({
            userId: user.id,
            phone: user.phone,
            exp: Date.now() + (30 * 24 * 60 * 60 * 1000) // 30 days
        }))

        return new Response(
            JSON.stringify({
                success: true,
                token: token,
                user: {
                    id: user.id,
                    fullName: user.full_name,
                    phone: user.phone,
                    issuesReported: user.issues_reported || 0,
                    issuesResolved: user.issues_resolved || 0
                }
            }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error) {
        console.error('Login error:', error)
        return new Response(
            JSON.stringify({ success: false, error: 'Login failed' }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})
