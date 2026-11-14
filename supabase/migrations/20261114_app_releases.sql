-- MediBond BD App Releases & Non-Sensitive Remote Config Migration
-- Table for version announcements and mandatory update checking

CREATE TABLE IF NOT EXISTS public.app_releases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    platform TEXT NOT NULL DEFAULT 'android',
    version TEXT NOT NULL,
    build_number INT NOT NULL,
    minimum_supported_build INT NOT NULL DEFAULT 1,
    update_message TEXT NOT NULL DEFAULT '',
    store_url TEXT NOT NULL DEFAULT '',
    published_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.app_releases ENABLE ROW LEVEL SECURITY;

-- Public read access for active release information
CREATE POLICY "Public read active app releases"
    ON public.app_releases
    FOR SELECT
    USING (is_active = TRUE);

-- Insert initial release record
INSERT INTO public.app_releases (platform, version, build_number, minimum_supported_build, update_message, store_url, is_active)
VALUES ('android', '1.0.0', 1, 1, 'Welcome to MediBond BD!', 'https://play.google.com/store/apps/details?id=com.nethivo.medibond_bd', TRUE)
ON CONFLICT DO NOTHING;
