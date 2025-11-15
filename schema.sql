-- Schema for Bank Transactions Fraud Analysis (Postgres)

CREATE TABLE customers (
  customer_id SERIAL PRIMARY KEY,
  full_name TEXT NOT NULL,
  email TEXT UNIQUE,
  phone TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE accounts (
  account_id SERIAL PRIMARY KEY,
  customer_id INT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
  account_number TEXT UNIQUE NOT NULL,
  account_type TEXT NOT NULL,
  balance NUMERIC(14,2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transactions (
  transaction_id SERIAL PRIMARY KEY,
  account_id INT NOT NULL REFERENCES accounts(account_id) ON DELETE CASCADE,
  tx_type TEXT NOT NULL,
  amount NUMERIC(14,2) NOT NULL CHECK (amount > 0),
  tx_time TIMESTAMP NOT NULL,
  counterparty_account TEXT,
  location TEXT,
  description TEXT
);

CREATE TABLE fraud_alerts (
  alert_id SERIAL PRIMARY KEY,
  transaction_id INT NOT NULL REFERENCES transactions(transaction_id) ON DELETE CASCADE,
  alert_type TEXT NOT NULL,
  score NUMERIC(5,2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_transactions_account_time ON transactions(account_id, tx_time);
CREATE INDEX idx_transactions_tx_time ON transactions(tx_time);
CREATE INDEX idx_transactions_amount ON transactions(amount);
