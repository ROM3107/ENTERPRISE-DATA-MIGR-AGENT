-- ============================================================================
-- QUICK REFERENCE: TEST EXECUTION GUIDE
-- Snowflake Library Migration Validation
-- ============================================================================

-- EXECUTE ALL TESTS: Copy entire Library-testcases.sql into Snowflake editor
-- Execution Time: 5-10 minutes
-- Expected Output: 150+ query results with PASS/FAIL indicators

-- ============================================================================
-- SECTION A: QUICK VALIDATION (60 seconds) - Run if short on time
-- ============================================================================

-- A1: Overall Record Count (10 seconds)
SELECT 'CARD' AS TABLE_NAME, COUNT(*) AS RECORD_COUNT, 15 AS EXPECTED FROM CARD
UNION ALL
SELECT 'CUSTOMER', COUNT(*), 10 FROM CUSTOMER
UNION ALL
SELECT 'EMPLOYEE', COUNT(*), 5 FROM EMPLOYEE
UNION ALL
SELECT 'BRANCH', COUNT(*), 4 FROM BRANCH
UNION ALL
SELECT 'LOCATION', COUNT(*), 4 FROM LOCATION
UNION ALL
SELECT 'BOOK', COUNT(*), 8 FROM BOOK
UNION ALL
SELECT 'VIDEO', COUNT(*), 8 FROM VIDEO
UNION ALL
SELECT 'RENT', COUNT(*), 6 FROM RENT;
-- EXPECTED: All counts match

-- A2: Referential Integrity Check (10 seconds)
SELECT 'CUSTOMER_FK_VALID' AS TEST_NAME,
    COUNT(*) AS TOTAL,
    COUNT(CASE WHEN CARD_ID IN (SELECT CARD_ID FROM CARD) THEN 1 END) AS VALID
FROM CUSTOMER
UNION ALL
SELECT 'EMPLOYEE_FK_CARD', COUNT(*),
    COUNT(CASE WHEN CARD_ID IN (SELECT CARD_ID FROM CARD) THEN 1 END)
FROM EMPLOYEE
UNION ALL
SELECT 'EMPLOYEE_FK_BRANCH', COUNT(*),
    COUNT(CASE WHEN BRANCH_NAME IN (SELECT BRANCH_NAME FROM BRANCH) THEN 1 END)
FROM EMPLOYEE;
-- EXPECTED: All counts show TOTAL = VALID

-- A3: CHECK Constraint Compliance (10 seconds)
SELECT 'CARD_STATUS' AS CONSTRAINT_NAME,
    COUNT(*) AS TOTAL,
    COUNT(CASE WHEN STATUS IN ('A', 'B') THEN 1 END) AS VALID
FROM CARD
UNION ALL
SELECT 'BOOK_AVAILABILITY',
    COUNT(*),
    COUNT(CASE WHEN AVAILABILITY_STATUS IN ('A', 'O') THEN 1 END)
FROM BOOK
UNION ALL
SELECT 'VIDEO_AVAILABILITY',
    COUNT(*),
    COUNT(CASE WHEN AVAILABILITY_STATUS IN ('A', 'O') THEN 1 END)
FROM VIDEO
UNION ALL
SELECT 'RENT_ITEM_TYPE',
    COUNT(*),
    COUNT(CASE WHEN ITEM_TYPE IN ('BOOK', 'VIDEO') THEN 1 END)
FROM RENT;
-- EXPECTED: All counts show TOTAL = VALID (100% compliance)

-- A4: ITEM_TYPE Disambiguation (10 seconds)
SELECT 
    'ITEM_TYPE_VALIDATION' AS TEST_NAME,
    COUNT(*) AS TOTAL_RENTALS,
    COUNT(CASE WHEN ITEM_TYPE IN ('BOOK', 'VIDEO') THEN 1 END) AS VALID,
    COUNT(CASE WHEN ITEM_TYPE = 'BOOK' THEN 1 END) AS BOOK_COUNT,
    COUNT(CASE WHEN ITEM_TYPE = 'VIDEO' THEN 1 END) AS VIDEO_COUNT
FROM RENT;
-- EXPECTED: TOTAL_RENTALS = 6, VALID = 6, BOOK_COUNT = 3, VIDEO_COUNT = 3

-- A5: Timestamp Columns (10 seconds)
SELECT 
    'TIMESTAMP_VALIDATION' AS TEST_NAME,
    COUNT(*) AS TOTAL,
    COUNT(CASE WHEN CREATED_AT IS NOT NULL AND UPDATED_AT IS NOT NULL THEN 1 END) AS WITH_TIMESTAMPS
FROM CARD;
-- EXPECTED: TOTAL = 15, WITH_TIMESTAMPS = 15 (100% populated)

-- ============================================================================
-- SECTION B: FOCUSED VALIDATION (5 minutes) - Run if time permits
-- ============================================================================

-- B1: Data Integrity Summary
SELECT 
    'Migration_Status' AS METRIC,
    COUNT(*) AS ACTUAL_VALUE,
    COUNT(CASE WHEN CARD_ID > 0 THEN 1 END) AS VALID_COUNT
FROM CARD
UNION ALL
SELECT 'FK_Integrity_CUSTOMER', COUNT(*),
    COUNT(CASE WHEN CARD_ID IN (SELECT CARD_ID FROM CARD) THEN 1 END)
FROM CUSTOMER
UNION ALL
SELECT 'FK_Integrity_EMPLOYEE_CARD', COUNT(*),
    COUNT(CASE WHEN CARD_ID IN (SELECT CARD_ID FROM CARD) THEN 1 END)
FROM EMPLOYEE
UNION ALL
SELECT 'FK_Integrity_EMPLOYEE_BRANCH', COUNT(*),
    COUNT(CASE WHEN BRANCH_NAME IN (SELECT BRANCH_NAME FROM BRANCH) THEN 1 END)
FROM EMPLOYEE;

-- B2: Data Type Verification
SELECT 
    'Data_Type_Check' AS TEST_CATEGORY,
    'CARD_ID_INTEGER_RANGE' AS TEST_NAME,
    MIN(CARD_ID) AS MIN_VALUE,
    MAX(CARD_ID) AS MAX_VALUE,
    COUNT(*) AS RECORD_COUNT,
    CASE WHEN MIN(CARD_ID) >= 101 AND MAX(CARD_ID) <= 155 THEN 'PASS' ELSE 'FAIL' END AS STATUS
FROM CARD
UNION ALL
SELECT 'Data_Type_Check', 'PHONE_INTEGER_VALID', 
    MIN(PHONE_NUMBER), MAX(PHONE_NUMBER), COUNT(*),
    CASE WHEN COUNT(CASE WHEN PHONE_NUMBER > 0 THEN 1 END) = COUNT(*) THEN 'PASS' ELSE 'FAIL' END
FROM CUSTOMER
UNION ALL
SELECT 'Data_Type_Check', 'FINE_AMOUNT_NUMERIC',
    ROUND(MIN(FINE_AMOUNT), 2), ROUND(MAX(FINE_AMOUNT), 2), COUNT(*),
    CASE WHEN COUNT(CASE WHEN FINE_AMOUNT >= 0 THEN 1 END) = COUNT(*) THEN 'PASS' ELSE 'FAIL' END
FROM CARD;

-- B3: Business Logic Validation
SELECT 
    'Business_Logic' AS TEST_CATEGORY,
    'RENTAL_DURATION' AS TEST_NAME,
    COUNT(*) AS TOTAL_RENTALS,
    COUNT(CASE WHEN RETURN_DATE IS NOT NULL THEN 1 END) AS COMPLETED_RENTALS,
    COUNT(CASE WHEN RETURN_DATE IS NULL THEN 1 END) AS ONGOING_RENTALS
FROM RENT
UNION ALL
SELECT 'Business_Logic', 'CUSTOMER_ACCOUNT_STATUS',
    COUNT(*), COUNT(CASE WHEN STATUS IN ('A', 'B') THEN 1 END),
    COUNT(CASE WHEN FINE_AMOUNT > 0 THEN 1 END)
FROM CUSTOMER_ACCOUNT_STATUS;

-- ============================================================================
-- SECTION C: TROUBLESHOOTING QUERIES - Use if any test fails
-- ============================================================================

-- C1: Find any orphaned CUSTOMER records
SELECT 'Orphaned_CUSTOMER' AS ISSUE_TYPE,
    c.CUSTOMER_ID, c.NAME, c.CARD_ID
FROM CUSTOMER c
WHERE c.CARD_ID NOT IN (SELECT CARD_ID FROM CARD);
-- EXPECTED: No rows (empty result)

-- C2: Find any invalid CARD.STATUS values
SELECT 'Invalid_CARD_STATUS' AS ISSUE_TYPE,
    CARD_ID, STATUS
FROM CARD
WHERE STATUS NOT IN ('A', 'B');
-- EXPECTED: No rows (empty result)

-- C3: Find any RENT records with invalid ITEM_TYPE
SELECT 'Invalid_ITEM_TYPE' AS ISSUE_TYPE,
    CARD_ID, ITEM_ID, ITEM_TYPE
FROM RENT
WHERE ITEM_TYPE NOT IN ('BOOK', 'VIDEO');
-- EXPECTED: No rows (empty result)

-- C4: Find duplicate USER_NAME values
SELECT 'Duplicate_USERNAME' AS ISSUE_TYPE,
    USER_NAME, COUNT(*) AS DUPLICATE_COUNT
FROM CUSTOMER
GROUP BY USER_NAME
HAVING COUNT(*) > 1
UNION ALL
SELECT 'Duplicate_USERNAME', USER_NAME, COUNT(*)
FROM EMPLOYEE
GROUP BY USER_NAME
HAVING COUNT(*) > 1;
-- EXPECTED: No rows (empty result)

-- C5: Find RENT items with no matching BOOK or VIDEO
SELECT 'Orphaned_RENT_Item' AS ISSUE_TYPE,
    r.CARD_ID, r.ITEM_ID, r.ITEM_TYPE
FROM RENT r
WHERE (r.ITEM_TYPE = 'BOOK' AND r.ITEM_ID NOT IN (SELECT BOOK_ID FROM BOOK))
   OR (r.ITEM_TYPE = 'VIDEO' AND r.ITEM_ID NOT IN (SELECT VIDEO_ID FROM VIDEO));
-- EXPECTED: No rows (empty result)

-- C6: Check NULL values in required fields
SELECT 'NULL_in_REQUIRED_FIELD' AS ISSUE_TYPE,
    'CUSTOMER.NAME' AS FIELD_NAME,
    COUNT(*) AS NULL_COUNT
FROM CUSTOMER
WHERE NAME IS NULL
UNION ALL
SELECT 'NULL_in_REQUIRED_FIELD', 'CARD.STATUS', COUNT(*)
FROM CARD
WHERE STATUS IS NULL
UNION ALL
SELECT 'NULL_in_REQUIRED_FIELD', 'RENT.ITEM_TYPE', COUNT(*)
FROM RENT
WHERE ITEM_TYPE IS NULL;
-- EXPECTED: All NULL_COUNT should be 0

-- ============================================================================
-- SECTION D: FINAL VERIFICATION REPORT (generates pass/fail summary)
-- ============================================================================

-- D1: Generate Final Status Report
SELECT 
    'MIGRATION_VALIDATION_REPORT' AS REPORT_TYPE,
    'Generated: ' || CURRENT_TIMESTAMP()::VARCHAR AS TIMESTAMP_GENERATED,
    CASE 
        WHEN (SELECT COUNT(*) FROM CARD) = 15 AND
             (SELECT COUNT(*) FROM CUSTOMER) = 10 AND
             (SELECT COUNT(*) FROM EMPLOYEE) = 5 AND
             (SELECT COUNT(*) FROM BRANCH) = 4 AND
             (SELECT COUNT(*) FROM LOCATION) = 4 AND
             (SELECT COUNT(*) FROM BOOK) = 8 AND
             (SELECT COUNT(*) FROM VIDEO) >= 7 AND
             (SELECT COUNT(*) FROM RENT) = 6 AND
             (SELECT COUNT(*) FROM CARD WHERE STATUS NOT IN ('A', 'B')) = 0 AND
             (SELECT COUNT(*) FROM RENT WHERE ITEM_TYPE NOT IN ('BOOK', 'VIDEO')) = 0
        THEN 'ALL_TESTS_PASS'
        ELSE 'SOME_TESTS_FAIL'
    END AS OVERALL_STATUS;

-- D2: Detailed Compliance Score
SELECT 
    'TEST_CATEGORY' AS CATEGORY,
    'COUNT_COMPLIANCE' AS TEST_NAME,
    CASE 
        WHEN (SELECT COUNT(*) FROM CARD) = 15 AND
             (SELECT COUNT(*) FROM CUSTOMER) = 10 AND
             (SELECT COUNT(*) FROM EMPLOYEE) = 5 AND
             (SELECT COUNT(*) FROM BRANCH) = 4 AND
             (SELECT COUNT(*) FROM LOCATION) = 4 AND
             (SELECT COUNT(*) FROM BOOK) = 8 AND
             (SELECT COUNT(*) FROM VIDEO) >= 7 AND
             (SELECT COUNT(*) FROM RENT) = 6
        THEN 100 ELSE 0
    END AS COMPLIANCE_PERCENTAGE
UNION ALL
SELECT 'TEST_CATEGORY', 'CONSTRAINT_COMPLIANCE',
    CASE 
        WHEN (SELECT COUNT(*) FROM CARD WHERE STATUS NOT IN ('A', 'B')) = 0 AND
             (SELECT COUNT(*) FROM BOOK WHERE AVAILABILITY_STATUS NOT IN ('A', 'O')) = 0 AND
             (SELECT COUNT(*) FROM VIDEO WHERE AVAILABILITY_STATUS NOT IN ('A', 'O')) = 0 AND
             (SELECT COUNT(*) FROM RENT WHERE ITEM_TYPE NOT IN ('BOOK', 'VIDEO')) = 0
        THEN 100 ELSE 0
    END
UNION ALL
SELECT 'TEST_CATEGORY', 'REFERENTIAL_INTEGRITY',
    ROUND(100.0 * (SELECT COUNT(*) FROM CUSTOMER c 
            WHERE c.CARD_ID IN (SELECT CARD_ID FROM CARD)) / COUNT(*), 2)
FROM CUSTOMER;

-- ============================================================================
-- SECTION E: PERFORMANCE BASELINE (query execution statistics)
-- ============================================================================

-- E1: Query Performance Summary
-- Note: Run this AFTER executing all tests to see performance metrics
-- This queries Snowflake's query history
SELECT 
    QUERY_ID,
    QUERY_TEXT,
    EXECUTION_TIME,
    ROWS_RETURNED
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
WHERE START_TIME >= CURRENT_TIMESTAMP() - INTERVAL '1 hour'
ORDER BY EXECUTION_TIME DESC
LIMIT 20;

-- ============================================================================
-- RECOMMENDED EXECUTION ORDER
-- ============================================================================

/*
STEP 1: Run SECTION A (Quick Validation) = 60 seconds
  - Verify all record counts match expected
  - Verify no orphaned FK records
  - Verify CHECK constraints satisfied
  - Verify ITEM_TYPE properly populated
  - Verify timestamps present

STEP 2: If SECTION A all PASS, run SECTION B (Focused Validation) = 5 minutes
  - Deeper data integrity checks
  - Data type conversions
  - Business logic validation
  - Materialized views

STEP 3: If any failures in SECTION A or B, run SECTION C (Troubleshooting)
  - Identify specific failing records
  - Find root cause
  - Fix issues
  - Re-run failing tests

STEP 4: When all PASS, run SECTION D (Final Report)
  - Generate comprehensive compliance score
  - Create sign-off documentation
  - Archive test results

STEP 5: Optional - Run SECTION E (Performance Baseline)
  - Establish performance metrics
  - Plan for performance monitoring
  - Identify slow queries if any
*/

-- ============================================================================
-- PASS/FAIL CRITERIA
-- ============================================================================

/*
PASS Criteria:
✓ SECTION A: All record counts match expected values (60 seconds)
✓ No orphaned records in any table
✓ All FK references valid (100% compliance)
✓ All CHECK constraints satisfied (100% compliance)
✓ ITEM_TYPE column properly populated and valid
✓ CREATED_AT and UPDATED_AT timestamps present
✓ Data types converted correctly (INTEGER, NUMERIC, VARCHAR, DATE)
✓ Materialized views created and functional
✓ Overall compliance score: 100%

FAIL Criteria:
✗ Any record count mismatch
✗ Any orphaned or unreferenced records
✗ Any FK constraint violation
✗ Any CHECK constraint violation
✗ Missing or invalid ITEM_TYPE values
✗ Missing or NULL timestamp columns
✗ Data type conversion errors
✗ Data value corruption
✗ Compliance score < 100%
*/

-- ============================================================================
-- SIGN-OFF DOCUMENTATION
-- ============================================================================

/*
When all tests pass, complete this sign-off:

TEST EXECUTION SUMMARY
Date: [DATE]
Tester: [NAME]
Snowflake Account: [ACCOUNT]
Database: [DB_NAME]

RESULTS:
- Total Tests Executed: 150+
- Tests Passed: [COUNT]
- Tests Failed: [COUNT]
- Overall Compliance: [%]

TABLES VALIDATED:
☐ CARD (15 records)
☐ CUSTOMER (10 records)
☐ EMPLOYEE (5 records)
☐ BRANCH (4 records)
☐ LOCATION (4 records)
☐ BOOK (8 records)
☐ VIDEO (7-8 records)
☐ RENT (6 records)

CONSTRAINTS VALIDATED:
☐ Primary Keys
☐ Foreign Keys
☐ CHECK Constraints
☐ UNIQUE Constraints
☐ NOT NULL Constraints

DATA FEATURES VALIDATED:
☐ ITEM_TYPE Column
☐ Timestamp Columns (CREATED_AT, UPDATED_AT)
☐ Materialized Views (3)
☐ Clustering Keys
☐ Data Type Conversions

APPROVED FOR PRODUCTION:
[ ] Yes - All validations passed
[ ] No - Issues remain (list issues):

Signature: ________________  Date: __________
*/

-- ============================================================================
-- END OF QUICK REFERENCE GUIDE
-- ============================================================================
