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
        const { fullName, phone, idNumber, password, village } = await req.json()

        // Validation
        if (!fullName || !phone || !idNumber || !password) {
            return new Response(
                JSON.stringify({ success: false, error: 'All fields are required' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        const supabase = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        // Check if user already exists
        const { data: existing } = await supabase
            .from('app_users')
            .select('id')
            .or(`phone.eq.${phone},id_number.eq.${idNumber}`)
            .single()

        if (existing) {
            return new Response(
                JSON.stringify({ success: false, error: 'Phone or ID already registered' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Hash password
        const passwordHash = await bcrypt.hash(password)

        // Insert user
        const { data: newUser, error: insertError } = await supabase
            .from('app_users')
            .insert({
                full_name: fullName,
                phone: phone,
                id_number: idNumber,
                password_hash: passwordHash,
                village: village || null,
            })
            .select()
            .single()

        if (insertError) {
            console.error('Insert error:', insertError)
            return new Response(
                JSON.stringify({ success: false, error: 'Registration failed' }),
                { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Generate simple JWT-like token (using user ID + timestamp)
        const token = btoa(JSON.stringify({
            userId: newUser.id,
            phone: newUser.phone,
            exp: Date.now() + (30 * 24 * 60 * 60 * 1000) // 30 days
        }))

        return new Response(
            JSON.stringify({
                success: true,
                token: token,
                user: {
                    id: newUser.id,
                    fullName: newUser.full_name,
                    phone: newUser.phone,
                    issuesReported: 0
                }
            }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error) {
        console.error('Registration error:', error)
        return new Response(
            JSON.stringify({ success: false, error: 'Registration failed' }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})
