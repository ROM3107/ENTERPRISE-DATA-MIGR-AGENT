# Snowflake Customer Package - Developer Quick Reference

**Date**: 2026-06-14  
**Package**: customer_pkg (Converted from Oracle to Snowflake)  
**Location**: `CUSTOMER_MGMT` schema  

---

## Table of Contents

1. [Connection Setup](#connection-setup)
2. [Procedure Reference](#procedure-reference)
3. [Code Examples](#code-examples)
4. [Error Handling](#error-handling)
5. [Common Tasks](#common-tasks)
6. [Troubleshooting](#troubleshooting)

---

## Connection Setup

### Connection String

```
Account: <your_snowflake_account>
User: <your_username>
Password: <your_password>
Warehouse: <your_warehouse>
Database: <your_database>
Schema: CUSTOMER_MGMT
```

### Connection Examples

#### Python (snowflake-connector)
```python
import snowflake.connector

conn = snowflake.connector.connect(
    user='your_user',
    password='your_password',
    account='xy12345.us-east-1',
    warehouse='COMPUTE_WH',
    database='CUSTOMERS_DB',
    schema='CUSTOMER_MGMT'
)
cursor = conn.cursor()
```

#### Node.js (snowflake-sdk)
```javascript
const snowflake = require('snowflake-sdk');

const connection = snowflake.createConnection({
    account: 'xy12345.us-east-1',
    user: 'your_user',
    password: 'your_password',
    warehouse: 'COMPUTE_WH',
    database: 'CUSTOMERS_DB',
    schema: 'CUSTOMER_MGMT'
});
```

#### Java (JDBC)
```java
String url = "jdbc:snowflake://xy12345.us-east-1.snowflakecomputing.com";
Properties props = new Properties();
props.setProperty("user", "your_user");
props.setProperty("password", "your_password");
props.setProperty("warehouse", "COMPUTE_WH");
props.setProperty("db", "CUSTOMERS_DB");
props.setProperty("schema", "CUSTOMER_MGMT");

Connection conn = DriverManager.getConnection(url, props);
```

---

## Procedure Reference

### 1. new_customer()

**Purpose**: Create a new customer record and return the generated customer ID.

**Signature**:
```sql
CALL new_customer(p_customer_name VARCHAR) RETURNS BIGINT
```

**Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| p_customer_name | VARCHAR | Customer name (required) |

**Returns**: BIGINT - The newly generated customer_id

**Example**:
```sql
CALL new_customer('John Doe');
-- Returns: 1
```

---

### 2. get_customer()

**Purpose**: Retrieve complete customer record by ID.

**Signature**:
```sql
CALL get_customer(p_customer_id BIGINT) RETURNS TABLE (...)
```

**Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| p_customer_id | BIGINT | Customer ID to retrieve (required) |

**Returns**: TABLE with columns:
- customer_id (BIGINT)
- customer_name (VARCHAR)
- last_active_date (TIMESTAMP_NTZ)
- created_date (TIMESTAMP_NTZ)
- updated_date (TIMESTAMP_NTZ)

**Example**:
```sql
CALL get_customer(1);
-- Returns: 1 row with all customer details
```

---

### 3. get_customer_name()

**Purpose**: Get customer name by ID.

**Signature**:
```sql
CALL get_customer_name(p_customer_id BIGINT) RETURNS TABLE (customer_name VARCHAR)
```

**Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| p_customer_id | BIGINT | Customer ID (required) |

**Returns**: TABLE with column:
- customer_name (VARCHAR)

**Example**:
```sql
CALL get_customer_name(1);
-- Returns: "John Doe"
```

---

### 4. set_customer()

**Purpose**: Update customer name by ID.

**Signature**:
```sql
CALL set_customer(
    p_customer_id BIGINT,
    p_customer_name VARCHAR
) RETURNS VARCHAR
```

**Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| p_customer_id | BIGINT | Customer ID to update (required) |
| p_customer_name | VARCHAR | New customer name (required) |

**Returns**: VARCHAR - Status message with rows affected count

**Example**:
```sql
CALL set_customer(1, 'Jane Doe');
-- Returns: "Customer updated successfully. Rows affected: 1"
```

---

### 5. set_customer_object()

**Purpose**: Update entire customer record from object.

**Signature**:
```sql
CALL set_customer_object(p_row OBJECT) RETURNS VARCHAR
```

**Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| p_row | OBJECT | Customer record object with fields |

**Object Fields**:
```
{
  "customer_id": BIGINT,
  "customer_name": VARCHAR,
  "last_active_date": TIMESTAMP_NTZ,
  "created_date": TIMESTAMP_NTZ,
  "updated_date": TIMESTAMP_NTZ
}
```

**Returns**: VARCHAR - Status message

**Example**:
```sql
CALL set_customer_object(
    OBJECT_CONSTRUCT(
        'customer_id', 1,
        'customer_name', 'Jane Doe',
        'last_active_date', CURRENT_TIMESTAMP
    )
);
-- Returns: "Customer record updated successfully. Rows affected: 1"
```

---

### 6. delete_customer()

**Purpose**: Delete a customer record.

**Signature**:
```sql
CALL delete_customer(p_customer_id BIGINT) RETURNS VARCHAR
```

**Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| p_customer_id | BIGINT | Customer ID to delete (required) |

**Returns**: VARCHAR - Status message with rows deleted count

**Example**:
```sql
CALL delete_customer(1);
-- Returns: "Customer deleted successfully. Rows affected: 1"
```

---

### 7. purge_old_customers()

**Purpose**: Delete customers inactive since a specified date.

**Signature**:
```sql
CALL purge_old_customers(
    p_since_date DATE,
    p_delete_audit_trail BOOLEAN DEFAULT FALSE
) RETURNS OBJECT
```

**Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| p_since_date | DATE | Cutoff date for inactivity (required) |
| p_delete_audit_trail | BOOLEAN | Delete audit trail records (optional, default: FALSE) |

**Returns**: OBJECT with fields:
```json
{
  "rows_deleted": BIGINT,
  "audit_trail_processed": BOOLEAN,
  "purge_status": VARCHAR,
  "execution_timestamp": TIMESTAMP_NTZ
}
```

**Example**:
```sql
CALL purge_old_customers('2020-01-01'::DATE, TRUE);
-- Returns:
-- {
--   "rows_deleted": 150,
--   "audit_trail_processed": true,
--   "purge_status": "Success",
--   "execution_timestamp": "2026-06-14 10:30:45.123"
-- }
```

---

## Code Examples

### Python

#### Create Customer
```python
import snowflake.connector

conn = snowflake.connector.connect(...)
cursor = conn.cursor()

# Create customer
cursor.execute("CALL new_customer('John Doe')")
customer_id = cursor.fetchone()[0]
print(f"Created customer: {customer_id}")
```

#### Get Customer
```python
# Get customer details
cursor.execute("CALL get_customer(1)")
result = cursor.fetchall()
for row in result:
    print(f"ID: {row[0]}, Name: {row[1]}, Created: {row[3]}")
```

#### Update Customer
```python
# Update customer
cursor.execute("CALL set_customer(1, 'Jane Doe')")
status = cursor.fetchone()[0]
print(status)
```

#### Delete Customer
```python
# Delete customer
cursor.execute("CALL delete_customer(1)")
status = cursor.fetchone()[0]
print(status)
```

#### Purge Old Customers
```python
# Purge customers inactive since 2020-01-01
cursor.execute("CALL purge_old_customers('2020-01-01'::DATE, FALSE)")
result = cursor.fetchone()[0]
print(f"Deleted {result['rows_deleted']} customers")
```

---

### Node.js

#### Create Customer
```javascript
const connection = snowflake.createConnection({...});

connection.execute({
    sqlText: "CALL new_customer('John Doe')",
    complete: function(err, stmt, rows) {
        if (err) {
            console.error('Error creating customer:', err);
        } else {
            const customerId = rows[0][0];
            console.log(`Created customer: ${customerId}`);
        }
    }
});
```

#### Get Customer
```javascript
connection.execute({
    sqlText: "CALL get_customer(1)",
    complete: function(err, stmt, rows) {
        if (err) {
            console.error('Error retrieving customer:', err);
        } else {
            rows.forEach(row => {
                console.log(`ID: ${row[0]}, Name: ${row[1]}`);
            });
        }
    }
});
```

---

### Java

#### Create Customer
```java
Statement stmt = connection.createStatement();
try {
    ResultSet rs = stmt.executeQuery("CALL new_customer('John Doe')");
    if (rs.next()) {
        long customerId = rs.getLong(1);
        System.out.println("Created customer: " + customerId);
    }
} finally {
    stmt.close();
}
```

#### Get Customer
```java
Statement stmt = connection.createStatement();
try {
    ResultSet rs = stmt.executeQuery("CALL get_customer(1)");
    while (rs.next()) {
        System.out.println("ID: " + rs.getLong(1) + ", Name: " + rs.getString(2));
    }
} finally {
    stmt.close();
}
```

---

### SQL Direct

#### Create Multiple Customers
```sql
-- Insert directly into table
INSERT INTO CUSTOMER_MGMT.xy_customer (customer_id, customer_name)
SELECT NEXTVAL('CUSTOMER_MGMT.xy_customer_seq'), customer_name
FROM (
    VALUES 
        ('Customer 1'),
        ('Customer 2'),
        ('Customer 3')
) AS new_customers(customer_name);

-- Or use procedure
CALL new_customer('Customer 1');
CALL new_customer('Customer 2');
CALL new_customer('Customer 3');
```

#### Bulk Update
```sql
UPDATE CUSTOMER_MGMT.xy_customer
SET customer_name = CONCAT(customer_name, ' (Updated)')
WHERE created_date < CURRENT_DATE - INTERVAL '90 DAYS';
```

#### Audit Trail Query
```sql
SELECT 
    audit_id,
    customer_id,
    action,
    changed_by,
    change_timestamp
FROM CUSTOMER_MGMT.xy_customer_audit
WHERE change_timestamp >= CURRENT_TIMESTAMP - INTERVAL '24 HOURS'
ORDER BY change_timestamp DESC;
```

---

## Error Handling

### Common Errors & Solutions

#### Error: Customer Not Found

```python
cursor.execute("CALL get_customer(999)")
result = cursor.fetchall()
if not result:
    print("Customer not found")
else:
    print(result[0])
```

#### Error: Invalid Parameter

```python
try:
    cursor.execute("CALL new_customer(NULL)")
except snowflake.connector.errors.ProgrammingError as e:
    print(f"Error: {e}")
```

#### Error: Procedure Execution Failed

```python
try:
    cursor.execute("CALL set_customer('invalid', 'name')")
except snowflake.connector.errors.DatabaseError as e:
    print(f"Database error: {e}")
```

---

## Common Tasks

### Task 1: Create and Retrieve Customer

```python
# Create
cursor.execute("CALL new_customer('John Smith')")
cust_id = cursor.fetchone()[0]

# Retrieve
cursor.execute(f"CALL get_customer({cust_id})")
customer_data = cursor.fetchall()[0]

print(f"Created customer {cust_id}: {customer_data[1]}")
```

### Task 2: Update Customer with Validation

```python
# Check if exists first
cursor.execute("CALL get_customer(1)")
if cursor.fetchall():
    # Update
    cursor.execute("CALL set_customer(1, 'New Name')")
    status = cursor.fetchone()[0]
    print(status)
else:
    print("Customer does not exist")
```

### Task 3: Archive Old Customers

```python
# Purge customers inactive before 2023
cursor.execute("CALL purge_old_customers('2023-01-01'::DATE, FALSE)")
result = cursor.fetchone()[0]

print(f"Purged {result['rows_deleted']} customers")
print(f"Audit trail processed: {result['audit_trail_processed']}")
print(f"Status: {result['purge_status']}")
```

### Task 4: Get Recent Changes from Audit Trail

```sql
SELECT 
    a.customer_id,
    c.customer_name,
    a.action,
    a.old_values,
    a.new_values,
    a.change_timestamp
FROM CUSTOMER_MGMT.xy_customer_audit a
LEFT JOIN CUSTOMER_MGMT.xy_customer c ON a.customer_id = c.customer_id
WHERE a.change_timestamp >= CURRENT_TIMESTAMP - INTERVAL '7 DAYS'
ORDER BY a.change_timestamp DESC;
```

### Task 5: Generate Customer Report

```sql
SELECT 
    customer_id,
    customer_name,
    created_date,
    last_active_date,
    DATEDIFF(DAY, last_active_date, CURRENT_DATE) as days_inactive
FROM CUSTOMER_MGMT.xy_customer
WHERE last_active_date IS NOT NULL
ORDER BY last_active_date DESC;
```

---

## Troubleshooting

### Issue: Procedure Not Found

```
Error: (001003): SQL compilation error: Object 'CUSTOMER_MGMT.NEW_CUSTOMER' does not exist or not authorized.
```

**Solution**:
```sql
-- Verify procedure exists
SHOW PROCEDURES IN SCHEMA CUSTOMER_MGMT;

-- If missing, re-execute the conversion SQL file
-- Verify schema is set correctly in connection
```

### Issue: Permission Denied

```
Error: (002003): SQL compilation error: Cannot execute procedure 'CUSTOMER_MGMT.NEW_CUSTOMER'
```

**Solution**:
```sql
-- Grant execution permission
GRANT EXECUTE ON PROCEDURE CUSTOMER_MGMT.new_customer(VARCHAR) TO ROLE your_role;
```

### Issue: Parameter Type Mismatch

```
Error: (002406): Numeric value '-1' is not recognized
```

**Solution**: Ensure parameter types match:
```python
# Correct
cursor.execute(f"CALL get_customer({int(customer_id)})")

# Incorrect
cursor.execute(f"CALL get_customer('{customer_id}')")
```

### Issue: Timeout on Large Operations

**Solution**:
```sql
-- Adjust session timeout
ALTER SESSION SET STATEMENT_TIMEOUT_IN_SECONDS = 600;

-- Increase warehouse size
ALTER WAREHOUSE COMPUTE_WH SET WAREHOUSE_SIZE = 'MEDIUM';

-- Execute operation
CALL purge_old_customers('2020-01-01'::DATE, FALSE);
```

### Issue: Sequence Out of Sync

```sql
-- Check current value
SHOW SEQUENCES LIKE '%xy_customer_seq%';

-- Reset if needed
ALTER SEQUENCE CUSTOMER_MGMT.xy_customer_seq SET INCREMENT = 1;

-- Manually set to max ID + 1
ALTER SEQUENCE CUSTOMER_MGMT.xy_customer_seq SET START = (
    SELECT MAX(customer_id) + 1 FROM CUSTOMER_MGMT.xy_customer
);
```

---

## Performance Tips

1. **Use Indexes**: The converted package includes indexes on common query columns
   ```sql
   -- Check indexes
   SHOW INDEXES IN TABLE CUSTOMER_MGMT.xy_customer;
   ```

2. **Batch Operations**: For multiple inserts, use batch mode
   ```python
   cursor.execute("ALTER SESSION SET USE_CACHED_RESULT = FALSE")
   for customer_name in customer_list:
       cursor.execute(f"CALL new_customer('{customer_name}')")
   ```

3. **Monitor Query Performance**: Use EXPLAIN
   ```sql
   EXPLAIN PLAN FOR CALL get_customer(1);
   ```

4. **Optimize Warehouse**: Right-size your warehouse for workload
   ```sql
   SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
   WHERE START_TIME >= CURRENT_TIMESTAMP - INTERVAL '7 DAYS'
   LIMIT 100;
   ```

---

## Migration from Oracle

If transitioning from Oracle:

1. **Connection String Change**:
   ```
   Oracle: user/password@tnsname
   Snowflake: account/user/password/warehouse/database/schema
   ```

2. **Procedure Call Change**:
   ```sql
   -- Oracle
   EXEC customer_pkg.new_customer('John Doe');
   
   -- Snowflake
   CALL new_customer('John Doe');
   ```

3. **Result Handling Change**:
   ```python
   # Oracle: Result variable from procedure
   # Snowflake: Result set from RETURNS clause
   cursor.execute("CALL get_customer(1)")
   result = cursor.fetchall()  # Fetch results
   ```

---

## FAQ

**Q: Can I use the procedures in views?**
A: No, Snowflake procedures cannot be used directly in views. Use them in applications or stored procedures only.

**Q: Do the procedures support transactions?**
A: Yes, each procedure executes within a transaction. Set autocommit mode appropriately.

**Q: How do I handle NULL values?**
A: Use `COALESCE()` or conditional logic in procedures. NULL returns typically indicate "not found".

**Q: Can I add new procedures?**
A: Yes, use `CREATE OR REPLACE PROCEDURE` with the same naming convention.

**Q: What's the performance difference from Oracle?**
A: Snowflake is optimized for analytics. CRUD operations are comparable or faster due to columnar storage.

---

## Additional Resources

- [Snowflake SQL Reference](https://docs.snowflake.com/en/sql-reference.html)
- [Snowflake Procedures Guide](https://docs.snowflake.com/en/sql-reference/sql/create-procedure.html)
- [Snowflake Best Practices](https://docs.snowflake.com/en/user-guide/best-practices.html)
- [Snowflake Drivers](https://docs.snowflake.com/en/user-guide/drivers.html)

---

**Document Version**: 1.0  
**Last Updated**: 2026-06-14  
**Status**: Ready for Use
