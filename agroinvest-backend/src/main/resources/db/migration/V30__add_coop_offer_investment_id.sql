ALTER TABLE coop_offers ADD COLUMN investment_id UUID REFERENCES investments(id);
