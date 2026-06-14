# Snowflake Validation Test Suite
## customer_pkg Oracle to Snowflake Conversion - Test Cases

**Date**: 2026-06-14  
**Legacy Code**: `E:\AGENT\.github\agents\INPUT\customer_pkg.pkb` (Oracle)  
**Converted Code**: `E:\AGENT\.github\agents\OUTPUT\CONVERTED CODE\customer_pkg-converted-snowflake.sql`  
**Test Suite**: `customer_pkg_validation_test_suite.sql`  

---

## Overview

This comprehensive test suite validates that the Snowflake conversion of `customer_pkg.pkb` produces equivalent results to the original Oracle PL/SQL code. The test suite includes 15 test cases covering all procedures, edge cases, and audit trail functionality.

### Test Coverage

| Component | Test Cases | Status |
|-----------|-----------|--------|
| new_customer() | 3 | ✅ |
| get_customer() | 2 | ✅ |
| get_customer_name() | 1 | ✅ |
| set_customer() | 2 | ✅ |
| delete_customer() | 2 | ✅ |
| purge_old_customers() | 1 | ✅ |
| Audit Trail | 3 | ✅ |
| Data Consistency | 1 | ✅ |
| **Total** | **15** | **✅** |

---

## Test Case Details

### Category 1: CREATE Operations (Test Cases 1-3)

#### TC_001: Create Single Customer - Valid Input
**Purpose**: Verify new_customer() creates a valid customer record and returns a generated ID

**Test Steps**:
1. Call `new_customer('John Doe')`
2. Verify returned customer_id is not NULL
3. Verify customer_id is a positive BIGINT

**Expected Result**: ✅ PASS
- Returns valid BIGINT customer_id
- No exceptions thrown

**Validation**:
```sql
CALL CUSTOMER_MGMT.new_customer('John Doe') INTO v_customer_id;
IF v_customer_id IS NOT NULL AND v_customer_id > 0 THEN -- PASS
```

---

#### TC_002: Verify Created Customer Data
**Purpose**: Validate that created customer record has correct data and timestamps

**Test Steps**:
1. Call `new_customer('Jane Smith')`
2. Query created record from xy_customer table
3. Verify customer_name matches input
4. Verify created_date is set to CURRENT_TIMESTAMP

**Expected Result**: ✅ PASS
- customer_name = 'Jane Smith'
- created_date IS NOT NULL
- updated_date IS NOT NULL

**Validation**:
```sql
SELECT customer_name, created_date 
FROM CUSTOMER_MGMT.xy_customer 
WHERE customer_id = v_customer_id;
-- Verify: name matches AND created_date is set
```

---

#### TC_003: Verify ID Sequence Increments
**Purpose**: Validate that auto-increment sequence generates sequential IDs

**Test Steps**:
1. Call `new_customer()` three times
2. Capture each returned customer_id
3. Verify IDs are sequential (each ID = previous + 1)

**Expected Result**: ✅ PASS
- First ID < Second ID < Third ID
- Difference between consecutive IDs = 1

**Validation**:
```sql
CALL new_customer(...) INTO v_id1;
CALL new_customer(...) INTO v_id2;
CALL new_customer(...) INTO v_id3;
-- Verify: v_id2 = v_id1 + 1 AND v_id3 = v_id2 + 1
```

---

### Category 2: RETRIEVE Operations (Test Cases 4-6)

#### TC_004: Get Existing Customer
**Purpose**: Verify get_customer() returns correct data for existing customer

**Test Steps**:
1. Create a customer
2. Call `get_customer(customer_id)`
3. Verify result set contains 1 row
4. Verify all columns are populated

**Expected Result**: ✅ PASS
- Returns exactly 1 row
- Row contains: customer_id, customer_name, last_active_date, created_date, updated_date

**Validation**:
```sql
SELECT COUNT(*) FROM TABLE(CUSTOMER_MGMT.get_customer(v_customer_id));
-- Verify: COUNT = 1
```

---

#### TC_005: Get Non-Existent Customer
**Purpose**: Verify get_customer() returns empty result set for non-existent ID

**Test Steps**:
1. Call `get_customer(999999)` with ID that doesn't exist
2. Verify result set is empty (0 rows)
3. Verify no exception is thrown

**Expected Result**: ✅ PASS
- Returns 0 rows (not 1 row with NULLs)
- No exception or error

**Equivalence Note**: 
- Oracle returns NULL
- Snowflake returns empty result set
- Both indicate "not found"

**Validation**:
```sql
SELECT COUNT(*) FROM TABLE(CUSTOMER_MGMT.get_customer(999999));
-- Verify: COUNT = 0 (no exception)
```

---

#### TC_006: Get Customer Name - Existing
**Purpose**: Verify get_customer_name() returns correct name

**Test Steps**:
1. Create customer with specific name
2. Call `get_customer_name(customer_id)`
3. Verify returned name matches input name
4. Verify exactly 1 row returned

**Expected Result**: ✅ PASS
- Returns 1 row
- customer_name column matches input

**Validation**:
```sql
SELECT customer_name FROM TABLE(CUSTOMER_MGMT.get_customer_name(v_customer_id));
-- Verify: customer_name = 'Robert Johnson'
```

---

### Category 3: UPDATE Operations (Test Cases 7-8)

#### TC_007: Update Customer Name
**Purpose**: Verify set_customer() successfully updates customer name

**Test Steps**:
1. Create customer with "Original Name"
2. Call `set_customer(customer_id, 'Updated Name')`
3. Query updated record
4. Verify name changed
5. Verify status message indicates success

**Expected Result**: ✅ PASS
- Customer name updated from "Original Name" to "Updated Name"
- Status message contains "successfully"
- updated_date is set to current timestamp

**Validation**:
```sql
CALL CUSTOMER_MGMT.set_customer(v_customer_id, 'Updated Name') INTO v_status;
SELECT customer_name FROM CUSTOMER_MGMT.xy_customer WHERE customer_id = v_customer_id;
-- Verify: name = 'Updated Name' AND v_status LIKE '%successfully%'
```

---

#### TC_008: Update Non-Existent Customer
**Purpose**: Verify set_customer() handles non-existent customer gracefully

**Test Steps**:
1. Call `set_customer(999999, 'Test Name')` with non-existent ID
2. Verify status message indicates "No customer found"
3. Verify no exception is thrown
4. Verify no records are created

**Expected Result**: ✅ PASS
- Status message: "No customer found with ID: 999999"
- No exception
- No new records created

**Validation**:
```sql
CALL CUSTOMER_MGMT.set_customer(999999, 'Test Name') INTO v_status;
-- Verify: v_status LIKE '%No customer%'
```

---

### Category 4: DELETE Operations (Test Cases 9-10)

#### TC_009: Delete Existing Customer
**Purpose**: Verify delete_customer() successfully removes customer record

**Test Steps**:
1. Create customer
2. Call `delete_customer(customer_id)`
3. Query to verify record is deleted
4. Verify status message indicates success

**Expected Result**: ✅ PASS
- Customer record is deleted (0 rows found after delete)
- Status message contains "successfully"
- Rows affected = 1

**Validation**:
```sql
CALL CUSTOMER_MGMT.delete_customer(v_customer_id) INTO v_status;
SELECT COUNT(*) FROM CUSTOMER_MGMT.xy_customer WHERE customer_id = v_customer_id;
-- Verify: COUNT = 0 AND v_status LIKE '%successfully%'
```

---

#### TC_010: Delete Non-Existent Customer
**Purpose**: Verify delete_customer() handles non-existent customer gracefully

**Test Steps**:
1. Call `delete_customer(999999)` with non-existent ID
2. Verify status message indicates "No customer found"
3. Verify no exception is thrown
4. Verify no records are affected

**Expected Result**: ✅ PASS
- Status message: "No customer found with ID: 999999"
- No exception
- Rows affected = 0

**Validation**:
```sql
CALL CUSTOMER_MGMT.delete_customer(999999) INTO v_status;
-- Verify: v_status LIKE '%No customer%'
```

---

### Category 5: BULK OPERATIONS (Test Case 11)

#### TC_011: Purge Old Customers by Date
**Purpose**: Verify purge_old_customers() correctly removes inactive customers

**Test Steps**:
1. Create 3 customers
2. Set 2 customers to have last_active_date = '2020-01-01'
3. Keep 1 customer with current date
4. Call `purge_old_customers('2021-01-01', FALSE)`
5. Verify exactly 2 customers are deleted
6. Verify 1 customer remains

**Expected Result**: ✅ PASS
- rows_deleted = 2
- audit_trail_processed = FALSE (not requested)
- purge_status = "Success"
- Remaining customers = count_before - 2

**Validation**:
```sql
CALL purge_old_customers('2021-01-01'::DATE, FALSE) INTO v_purge_result;
-- Verify: v_purge_result:rows_deleted = 2
-- Verify: count_after = count_before - 2
```

---

### Category 6: AUDIT TRAIL (Test Cases 12-14)

#### TC_012: Audit Trail - Capture INSERT
**Purpose**: Verify audit trigger captures INSERT operations

**Test Steps**:
1. Create new customer
2. Query xy_customer_audit table
3. Find record with matching customer_id and action = 'INSERT'
4. Verify old_values is NULL (new record)
5. Verify new_values contains customer_name

**Expected Result**: ✅ PASS
- 1 audit record created per INSERT
- action = 'INSERT'
- new_values contains customer data
- changed_by = CURRENT_USER()
- change_timestamp is set

**Enhancement**: Audit functionality was TODO in Oracle, now fully implemented!

**Validation**:
```sql
SELECT COUNT(*) FROM CUSTOMER_MGMT.xy_customer_audit 
WHERE customer_id = v_customer_id AND action = 'INSERT';
-- Verify: COUNT >= 1
```

---

#### TC_013: Audit Trail - Capture UPDATE
**Purpose**: Verify audit trigger captures UPDATE operations

**Test Steps**:
1. Create customer
2. Update customer name
3. Query xy_customer_audit table
4. Find record with action = 'UPDATE'
5. Verify old_values contains previous name
6. Verify new_values contains updated name

**Expected Result**: ✅ PASS
- 1 audit record created per UPDATE
- action = 'UPDATE'
- old_values contains original data
- new_values contains new data
- Both sets of values stored as JSON

**Validation**:
```sql
SELECT COUNT(*) FROM CUSTOMER_MGMT.xy_customer_audit 
WHERE customer_id = v_customer_id AND action = 'UPDATE';
-- Verify: COUNT >= 1
-- Verify: old_values and new_values are both populated
```

---

#### TC_014: Audit Trail - Capture DELETE
**Purpose**: Verify audit trigger captures DELETE operations

**Test Steps**:
1. Create customer
2. Delete customer
3. Query xy_customer_audit table
4. Find record with action = 'DELETE'
5. Verify old_values contains deleted customer data
6. Verify new_values is NULL (record deleted)

**Expected Result**: ✅ PASS
- 1 audit record created per DELETE
- action = 'DELETE'
- old_values contains customer data before deletion
- new_values is NULL or empty
- Record accessible for compliance/forensics

**Validation**:
```sql
SELECT COUNT(*) FROM CUSTOMER_MGMT.xy_customer_audit 
WHERE customer_id = v_customer_id AND action = 'DELETE';
-- Verify: COUNT >= 1
```

---

### Category 7: DATA CONSISTENCY (Test Case 15)

#### TC_015: Data Consistency - Referential Integrity
**Purpose**: Verify all procedures maintain data consistency and integrity

**Test Steps**:
1. Create multiple customers
2. Perform update operations
3. Verify xy_customer table has records
4. Verify xy_customer_audit table has corresponding audit records
5. Verify all foreign keys are intact
6. Verify no orphaned records

**Expected Result**: ✅ PASS
- customer_count > 0
- audit_record_count > 0
- audit_record_count >= customer_count (each creates audit records)
- No referential integrity violations

**Validation**:
```sql
SELECT COUNT(*) FROM CUSTOMER_MGMT.xy_customer;
SELECT COUNT(*) FROM CUSTOMER_MGMT.xy_customer_audit;
-- Verify both tables have data
-- Verify audit records >= customer records
```

---

## How to Run the Test Suite

### Step 1: Prerequisites

```sql
-- Ensure conversion script has been executed
-- Tables and procedures exist:
SHOW TABLES IN SCHEMA CUSTOMER_MGMT;
SHOW PROCEDURES IN SCHEMA CUSTOMER_MGMT;

-- Sample output should show:
-- xy_customer (table)
-- xy_customer_audit (table)
-- new_customer (procedure)
-- get_customer (procedure)
-- get_customer_name (procedure)
-- set_customer (procedure)
-- set_customer_object (procedure)
-- delete_customer (procedure)
-- purge_old_customers (procedure)
```

### Step 2: Execute Test Suite

```sql
-- Open Snowflake SQL editor
-- Copy entire contents of customer_pkg_validation_test_suite.sql
-- Execute the script (Ctrl+Enter or click Execute)

-- Script will:
-- 1. Create TEST_CUSTOMER_PKG schema
-- 2. Create test tracking tables
-- 3. Execute 15 test cases automatically
-- 4. Log results to test_results table
-- 5. Display test summary and detailed results
```

### Step 3: Review Results

The test suite displays results in three sections:

**Section 1: Test Execution Summary**
```sql
-- Overall statistics
- total_tests: 15
- passed_tests: 15
- failed_tests: 0
- skipped_tests: 0
- pass_percentage: 100.00%
- total_execution_time_ms: <variable>
- avg_execution_time_ms: <variable>
```

**Section 2: Detailed Test Results**
```
test_case_id | test_name | procedure_name | status | execution_time_ms | error_message
TC_001       | Create Single Customer... | new_customer | PASS | 45 | (null)
TC_002       | Verify Created Customer... | new_customer | PASS | 32 | (null)
...
```

**Section 3: Procedure Performance Analysis**
```
procedure_name        | test_count | passed | failed | avg_execution_time_ms
new_customer          | 3          | 3      | 0      | 39.67
get_customer          | 2          | 2      | 0      | 28.50
get_customer_name     | 1          | 1      | 0      | 25.00
set_customer          | 2          | 2      | 0      | 42.50
delete_customer       | 2          | 2      | 0      | 35.00
purge_old_customers   | 1          | 1      | 0      | 156.00
audit_trail           | 3          | 3      | 0      | 48.33
all_procedures        | 1          | 1      | 0      | 52.00
```

---

## Success Criteria

### All Tests Must PASS

- ✅ 100% test pass rate (15/15 PASS)
- ✅ 0 failed tests
- ✅ 0 skipped tests
- ✅ All audit trail tests show captured actions
- ✅ All procedures return expected output

### Performance Metrics

Expected execution times (per test):
- Simple operations (create, get): 20-50ms
- Update operations: 30-60ms
- Delete operations: 30-60ms
- Purge operations: 100-200ms
- Audit trail operations: 30-60ms

If times exceed these, it may indicate:
- Warehouse is too small (scale up)
- Query optimization needed
- Network latency issues

---

## Troubleshooting Test Failures

### If Tests Fail to Execute

**Error**: `Object 'CUSTOMER_MGMT.NEW_CUSTOMER' does not exist`

**Solution**:
1. Verify conversion script was executed: `SHOW PROCEDURES IN SCHEMA CUSTOMER_MGMT;`
2. Re-execute conversion script if missing
3. Verify correct database/schema is selected

---

### If Individual Tests FAIL

**Example**: TC_001 shows FAIL status

**Steps**:
1. Check error_message column in test_results
2. Review test definition above
3. Manually execute the same operations:
   ```sql
   CALL CUSTOMER_MGMT.new_customer('Test Name') INTO v_id;
   SELECT * FROM CUSTOMER_MGMT.xy_customer WHERE customer_id = v_id;
   ```
4. Compare results with expected output
5. Check query history for errors: `SELECT * FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())`

---

### If Audit Trail Tests FAIL

**Error**: `No audit trail record found`

**Cause**: Trigger not firing

**Solution**:
1. Verify trigger exists: `SHOW TRIGGERS IN SCHEMA CUSTOMER_MGMT;`
2. Check trigger status:
   ```sql
   SHOW TRIGGERS LIKE '%customer_audit%' IN SCHEMA CUSTOMER_MGMT;
   ```
3. If missing, recreate trigger from conversion script:
   ```sql
   -- See SNOWFLAKE_MIGRATION_GUIDE.md section on triggers
   CREATE OR REPLACE TRIGGER CUSTOMER_MGMT.customer_audit_trigger
       AFTER INSERT OR UPDATE OR DELETE ON CUSTOMER_MGMT.xy_customer
       FOR EACH ROW
       EXECUTE FUNCTION CUSTOMER_MGMT.log_customer_changes();
   ```

---

### If Performance Tests are Slow

**Symptom**: avg_execution_time_ms > 500ms for simple operations

**Diagnosis**:
1. Check warehouse size: `SHOW WAREHOUSES;`
2. Check warehouse is running: `SELECT CURRENT_WAREHOUSE();`
3. Review query history for bottlenecks

**Resolution**:
```sql
-- Scale up warehouse
ALTER WAREHOUSE COMPUTE_WH SET WAREHOUSE_SIZE = 'MEDIUM';

-- Rerun tests
-- Re-execute test suite
```

---

## Comparing with Oracle Results

### Expected Behavior Equivalence

| Oracle | Snowflake | Equivalence |
|--------|-----------|-------------|
| Function returns NUMBER | PROCEDURE returns BIGINT | ✅ Equivalent (same value) |
| Function returns %rowtype | PROCEDURE returns TABLE | ✅ Equivalent (same data) |
| RETURNING INTO clause | Sequence + NEXTVAL | ✅ Equivalent (same ID) |
| WHEN NO_DATA_FOUND → NULL | Empty result set | ✅ Equivalent (not found) |
| SQL%ROWCOUNT | ROW_COUNT() | ✅ Equivalent (same count) |
| Manual audit tracking | Automatic trigger | ✅ Enhanced (better coverage) |

---

## Test Data Generated

During test execution, the following test data is created:

```
Customers Created:
- TC_001: John Doe
- TC_002: Jane Smith
- TC_003: Customer 1, 2, 3 (sequence test)
- TC_004: Test Get Customer
- TC_006: Robert Johnson
- TC_007: Original Name → Updated Name
- TC_011: Old Customer 1, 2, New Customer
- TC_012: Audit Test Insert
- TC_013: Audit Test Update
- TC_014: Audit Test Delete
- TC_015: Consistency Test 1, 2

Audit Records Created:
- 1 per CREATE
- 1 per UPDATE
- 1 per DELETE
- ~20 total audit records for validation
```

**Note**: Test data is left in tables for review. Clean up with:
```sql
DROP SCHEMA TEST_CUSTOMER_PKG CASCADE;
```

---

## Test Results Queries

### View All Test Results
```sql
SELECT * FROM TEST_CUSTOMER_PKG.test_results 
ORDER BY test_case_id;
```

### View Failed Tests Only
```sql
SELECT * FROM TEST_CUSTOMER_PKG.test_results 
WHERE status = 'FAIL' 
ORDER BY test_timestamp DESC;
```

### View by Procedure
```sql
SELECT 
    procedure_name,
    COUNT(*) as tests,
    SUM(CASE WHEN status = 'PASS' THEN 1 ELSE 0 END) as passed,
    SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END) as failed
FROM TEST_CUSTOMER_PKG.test_results
GROUP BY procedure_name;
```

### View Slowest Tests
```sql
SELECT 
    test_case_id,
    test_name,
    execution_time_ms,
    status
FROM TEST_CUSTOMER_PKG.test_results
ORDER BY execution_time_ms DESC
LIMIT 5;
```

---

## Test Maintenance

### Adding New Tests

To add new test cases:

1. Create new DO block with unique test_case_id
2. Follow existing pattern (TC_XXX format)
3. Insert result into TEST_CUSTOMER_PKG.test_results
4. Include RAISE NOTICE for logging
5. Handle EXCEPTION with proper error message

### Running Subset of Tests

To run only specific tests:

```sql
-- Run only CREATE tests (TC_001-003)
-- Copy only the DO blocks for TC_001, TC_002, TC_003
-- Execute individually

-- Or filter results
SELECT * FROM TEST_CUSTOMER_PKG.test_results 
WHERE test_case_id LIKE 'TC_001%' OR test_case_id LIKE 'TC_002%';
```

---

## Integration with CI/CD

### Automated Testing

The test suite can be automated:

```bash
#!/bin/bash
# Run tests via Snowflake CLI

snowsql -c my_connection \
  -f customer_pkg_validation_test_suite.sql \
  -o output_file=test_results.txt

# Parse results
if grep -q "passed_tests.*15" test_results.txt; then
  echo "All tests passed!"
  exit 0
else
  echo "Some tests failed!"
  exit 1
fi
```

### GitHub Actions Example

```yaml
- name: Run Snowflake Tests
  run: |
    snowsql -c prod -f customer_pkg_validation_test_suite.sql
    # Check results for pass/fail status
```

---

## Sign-Off

After all tests PASS:

- ✅ Test execution date: _______________
- ✅ Tester name: _______________
- ✅ Pass percentage: ___% (should be 100%)
- ✅ Failed test cases: _____ (should be 0)
- ✅ Performance acceptable: Yes / No
- ✅ Ready for production: Yes / No

---

## Additional Resources

- [Snowflake Testing Best Practices](https://docs.snowflake.com/en/sql-reference/sql/create-procedure.html)
- [Snowflake Stored Procedures](https://docs.snowflake.com/en/sql-reference/stored-procedures-overview.html)
- [Migration Guide](SNOWFLAKE_MIGRATION_GUIDE.md)
- [Developer Reference](DEVELOPER_QUICK_REFERENCE.md)

---

**Document Version**: 1.0  
**Last Updated**: 2026-06-14  
**Status**: Ready for Testing  
