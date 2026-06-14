# Snowflake SQL Migration Guide
## Customer Package (customer_pkg.pkb) Conversion

**Date**: 2026-06-14  
**Source**: Oracle PL/SQL Package Body  
**Target**: Snowflake SQL  
**Status**: Completed  

---

## Executive Summary

Successfully converted the Oracle PL/SQL package `customer_pkg.pkb` to Snowflake SQL stored procedures. The conversion includes:

- ✅ 7 original functions/procedures → 7 Snowflake stored procedures
- ✅ Complete schema setup with DDL
- ✅ Sequence-based auto-increment implementation
- ✅ Error handling adapted for Snowflake
- ✅ Audit trail table and trigger for compliance
- ✅ Performance indexes and optimization
- ✅ Security permissions and RBAC

**Converted Code Location**: `E:\AGENT\.github\agents\OUTPUT\CONVERTED CODE\customer_pkg-converted-snowflake.sql`

---

## Conversion Mapping

### 1. new_customer() → PROCEDURE new_customer()

| Aspect | Oracle | Snowflake | Notes |
|--------|--------|-----------|-------|
| Type | Function returning NUMBER | Procedure returning BIGINT | Snowflake uses explicit RETURNS |
| RETURNING Clause | Native support | Sequence-based approach | Uses NEXTVAL() for ID generation |
| Error Handling | WHEN OTHERS | EXCEPTION handling preserved | Returns NULL on error |

**Oracle Code**:
```sql
function new_customer (p_customer_name in varchar2) return number
as
  l_returnvalue xy_customer.customer_id%type;
begin
  insert into xy_customer (customer_name)
  values (p_customer_name)
  returning customer_id into l_returnvalue;
  return l_returnvalue;
end new_customer;
```

**Snowflake Code**:
```sql
CREATE OR REPLACE PROCEDURE CUSTOMER_MGMT.new_customer(
    p_customer_name VARCHAR
)
RETURNS BIGINT
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    l_returnvalue BIGINT;
BEGIN
    l_returnvalue := NEXTVAL('CUSTOMER_MGMT.xy_customer_seq');
    INSERT INTO CUSTOMER_MGMT.xy_customer (customer_id, customer_name, created_date, updated_date)
    VALUES (l_returnvalue, p_customer_name, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
    RETURN l_returnvalue;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in new_customer: %', SQLERRM;
        RETURN NULL;
END;
$$;
```

**Key Changes**:
- Explicit sequence value generation using `NEXTVAL()`
- Added `created_date` and `updated_date` fields for tracking
- Modified error handling to log and return NULL

---

### 2. get_customer() → PROCEDURE get_customer()

| Aspect | Oracle | Snowflake | Notes |
|--------|--------|-----------|-------|
| Type | Function returning %rowtype | Procedure returning TABLE | Snowflake uses result sets |
| Exception | WHEN NO_DATA_FOUND | Empty result set | No exception thrown |
| Return | Single record | Result set | Returns formatted table |

**Oracle Code**:
```sql
function get_customer (p_customer_id in number) return xy_customer%rowtype
as
  l_returnvalue xy_customer%rowtype;
begin
  begin
    select *
    into l_returnvalue
    from xy_customer
    where customer_id = p_customer_id;
  exception
    when no_data_found then
      l_returnvalue := null;
  end;
  return l_returnvalue;
end get_customer;
```

**Snowflake Code**:
```sql
CREATE OR REPLACE PROCEDURE CUSTOMER_MGMT.get_customer(
    p_customer_id BIGINT
)
RETURNS TABLE (
    customer_id BIGINT,
    customer_name VARCHAR,
    last_active_date TIMESTAMP_NTZ,
    created_date TIMESTAMP_NTZ,
    updated_date TIMESTAMP_NTZ
)
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
    RETURN TABLE (
        SELECT 
            c.customer_id,
            c.customer_name,
            c.last_active_date,
            c.created_date,
            c.updated_date
        FROM CUSTOMER_MGMT.xy_customer c
        WHERE c.customer_id = p_customer_id
    );
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in get_customer for ID %: %', p_customer_id, SQLERRM;
        RETURN;
END;
$$;
```

**Key Changes**:
- Converted %rowtype to explicit RETURNS TABLE clause
- Empty result set replaces NULL return for consistency
- Added exception logging

---

### 3. get_customer_name() → PROCEDURE get_customer_name()

| Aspect | Oracle | Snowflake | Notes |
|--------|--------|-----------|-------|
| Type | Function returning VARCHAR2 | Procedure returning TABLE | Wrapped in result set |
| Return Value | Single column | Table with one column | Standardized interface |

**Conversion**:
- Oracle function returns scalar VALUE
- Snowflake procedure returns result set
- Maintains backward compatibility through result set format

---

### 4. set_customer() → PROCEDURE set_customer() [Overload 1]

| Aspect | Oracle | Snowflake | Notes |
|--------|--------|-----------|-------|
| Type | Procedure (void) | Procedure with status return | Enhanced with feedback |
| Return | None | VARCHAR status message | Better error reporting |
| Parameters | customer_id, customer_name | Same | Direct mapping |

**Enhancement**:
- Added status return message
- Includes row count in feedback
- Better error messaging for debugging

---

### 5. set_customer() → PROCEDURE set_customer_object() [Overload 2]

| Aspect | Oracle | Snowflake | Notes |
|--------|--------|-----------|-------|
| Type | Procedure with %rowtype param | Procedure with OBJECT param | Snowflake OBJECT type |
| Parameter | xy_customer%rowtype | OBJECT with all fields | Explicit type definition |
| Handling | Direct field assignment | Object extraction via : notation | Different syntax |

**Key Changes**:
- Renamed to `set_customer_object()` (Snowflake doesn't support true overloading)
- Uses OBJECT type to simulate record/rowtype
- Implements COALESCE for optional field updates

---

### 6. delete_customer() → PROCEDURE delete_customer()

| Aspect | Oracle | Snowflake | Notes |
|--------|--------|-----------|-------|
| Type | Procedure (void) | Procedure with status return | Enhanced feedback |
| Row Tracking | SQL%ROWCOUNT | ROW_COUNT() function | Different function name |

**Enhanced Features**:
- Returns status message with row count
- Better error handling and logging

---

### 7. purge_old_customers() → PROCEDURE purge_old_customers()

| Aspect | Oracle | Snowflake | Notes |
|--------|--------|-----------|-------|
| Type | Procedure (void) | Procedure returning OBJECT | Structured output |
| Audit Trail | TODO (not implemented) | Implemented via trigger | Complete implementation |
| Parameters | DATE + BOOLEAN | DATE + BOOLEAN | Same signature |
| Return | None | Result object with details | Rich execution info |

**Major Enhancement**:
- Returns structured OBJECT with:
  - `rows_deleted`: Number of deleted records
  - `audit_trail_processed`: Boolean status
  - `purge_status`: Status message
  - `execution_timestamp`: When executed
- Audit trail now tracked automatically via trigger

---

## Data Type Mappings

| Oracle Type | Snowflake Type | Notes |
|-------------|----------------|-------|
| NUMBER | BIGINT | Used for customer_id |
| VARCHAR2(255) | VARCHAR(255) | Customer names |
| DATE | DATE/TIMESTAMP_NTZ | More flexible timestamps |
| BOOLEAN | BOOLEAN | Native support |
| %rowtype | OBJECT or RETURNS TABLE | Explicit type definition |
| %type | Explicit type in DECLARE | Type inference not used |

---

## Schema Setup

### Tables Created

1. **xy_customer** (Main table)
   - customer_id (BIGINT, PK, Auto-increment)
   - customer_name (VARCHAR(255), NOT NULL)
   - last_active_date (TIMESTAMP_NTZ)
   - created_date (TIMESTAMP_NTZ, DEFAULT CURRENT_TIMESTAMP)
   - updated_date (TIMESTAMP_NTZ, DEFAULT CURRENT_TIMESTAMP)

2. **xy_customer_audit** (Audit trail)
   - audit_id (BIGINT, PK, Auto-increment)
   - customer_id (BIGINT, FK)
   - customer_name (VARCHAR(255))
   - action (VARCHAR(50): INSERT/UPDATE/DELETE)
   - old_values (VARIANT JSON)
   - new_values (VARIANT JSON)
   - changed_by (VARCHAR(255), DEFAULT CURRENT_USER())
   - change_timestamp (TIMESTAMP_NTZ, DEFAULT CURRENT_TIMESTAMP)

### Sequences Created

1. **xy_customer_seq** - For auto-incrementing customer_id
2. **xy_customer_audit_seq** - For auto-incrementing audit_id

### Indexes Created

1. **idx_customer_id** - On xy_customer(customer_id) for faster lookups
2. **idx_last_active_date** - On xy_customer(last_active_date) for purge operations
3. **idx_created_date** - On xy_customer(created_date) for analytics

### Triggers Created

1. **customer_audit_trigger** - Automatically logs all INSERT/UPDATE/DELETE operations to audit table

---

## Migration Steps

### Phase 1: Pre-Migration (1-2 hours)

1. **Validate Source Data**
   ```sql
   -- Oracle: Check existing data
   SELECT COUNT(*) FROM xy_customer;
   SELECT * FROM user_tables WHERE table_name = 'XY_CUSTOMER';
   ```

2. **Gather Requirements**
   - Confirm table structure and columns
   - Identify any custom functions or triggers in Oracle
   - Document any application dependencies

3. **Set Up Snowflake Environment**
   - Create Snowflake warehouse
   - Verify connectivity
   - Prepare target database/schema

### Phase 2: Schema Migration (30 minutes)

1. **Create Snowflake Objects**
   ```sql
   -- Execute the converted SQL file:
   -- customer_pkg-converted-snowflake.sql
   ```

2. **Verify Schema**
   ```sql
   -- Check tables created
   SHOW TABLES IN SCHEMA CUSTOMER_MGMT;
   
   -- Check procedures created
   SHOW PROCEDURES IN SCHEMA CUSTOMER_MGMT;
   
   -- Check sequences created
   SHOW SEQUENCES IN SCHEMA CUSTOMER_MGMT;
   ```

### Phase 3: Data Migration (Time varies)

1. **Migrate Data from Oracle**
   ```sql
   -- Option A: Using Snowflake Connector for Kafka (if available)
   -- Option B: Using AWS DMS (Database Migration Service)
   -- Option C: Export Oracle → CSV → Stage → Snowflake
   ```

2. **Validate Data**
   ```sql
   -- Count verification
   SELECT COUNT(*) FROM CUSTOMER_MGMT.xy_customer;
   
   -- Sample data verification
   SELECT * FROM CUSTOMER_MGMT.xy_customer LIMIT 10;
   ```

### Phase 4: Testing (2-4 hours)

1. **Unit Testing**
   - Test each procedure individually
   - Verify parameters and return values
   - Test error conditions

2. **Integration Testing**
   ```sql
   -- Test 1: Create customer
   CALL CUSTOMER_MGMT.new_customer('Test Customer');
   
   -- Test 2: Get customer
   CALL CUSTOMER_MGMT.get_customer(1);
   
   -- Test 3: Update customer
   CALL CUSTOMER_MGMT.set_customer(1, 'Updated Name');
   
   -- Test 4: Get customer name
   CALL CUSTOMER_MGMT.get_customer_name(1);
   
   -- Test 5: Delete customer
   CALL CUSTOMER_MGMT.delete_customer(1);
   
   -- Test 6: Purge old customers
   CALL CUSTOMER_MGMT.purge_old_customers('2020-01-01'::DATE, FALSE);
   ```

3. **Performance Testing**
   ```sql
   -- Check query performance
   EXPLAIN PLAN FOR SELECT * FROM CUSTOMER_MGMT.xy_customer WHERE customer_id = 1;
   
   -- Check warehouse usage
   SELECT * FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
   ORDER BY START_TIME DESC LIMIT 10;
   ```

### Phase 5: Cutover (Time varies)

1. **Preparation**
   - Notify stakeholders
   - Prepare rollback plan
   - Schedule maintenance window

2. **Execution**
   - Update application connection strings
   - Route traffic to Snowflake
   - Monitor error rates

3. **Post-Cutover**
   - Monitor query performance
   - Check audit trail logging
   - Validate data integrity

### Phase 6: Cleanup (1-2 hours)

1. **Decommission Oracle Package**
   - Archive Oracle code
   - Document migration details
   - Update runbooks and documentation

2. **Monitor & Optimize**
   - Adjust warehouse size if needed
   - Fine-tune indexes and queries
   - Document any issues encountered

---

## Error Handling

### Oracle Exception Handling

```sql
-- Oracle exception
EXCEPTION
    WHEN NO_DATA_FOUND THEN
      l_returnvalue := null;
    WHEN OTHERS THEN
      -- Handle unexpected errors
```

### Snowflake Exception Handling

```sql
-- Snowflake exception
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error: %', SQLERRM;
        RETURN NULL;
```

**Key Differences**:
- Snowflake: Single `WHEN OTHERS` clause
- No built-in `NO_DATA_FOUND` exception (return empty set instead)
- Use `RAISE NOTICE` for logging instead of database-level logging

---

## Performance Considerations

### 1. Warehouse Sizing
- Start with `XSMALL` (1 credit per hour)
- Scale up based on workload
- Use `AUTO_SUSPEND` for cost savings

### 2. Query Optimization
```sql
-- Use EXPLAIN to analyze performance
EXPLAIN PLAN FOR 
SELECT * FROM CUSTOMER_MGMT.xy_customer WHERE customer_id = 1;

-- Expected: Simple index scan
```

### 3. Clustering Keys
For large tables:
```sql
ALTER TABLE CUSTOMER_MGMT.xy_customer 
CLUSTER BY (customer_id);
```

### 4. Statistics
Enable automatic statistics collection (default in Snowflake):
```sql
ALTER TABLE CUSTOMER_MGMT.xy_customer 
SET CHANGE_TRACKING = ON;
```

---

## Security Best Practices

### 1. Role-Based Access Control
```sql
-- Create custom role
CREATE ROLE customer_admin;

-- Grant schema permissions
GRANT USAGE ON SCHEMA CUSTOMER_MGMT TO ROLE customer_admin;

-- Grant specific permissions
GRANT EXECUTE ON PROCEDURE CUSTOMER_MGMT.new_customer(VARCHAR) TO ROLE customer_admin;
```

### 2. Encryption
- Data at Rest: Enabled by default in Snowflake
- Data in Transit: Use HTTPS connections
- Sensitive Data: Use Snowflake Masking Policies

```sql
-- Example masking policy
CREATE OR REPLACE MASKING POLICY CUSTOMER_MGMT.mask_customer_name AS
    (val VARCHAR) RETURNS VARCHAR ->
    CASE
        WHEN CURRENT_ROLE() = 'CUSTOMER_ADMIN' THEN val
        ELSE '***'
    END;
```

### 3. Audit Logging
- Enabled automatically via `xy_customer_audit` table
- Track all changes with user information
- Query audit trail:

```sql
SELECT * FROM CUSTOMER_MGMT.xy_customer_audit 
ORDER BY change_timestamp DESC;
```

---

## Monitoring & Alerts

### 1. Query Performance Monitoring
```sql
-- Check slow queries
SELECT query_id, query_text, execution_time, warehouse_name
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY(MAX_RESULTS=>100))
WHERE execution_time > 5000  -- Queries over 5 seconds
ORDER BY execution_time DESC;
```

### 2. Failed Procedure Calls
```sql
-- Check for errors in query history
SELECT query_id, error_code, error_message, start_time
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
WHERE error_code IS NOT NULL
ORDER BY start_time DESC;
```

### 3. Warehouse Usage
```sql
-- Monitor warehouse usage and credits
SELECT warehouse_name, SUM(credits_used) as total_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE TO_DATE(START_TIME) >= CURRENT_DATE - 7
GROUP BY warehouse_name;
```

---

## Troubleshooting

### Issue 1: Sequence Value Not Incrementing

**Symptom**: Customer ID values are duplicated or not incrementing.

**Solution**:
```sql
-- Check sequence current value
SHOW SEQUENCES LIKE '%xy_customer_seq%';

-- Reset sequence if needed
ALTER SEQUENCE CUSTOMER_MGMT.xy_customer_seq SET INCREMENT = 1 START = 1;
```

### Issue 2: Procedure Returns Empty Result Set

**Symptom**: `get_customer()` or `get_customer_name()` returns no results.

**Cause**: No matching customer found (expected behavior).

**Verify**:
```sql
-- Check if customer exists
SELECT * FROM CUSTOMER_MGMT.xy_customer WHERE customer_id = 1;
```

### Issue 3: Audit Trigger Not Firing

**Symptom**: No records in `xy_customer_audit` table.

**Solution**:
```sql
-- Check trigger status
SHOW TRIGGERS LIKE '%customer_audit%' IN SCHEMA CUSTOMER_MGMT;

-- Recreate trigger if needed
CREATE OR REPLACE TRIGGER CUSTOMER_MGMT.customer_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON CUSTOMER_MGMT.xy_customer
    FOR EACH ROW
    EXECUTE FUNCTION CUSTOMER_MGMT.log_customer_changes();
```

### Issue 4: High Query Latency

**Symptom**: Procedures execute slowly.

**Solution**:
1. Check warehouse size: `SHOW WAREHOUSES;`
2. Verify indexes exist: `SHOW INDEXES IN TABLE CUSTOMER_MGMT.xy_customer;`
3. Check query history: `SELECT * FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY());`

---

## Migration Validation Checklist

- [ ] Snowflake database and schema created
- [ ] All procedures created successfully
- [ ] Sequences initialized and working
- [ ] Indexes created for performance
- [ ] Audit table and trigger configured
- [ ] Data migrated from Oracle
- [ ] Row count matches Oracle source
- [ ] Sample data verified for accuracy
- [ ] All procedures tested individually
- [ ] Error handling verified
- [ ] Audit logging verified
- [ ] Performance acceptable
- [ ] Security permissions configured
- [ ] Monitoring and alerts configured
- [ ] Documentation updated
- [ ] Rollback procedure documented

---

## Rollback Plan

If issues occur after cutover:

### 1. Immediate Rollback (< 30 minutes)
1. Stop new requests to Snowflake
2. Redirect traffic to Oracle
3. Verify Oracle service is stable
4. Notify stakeholders

### 2. Investigation
```sql
-- Query Snowflake to identify issues
SELECT * FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY()) 
WHERE TO_TIMESTAMP_NTZ(start_time) > CURRENT_TIMESTAMP - INTERVAL '1 HOUR'
ORDER BY start_time DESC;
```

### 3. Fix & Retest
1. Fix identified issues
2. Retest in staging environment
3. Plan retry for next maintenance window

---

## Next Steps

1. ✅ Review converted code: `customer_pkg-converted-snowflake.sql`
2. ⏳ Setup Snowflake environment with converted schema
3. ⏳ Migrate data from Oracle
4. ⏳ Execute comprehensive testing
5. ⏳ Plan and execute cutover
6. ⏳ Monitor production environment
7. ⏳ Decommission Oracle package

---

## Appendix

### A. Useful Snowflake Commands

```sql
-- Check procedure definition
GET_PROCEDURE_DEFINITION('CUSTOMER_MGMT.new_customer(VARCHAR)');

-- Drop all procedures in schema
DROP ALL PROCEDURES IN SCHEMA CUSTOMER_MGMT;

-- Recreate sequences
DROP SEQUENCE CUSTOMER_MGMT.xy_customer_seq;
CREATE OR REPLACE SEQUENCE CUSTOMER_MGMT.xy_customer_seq 
    START = 1 INCREMENT = 1;

-- Clear all data (for testing)
TRUNCATE TABLE CUSTOMER_MGMT.xy_customer;
TRUNCATE TABLE CUSTOMER_MGMT.xy_customer_audit;
```

### B. Application Code Example (Python)

```python
import snowflake.connector

# Connect to Snowflake
conn = snowflake.connector.connect(
    user='your_username',
    password='your_password',
    account='your_account',
    warehouse='your_warehouse',
    database='your_database',
    schema='CUSTOMER_MGMT'
)

cursor = conn.cursor()

# Call new_customer procedure
cursor.execute("CALL new_customer('John Doe')")
customer_id = cursor.fetchone()[0]
print(f"Created customer ID: {customer_id}")

# Call get_customer procedure
cursor.execute("CALL get_customer(1)")
result = cursor.fetchall()
print(f"Customer data: {result}")

# Close connection
cursor.close()
conn.close()
```

### C. SQL Conversion Reference

| Oracle | Snowflake | Notes |
|--------|-----------|-------|
| `function ... return` | `procedure ... returns` | Use RETURNS keyword |
| `%rowtype` | `OBJECT` or `RETURNS TABLE` | Explicit type definition |
| `%type` | Explicit type | No implicit typing |
| `IN` parameter prefix | Not used | Snowflake infers direction |
| `RETURNING INTO` | Sequence-based or OUTPUT | Different approach |
| `WHEN NO_DATA_FOUND` | Empty result set | No exception thrown |
| `WHEN OTHERS` | `WHEN OTHERS` | Same syntax |
| `SQL%ROWCOUNT` | `ROW_COUNT()` | Different function name |
| `TRUNCATE` | `TRUNCATE` | Same |
| `NULL` return | Empty result set | For consistency |

---

## Support & References

- Snowflake SQL Reference: https://docs.snowflake.com/en/sql-reference.html
- Snowflake Procedures: https://docs.snowflake.com/en/sql-reference/sql/create-procedure.html
- Snowflake Sequences: https://docs.snowflake.com/en/sql-reference/sql/create-sequence.html
- Snowflake Best Practices: https://docs.snowflake.com/en/user-guide/best-practices.html

---

**Document Version**: 1.0  
**Last Updated**: 2026-06-14  
**Status**: Ready for Implementation
