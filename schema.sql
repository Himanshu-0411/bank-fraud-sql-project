
create database bank;
use bank;

CREATE TABLE customers (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(200) NOT NULL,
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(50),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE accounts (
  account_id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  account_number VARCHAR(50) UNIQUE NOT NULL,
  account_type VARCHAR(50) NOT NULL,
  balance DECIMAL(14,2) DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

CREATE TABLE transactions (
  transaction_id INT AUTO_INCREMENT PRIMARY KEY,
  account_id INT NOT NULL,
  tx_type VARCHAR(50) NOT NULL, -- 'debit','credit','transfer'
  amount DECIMAL(14,2) NOT NULL,
  tx_time DATETIME NOT NULL,
  counterparty_account VARCHAR(50),
  location VARCHAR(200), -- format 'City,CC' (CC=country code)
  description TEXT,
  FOREIGN KEY (account_id) REFERENCES accounts(account_id) ON DELETE CASCADE,
  CHECK (amount > 0)
);

CREATE TABLE fraud_alerts (
  alert_id INT AUTO_INCREMENT PRIMARY KEY,
  transaction_id INT NOT NULL,
  alert_type VARCHAR(100) NOT NULL,
  score DECIMAL(5,2) DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX idx_transactions_account_time ON transactions(account_id, tx_time);
CREATE INDEX idx_transactions_tx_time ON transactions(tx_time);
CREATE INDEX idx_transactions_amount ON transactions(amount);
