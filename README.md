# Bank Transactions Fraud Analysis

A SQL project that models bank accounts and transactions and demonstrates fraud-detection queries using pure SQL. Includes schema, sample data, analytical queries (aggregation, window functions, CTEs), performance notes, and interview guidance.

## Overview
This project simulates a bank database with customers, accounts, transactions, and alerts. The goal is to detect suspicious transactions using SQL logic: frequent high-value transactions, rapid transfers, unusual locations, and velocity rules.

## Files
- schema.sql  
- sample_data.sql  
- queries.sql  
- ER_diagram.txt  
- resume_lines.txt  
- presentation_tips.txt  
- final_notes.txt

## Running the Project
1. Create DB: `createdb bank_fraud`
2. Load schema: `psql -d bank_fraud -f schema.sql`
3. Load sample data: `psql -d bank_fraud -f sample_data.sql`
4. Run queries: `psql -d bank_fraud -f queries.sql`

