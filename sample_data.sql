-- Small sample data for demonstration

INSERT INTO customers(full_name, email, phone) VALUES
('Amit Sharma','amit.sharma@example.com','+919876543210'),
('Neha Singh','neha.singh@example.com','+919812345678'),
('Rohit Verma','rohit.verma@example.com','+919900112233');

INSERT INTO accounts(customer_id, account_number, account_type, balance) VALUES
(1, 'ACC1000001', 'savings', 15000.00),
(1, 'ACC1000002', 'current', 5000.00),
(2, 'ACC2000001', 'savings', 25000.00),
(3, 'ACC3000001', 'savings', 800.00);

-- Transactions: normal activity
INSERT INTO transactions(account_id, tx_type, amount, tx_time, counterparty_account, location, description) VALUES
(1,'debit', 200.00,  '2025-10-01 09:15:00', NULL, 'Mumbai,IN','groceries'),
(1,'credit',5000.00, '2025-10-03 10:00:00', NULL, 'Mumbai,IN','salary'),
(2,'debit',100.00,  '2025-10-05 14:30:00', NULL, 'Pune,IN','utility bill'),
(3,'debit',50.00,   '2025-10-07 18:00:00', NULL, 'Delhi,IN','coffee');

-- Suspicious patterns: large & frequent
INSERT INTO transactions(account_id, tx_type, amount, tx_time, counterparty_account, location, description) VALUES
(1,'transfer',4000.00,'2025-10-10 08:00:00','ACC2000001','Mumbai,IN','transfer to friend'),
(1,'transfer',3500.00,'2025-10-10 08:05:00','ACC2000001','Mumbai,IN','transfer to friend 2'),
(1,'transfer',3000.00,'2025-10-10 08:07:00','ACC2000001','Mumbai,IN','rapid transfers'),
(2,'transfer',12000.00,'2025-10-11 02:00:00','ACC9999999','Lagos,NG','odd overseas transfer'),
(3,'debit',700.00,'2025-10-12 03:10:00', NULL, 'Kolkata,IN','atm withdrawal');

-- Add a very high-frequency small tx series (velocity) using Postgres generate_series
INSERT INTO transactions(account_id, tx_type, amount, tx_time, counterparty_account, location, description)
SELECT 1,'debit', 50.00, '2025-10-13 09:' || lpad((i::text),2,'0') || ':00', NULL, 'Mumbai,IN', 'micro payment'
FROM generate_series(0,9) AS s(i);
