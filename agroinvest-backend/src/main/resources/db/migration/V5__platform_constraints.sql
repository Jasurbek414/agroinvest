ALTER TABLE projects ADD CONSTRAINT chk_project_expected_return CHECK (expected_return_pct >= 0 AND expected_return_pct <= 100);
ALTER TABLE projects ADD CONSTRAINT chk_project_commission CHECK (commission_pct >= 0 AND commission_pct <= 100);
ALTER TABLE projects ADD CONSTRAINT chk_project_investor_share CHECK (investor_share_pct >= 0 AND investor_share_pct <= 100);
ALTER TABLE projects ADD CONSTRAINT chk_project_farmer_share CHECK (farmer_share_pct >= 0 AND farmer_share_pct <= 100);
ALTER TABLE projects ADD CONSTRAINT chk_project_shares_sum CHECK (investor_share_pct + farmer_share_pct = 100);
ALTER TABLE projects ADD CONSTRAINT chk_project_target_amount CHECK (target_amount > 0);
ALTER TABLE projects ADD CONSTRAINT chk_project_raised_amount CHECK (raised_amount >= 0 AND raised_amount <= target_amount);

ALTER TABLE investments ADD CONSTRAINT chk_investment_amount CHECK (amount > 0);
ALTER TABLE investments ADD CONSTRAINT chk_investment_share CHECK (share_pct >= 0 AND share_pct <= 100);

ALTER TABLE transactions ADD CONSTRAINT chk_transaction_amount CHECK (amount > 0);

ALTER TABLE wallets ADD CONSTRAINT chk_wallet_balance CHECK (balance >= 0);
ALTER TABLE wallets ADD CONSTRAINT chk_wallet_frozen CHECK (frozen >= 0);

ALTER TABLE withdrawal_requests ADD CONSTRAINT chk_withdrawal_amount CHECK (amount > 0);
