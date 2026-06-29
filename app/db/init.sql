-- Banking App Database Schema (PostgreSQL / RDS)

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Accounts table
CREATE TABLE accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    account_number VARCHAR(20) UNIQUE NOT NULL,
    account_type VARCHAR(20) CHECK (account_type IN ('savings', 'checking', 'business')),
    balance DECIMAL(15,2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(10) DEFAULT 'active' CHECK (status IN ('active', 'frozen', 'closed')),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Transactions table
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    from_account UUID REFERENCES accounts(id),
    to_account UUID REFERENCES accounts(id),
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    type VARCHAR(20) CHECK (type IN ('transfer', 'deposit', 'withdrawal')),
    description TEXT,
    status VARCHAR(20) DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed')),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_accounts_user ON accounts(user_id);
CREATE INDEX idx_transactions_from ON transactions(from_account);
CREATE INDEX idx_transactions_to ON transactions(to_account);
CREATE INDEX idx_transactions_date ON transactions(created_at DESC);

-- Seed demo data
INSERT INTO users (id, email, password_hash, full_name, phone) VALUES
    ('a1b2c3d4-0001-4000-8000-000000000001', 'john@example.com', '$2b$10$dummyhash', 'John Doe', '+1234567890'),
    ('a1b2c3d4-0002-4000-8000-000000000002', 'jane@example.com', '$2b$10$dummyhash', 'Jane Smith', '+1987654321');

INSERT INTO accounts (user_id, account_number, account_type, balance) VALUES
    ('a1b2c3d4-0001-4000-8000-000000000001', 'ACC-10001001', 'savings', 15420.50),
    ('a1b2c3d4-0001-4000-8000-000000000001', 'ACC-10001002', 'checking', 3280.75),
    ('a1b2c3d4-0002-4000-8000-000000000002', 'ACC-10002001', 'savings', 42100.00);
