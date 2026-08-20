-- 003_seed.sql (Postgres)
\connect wholesales_db

INSERT INTO companies (name, email, password_hash, bank_code, account_number, balance)
VALUES ('Seed Company', 'seed@company.test', '$2a$10$placeholderhash', 'BRI', '000111222', 1000000.00)
ON CONFLICT (email) DO UPDATE SET email = EXCLUDED.email;