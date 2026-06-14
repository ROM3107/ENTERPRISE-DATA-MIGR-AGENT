-- ============================================================================
-- TEST CASE DOCUMENTATION: Oracle to Snowflake Library Migration
-- ============================================================================
-- File: Library-testcases.sql
-- Purpose: Comprehensive validation of Oracle → Snowflake migration
-- Generated: 2026-06-14
-- Status: Production-Ready
-- ============================================================================

# TEST SUITE OVERVIEW

## Purpose
This test suite validates 100% functional equivalence between the Oracle legacy 
Library database and the Snowflake modernized implementation. It ensures data 
integrity, referential consistency, and proper transformation of all schema 
components.

## Scope
- **Legacy System**: Oracle SQL (8 tables, 45 total records)
- **Target System**: Snowflake SQL (8 tables, 45+ total records)
- **Test Coverage**: 150+ test cases across 11 validation categories
- **Expected Duration**: 5-10 minutes for full execution

## Key Migration Validations
1. All 15 CARD records with correct status ('A'/'B') and fine amounts
2. All 10 CUSTOMER records with valid FK to CARD table
3. All 5 EMPLOYEE records with valid FK to CARD and BRANCH tables
4. All 4 BRANCH records with valid FK to LOCATION table
5. All 4 LOCATION records exist as master references
6. All 8 BOOK records with composite key (ISBN, BOOK_ID)
7. All 7-8 VIDEO records with composite key (TITLE, YEAR, VIDEO_ID)
8. All 6 RENT records with new ITEM_TYPE disambiguation column
9. All CHECK constraints enforced (STATUS, AVAILABILITY_STATUS, ITEM_TYPE)
10. All timestamp columns (CREATED_AT, UPDATED_AT) populated for audit trail

---

# TEST EXECUTION GUIDE

## Prerequisites
1. Snowflake database environment accessible
2. All migration scripts executed successfully
3. All tables created and data loaded
4. Query editor or SQL client ready

## Execution Steps
1. **Execute Full Test Suite**: Run entire Library-testcases.sql file
2. **Review Results**: Check each test for PASS/FAIL status
3. **Investigate Failures**: Review any FAIL results with detail queries
4. **Generate Report**: Compile results into test execution log
5. **Sign Off**: Obtain stakeholder approval for production deployment

## Expected Output
- 150+ SELECT queries with results
- Status indicators (PASS/FAIL) for each test
- Summary statistics showing data quality metrics
- No error messages or constraint violations

---

# TEST CATEGORY BREAKDOWN

## Category 1: Data Integrity Tests (35+ tests)
**Purpose**: Verify all records migrated correctly with accurate values

**Key Tests**:
- TEST 1.1 - CARD record count (expect: 15)
- TEST 1.2 - CARD status distribution (6 active, 9 blocked)
- TEST 1.3 - CARD fine amounts numeric validation
- TEST 1.5 - CUSTOMER record count (expect: 10)
- TEST 1.10 - EMPLOYEE record count (expect: 5)
- TEST 1.14 - BRANCH record count (expect: 4)
- TEST 1.16 - LOCATION record count (expect: 4)
- TEST 1.17 - BOOK record count (expect: 8)
- TEST 1.24 - VIDEO record count (expect: 7-8)
- TEST 1.29 - RENT record count (expect: 6)

**Validation Criteria**:
- ✓ All record counts match expected values
- ✓ All data types are correct
- ✓ All values are within valid ranges
- ✓ No unexpected NULL values in required fields

---

## Category 2: Foreign Key Constraint Tests (14 tests)
**Purpose**: Verify all referential relationships are valid

**Key Tests**:
- TEST 2.1 - Orphaned CUSTOMER records (expect: 0)
- TEST 2.2 - Orphaned EMPLOYEE records - CARD (expect: 0)
- TEST 2.3 - Orphaned EMPLOYEE records - BRANCH (expect: 0)
- TEST 2.4 - Orphaned BRANCH records (expect: 0)
- TEST 2.5 - Orphaned BOOK records (expect: 0)
- TEST 2.6 - Orphaned VIDEO records (expect: 0)
- TEST 2.7 - Orphaned RENT records (expect: 0)
- TEST 2.8 to 2.14 - Complete FK chain validation

**Foreign Key Relationships Tested**:
```
CUSTOMER.CARD_ID         → CARD.CARD_ID
EMPLOYEE.CARD_ID         → CARD.CARD_ID
EMPLOYEE.BRANCH_NAME     → BRANCH.BRANCH_NAME
BRANCH.ADDRESS           → LOCATION.ADDRESS
BOOK.ADDRESS             → LOCATION.ADDRESS
VIDEO.ADDRESS            → LOCATION.ADDRESS
RENT.CARD_ID             → CARD.CARD_ID
RENT.ITEM_ID + ITEM_TYPE → BOOK.BOOK_ID or VIDEO.VIDEO_ID
```

**Validation Criteria**:
- ✓ No orphaned records (0 violations)
- ✓ All FK references resolve correctly
- ✓ FK chains maintain data lineage
- ✓ No NULL values in FK columns (where required)

---

## Category 3: CHECK Constraint Tests (10 tests)
**Purpose**: Validate all CHECK constraints are enforced

**CHECK Constraints Tested**:
- CARD.STATUS must be 'A' or 'B' (all 15 cards)
- BOOK.AVAILABILITY_STATUS must be 'A' or 'O' (all 8 books)
- VIDEO.AVAILABILITY_STATUS must be 'A' or 'O' (all 7-8 videos)
- RENT.ITEM_TYPE must be 'BOOK' or 'VIDEO' (all 6 rentals)
- RENT date logic: CHECKOUT_DATE <= RETURN_DATE (or RETURN_DATE IS NULL)

**Key Tests**:
- TEST 3.1 - CARD.STATUS validation
- TEST 3.3 - BOOK.AVAILABILITY_STATUS validation
- TEST 3.5 - VIDEO.AVAILABILITY_STATUS validation
- TEST 3.7 - RENT.ITEM_TYPE validation
- TEST 3.9 - RENT date logic validation

**Validation Criteria**:
- ✓ 100% constraint compliance
- ✓ Zero constraint violations
- ✓ All invalid values caught and reported

---

## Category 4: Data Type Conversion Tests (14 tests)
**Purpose**: Verify data types converted correctly from Oracle to Snowflake

**Conversions Tested**:
```
NUMBER              → INTEGER
NUMBER(precision,2) → NUMERIC
VARCHAR2(n)         → VARCHAR(n)
DATE                → DATE
INT                 → INTEGER
```

**Specific Conversions**:
- CARD_ID: NUMBER → INTEGER (range: 101-155)
- CUSTOMER_ID: NUMBER → INTEGER (range: 1-10)
- EMPLOYEE_ID: NUMBER → INTEGER (range: 211-215)
- PHONE_NUMBER: NUMBER(9) → INTEGER
- FINE_AMOUNT: NUMBER(10,2) → NUMERIC (2 decimal places)
- PAYCHECK_AMOUNT: NUMBER(8,2) → NUMERIC (2 decimal places)
- DAMAGE_COST: NUMBER(10,2) → NUMERIC
- LOST_COST: NUMBER(10,2) → NUMERIC
- YEAR: INT → INTEGER
- VARCHAR2 columns → VARCHAR with same lengths

**Key Tests**:
- TEST 4.1 to 4.3 - INTEGER ID type validation
- TEST 4.4 to 4.5 - INTEGER phone number validation
- TEST 4.6 to 4.9 - NUMERIC decimal validation
- TEST 4.10 - INTEGER year validation
- TEST 4.11 to 4.14 - VARCHAR and DATE validation

**Validation Criteria**:
- ✓ All numeric values in correct range
- ✓ All strings within length limits
- ✓ All dates valid and parseable
- ✓ No precision loss in decimal conversions

---

## Category 5: ITEM_TYPE Disambiguation Tests (7 tests)
**Purpose**: Validate critical ITEM_TYPE column addition (resolves ambiguity)

**Problem Solved**:
Original Oracle schema had ambiguous ITEM_ID in RENT table that could reference
either BOOK.BOOK_ID or VIDEO.VIDEO_ID without clear distinction.

**Solution Implemented**:
Added ITEM_TYPE column with values 'BOOK' or 'VIDEO' to eliminate ambiguity.

**Key Tests**:
- TEST 5.1 - ITEM_TYPE column populated with valid values
- TEST 5.2 - Composite PK includes ITEM_TYPE (no duplicates)
- TEST 5.3 - ITEM_TYPE='BOOK' references are valid
- TEST 5.4 - ITEM_TYPE='VIDEO' references are valid
- TEST 5.5 - No orphaned ITEM_ID references
- TEST 5.6 - ITEM_TYPE distribution (3 BOOK, 3 VIDEO)
- TEST 5.7 - Unique item identification with ITEM_TYPE

**Validation Criteria**:
- ✓ ITEM_TYPE set on all RENT records
- ✓ ITEM_TYPE values are 'BOOK' or 'VIDEO'
- ✓ All ITEM_ID + ITEM_TYPE combinations are valid
- ✓ No orphaned rental references
- ✓ Composite PK includes ITEM_TYPE for uniqueness

---

## Category 6: Timestamp Column Tests (7 tests)
**Purpose**: Validate new audit trail columns (CREATED_AT, UPDATED_AT)

**Purpose of Timestamp Columns**:
Original Oracle schema lacked audit date tracking. Snowflake implementation adds:
- CREATED_AT: Timestamp when record was inserted
- UPDATED_AT: Timestamp when record was last modified

**Key Tests**:
- TEST 6.1 - CARD CREATED_AT populated
- TEST 6.2 - CARD UPDATED_AT populated
- TEST 6.3 - CREATED_AT <= UPDATED_AT logic
- TEST 6.4 to 6.7 - All tables have timestamp columns

**Validation Criteria**:
- ✓ All records have CREATED_AT timestamp
- ✓ All records have UPDATED_AT timestamp
- ✓ CREATED_AT <= UPDATED_AT for all records
- ✓ Timestamps are recent (migration date)

**Time Travel Capability** (Snowflake Feature):
With timestamps and Time Travel enabled, can query tables at any point in time:
```sql
SELECT * FROM CARD AT(OFFSET => -3600)  -- 1 hour ago
SELECT * FROM CARD CHANGES(...)          -- Show all changes
```

---

## Category 7: Business Logic Tests (7 tests)
**Purpose**: Validate business logic and materialized views

**Business Logic Tested**:
- Rental duration calculation (RETURN_DATE - CHECKOUT_DATE)
- Ongoing rental detection (RETURN_DATE IS NULL)
- Fine calculation for overdue items
- Customer account status tracking
- Branch inventory status
- Overdue rental identification

**Key Tests**:
- TEST 7.1 - RENTAL_DURATION_DAYS calculation
- TEST 7.2 - Ongoing rentals detection
- TEST 7.3 - CUSTOMER_ACCOUNT_STATUS view validation
- TEST 7.4 - Customers with fines identification
- TEST 7.5 - BRANCH_INVENTORY_STATUS view validation
- TEST 7.6 - OVERDUE_RENTALS view validation
- TEST 7.7 - Complete rental lifecycle tracking

**Materialized Views Tested**:
1. **CUSTOMER_ACCOUNT_STATUS**: Shows customer rental counts and fine status
2. **BRANCH_INVENTORY_STATUS**: Shows available/rented items by location
3. **OVERDUE_RENTALS**: Shows items past return date with fine calculations

**Validation Criteria**:
- ✓ Rental duration calculated correctly
- ✓ Ongoing vs completed rentals distinguished
- ✓ Views return expected aggregations
- ✓ Fine calculations are accurate

---

## Category 8: Edge Case Tests (13 tests)
**Purpose**: Validate special conditions and boundary cases

**Edge Cases Tested**:
- NULL handling (RETURN_DATE IS NULL for ongoing rentals)
- Blocked cards with fines
- Zero fine amounts
- Multiple employees in same branch
- Items in different states (NEW, GOOD, BAD, USED)
- Inventory distribution across locations
- Customer name length limits
- UNIQUE constraint enforcement
- Password field requirements
- Extreme values (min/max amounts)

**Key Tests**:
- TEST 8.1 - Unreturned items (NULL RETURN_DATE)
- TEST 8.2 - Blocked cards with fines
- TEST 8.3 - Zero fine amounts
- TEST 8.4 - Employee distribution by branch
- TEST 8.5 to 8.6 - Item state distribution
- TEST 8.7 to 8.8 - Inventory by location
- TEST 8.9 - Customer name length
- TEST 8.10 to 8.11 - UNIQUE constraint (USER_NAME)
- TEST 8.12 to 8.13 - Password field validation

**Validation Criteria**:
- ✓ NULLs handled correctly in specific fields
- ✓ Constraint boundaries respected
- ✓ No duplicate usernames
- ✓ Required fields always populated
- ✓ Value ranges valid

---

## Category 9: Comparison Tests (10 tests)
**Purpose**: Compare expected vs actual for complete data set

**Comparisons Tested**:
- Row counts by table (CARD: 15, CUSTOMER: 10, EMPLOYEE: 5, etc.)
- Data value accuracy (sample 10% of records)
- Join results (all FK relationships)
- Aggregations (total fines, paycheck totals, costs)
- Date ranges (SIGNUP_DATE, CHECKOUT_DATE, RETURN_DATE)

**Key Tests**:
- TEST 9.1 - Overall record count summary
- TEST 9.2 - Card fine total validation
- TEST 9.3 - Paycheck total validation
- TEST 9.4 to 9.5 - Inventory cost analysis
- TEST 9.6 to 9.7 - Relationship validation
- TEST 9.8 to 9.10 - Join integrity and data completeness

**Expected Results**:
```
CARD:     15 records (6 active, 9 blocked)
CUSTOMER: 10 records
EMPLOYEE:  5 records
BRANCH:    4 records
LOCATION:  4 records
BOOK:      8 records
VIDEO:     7-8 records
RENT:      6 records
```

**Validation Criteria**:
- ✓ All counts match expected values
- ✓ All joins produce correct results
- ✓ All aggregations match calculated values
- ✓ Sample data verification confirms accuracy

---

## Category 10: Summary & Validation Tests (16+ tests)
**Purpose**: Final validation and certification

**Final Checks**:
- Primary key uniqueness across all tables
- Constraint compliance summary
- Migration completeness checklist
- Data quality metrics

**Key Tests**:
- TEST 10.1 - Primary key uniqueness
- TEST 10.2 - Constraint compliance summary
- TEST 10.3 - Migration completeness checklist
- TEST 10.4 - Data quality metrics

**Migration Completeness Checklist**:
- ✓ All 8 tables created
- ✓ All indexes created (if applicable)
- ✓ All 45+ records migrated
- ✓ All FKs validated
- ✓ All CHECK constraints working
- ✓ All timestamp columns added
- ✓ ITEM_TYPE column added to RENT
- ✓ Materialized views created
- ✓ Zero data quality issues

---

# TEST RESULTS INTERPRETATION

## PASS Result
Indicates the test condition is satisfied. Example:
```
TEST 1.1 - CARD Record Count
Actual: 15, Expected: 15, Status: PASS
```

## FAIL Result
Indicates the test condition is NOT satisfied. Requires investigation. Example:
```
TEST 1.5 - CUSTOMER Record Count
Actual: 9, Expected: 10, Status: FAIL
Action: Verify migration script completed successfully
```

## Quality Metrics
Tests calculate quality percentages:
```
TEST 10.4 - Data Quality Metrics
Referential Integrity: 100.00% PASS
Constraint Compliance: 100.00% PASS
Data Completeness: 100.00% PASS
```

---

# EXPECTED TEST RESULTS SUMMARY

## Count Validation Results
```
CARD:      15 records ✓
CUSTOMER:  10 records ✓
EMPLOYEE:  5 records ✓
BRANCH:    4 records ✓
LOCATION:  4 records ✓
BOOK:      8 records ✓
VIDEO:     7-8 records ✓
RENT:      6 records ✓
TOTAL:     45+ records ✓
```

## Status Distribution Results
```
CARD STATUS:
  'A' (Active):  6 records
  'B' (Blocked): 9 records

BOOK/VIDEO AVAILABILITY_STATUS:
  'A' (Available): 6+6 = 12+ records
  'O' (Out):      2+1 = 3+ records

RENT ITEM_TYPE:
  'BOOK':  3 records
  'VIDEO': 3 records
```

## Fine Amount Results
```
Active Cards (A):  0 fines (0.00)
Blocked Cards (B): Varies (10.00, 15.25, 25.50, 50.00)
Total Fines:      ~100.75 (sum of all fines)
```

## FK Relationship Results
```
CUSTOMER → CARD:        10/10 valid (100%)
EMPLOYEE → CARD:         5/5 valid (100%)
EMPLOYEE → BRANCH:       5/5 valid (100%)
BRANCH → LOCATION:       4/4 valid (100%)
BOOK → LOCATION:         8/8 valid (100%)
VIDEO → LOCATION:        7+/7+ valid (100%)
RENT → CARD:             6/6 valid (100%)
RENT → BOOK|VIDEO:       6/6 valid (100%)
```

---

# POST-TEST VERIFICATION STEPS

## If All Tests PASS
1. Generate test execution report
2. Archive test results with timestamp
3. Schedule production deployment
4. Notify stakeholders of success
5. Plan post-deployment monitoring

## If Any Tests FAIL
1. Document failure details with TEST ID
2. Review migration scripts for issues
3. Check source data in Oracle (if available)
4. Fix data/schema issues
5. Re-execute failed tests
6. Repeat until all tests pass

## Post-Deployment Actions
1. Enable Time Travel on all tables (90-day retention)
2. Create backup tables from current state
3. Implement monitoring queries
4. Test password hashing (if not already done)
5. Monitor query performance metrics
6. Document any manual fixes applied

---

# PERFORMANCE EXPECTATIONS

## Query Execution Time
- Individual test: < 1 second
- All tests: 5-10 minutes total
- Summary report: < 30 seconds

## Resource Usage
- Memory: ~50-100 MB
- Storage: ~500 MB (with Time Travel)
- Compute: SMALL warehouse sufficient

## Optimization Recommendations
1. Run tests during off-peak hours
2. Use SMALL warehouse for tests
3. Create indexes on FK columns
4. Enable query caching for repeated tests
5. Use clustering keys (already configured)

---

# TROUBLESHOOTING GUIDE

## Common Issues & Solutions

### Issue: FAIL on record count test
**Cause**: Migration script didn't complete or data wasn't loaded
**Solution**: 
- Verify migration script ran without errors
- Check source data for expected record counts
- Re-run migration if necessary

### Issue: FAIL on FK constraint test
**Cause**: Orphaned records or missing parent records
**Solution**:
- Use detail query to identify orphaned records
- Check data values in source system
- Verify FK relationships in DDL

### Issue: FAIL on CHECK constraint test
**Cause**: Invalid values in constrained column
**Solution**:
- Use detail query (TEST 3.2, 3.4, 3.6, 3.8) to find violating records
- Correct invalid values or update constraint definition
- Re-run validation test

### Issue: FAIL on ITEM_TYPE test
**Cause**: Missing or incorrect ITEM_TYPE values
**Solution**:
- Verify ITEM_TYPE was populated during INSERT
- Check for orphaned ITEM_ID references
- Use TEST 5.5 to identify specific issues
- Update RENT records with correct ITEM_TYPE

### Issue: Timestamp columns NULL
**Cause**: DEFAULT values not applied during INSERT
**Solution**:
- Check INSERT statements use DEFAULT keyword
- Manually UPDATE with current timestamp
- Re-load data with corrected INSERT statements

---

# SIGN-OFF CHECKLIST

Use this checklist to verify migration readiness:

- [ ] All 150+ tests executed successfully
- [ ] All tests report PASS status
- [ ] No data quality issues identified
- [ ] All FK relationships validated
- [ ] All CHECK constraints enforced
- [ ] ITEM_TYPE column properly populated
- [ ] Timestamp columns (CREATED_AT, UPDATED_AT) present
- [ ] Materialized views created and functional
- [ ] Data types converted correctly
- [ ] Record counts match expected values
- [ ] Zero orphaned records
- [ ] Zero constraint violations
- [ ] Performance baseline established
- [ ] Backup created before production use
- [ ] Post-deployment monitoring plan ready
- [ ] Stakeholders informed and approved
- [ ] Rollback plan documented
- [ ] Production deployment scheduled

---

# MIGRATION CERTIFICATION

**Test Suite Version**: 1.0
**Total Tests**: 150+
**Execution Date**: [EXECUTION DATE]
**Result**: ALL PASS / SOME FAILURES (circle one)
**Quality Score**: ___% (Referential Integrity + Constraint Compliance + Completeness)
**Tested By**: __________________ (name)
**Approved By**: ________________ (name, title)
**Date**: __________________

---

# APPENDIX: EXAMPLE TEST QUERIES

## Quick Validation Query (5 seconds)
```sql
SELECT 'CARD' AS TABLE_NAME, COUNT(*) AS RECORD_COUNT FROM CARD
UNION ALL
SELECT 'CUSTOMER', COUNT(*) FROM CUSTOMER
UNION ALL
SELECT 'EMPLOYEE', COUNT(*) FROM EMPLOYEE
UNION ALL
SELECT 'BRANCH', COUNT(*) FROM BRANCH
UNION ALL
SELECT 'LOCATION', COUNT(*) FROM LOCATION
UNION ALL
SELECT 'BOOK', COUNT(*) FROM BOOK
UNION ALL
SELECT 'VIDEO', COUNT(*) FROM VIDEO
UNION ALL
SELECT 'RENT', COUNT(*) FROM RENT;
```

## FK Integrity Check (2 seconds)
```sql
SELECT 'CUSTOMER_FK_CARD' AS CHECK_TYPE,
       COUNT(CASE WHEN c.CARD_ID IN (SELECT CARD_ID FROM CARD) THEN 1 END) AS VALID,
       COUNT(*) - COUNT(CASE WHEN c.CARD_ID IN (SELECT CARD_ID FROM CARD) THEN 1 END) AS INVALID
FROM CUSTOMER c
UNION ALL
SELECT 'EMPLOYEE_FK_CARD',
       COUNT(CASE WHEN e.CARD_ID IN (SELECT CARD_ID FROM CARD) THEN 1 END),
       COUNT(*) - COUNT(CASE WHEN e.CARD_ID IN (SELECT CARD_ID FROM CARD) THEN 1 END)
FROM EMPLOYEE e;
```

## Constraint Compliance Check (2 seconds)
```sql
SELECT 'CARD_STATUS' AS CONSTRAINT_NAME,
       COUNT(CASE WHEN STATUS IN ('A', 'B') THEN 1 END) AS COMPLIANT,
       COUNT(*) - COUNT(CASE WHEN STATUS IN ('A', 'B') THEN 1 END) AS VIOLATIONS
FROM CARD
UNION ALL
SELECT 'BOOK_AVAILABILITY',
       COUNT(CASE WHEN AVAILABILITY_STATUS IN ('A', 'O') THEN 1 END),
       COUNT(*) - COUNT(CASE WHEN AVAILABILITY_STATUS IN ('A', 'O') THEN 1 END)
FROM BOOK;
```

---

# REFERENCES

- Snowflake Documentation: https://docs.snowflake.com/
- Oracle to Snowflake Migration Guide
- Library Database Schema Documentation
- Data Migration Validation Best Practices

---

**End of Test Documentation**
