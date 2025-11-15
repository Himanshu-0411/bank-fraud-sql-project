-- Fraud-detection & analytics queries

-- 1) High-value transactions (simple rule)
SELECT t.transaction_id, a.account_number, c.full_name, t.amount, t.tx_time, t.location
FROM transactions t
JOIN accounts a ON a.account_id = t.account_id
JOIN customers c ON c.customer_id = a.customer_id
WHERE t.amount >= 5000
ORDER BY t.amount DESC;

-- 2) Rapid consecutive transfers from same account (velocity rule)
-- Find transfers where the previous transfer for same account was within 10 minutes
WITH transfers AS (
  SELECT t.*, a.account_number, c.full_name
  FROM transactions t
  JOIN accounts a ON a.account_id = t.account_id
  JOIN customers c ON c.customer_id = a.customer_id
  WHERE t.tx_type = 'transfer'
), numbered AS (
  SELECT *, LAG(tx_time) OVER (PARTITION BY account_id ORDER BY tx_time) AS prev_time,
         ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY tx_time) AS rn
  FROM transfers
)
SELECT n.account_id, n.account_number, n.full_name, n.transaction_id, n.amount, n.tx_time, n.prev_time
FROM numbered n
WHERE n.prev_time IS NOT NULL
  AND EXTRACT(EPOCH FROM (n.tx_time - n.prev_time))/60 <= 10
ORDER BY n.account_id, n.tx_time;

-- 3) Multiple high-value transfers to same counterparty
SELECT account_id, counterparty_account, COUNT(*) AS transfers_to_same, SUM(amount) AS total_sent
FROM transactions
WHERE tx_type = 'transfer'
GROUP BY account_id, counterparty_account
HAVING COUNT(*) >= 2 AND SUM(amount) >= 5000
ORDER BY total_sent DESC;

-- 4) Unusual location vs recent locations (last 30 days)
WITH recent_locations AS (
  SELECT account_id, ARRAY_AGG(DISTINCT SPLIT_PART(location, ',', 2)) AS countries
  FROM transactions
  WHERE tx_time >= NOW() - INTERVAL '30 days'
  GROUP BY account_id
)
SELECT t.transaction_id, a.account_number, c.full_name, t.location, rl.countries
FROM transactions t
JOIN accounts a ON a.account_id = t.account_id
JOIN customers c ON c.customer_id = a.customer_id
LEFT JOIN recent_locations rl ON rl.account_id = t.account_id
WHERE rl.countries IS NOT NULL
  AND NOT (SPLIT_PART(t.location, ',', 2) = ANY(rl.countries))
  AND t.tx_time >= NOW() - INTERVAL '7 days'
ORDER BY t.tx_time DESC;

-- 5) Score-based alerting: combine rules into a simple score
WITH high_value AS (
  SELECT transaction_id, 1.0 AS score FROM transactions WHERE amount >= 5000
), rapid AS (
  SELECT transaction_id, 1.5 AS score
  FROM (
    SELECT transaction_id, account_id, tx_time,
      LAG(tx_time) OVER (PARTITION BY account_id ORDER BY tx_time) AS prev_time
    FROM transactions WHERE tx_type='transfer'
  ) t
  WHERE prev_time IS NOT NULL AND EXTRACT(EPOCH FROM (tx_time - prev_time))/60 <= 10
), overseas AS (
  SELECT transaction_id, 1.2 AS score
  FROM transactions WHERE location IS NOT NULL AND SPLIT_PART(location, ',', 2) NOT IN ('IN')
)
SELECT t.transaction_id, a.account_number, c.full_name, t.amount, t.tx_time,
  COALESCE(h.score,0) + COALESCE(r.score,0) + COALESCE(o.score,0) AS fraud_score
FROM transactions t
JOIN accounts a ON a.account_id = t.account_id
JOIN customers c ON c.customer_id = a.customer_id
LEFT JOIN high_value h ON h.transaction_id = t.transaction_id
LEFT JOIN rapid r ON r.transaction_id = t.transaction_id
LEFT JOIN overseas o ON o.transaction_id = t.transaction_id
WHERE COALESCE(h.score,0) + COALESCE(r.score,0) + COALESCE(o.score,0) > 0
ORDER BY fraud_score DESC;

-- 6) Insert alerts into fraud_alerts table for high-scoring txns (example)
INSERT INTO fraud_alerts(transaction_id, alert_type, score)
SELECT transaction_id, 'combined_score', COALESCE(h.score,0) + COALESCE(r.score,0) + COALESCE(o.score,0)
FROM (
  SELECT t.transaction_id,
    (CASE WHEN t.amount >= 5000 THEN 1.0 ELSE 0 END) AS hscore,
    (CASE WHEN t.tx_type='transfer' AND EXISTS (
        SELECT 1 FROM transactions t2
        WHERE t2.account_id = t.account_id
          AND t2.tx_time < t.tx_time
          AND EXTRACT(EPOCH FROM (t.tx_time - t2.tx_time))/60 <= 10
    ) THEN 1.5 ELSE 0 END) AS rscore,
    (CASE WHEN t.location IS NOT NULL AND SPLIT_PART(t.location, ',', 2) NOT IN ('IN') THEN 1.2 ELSE 0 END) AS oscore
  FROM transactions t
) tsc
CROSS JOIN LATERAL (
  SELECT tsc.transaction_id,
         tsc.hscore AS score_h,
         tsc.rscore AS score_r,
         tsc.oscore AS score_o
) s
WHERE (s.score_h + s.score_r + s.score_o) > 0
-- Note: adapt ON CONFLICT or unique constraint if needed in production;

-- 7) Aggregation: total amount sent by each account in last 30 days
SELECT a.account_number, c.full_name, SUM(amount) AS total_sent_30d
FROM transactions t
JOIN accounts a ON a.account_id = t.account_id
JOIN customers c ON c.customer_id = a.customer_id
WHERE t.tx_time >= NOW() - INTERVAL '30 days' AND t.tx_type IN ('transfer','debit')
GROUP BY a.account_number, c.full_name
ORDER BY total_sent_30d DESC;

-- 8) EXPLAIN example (run in psql to capture plan)
EXPLAIN ANALYZE
SELECT account_id, SUM(amount) FROM transactions WHERE tx_time >= NOW() - INTERVAL '90 days' GROUP BY account_id;
