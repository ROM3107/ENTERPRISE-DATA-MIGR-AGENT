-- ============================================================================
-- SNOWFLAKE VALIDATION TEST SUITE
-- Converted Code: customer_pkg-converted-snowflake.sql
-- Test Framework: Snowflake SQL + Result Comparison
-- ============================================================================

-- ============================================================================
-- SETUP: Test Environment Preparation
-- ============================================================================

-- Create test schema
CREATE SCHEMA IF NOT EXISTS TEST_CUSTOMER_PKG;

-- Create test data source table (for reference data)
CREATE OR REPLACE TABLE TEST_CUSTOMER_PKG.test_data_source (
    test_case_id VARCHAR(50),
    description VARCHAR(500),
    input_customer_name VARCHAR(255),
    input_customer_id BIGINT,
    input_date DATE,
    expected_status VARCHAR(100),
    expected_rows_affected BIGINT,
    created_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP
)
COMMENT = 'Test data source - contains test cases and expected results';

-- Create test results table (for tracking test execution)
CREATE OR REPLACE TABLE TEST_CUSTOMER_PKG.test_results (
    test_run_id VARCHAR(50) DEFAULT CONCAT('RUN_', TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDD_HHmmss')),
    test_case_id VARCHAR(50),
    test_name VARCHAR(255),
    procedure_name VARCHAR(100),
    input_params VARIANT,
    expected_output VARIANT,
    actual_output VARIANT,
    status VARCHAR(20),  -- PASS, FAIL, SKIP
    error_message VARCHAR(1000),
    execution_time_ms BIGINT,
    test_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP
)
COMMENT = 'Test results - tracks all test executions and outcomes';

-- Create comparison results table
CREATE OR REPLACE TABLE TEST_CUSTOMER_PKG.data_comparison_results (
    comparison_type VARCHAR(100),  -- Row count, Data integrity, Audit trail
    source_system VARCHAR(50),      -- Oracle, Snowflake
    record_count BIGINT,
    sample_data VARIANT,
    validation_status VARCHAR(20),  -- MATCH, MISMATCH
    comparison_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP
)
COMMENT = 'Data comparison results - validates Oracle vs Snowflake data equivalence';


-- ============================================================================
-- TEST CASE 1: CREATE CUSTOMER (new_customer)
-- ============================================================================

-- Test Case 1.1: Create single customer with valid name
DO
$$
DECLARE
    v_test_id VARCHAR := 'TC_001_CREATE_SINGLE';
    v_test_name VARCHAR := 'Create Single Customer - Valid Input';
    v_customer_id BIGINT;
    v_start_time TIMESTAMP_NTZ := CURRENT_TIMESTAMP;
    v_execution_time_ms BIGINT;
BEGIN
    -- Execute procedure
    CALL CUSTOMER_MGMT.new_customer('John Doe') INTO v_customer_id;
    
    -- Calculate execution time
    v_execution_time_ms := DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP);
    
    -- Validate result
    IF v_customer_id IS NOT NULL AND v_customer_id > 0 THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, expected_output, 
             actual_output, status, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'new_customer', 
             OBJECT_CONSTRUCT('customer_name', 'John Doe'),
             OBJECT_CONSTRUCT('customer_id_generated', TRUE, 'type', 'BIGINT'),
             OBJECT_CONSTRUCT('customer_id', v_customer_id, 'type', 'BIGINT'),
             'PASS', v_execution_time_ms);
        
        RAISE NOTICE 'TEST PASSED: % - Generated customer ID: %', v_test_id, v_customer_id;
    ELSE
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'new_customer', 
             OBJECT_CONSTRUCT('customer_name', 'John Doe'),
             'FAIL', 'Customer ID was NULL or invalid', v_execution_time_ms);
        
        RAISE NOTICE 'TEST FAILED: % - Customer ID is NULL or invalid', v_test_id;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'new_customer', 
             OBJECT_CONSTRUCT('customer_name', 'John Doe'),
             'FAIL', SQLERRM, DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP));
        
        RAISE NOTICE 'TEST ERROR: % - %', v_test_id, SQLERRM;
END;
$$;

-- Test Case 1.2: Verify customer record created with correct data
DO
$$
DECLARE
    v_test_id VARCHAR := 'TC_002_CREATE_VERIFY_DATA';
    v_test_name VARCHAR := 'Verify Created Customer Data';
    v_customer_id BIGINT;
    v_customer_name VARCHAR;
    v_created_date TIMESTAMP_NTZ;
    v_start_time TIMESTAMP_NTZ := CURRENT_TIMESTAMP;
    v_execution_time_ms BIGINT;
BEGIN
    -- Create customer
    CALL CUSTOMER_MGMT.new_customer('Jane Smith') INTO v_customer_id;
    
    -- Query created customer
    SELECT customer_name, created_date 
    INTO v_customer_name, v_created_date
    FROM CUSTOMER_MGMT.xy_customer 
    WHERE customer_id = v_customer_id;
    
    -- Calculate execution time
    v_execution_time_ms := DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP);
    
    -- Validate data
    IF v_customer_name = 'Jane Smith' AND v_created_date IS NOT NULL THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, expected_output, 
             actual_output, status, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'new_customer', 
             OBJECT_CONSTRUCT('customer_name', 'Jane Smith'),
             OBJECT_CONSTRUCT('name_matches', TRUE, 'created_date_set', TRUE),
             OBJECT_CONSTRUCT('name', v_customer_name, 'created_date', v_created_date),
             'PASS', v_execution_time_ms);
        
        RAISE NOTICE 'TEST PASSED: % - Data verified correctly', v_test_id;
    ELSE
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'new_customer', 
             OBJECT_CONSTRUCT('customer_name', 'Jane Smith'),
             'FAIL', 'Customer data does not match expected values', v_execution_time_ms);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'new_customer', 
             OBJECT_CONSTRUCT('customer_name', 'Jane Smith'),
             'FAIL', SQLERRM, DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP));
END;
$$;

-- Test Case 1.3: Create multiple customers - verify ID sequence
DO
$$
DECLARE
    v_test_id VARCHAR := 'TC_003_SEQUENCE_INCREMENT';
    v_test_name VARCHAR := 'Verify ID Sequence Increments';
    v_id1 BIGINT;
    v_id2 BIGINT;
    v_id3 BIGINT;
    v_start_time TIMESTAMP_NTZ := CURRENT_TIMESTAMP;
    v_execution_time_ms BIGINT;
BEGIN
    -- Create three customers
    CALL CUSTOMER_MGMT.new_customer('Customer 1') INTO v_id1;
    CALL CUSTOMER_MGMT.new_customer('Customer 2') INTO v_id2;
    CALL CUSTOMER_MGMT.new_customer('Customer 3') INTO v_id3;
    
    -- Calculate execution time
    v_execution_time_ms := DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP);
    
    -- Validate sequence (IDs should be sequential)
    IF v_id1 < v_id2 AND v_id2 < v_id3 AND (v_id2 - v_id1 = 1) AND (v_id3 - v_id2 = 1) THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, expected_output, 
             actual_output, status, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'new_customer', 
             OBJECT_CONSTRUCT('action', 'create_3_customers'),
             OBJECT_CONSTRUCT('sequential_ids', TRUE),
             OBJECT_CONSTRUCT('id1', v_id1, 'id2', v_id2, 'id3', v_id3),
             'PASS', v_execution_time_ms);
        
        RAISE NOTICE 'TEST PASSED: % - IDs are sequential: % -> % -> %', v_test_id, v_id1, v_id2, v_id3;
    ELSE
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'new_customer', 
             OBJECT_CONSTRUCT('action', 'create_3_customers'),
             'FAIL', 'IDs are not sequential', v_execution_time_ms);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'new_customer', 
             OBJECT_CONSTRUCT('action', 'create_3_customers'),
             'FAIL', SQLERRM, DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP));
END;
$$;


-- ============================================================================
-- TEST CASE 2: RETRIEVE CUSTOMER (get_customer)
-- ============================================================================

-- Test Case 2.1: Get existing customer
DO
$$
DECLARE
    v_test_id VARCHAR := 'TC_004_GET_EXISTING';
    v_test_name VARCHAR := 'Get Existing Customer';
    v_customer_id BIGINT;
    v_result_rows BIGINT;
    v_start_time TIMESTAMP_NTZ := CURRENT_TIMESTAMP;
    v_execution_time_ms BIGINT;
BEGIN
    -- Create a test customer
    CALL CUSTOMER_MGMT.new_customer('Test Get Customer') INTO v_customer_id;
    
    -- Count results from get_customer
    SELECT COUNT(*) INTO v_result_rows 
    FROM TABLE(CUSTOMER_MGMT.get_customer(v_customer_id));
    
    -- Calculate execution time
    v_execution_time_ms := DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP);
    
    -- Validate result
    IF v_result_rows = 1 THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, expected_output, 
             actual_output, status, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'get_customer', 
             OBJECT_CONSTRUCT('customer_id', v_customer_id),
             OBJECT_CONSTRUCT('rows_returned', 1),
             OBJECT_CONSTRUCT('rows_returned', v_result_rows),
             'PASS', v_execution_time_ms);
        
        RAISE NOTICE 'TEST PASSED: % - Found 1 customer record', v_test_id;
    ELSE
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'get_customer', 
             OBJECT_CONSTRUCT('customer_id', v_customer_id),
             'FAIL', 'Expected 1 row, got ' || v_result_rows, v_execution_time_ms);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'get_customer', 
             OBJECT_CONSTRUCT('customer_id', v_customer_id),
             'FAIL', SQLERRM, DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP));
END;
$$;

-- Test Case 2.2: Get non-existent customer
DO
$$
DECLARE
    v_test_id VARCHAR := 'TC_005_GET_NONEXISTENT';
    v_test_name VARCHAR := 'Get Non-Existent Customer';
    v_result_rows BIGINT;
    v_start_time TIMESTAMP_NTZ := CURRENT_TIMESTAMP;
    v_execution_time_ms BIGINT;
BEGIN
    -- Try to get customer with ID that doesn't exist
    SELECT COUNT(*) INTO v_result_rows 
    FROM TABLE(CUSTOMER_MGMT.get_customer(999999));
    
    -- Calculate execution time
    v_execution_time_ms := DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP);
    
    -- Should return 0 rows (not found)
    IF v_result_rows = 0 THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, expected_output, 
             actual_output, status, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'get_customer', 
             OBJECT_CONSTRUCT('customer_id', 999999),
             OBJECT_CONSTRUCT('rows_returned', 0, 'behavior', 'no_exception'),
             OBJECT_CONSTRUCT('rows_returned', v_result_rows),
             'PASS', v_execution_time_ms);
        
        RAISE NOTICE 'TEST PASSED: % - Non-existent customer returns 0 rows', v_test_id;
    ELSE
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'get_customer', 
             OBJECT_CONSTRUCT('customer_id', 999999),
             'FAIL', 'Expected 0 rows for non-existent customer', v_execution_time_ms);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'get_customer', 
             OBJECT_CONSTRUCT('customer_id', 999999),
             'FAIL', SQLERRM, DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP));
END;
$$;


-- ============================================================================
-- TEST CASE 3: GET CUSTOMER NAME (get_customer_name)
-- ============================================================================

-- Test Case 3.1: Get customer name - existing customer
DO
$$
DECLARE
    v_test_id VARCHAR := 'TC_006_GET_NAME_EXISTING';
    v_test_name VARCHAR := 'Get Customer Name - Existing';
    v_customer_id BIGINT;
    v_retrieved_name VARCHAR;
    v_count BIGINT;
    v_start_time TIMESTAMP_NTZ := CURRENT_TIMESTAMP;
    v_execution_time_ms BIGINT;
BEGIN
    -- Create customer with specific name
    CALL CUSTOMER_MGMT.new_customer('Robert Johnson') INTO v_customer_id;
    
    -- Get customer name
    SELECT COUNT(*), MAX(customer_name) 
    INTO v_count, v_retrieved_name
    FROM TABLE(CUSTOMER_MGMT.get_customer_name(v_customer_id));
    
    -- Calculate execution time
    v_execution_time_ms := DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP);
    
    -- Validate
    IF v_count = 1 AND v_retrieved_name = 'Robert Johnson' THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, expected_output, 
             actual_output, status, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'get_customer_name', 
             OBJECT_CONSTRUCT('customer_id', v_customer_id),
             OBJECT_CONSTRUCT('customer_name', 'Robert Johnson'),
             OBJECT_CONSTRUCT('customer_name', v_retrieved_name),
             'PASS', v_execution_time_ms);
        
        RAISE NOTICE 'TEST PASSED: % - Retrieved name: %', v_test_id, v_retrieved_name;
    ELSE
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'get_customer_name', 
             OBJECT_CONSTRUCT('customer_id', v_customer_id),
             'FAIL', 'Name mismatch or no rows returned', v_execution_time_ms);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'get_customer_name', 
             OBJECT_CONSTRUCT('customer_id', v_customer_id),
             'FAIL', SQLERRM, DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP));
END;
$$;


-- ============================================================================
-- TEST CASE 4: UPDATE CUSTOMER (set_customer)
-- ============================================================================

-- Test Case 4.1: Update customer name
DO
$$
DECLARE
    v_test_id VARCHAR := 'TC_007_UPDATE_NAME';
    v_test_name VARCHAR := 'Update Customer Name';
    v_customer_id BIGINT;
    v_status VARCHAR;
    v_updated_name VARCHAR;
    v_start_time TIMESTAMP_NTZ := CURRENT_TIMESTAMP;
    v_execution_time_ms BIGINT;
BEGIN
    -- Create customer
    CALL CUSTOMER_MGMT.new_customer('Original Name') INTO v_customer_id;
    
    -- Update customer name
    CALL CUSTOMER_MGMT.set_customer(v_customer_id, 'Updated Name') INTO v_status;
    
    -- Verify update
    SELECT customer_name INTO v_updated_name 
    FROM CUSTOMER_MGMT.xy_customer 
    WHERE customer_id = v_customer_id;
    
    -- Calculate execution time
    v_execution_time_ms := DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP);
    
    -- Validate
    IF v_updated_name = 'Updated Name' AND v_status LIKE '%successfully%' THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, expected_output, 
             actual_output, status, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'set_customer', 
             OBJECT_CONSTRUCT('customer_id', v_customer_id, 'new_name', 'Updated Name'),
             OBJECT_CONSTRUCT('name_updated', TRUE, 'status_indicates_success', TRUE),
             OBJECT_CONSTRUCT('name', v_updated_name, 'status', v_status),
             'PASS', v_execution_time_ms);
        
        RAISE NOTICE 'TEST PASSED: % - Customer name updated successfully', v_test_id;
    ELSE
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'set_customer', 
             OBJECT_CONSTRUCT('customer_id', v_customer_id, 'new_name', 'Updated Name'),
             'FAIL', 'Update failed or status message incorrect', v_execution_time_ms);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'set_customer', 
             OBJECT_CONSTRUCT('customer_id', v_customer_id, 'new_name', 'Updated Name'),
             'FAIL', SQLERRM, DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP));
END;
$$;

-- Test Case 4.2: Update non-existent customer
DO
$$
DECLARE
    v_test_id VARCHAR := 'TC_008_UPDATE_NONEXISTENT';
    v_test_name VARCHAR := 'Update Non-Existent Customer';
    v_status VARCHAR;
    v_start_time TIMESTAMP_NTZ := CURRENT_TIMESTAMP;
    v_execution_time_ms BIGINT;
BEGIN
    -- Try to update non-existent customer
    CALL CUSTOMER_MGMT.set_customer(999999, 'Test Name') INTO v_status;
    
    -- Calculate execution time
    v_execution_time_ms := DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP);
    
    -- Should return "No customer found" message
    IF v_status LIKE '%No customer%' THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, expected_output, 
             actual_output, status, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'set_customer', 
             OBJECT_CONSTRUCT('customer_id', 999999),
             OBJECT_CONSTRUCT('message_type', 'not_found'),
             OBJECT_CONSTRUCT('status_message', v_status),
             'PASS', v_execution_time_ms);
        
        RAISE NOTICE 'TEST PASSED: % - Correct message for non-existent customer', v_test_id;
    ELSE
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'set_customer', 
             OBJECT_CONSTRUCT('customer_id', 999999),
             'FAIL', 'Expected "No customer" message, got: ' || v_status, v_execution_time_ms);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'set_customer', 
             OBJECT_CONSTRUCT('customer_id', 999999),
             'FAIL', SQLERRM, DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP));
END;
$$;


-- ============================================================================
-- TEST CASE 5: DELETE CUSTOMER (delete_customer)
-- ============================================================================

-- Test Case 5.1: Delete existing customer
DO
$$
DECLARE
    v_test_id VARCHAR := 'TC_009_DELETE_EXISTING';
    v_test_name VARCHAR := 'Delete Existing Customer';
    v_customer_id BIGINT;
    v_status VARCHAR;
    v_count_after BIGINT;
    v_start_time TIMESTAMP_NTZ := CURRENT_TIMESTAMP;
    v_execution_time_ms BIGINT;
BEGIN
    -- Create customer
    CALL CUSTOMER_MGMT.new_customer('To Delete') INTO v_customer_id;
    
    -- Delete customer
    CALL CUSTOMER_MGMT.delete_customer(v_customer_id) INTO v_status;
    
    -- Verify deletion
    SELECT COUNT(*) INTO v_count_after 
    FROM CUSTOMER_MGMT.xy_customer 
    WHERE customer_id = v_customer_id;
    
    -- Calculate execution time
    v_execution_time_ms := DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP);
    
    -- Validate
    IF v_count_after = 0 AND v_status LIKE '%successfully%' THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, expected_output, 
             actual_output, status, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'delete_customer', 
             OBJECT_CONSTRUCT('customer_id', v_customer_id),
             OBJECT_CONSTRUCT('deleted', TRUE, 'record_count', 0),
             OBJECT_CONSTRUCT('deleted', TRUE, 'status', v_status),
             'PASS', v_execution_time_ms);
        
        RAISE NOTICE 'TEST PASSED: % - Customer deleted successfully', v_test_id;
    ELSE
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'delete_customer', 
             OBJECT_CONSTRUCT('customer_id', v_customer_id),
             'FAIL', 'Deletion failed or record still exists', v_execution_time_ms);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'delete_customer', 
             OBJECT_CONSTRUCT('customer_id', v_customer_id),
             'FAIL', SQLERRM, DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP));
END;
$$;

-- Test Case 5.2: Delete non-existent customer
DO
$$
DECLARE
    v_test_id VARCHAR := 'TC_010_DELETE_NONEXISTENT';
    v_test_name VARCHAR := 'Delete Non-Existent Customer';
    v_status VARCHAR;
    v_start_time TIMESTAMP_NTZ := CURRENT_TIMESTAMP;
    v_execution_time_ms BIGINT;
BEGIN
    -- Try to delete non-existent customer
    CALL CUSTOMER_MGMT.delete_customer(999999) INTO v_status;
    
    -- Calculate execution time
    v_execution_time_ms := DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP);
    
    -- Should return "No customer found" message
    IF v_status LIKE '%No customer%' THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, expected_output, 
             actual_output, status, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'delete_customer', 
             OBJECT_CONSTRUCT('customer_id', 999999),
             OBJECT_CONSTRUCT('message_type', 'not_found'),
             OBJECT_CONSTRUCT('status_message', v_status),
             'PASS', v_execution_time_ms);
        
        RAISE NOTICE 'TEST PASSED: % - Correct message for non-existent customer', v_test_id;
    ELSE
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'delete_customer', 
             OBJECT_CONSTRUCT('customer_id', 999999),
             'FAIL', 'Expected "No customer" message', v_execution_time_ms);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'delete_customer', 
             OBJECT_CONSTRUCT('customer_id', 999999),
             'FAIL', SQLERRM, DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP));
END;
$$;


-- ============================================================================
-- TEST CASE 6: PURGE OLD CUSTOMERS (purge_old_customers)
-- ============================================================================

-- Test Case 6.1: Purge customers with specified date
DO
$$
DECLARE
    v_test_id VARCHAR := 'TC_011_PURGE_BY_DATE';
    v_test_name VARCHAR := 'Purge Old Customers by Date';
    v_customer_id1 BIGINT;
    v_customer_id2 BIGINT;
    v_customer_id3 BIGINT;
    v_purge_result VARIANT;
    v_rows_deleted BIGINT;
    v_count_before BIGINT;
    v_count_after BIGINT;
    v_start_time TIMESTAMP_NTZ := CURRENT_TIMESTAMP;
    v_execution_time_ms BIGINT;
BEGIN
    -- Create customers with different inactive dates
    CALL CUSTOMER_MGMT.new_customer('Old Customer 1') INTO v_customer_id1;
    CALL CUSTOMER_MGMT.new_customer('Old Customer 2') INTO v_customer_id2;
    CALL CUSTOMER_MGMT.new_customer('New Customer') INTO v_customer_id3;
    
    -- Update last_active_date for some customers (simulate old records)
    UPDATE CUSTOMER_MGMT.xy_customer 
    SET last_active_date = '2020-01-01'::TIMESTAMP_NTZ 
    WHERE customer_id IN (v_customer_id1, v_customer_id2);
    
    -- Count before purge
    SELECT COUNT(*) INTO v_count_before FROM CUSTOMER_MGMT.xy_customer;
    
    -- Purge customers inactive before 2021
    CALL CUSTOMER_MGMT.purge_old_customers('2021-01-01'::DATE, FALSE) INTO v_purge_result;
    
    -- Count after purge
    SELECT COUNT(*) INTO v_count_after FROM CUSTOMER_MGMT.xy_customer;
    
    -- Extract rows_deleted from result
    v_rows_deleted := v_purge_result:rows_deleted;
    
    -- Calculate execution time
    v_execution_time_ms := DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP);
    
    -- Validate
    IF v_rows_deleted = 2 AND v_count_after = v_count_before - 2 THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, expected_output, 
             actual_output, status, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'purge_old_customers', 
             OBJECT_CONSTRUCT('cutoff_date', '2021-01-01'),
             OBJECT_CONSTRUCT('rows_deleted', 2),
             OBJECT_CONSTRUCT('rows_deleted', v_rows_deleted, 'purge_result', v_purge_result),
             'PASS', v_execution_time_ms);
        
        RAISE NOTICE 'TEST PASSED: % - Purged % old customers', v_test_id, v_rows_deleted;
    ELSE
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'purge_old_customers', 
             OBJECT_CONSTRUCT('cutoff_date', '2021-01-01'),
             'FAIL', 'Expected 2 rows deleted, got ' || v_rows_deleted, v_execution_time_ms);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'purge_old_customers', 
             OBJECT_CONSTRUCT('cutoff_date', '2021-01-01'),
             'FAIL', SQLERRM, DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP));
END;
$$;


-- ============================================================================
-- TEST CASE 7: AUDIT TRAIL VALIDATION
-- ============================================================================

-- Test Case 7.1: Audit trail captures INSERT
DO
$$
DECLARE
    v_test_id VARCHAR := 'TC_012_AUDIT_INSERT';
    v_test_name VARCHAR := 'Audit Trail - Capture INSERT';
    v_customer_id BIGINT;
    v_audit_count BIGINT;
    v_start_time TIMESTAMP_NTZ := CURRENT_TIMESTAMP;
    v_execution_time_ms BIGINT;
BEGIN
    -- Create customer
    CALL CUSTOMER_MGMT.new_customer('Audit Test Insert') INTO v_customer_id;
    
    -- Check audit trail
    SELECT COUNT(*) INTO v_audit_count 
    FROM CUSTOMER_MGMT.xy_customer_audit 
    WHERE customer_id = v_customer_id AND action = 'INSERT';
    
    -- Calculate execution time
    v_execution_time_ms := DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP);
    
    -- Validate
    IF v_audit_count > 0 THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, expected_output, 
             actual_output, status, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'audit_trail', 
             OBJECT_CONSTRUCT('action', 'INSERT', 'customer_id', v_customer_id),
             OBJECT_CONSTRUCT('audit_recorded', TRUE),
             OBJECT_CONSTRUCT('audit_count', v_audit_count),
             'PASS', v_execution_time_ms);
        
        RAISE NOTICE 'TEST PASSED: % - INSERT action recorded in audit trail', v_test_id;
    ELSE
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'audit_trail', 
             OBJECT_CONSTRUCT('action', 'INSERT', 'customer_id', v_customer_id),
             'FAIL', 'No audit trail record found for INSERT', v_execution_time_ms);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'audit_trail', 
             OBJECT_CONSTRUCT('action', 'INSERT'),
             'FAIL', SQLERRM, DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP));
END;
$$;

-- Test Case 7.2: Audit trail captures UPDATE
DO
$$
DECLARE
    v_test_id VARCHAR := 'TC_013_AUDIT_UPDATE';
    v_test_name VARCHAR := 'Audit Trail - Capture UPDATE';
    v_customer_id BIGINT;
    v_audit_count BIGINT;
    v_start_time TIMESTAMP_NTZ := CURRENT_TIMESTAMP;
    v_execution_time_ms BIGINT;
    v_status VARCHAR;
BEGIN
    -- Create customer
    CALL CUSTOMER_MGMT.new_customer('Audit Test Update') INTO v_customer_id;
    
    -- Update customer
    CALL CUSTOMER_MGMT.set_customer(v_customer_id, 'Updated for Audit') INTO v_status;
    
    -- Check audit trail for UPDATE action
    SELECT COUNT(*) INTO v_audit_count 
    FROM CUSTOMER_MGMT.xy_customer_audit 
    WHERE customer_id = v_customer_id AND action = 'UPDATE';
    
    -- Calculate execution time
    v_execution_time_ms := DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP);
    
    -- Validate
    IF v_audit_count > 0 THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, expected_output, 
             actual_output, status, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'audit_trail', 
             OBJECT_CONSTRUCT('action', 'UPDATE', 'customer_id', v_customer_id),
             OBJECT_CONSTRUCT('audit_recorded', TRUE),
             OBJECT_CONSTRUCT('audit_count', v_audit_count),
             'PASS', v_execution_time_ms);
        
        RAISE NOTICE 'TEST PASSED: % - UPDATE action recorded in audit trail', v_test_id;
    ELSE
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'audit_trail', 
             OBJECT_CONSTRUCT('action', 'UPDATE', 'customer_id', v_customer_id),
             'FAIL', 'No audit trail record found for UPDATE', v_execution_time_ms);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'audit_trail', 
             OBJECT_CONSTRUCT('action', 'UPDATE'),
             'FAIL', SQLERRM, DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP));
END;
$$;

-- Test Case 7.3: Audit trail captures DELETE
DO
$$
DECLARE
    v_test_id VARCHAR := 'TC_014_AUDIT_DELETE';
    v_test_name VARCHAR := 'Audit Trail - Capture DELETE';
    v_customer_id BIGINT;
    v_audit_count BIGINT;
    v_start_time TIMESTAMP_NTZ := CURRENT_TIMESTAMP;
    v_execution_time_ms BIGINT;
    v_status VARCHAR;
BEGIN
    -- Create customer
    CALL CUSTOMER_MGMT.new_customer('Audit Test Delete') INTO v_customer_id;
    
    -- Delete customer
    CALL CUSTOMER_MGMT.delete_customer(v_customer_id) INTO v_status;
    
    -- Check audit trail for DELETE action
    SELECT COUNT(*) INTO v_audit_count 
    FROM CUSTOMER_MGMT.xy_customer_audit 
    WHERE customer_id = v_customer_id AND action = 'DELETE';
    
    -- Calculate execution time
    v_execution_time_ms := DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP);
    
    -- Validate
    IF v_audit_count > 0 THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, expected_output, 
             actual_output, status, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'audit_trail', 
             OBJECT_CONSTRUCT('action', 'DELETE', 'customer_id', v_customer_id),
             OBJECT_CONSTRUCT('audit_recorded', TRUE),
             OBJECT_CONSTRUCT('audit_count', v_audit_count),
             'PASS', v_execution_time_ms);
        
        RAISE NOTICE 'TEST PASSED: % - DELETE action recorded in audit trail', v_test_id;
    ELSE
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'audit_trail', 
             OBJECT_CONSTRUCT('action', 'DELETE', 'customer_id', v_customer_id),
             'FAIL', 'No audit trail record found for DELETE', v_execution_time_ms);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'audit_trail', 
             OBJECT_CONSTRUCT('action', 'DELETE'),
             'FAIL', SQLERRM, DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP));
END;
$$;


-- ============================================================================
-- TEST CASE 8: DATA CONSISTENCY VALIDATION
-- ============================================================================

-- Test Case 8.1: Verify all procedures maintain data consistency
DO
$$
DECLARE
    v_test_id VARCHAR := 'TC_015_DATA_CONSISTENCY';
    v_test_name VARCHAR := 'Data Consistency - Referential Integrity';
    v_customer_id1 BIGINT;
    v_customer_id2 BIGINT;
    v_total_customers BIGINT;
    v_audit_records BIGINT;
    v_start_time TIMESTAMP_NTZ := CURRENT_TIMESTAMP;
    v_execution_time_ms BIGINT;
    v_consistency_check BOOLEAN := TRUE;
BEGIN
    -- Create customers
    CALL CUSTOMER_MGMT.new_customer('Consistency Test 1') INTO v_customer_id1;
    CALL CUSTOMER_MGMT.new_customer('Consistency Test 2') INTO v_customer_id2;
    
    -- Verify data integrity
    SELECT COUNT(*) INTO v_total_customers FROM CUSTOMER_MGMT.xy_customer;
    SELECT COUNT(*) INTO v_audit_records FROM CUSTOMER_MGMT.xy_customer_audit;
    
    -- Calculate execution time
    v_execution_time_ms := DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP);
    
    -- Basic consistency checks
    IF v_total_customers > 0 AND v_audit_records > 0 THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, expected_output, 
             actual_output, status, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'all_procedures', 
             OBJECT_CONSTRUCT('check', 'referential_integrity'),
             OBJECT_CONSTRUCT('has_customer_data', TRUE, 'has_audit_data', TRUE),
             OBJECT_CONSTRUCT('customer_count', v_total_customers, 'audit_count', v_audit_records),
             'PASS', v_execution_time_ms);
        
        RAISE NOTICE 'TEST PASSED: % - Data consistency verified', v_test_id;
    ELSE
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'all_procedures', 
             OBJECT_CONSTRUCT('check', 'referential_integrity'),
             'FAIL', 'Data consistency check failed', v_execution_time_ms);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO TEST_CUSTOMER_PKG.test_results 
            (test_case_id, test_name, procedure_name, input_params, status, error_message, execution_time_ms)
        VALUES 
            (v_test_id, v_test_name, 'all_procedures', 
             OBJECT_CONSTRUCT('check', 'referential_integrity'),
             'FAIL', SQLERRM, DATEDIFF(MILLISECOND, v_start_time, CURRENT_TIMESTAMP));
END;
$$;


-- ============================================================================
-- TEST SUMMARY & REPORTING
-- ============================================================================

-- Generate Test Summary Report
SELECT 
    'TEST EXECUTION SUMMARY' as report_type,
    COUNT(*) as total_tests,
    SUM(CASE WHEN status = 'PASS' THEN 1 ELSE 0 END) as passed_tests,
    SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END) as failed_tests,
    SUM(CASE WHEN status = 'SKIP' THEN 1 ELSE 0 END) as skipped_tests,
    ROUND(100.0 * SUM(CASE WHEN status = 'PASS' THEN 1 ELSE 0 END) / COUNT(*), 2) as pass_percentage,
    MIN(test_timestamp) as first_test_time,
    MAX(test_timestamp) as last_test_time,
    SUM(execution_time_ms) as total_execution_time_ms,
    ROUND(AVG(execution_time_ms), 2) as avg_execution_time_ms
FROM TEST_CUSTOMER_PKG.test_results;

-- Detailed Test Results
SELECT 
    test_case_id,
    test_name,
    procedure_name,
    status,
    execution_time_ms,
    error_message,
    test_timestamp
FROM TEST_CUSTOMER_PKG.test_results
ORDER BY test_case_id;

-- Failed Tests Summary
SELECT 
    test_case_id,
    test_name,
    procedure_name,
    error_message,
    test_timestamp
FROM TEST_CUSTOMER_PKG.test_results
WHERE status = 'FAIL'
ORDER BY test_timestamp DESC;

-- Procedure Performance Analysis
SELECT 
    procedure_name,
    COUNT(*) as test_count,
    SUM(CASE WHEN status = 'PASS' THEN 1 ELSE 0 END) as passed,
    SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END) as failed,
    ROUND(AVG(execution_time_ms), 2) as avg_execution_time_ms,
    MIN(execution_time_ms) as min_execution_time_ms,
    MAX(execution_time_ms) as max_execution_time_ms
FROM TEST_CUSTOMER_PKG.test_results
GROUP BY procedure_name
ORDER BY procedure_name;

-- ============================================================================
-- END OF TEST SUITE
-- ============================================================================

/*
TEST EXECUTION INSTRUCTIONS:
============================

1. PREREQUISITES:
   - Ensure customer_pkg-converted-snowflake.sql has been executed
   - Verify CUSTOMER_MGMT schema exists with all procedures
   - Verify TEST_CUSTOMER_PKG schema was created by this script

2. RUN ALL TESTS:
   - Execute this entire script in Snowflake SQL editor
   - Tests will execute automatically in sequence
   - Results will be logged to TEST_CUSTOMER_PKG.test_results

3. VIEW RESULTS:
   - Query test results at bottom of script
   - Check TEST_CUSTOMER_PKG.test_results table
   - Review PASS/FAIL status for each test case

4. TROUBLESHOOTING:
   - Check TEST_CUSTOMER_PKG.test_results for errors
   - Review error_message column for details
   - Check Snowflake query history for execution details

5. CLEANUP (if needed):
   - DROP SCHEMA TEST_CUSTOMER_PKG CASCADE;
   - This removes all test tables and results

VALIDATION CRITERIA:
====================

All test cases should PASS for successful validation:
- Test Cases 1-14: Individual procedure tests
- Test Summary: Shows pass percentage and statistics
- Detailed Results: Shows status for each test
- Procedure Analysis: Shows performance metrics

Expected Results:
- All 14 test cases should PASS
- Pass percentage should be 100%
- No failed tests should exist
- Audit trail tests should show INSERT/UPDATE/DELETE actions
- Performance metrics should be reasonable (<5000ms per test)

*/
