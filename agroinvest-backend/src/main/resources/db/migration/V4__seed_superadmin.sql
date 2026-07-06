-- Default SuperAdmin account setup (Initial password: changeme123 - MUST be changed on first login)
INSERT INTO users (role, full_name, phone_number, password_hash, kyc_status, is_active)
VALUES (
    'SUPERADMIN',
    'Super Admin',
    '+998901234567',
    '$2a$12$K1Lp49Rbe9rG/G9yq.6ySu2zZ3.3j168sBfPz7rQ103Eex3F3DFe.',
    'VERIFIED',
    true
);

-- Default platform settings setup
INSERT INTO platform_settings (setting_key, setting_value, description) VALUES
  ('default_commission_pct',        '10',     'Default platform commission percentage (%)'),
  ('min_investment_amount',         '100000', 'Minimum investment amount in UZS'),
  ('max_investment_cancel_hours',   '24',     'Maximum allowed time to cancel investment (hours)'),
  ('report_frequency_days',         '14',     'Required frequency of reports (days)'),
  ('default_investor_share_pct',    '70',     'Default investor share of net profits (%)'),
  ('default_farmer_share_pct',      '30',     'Default farmer share of net profits (%)'),
  ('otp_expiry_minutes',            '5',      'OTP code expiry time (minutes)'),
  ('max_otp_attempts',              '3',      'Maximum OTP attempts allowed before lock'),
  ('jwt_access_expiry_seconds',     '900',    'JWT access token expiry (seconds = 15 minutes)'),
  ('jwt_refresh_expiry_days',       '30',     'JWT refresh token expiry (days)');
