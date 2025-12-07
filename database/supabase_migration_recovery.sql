-- VOO Citizen App - Recovery Points Migration
-- Run this in Supabase SQL Editor:
-- https://supabase.com/dashboard/project/xzhmdxtzpuxycvsatjoe/sql/new

-- Recovery Points Table - tracks password reset attempts
CREATE TABLE recovery_points (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES app_users(id) ON DELETE CASCADE,
  phone TEXT NOT NULL,
  recovery_token TEXT,
  ip_address TEXT,
  device_info TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'used', 'expired')),
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '15 minutes'),
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_recovery_points_phone ON recovery_points(phone);
CREATE INDEX idx_recovery_points_user_id ON recovery_points(user_id);
CREATE INDEX idx_recovery_points_status ON recovery_points(status);
CREATE INDEX idx_recovery_points_created ON recovery_points(created_at DESC);
CREATE INDEX idx_recovery_points_expires ON recovery_points(expires_at);

-- Enable Row Level Security
ALTER TABLE recovery_points ENABLE ROW LEVEL SECURITY;

-- Auto-expire old recovery points (run via cron or manually)
-- UPDATE recovery_points SET status = 'expired' WHERE expires_at < NOW() AND status = 'pending';
