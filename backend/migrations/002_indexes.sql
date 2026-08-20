-- 002_indexes.sql
\connect wholesales_db

CREATE INDEX IF NOT EXISTS idx_companies_email ON companies(email);
CREATE INDEX IF NOT EXISTS idx_companies_account ON companies(account_number);
CREATE INDEX IF NOT EXISTS idx_transfers_trace ON transfers(trace_id);
CREATE INDEX IF NOT EXISTS idx_transfers_from ON transfers(from_company_id);
CREATE INDEX IF NOT EXISTS idx_topups_company ON topups(company_id);
