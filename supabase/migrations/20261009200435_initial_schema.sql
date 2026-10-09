CREATE TYPE user_role AS ENUM ('youth', 'company');
CREATE TYPE approval_status AS ENUM('pending', 'approved', 'rejected');

CREATE TABLE postal_codes(
    postal_code VARCHAR(4) PRIMARY KEY,
    city TEXT NOT NULL
);

CREATE TABLE profiles(
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    role user_role NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

CREATE TABLE youth_profiles (
    user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    first_name TEXT NOT NULL,
    postal_code VARCHAR(4) NOT NULL REFERENCES postal_codes(postal_code) NOT NULL,
    parent_email TEXT,
    is_parent_approved BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

CREATE TABLE parent_approvals(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    youth_user_id UUID NOT NULL REFERENCES youth_profiles(user_id) ON DELETE CASCADE,
    token UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    parent_email TEXT NOT NULL,
    status approval_status DEFAULT 'pending' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    ip_address TEXT
);

CREATE TABLE company_profiles(
    user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    company_name TEXT NOT NULL,
    cvr_number TEXT NOT NULL,
    street_name TEXT NOT NULL,
    street_number TEXT NOT NULL,
    postal_code VARCHAR(4) NOT NULL REFERENCES postal_codes(postal_code),
    is_verified BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

CREATE TABLE job_invitations(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES company_profiles(user_id) ON DELETE CASCADE,
    youth_id UUID NOT NULL REFERENCES youth_profiles(user_id) ON DELETE CASCADE,
    job_title TEXT NOT NULL,
    job_details TEXT NOT NULL,
    status approval_status DEFAULT 'pending' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    responed_at TIMESTAMPTZ
);  

-- ROW LEVEL SECURITY
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE youth_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users ca see their own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Youth can see and update their own profile"
    ON youth_profiles FOR ALL
    USING (auth.uid() = user_id);

-- Verificerede virksomheder skal kun kunne se forældregodkendte unge
CREATE POLICY "Verified companies can only see parent verified profiles"
    ON youth_profiles FOR SELECT
    USING (
        is_parent_approved = TRUE
        AND EXISTS(
            SELECT 1 FROM company_profiles
            WHERE user_id = auth.uid() AND is_verified = TRUE
        )
    );

CREATE POLICY "All authenticated profiles can see approved companies"
    ON company_profiles FOR SELECT
    TO authenticated
    USING (is_verified = TRUE);

CREATE POLICY "Company can update their own profile"
    ON company_profiles FOR ALL
    USING (auth.uid() = user_id);

-- Kun afsender og modtager af invitation skal kunne se invitationen
CREATE POLICY "Both profiles can see the invitation"
    ON job_invitations FOR SELECT
    USING (auth.uid() = company_id OR auth.uid() = youth_id);

-- Kun verificerede virksomheder kan sende invitation til forældregodkendte unge
CREATE POLICY "Verified companies can send invitations"
    ON job_invitations FOR INSERT
    WITH CHECK(
        auth.uid() = company_id
        AND EXISTS(
            SELECT 1 FROM company_profiles
            WHERE user_id = auth.uid() AND is_verified = TRUE
        )
        AND EXISTS(
            SELECT 1 FROM youth_profiles
            WHERE user_id = youth_id AND is_parent_approved = TRUE
        )
    );

-- En ung må kun opdatere status på invitationer sendt til dem selv
CREATE POLICY "Youth can respond to invitations"
    ON job_invitations FOR update
    USING (auth.uid() = youth_id)
    WITH CHECK (auth.uid() = youth_id);
