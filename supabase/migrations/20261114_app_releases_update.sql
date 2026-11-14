-- MediBond BD App Releases & Remote Config Migration (Production)
-- Table for version announcements and mandatory update checking

CREATE TABLE IF NOT EXISTS public.app_releases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    platform TEXT NOT NULL DEFAULT 'android',
    channel TEXT NOT NULL DEFAULT 'production',
    version_name TEXT NOT NULL,
    build_number INT NOT NULL,
    minimum_supported_build INT NOT NULL DEFAULT 1,
    release_notes TEXT NOT NULL DEFAULT '',
    update_url TEXT NOT NULL DEFAULT '',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    published_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.app_releases ENABLE ROW LEVEL SECURITY;

-- Allow public read access to active production release records
CREATE POLICY "Public read active production app releases"
    ON public.app_releases
    FOR SELECT
    USING (is_active = TRUE AND channel = 'production' AND platform = 'android');

-- Insert initial release record
INSERT INTO public.app_releases (platform, channel, version_name, build_number, minimum_supported_build, release_notes, update_url, is_active)
VALUES ('android', 'production', '1.0.0', 1, 1, 'Welcome to MediBond BD! Production release.', 'https://play.google.com/store/apps/details?id=com.nethivo.medibond_bd', TRUE)
ON CONFLICT DO NOTHING;
