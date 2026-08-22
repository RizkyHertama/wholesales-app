CREATE TABLE IF NOT EXISTS companies (
    id             BIGSERIAL    PRIMARY KEY,
    name           VARCHAR(255) NOT NULL,
    email          VARCHAR(255) NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL,
    phone          VARCHAR(20),
    balance        DECIMAL(15,2) NOT NULL DEFAULT 0,
    account_number VARCHAR(20) UNIQUE,
    created_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Tabel history transfer
CREATE TABLE IF NOT EXISTS transfers (
    id                BIGSERIAL    PRIMARY KEY,
    from_company_id   BIGINT       REFERENCES companies(id),
    to_company_id     BIGINT       REFERENCES companies(id),
    to_account_number VARCHAR(50)  NOT NULL,
    to_bank_name      VARCHAR(100),
    amount            DECIMAL(15,2) NOT NULL,
    fee               DECIMAL(15,2) NOT NULL DEFAULT 0,
    payment_method    VARCHAR(20)  NOT NULL, -- BI_FAST, RTGS, SKN
    transfer_type     VARCHAR(20)  NOT NULL, -- INTERNAL, EXTERNAL
    status            VARCHAR(20)  NOT NULL DEFAULT 'SUCCESS',
    note              TEXT,
    created_at        TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Index untuk mempercepat query history transfer
CREATE INDEX IF NOT EXISTS idx_transfers_from ON transfers(from_company_id);
CREATE INDEX IF NOT EXISTS idx_transfers_to   ON transfers(to_company_id);

-- Data dummy untuk testing
INSERT INTO companies (name, email, password_hash, phone, balance, account_number)
VALUES
    ('PT Maju Bersama',  'maju@example.com',      '$2a$10$dummy', '081234567890', 50000000, '1234567890'),
    ('PT Sejahtera Jaya','sejahtera@example.com',  '$2a$10$dummy', '089876543210', 25000000, '0987654321'),
    ('PT Admin Bank',    'admin@wholesales.com',   '$2a$10$dummy', '021-5551234',  0,        '0000000001')
ON CONFLICT DO NOTHING;