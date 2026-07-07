-- ENUM Types Creation (Checking/Dropping doesn't exist yet as clean database is assumed)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('SUPERADMIN','ADMIN','MODERATOR','VERIFIER','INVESTOR','FARMER');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'kyc_status') THEN
        CREATE TYPE kyc_status AS ENUM ('PENDING','VERIFIED','REJECTED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'asset_type') THEN
        CREATE TYPE asset_type AS ENUM ('LIVESTOCK','CROP','GREENHOUSE','POULTRY','BEEKEEPING','OTHER');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'risk_level') THEN
        CREATE TYPE risk_level AS ENUM ('LOW','MEDIUM','HIGH');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'proj_status') THEN
        CREATE TYPE proj_status AS ENUM ('PENDING','APPROVED','FUNDING','ACTIVE','COMPLETED','CANCELLED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'inv_status') THEN
        CREATE TYPE inv_status AS ENUM ('RESERVED','CONFIRMED','ACTIVE','PAID_OUT','REFUNDED','CANCELLED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'txn_type') THEN
        CREATE TYPE txn_type AS ENUM ('DEPOSIT','PAYOUT','COMMISSION','WITHDRAWAL','REFUND','FARMER_PAYOUT');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'txn_status') THEN
        CREATE TYPE txn_status AS ENUM ('PENDING','COMPLETED','FAILED','CANCELLED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'pay_provider') THEN
        CREATE TYPE pay_provider AS ENUM ('PAYME','CLICK','MANUAL','INTERNAL');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'wd_status') THEN
        CREATE TYPE wd_status AS ENUM ('PENDING','APPROVED','PROCESSED','REJECTED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'disp_status') THEN
        CREATE TYPE disp_status AS ENUM ('OPEN','INVESTIGATING','RESOLVED','CLOSED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'rep_type') THEN
        CREATE TYPE rep_type AS ENUM ('ROUTINE','EMERGENCY','VERIFICATION','FINAL','COMPLETION');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notif_ch') THEN
        CREATE TYPE notif_ch AS ENUM ('IN_APP','SMS','TELEGRAM','EMAIL');
    END IF;
END$$;

-- Table 1: users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role user_role NOT NULL DEFAULT 'INVESTOR',
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255),
    avatar_url VARCHAR(500),
    passport_data TEXT, -- AES-256 encrypted string
    kyc_status kyc_status DEFAULT 'PENDING',
    kyc_rejected_reason VARCHAR(500),
    kyc_verified_at TIMESTAMP,
    kyc_verified_by UUID REFERENCES users(id),
    rating DECIMAL(3,2) DEFAULT 0.00,
    total_projects INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    is_blocked BOOLEAN DEFAULT false,
    blocked_reason VARCHAR(500),
    blocked_at TIMESTAMP,
    blocked_by UUID REFERENCES users(id),
    telegram_chat_id BIGINT,
    fcm_token VARCHAR(500),
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- Table 2: wallets
CREATE TABLE wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id),
    balance DECIMAL(18,2) DEFAULT 0,
    frozen DECIMAL(18,2) DEFAULT 0,
    total_earned DECIMAL(18,2) DEFAULT 0,
    total_withdrawn DECIMAL(18,2) DEFAULT 0,
    updated_at TIMESTAMP DEFAULT now()
);

-- Table 3: projects
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farmer_id UUID NOT NULL REFERENCES users(id),
    asset_type asset_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    region VARCHAR(100),
    location_details VARCHAR(500),
    target_amount DECIMAL(18,2) NOT NULL,
    raised_amount DECIMAL(18,2) DEFAULT 0,
    min_investment DECIMAL(18,2) DEFAULT 100000,
    max_investment DECIMAL(18,2),
    expected_return_pct DECIMAL(5,2) NOT NULL,
    commission_pct DECIMAL(5,2) DEFAULT 10,
    investor_share_pct DECIMAL(5,2) DEFAULT 70,
    farmer_share_pct DECIMAL(5,2) DEFAULT 30,
    duration_days INTEGER NOT NULL,
    start_date DATE,
    end_date DATE,
    risk_level risk_level NOT NULL,
    status proj_status DEFAULT 'PENDING',
    rejection_reason VARCHAR(500),
    media_urls JSONB DEFAULT '[]',
    total_investors INTEGER DEFAULT 0,
    report_frequency_days INTEGER DEFAULT 14,
    admin_notes TEXT,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP,
    completed_at TIMESTAMP,
    final_amount DECIMAL(18,2),
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- Table 4: investments
CREATE TABLE investments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id),
    investor_id UUID NOT NULL REFERENCES users(id),
    amount DECIMAL(18,2) NOT NULL,
    share_pct DECIMAL(10,6) NOT NULL,
    idempotency_key VARCHAR(255) UNIQUE,
    contract_url VARCHAR(500),
    contract_signed_at TIMESTAMP,
    status inv_status DEFAULT 'RESERVED',
    payout_amount DECIMAL(18,2),
    payout_date TIMESTAMP,
    cancelled_at TIMESTAMP,
    cancel_reason VARCHAR(500),
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- Table 5: transactions (IMMUTABLE)
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    project_id UUID REFERENCES projects(id),
    investment_id UUID REFERENCES investments(id),
    type txn_type NOT NULL,
    amount DECIMAL(18,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'UZS',
    payment_provider pay_provider,
    external_payment_id VARCHAR(255),
    idempotency_key VARCHAR(255) UNIQUE,
    status txn_status DEFAULT 'PENDING',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT now()
);

-- Table 6: reports
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id),
    submitted_by UUID NOT NULL REFERENCES users(id),
    report_type rep_type NOT NULL,
    media_urls JSONB DEFAULT '[]',
    geo_lat DECIMAL(10,7),
    geo_lng DECIMAL(10,7),
    geo_accuracy FLOAT,
    notes TEXT,
    is_verified BOOLEAN DEFAULT false,
    verified_by UUID REFERENCES users(id),
    verified_at TIMESTAMP,
    admin_comment TEXT,
    created_at TIMESTAMP DEFAULT now()
);

-- Table 7: withdrawal_requests
CREATE TABLE withdrawal_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    amount DECIMAL(18,2) NOT NULL,
    status wd_status DEFAULT 'PENDING',
    bank_name VARCHAR(100),
    card_number VARCHAR(20),
    payment_details JSONB,
    admin_comment VARCHAR(500),
    processed_by UUID REFERENCES users(id),
    processed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT now()
);

-- Table 8: disputes
CREATE TABLE disputes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id),
    filed_by UUID NOT NULL REFERENCES users(id),
    against_user UUID NOT NULL REFERENCES users(id),
    dispute_type VARCHAR(100),
    description TEXT NOT NULL,
    status disp_status DEFAULT 'OPEN',
    resolution TEXT,
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- Table 9: notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    type VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    channel notif_ch DEFAULT 'IN_APP',
    sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT now()
);

-- Table 10: otp_codes
CREATE TABLE otp_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number VARCHAR(20) NOT NULL,
    code VARCHAR(6) NOT NULL,
    purpose VARCHAR(50),
    expires_at TIMESTAMP NOT NULL,
    is_used BOOLEAN DEFAULT false,
    attempts INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT now()
);
