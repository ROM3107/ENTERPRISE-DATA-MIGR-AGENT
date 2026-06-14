# Test Execution Guide & Results Template
## customer_pkg Validation Test Suite

**Test Suite**: customer_pkg_validation_test_suite.sql  
**Test Documentation**: TEST_CASES_DOCUMENTATION.md  
**Date**: 2026-06-14  

---

## Quick Start: Running Tests in 5 Minutes

### Step 1: Verify Prerequisites (1 minute)
```sql
-- In Snowflake SQL Editor, run:
SHOW PROCEDURES IN SCHEMA CUSTOMER_MGMT;
```

**Expected**: Should show 7 procedures listed:
- new_customer
- get_customer
- get_customer_name
- set_customer
- set_customer_object
- delete_customer
- purge_old_customers

If not listed, re-execute `customer_pkg-converted-snowflake.sql` first.

### Step 2: Execute Test Suite (2 minutes)
```sql
-- Copy entire contents of:
-- customer_pkg_validation_test_suite.sql

-- Paste into Snowflake SQL editor
-- Click Execute (or Ctrl+Enter)
-- Wait for completion (status: succeeded)
```

### Step 3: Review Results (2 minutes)
The script automatically displays:
1. **Test Summary** - Overall statistics
2. **Detailed Results** - Each test status
3. **Performance Analysis** - Execution times by procedure

---

## Interpreting Test Results

### Test Summary Output

```
report_type              | TEST EXECUTION SUMMARY
total_tests              | 15
passed_tests             | 15
failed_tests             | 0
skipped_tests            | 0
pass_percentage          | 100.00
total_execution_time_ms  | 1250
avg_execution_time_ms    | 83.33
```

**✅ SUCCESS**: Pass percentage = 100% AND failed_tests = 0

**❌ FAILURE**: Pass percentage < 100% OR failed_tests > 0

---

### Detailed Results Output

Each test shows:
```
test_case_id | test_name                    | procedure_name  | status | execution_time_ms | error_message
TC_001       | Create Single Customer...    | new_customer    | PASS   | 45                | (null)
TC_002       | Verify Created Customer...   | new_customer    | PASS   | 32                | (null)
```

**Status Values**:
- `PASS` ✅ - Test executed successfully, assertion passed
- `FAIL` ❌ - Test executed but assertion failed (see error_message)
- `SKIP` ⊘ - Test was not executed (see error_message for reason)

---

### Performance Analysis Output

```
procedure_name        | test_count | passed | failed | avg_execution_time_ms
new_customer          | 3          | 3      | 0      | 39.67
get_customer          | 2          | 2      | 0      | 28.50
```

**Expectations**:
- Simple operations (get, create, delete): 20-60ms
- Update operations: 30-80ms
- Purge operations: 100-300ms
- Average across all: 50-150ms

If times exceed these, consider:
1. Warehouse scaling
2. Network latency
3. Database load

---

## Test Case Reference

### Quick Lookup: Which Test Validates What?

| Need to Validate | Test Case | Status Column |
|-----------------|-----------|----------------|
| CREATE procedure works | TC_001 - TC_003 | All should be PASS |
| READ procedures work | TC_004 - TC_006 | All should be PASS |
| UPDATE procedure works | TC_007 - TC_008 | All should be PASS |
| DELETE procedure works | TC_009 - TC_010 | All should be PASS |
| BULK operations work | TC_011 | Should be PASS |
| Audit trail working | TC_012 - TC_014 | All should be PASS |
| Data consistency | TC_015 | Should be PASS |

---

## Reading the Results Table

### Query Test Results
```sql
-- View all results
SELECT * FROM TEST_CUSTOMER_PKG.test_results;

-- View only failed tests
SELECT * FROM TEST_CUSTOMER_PKG.test_results 
WHERE status = 'FAIL';

-- View specific procedure results
SELECT * FROM TEST_CUSTOMER_PKG.test_results 
WHERE procedure_name = 'new_customer';

-- View slowest tests
SELECT test_case_id, test_name, execution_time_ms 
FROM TEST_CUSTOMER_PKG.test_results 
ORDER BY execution_time_ms DESC;
```

---

## Handling Test Failures

### Scenario 1: All Tests PASS ✅

**Great!** Conversion is valid.

**Next Steps**:
1. Document test date/time
2. Sign off on validation
3. Proceed to production deployment

---

### Scenario 2: Some Tests FAIL ❌

**Steps to Resolve**:

1. **Identify Failed Tests**
   ```sql
   SELECT test_case_id, test_name, error_message 
   FROM TEST_CUSTOMER_PKG.test_results 
   WHERE status = 'FAIL';
   ```

2. **Read Error Message**
   - Contains details about what went wrong
   - Example: "Expected 1 row, got 0"

3. **Review Test Case Documentation**
   - Find test in TEST_CASES_DOCUMENTATION.md
   - Understand expected behavior
   - Check test steps

4. **Manual Testing**
   ```sql
   -- Reproduce the test manually
   CALL CUSTOMER_MGMT.new_customer('Test Name') INTO v_id;
   SELECT * FROM CUSTOMER_MGMT.xy_customer WHERE customer_id = v_id;
   ```

5. **Identify Root Cause**
   - Procedure logic error
   - Data type mismatch
   - Missing index or trigger
   - Permission issue

6. **Fix & Retest**
   - Correct the conversion SQL
   - Re-execute fixed code
   - Rerun test suite

---

### Scenario 3: Tests Won't Execute

**Error**: `Procedure does not exist`

**Solution**:
1. Verify conversion script executed: `SHOW PROCEDURES;`
2. Re-execute `customer_pkg-converted-snowflake.sql`
3. Verify no SQL errors in execution
4. Try test again

---

### Scenario 4: Slow Test Execution

**Symptom**: Individual tests taking >500ms

**Steps**:
1. Check warehouse size: `SELECT CURRENT_WAREHOUSE();`
2. Scale if needed:
   ```sql
   ALTER WAREHOUSE COMPUTE_WH SET WAREHOUSE_SIZE = 'MEDIUM';
   ```
3. Rerun tests
4. Compare execution times

---

## Test Execution Checklist

### Pre-Execution
- [ ] Snowflake account access confirmed
- [ ] Conversion script previously executed
- [ ] All procedures visible: `SHOW PROCEDURES IN SCHEMA CUSTOMER_MGMT;`
- [ ] Warehouse is running and sized appropriately
- [ ] No concurrent operations on xy_customer table

### During Execution
- [ ] Test suite executing without SQL errors
- [ ] Status shows "succeeded" after completion
- [ ] Test output visible in results pane
- [ ] No authentication or permission errors

### Post-Execution
- [ ] All 15 tests completed
- [ ] Pass percentage calculated
- [ ] Summary statistics displayed
- [ ] Detailed results queryable from TEST_CUSTOMER_PKG.test_results

---

## Test Results Template

**Fill this out after running tests:**

```
TEST EXECUTION REPORT
====================

Execution Date/Time: ___________________
Tester Name: ___________________
Organization: ___________________

ENVIRONMENT
-----------
Snowflake Account: ___________________
Warehouse: ___________________
Warehouse Size: ___________________
Database: ___________________
Schema: CUSTOMER_MGMT

TEST EXECUTION RESULTS
----------------------
Total Test Cases: 15
Passed: _____
Failed: _____
Skipped: _____
Pass Percentage: _____%

RESULT STATUS
-------------
☐ 100% Pass (All tests passed) ✅
☐ >90% Pass (Minor issues)
☐ 50-90% Pass (Some failures)
☐ <50% Pass (Multiple failures) ❌

DETAILED RESULTS
----------------
Create Operations (TC_001-003):     ☐ PASS / ☐ FAIL
Retrieve Operations (TC_004-006):   ☐ PASS / ☐ FAIL
Update Operations (TC_007-008):     ☐ PASS / ☐ FAIL
Delete Operations (TC_009-010):     ☐ PASS / ☐ FAIL
Bulk Operations (TC_011):           ☐ PASS / ☐ FAIL
Audit Trail (TC_012-014):           ☐ PASS / ☐ FAIL
Data Consistency (TC_015):          ☐ PASS / ☐ FAIL

PERFORMANCE METRICS
-------------------
Average Execution Time: _____ms
Fastest Procedure: ___________________
Slowest Procedure: ___________________
Total Test Duration: _____ms

ISSUES FOUND
-----------
Issue 1: ___________________________
  - Impact: ___________________________
  - Resolution: ___________________________

Issue 2: ___________________________
  - Impact: ___________________________
  - Resolution: ___________________________

SIGN-OFF
--------
Validation Status: ☐ APPROVED / ☐ CONDITIONAL / ☐ FAILED
Approval Date: ___________________
Approver Name: ___________________
Comments: ___________________________

NEXT STEPS
----------
☐ Deploy to production
☐ Fix issues and retest
☐ Escalate to development team
☐ Schedule followup review
```

---

## Common Test Failure Patterns

### Pattern 1: "No customer found" Message

**Test Fails**: TC_008, TC_010

**Symptom**: Expected "No customer found" but got something else

**Cause**: Message format changed

**Fix**: Check actual message format in procedure code
```sql
-- Should be: "No customer found with ID: xxx"
-- If different, update message in set_customer or delete_customer procedures
```

---

### Pattern 2: Audit Trail Records Not Found

**Test Fails**: TC_012, TC_013, TC_014

**Symptom**: Query returns 0 audit records

**Cause**: Trigger not executing

**Fix**:
```sql
-- Verify trigger exists
SHOW TRIGGERS LIKE 'customer_audit%' IN SCHEMA CUSTOMER_MGMT;

-- If missing, recreate from conversion script
-- If exists, check trigger is enabled (should be by default)
```

---

### Pattern 3: Non-Sequential IDs

**Test Fails**: TC_003

**Symptom**: Customer IDs not incrementing by 1

**Cause**: Sequence reset or modified

**Fix**:
```sql
-- Check sequence
SHOW SEQUENCES LIKE '%xy_customer_seq%' IN SCHEMA CUSTOMER_MGMT;

-- If needed, reset sequence
ALTER SEQUENCE CUSTOMER_MGMT.xy_customer_seq SET INCREMENT = 1;
```

---

### Pattern 4: Timeout Errors

**Test Fails**: TC_011 (purge)

**Symptom**: Procedure execution timeout

**Cause**: Warehouse too small or other operations running

**Fix**:
```sql
-- Scale up warehouse
ALTER WAREHOUSE COMPUTE_WH SET WAREHOUSE_SIZE = 'MEDIUM';

-- Rerun test
```

---

## Performance Baseline

After first successful test run, document these metrics:

| Metric | Value | Notes |
|--------|-------|-------|
| Average test time (ms) | _____ | Baseline for comparison |
| Fastest procedure (ms) | _____ | Best case performance |
| Slowest procedure (ms) | _____ | Worst case performance |
| Total suite time (ms) | _____ | Complete test duration |
| Create procedure (avg) | _____ | For future optimization |
| Read procedure (avg) | _____ | For future optimization |
| Update procedure (avg) | _____ | For future optimization |
| Delete procedure (avg) | _____ | For future optimization |

---

## Regression Testing

### After Each Update

If you modify the conversion code, rerun tests to ensure:
- ✅ All tests still PASS
- ✅ Performance hasn't degraded
- ✅ No new failures introduced
- ✅ Audit trail still working

```sql
-- Rerun test suite after any changes
-- Compare new results to baseline
-- Document any deviations
```

---

## Cleanup

### After Testing Complete

If you want to remove test schema:

```sql
-- WARNING: This deletes all test data and results!
DROP SCHEMA TEST_CUSTOMER_PKG CASCADE;
```

If you want to preserve results:

```sql
-- Export results before cleanup
SELECT * FROM TEST_CUSTOMER_PKG.test_results 
INTO OUTBOUND FILE 's3://my-bucket/test_results.csv';

-- Then delete
DROP SCHEMA TEST_CUSTOMER_PKG CASCADE;
```

---

## Support & Escalation

### If Tests Still Fail After Following Guide

1. **Collect Diagnostic Information**
   ```sql
   -- Capture procedure definitions
   SHOW PROCEDURES IN SCHEMA CUSTOMER_MGMT;
   GET_PROCEDURE_DEFINITION('CUSTOMER_MGMT.new_customer(VARCHAR)');
   
   -- Capture test results
   SELECT * FROM TEST_CUSTOMER_PKG.test_results 
   WHERE status = 'FAIL';
   
   -- Capture system state
   SELECT CURRENT_WAREHOUSE(), CURRENT_DATABASE(), CURRENT_SCHEMA();
   ```

2. **Review Documentation**
   - Check SNOWFLAKE_MIGRATION_GUIDE.md Troubleshooting section
   - Review DEVELOPER_QUICK_REFERENCE.md Error Handling section
   - Read TEST_CASES_DOCUMENTATION.md for specific test details

3. **Manual Testing**
   - Execute procedures directly to diagnose issues
   - Check data in xy_customer table
   - Verify audit trail tables

4. **Contact Support**
   - Provide test results showing failures
   - Include diagnostic information from step 1
   - Include steps to reproduce issue

---

## Sign-Off Template

**After successful test execution (100% pass rate):**

```
VALIDATION SIGN-OFF
==================

Test Suite: customer_pkg_validation_test_suite.sql
Conversion: customer_pkg (Oracle → Snowflake)
Date: ___________________

VALIDATION RESULTS
------------------
✅ All 15 test cases PASSED
✅ Pass percentage: 100%
✅ No failed tests
✅ No skipped tests
✅ Performance acceptable

SIGN-OFF
--------
Validated by: ___________________
Title: ___________________
Date: ___________________
Signature: ___________________

APPROVAL
--------
Approved by: ___________________
Title: ___________________
Date: ___________________
Signature: ___________________

NOTES/COMMENTS
--------------
___________________________________________
___________________________________________
___________________________________________

NEXT STEPS
----------
☐ Ready for production deployment
☐ Ready for user acceptance testing
☐ Documentation complete
☐ Training materials prepared
```

---

**Guide Version**: 1.0  
**Last Updated**: 2026-06-14  
**Status**: Ready for Use  
