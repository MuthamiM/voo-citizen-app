
-- =====================================================
-- STEP 10: Create lost_ids table
-- =====================================================
CREATE TABLE IF NOT EXISTS lost_ids (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  full_name TEXT NOT NULL,
  id_number TEXT NOT NULL,
  phone_number TEXT,
  description TEXT,
  status TEXT DEFAULT 'reported', -- reported, found, returned
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS for lost_ids
ALTER TABLE lost_ids ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable insert lost_ids for everyone"
ON lost_ids FOR INSERT
TO anon, authenticated
WITH CHECK (true);

CREATE POLICY "Enable read lost_ids for everyone"
ON lost_ids FOR SELECT
TO anon, authenticated
USING (true);

-- =====================================================
-- STEP 11: Create feedback table
-- =====================================================
CREATE TABLE IF NOT EXISTS app_feedback (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  message TEXT NOT NULL,
  user_id UUID REFERENCES app_users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS for feedback
ALTER TABLE app_feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable insert feedback for everyone"
ON app_feedback FOR INSERT
TO anon, authenticated
WITH CHECK (true);

CREATE POLICY "Enable read feedback for everyone"
ON app_feedback FOR SELECT
TO anon, authenticated
USING (true);
