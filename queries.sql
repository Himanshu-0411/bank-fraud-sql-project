-- Fraud detection queries (Postgres)

SELECT t.transaction_id, a.account_number, c.full_name, t.amount, t.tx_time, t.location
FROM transactions t
JOIN accounts a ON a.account_id = t.account_id
JOIN customers c ON c.customer_id = a.customer_id
WHERE t.amount >= 5000
ORDER BY t.amount DESC;

-- More SQL queries included in earlier version (shortened for zip)
