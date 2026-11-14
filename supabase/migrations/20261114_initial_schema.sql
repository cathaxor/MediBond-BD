-- MediBond BD Supabase PostgreSQL Database Migration Script
-- Version: 1.0.0
-- Security: Row Level Security (RLS) enabled on all user-owned tables

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. USER PROFILES TABLE (Linked to auth.users)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    date_of_birth DATE,
    age INT,
    gender TEXT,
    blood_group TEXT DEFAULT NULL,
    height_cm NUMERIC,
    weight_kg NUMERIC,
    allergies TEXT,
    medical_notes TEXT,
    avatar_color_value BIGINT DEFAULT 35961,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. FAMILY MEMBERS TABLE
CREATE TABLE IF NOT EXISTS public.family_members (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    relationship TEXT NOT NULL,
    relationship_bn TEXT NOT NULL DEFAULT 'পরিবার',
    age INT NOT NULL DEFAULT 30,
    birth_year INT,
    gender TEXT,
    blood_group TEXT DEFAULT NULL,
    avatar_initials TEXT NOT NULL DEFAULT 'FM',
    avatar_color_value BIGINT NOT NULL DEFAULT 35961,
    emergency_contact TEXT DEFAULT '',
    medical_notes TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. MEDICINES TABLE
CREATE TABLE IF NOT EXISTS public.medicines (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    family_member_id TEXT NOT NULL,
    name TEXT NOT NULL,
    strength TEXT DEFAULT '',
    form TEXT NOT NULL DEFAULT 'tablet',
    dosage TEXT NOT NULL DEFAULT '1 Tablet',
    instructions TEXT NOT NULL DEFAULT 'afterFood',
    times_per_day INT NOT NULL DEFAULT 1,
    stock_count INT NOT NULL DEFAULT 20,
    reorder_threshold INT NOT NULL DEFAULT 5,
    color_hex BIGINT NOT NULL DEFAULT 35961,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_paused BOOLEAN NOT NULL DEFAULT FALSE,
    start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_date TIMESTAMPTZ,
    weekdays TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7',
    notes TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. DOSE SCHEDULES TABLE
CREATE TABLE IF NOT EXISTS public.dose_schedules (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    medicine_id TEXT NOT NULL REFERENCES public.medicines(id) ON DELETE CASCADE,
    reminder_time TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. DOSE EVENTS TABLE
CREATE TABLE IF NOT EXISTS public.dose_events (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    medicine_id TEXT NOT NULL,
    profile_id TEXT NOT NULL,
    scheduled_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    action_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. EMERGENCY CONTACTS TABLE
CREATE TABLE IF NOT EXISTS public.emergency_contacts (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    profile_id TEXT NOT NULL,
    name TEXT NOT NULL,
    relationship TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. PRESCRIPTIONS TABLE
CREATE TABLE IF NOT EXISTS public.prescriptions (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    profile_id TEXT NOT NULL,
    title TEXT NOT NULL,
    doctor_name TEXT DEFAULT '',
    hospital_name TEXT DEFAULT '',
    prescription_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT DEFAULT '',
    tags TEXT DEFAULT '',
    document_path TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. USER SETTINGS TABLE
CREATE TABLE IF NOT EXISTS public.user_settings (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    setting_key TEXT NOT NULL,
    setting_value TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, setting_key)
);

-- ========================================================
-- ROW LEVEL SECURITY (RLS) POLICIES FOR USER ACCOUNT ISOLATION
-- ========================================================

-- Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medicines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dose_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dose_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- 1. user_profiles Policies
CREATE POLICY "Users can select own profile" ON public.user_profiles FOR SELECT USING (id = auth.uid());
CREATE POLICY "Users can insert own profile" ON public.user_profiles FOR INSERT WITH CHECK (id = auth.uid());
CREATE POLICY "Users can update own profile" ON public.user_profiles FOR UPDATE USING (id = auth.uid());
CREATE POLICY "Users can delete own profile" ON public.user_profiles FOR DELETE USING (id = auth.uid());

-- 2. family_members Policies
CREATE POLICY "Users can select own family members" ON public.family_members FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own family members" ON public.family_members FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own family members" ON public.family_members FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete own family members" ON public.family_members FOR DELETE USING (user_id = auth.uid());

-- 3. medicines Policies
CREATE POLICY "Users can select own medicines" ON public.medicines FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own medicines" ON public.medicines FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own medicines" ON public.medicines FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete own medicines" ON public.medicines FOR DELETE USING (user_id = auth.uid());

-- 4. dose_schedules Policies
CREATE POLICY "Users can select own dose schedules" ON public.dose_schedules FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own dose schedules" ON public.dose_schedules FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own dose schedules" ON public.dose_schedules FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete own dose schedules" ON public.dose_schedules FOR DELETE USING (user_id = auth.uid());

-- 5. dose_events Policies
CREATE POLICY "Users can select own dose events" ON public.dose_events FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own dose events" ON public.dose_events FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own dose events" ON public.dose_events FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete own dose events" ON public.dose_events FOR DELETE USING (user_id = auth.uid());

-- 6. emergency_contacts Policies
CREATE POLICY "Users can select own emergency contacts" ON public.emergency_contacts FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own emergency contacts" ON public.emergency_contacts FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own emergency contacts" ON public.emergency_contacts FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete own emergency contacts" ON public.emergency_contacts FOR DELETE USING (user_id = auth.uid());

-- 7. prescriptions Policies
CREATE POLICY "Users can select own prescriptions" ON public.prescriptions FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own prescriptions" ON public.prescriptions FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own prescriptions" ON public.prescriptions FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete own prescriptions" ON public.prescriptions FOR DELETE USING (user_id = auth.uid());

-- 8. user_settings Policies
CREATE POLICY "Users can select own settings" ON public.user_settings FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own settings" ON public.user_settings FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own settings" ON public.user_settings FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete own settings" ON public.user_settings FOR DELETE USING (user_id = auth.uid());
