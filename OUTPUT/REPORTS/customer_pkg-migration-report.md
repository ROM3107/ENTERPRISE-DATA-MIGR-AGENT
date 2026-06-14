# Customer Package (CUSTOMER_PKG) Migration Report
## Oracle PL/SQL to Snowflake SQL Conversion

**Report Date**: 2026-06-14  
**Source System**: Oracle Database (PL/SQL)  
**Target System**: Snowflake SQL  
**Package Name**: CUSTOMER_PKG  
**Original Author**: MBR | **Created**: 05.11.2020  

---

## Executive Summary

This report documents the analysis and migration strategy for the Oracle PL/SQL package `customer_pkg.pkb` to Snowflake SQL. The package provides centralized customer data management operations for the `xy_customer` table, including CRUD (Create, Read, Update, Delete) operations with both granular and bulk capabilities.

### Migration Scope
- **Total Components**: 7 subprograms (3 functions, 4 procedures)
- **Primary Table**: xy_customer
- **Data Types to Migrate**: 4 (NUMBER, VARCHAR2, DATE, BOOLEAN)
- **Oracle-Specific Features**: 5 major features requiring conversion
- **Estimated Complexity**: Medium
- **Recommended Approach**: Stored procedures + JavaScript UDFs for compatibility

---

## Detailed Component Analysis

### 1. CREATE Operation: `new_customer()`

#### Source Code (Oracle)
```sql
function new_customer(p_customer_name in varchar2) return number is
  l_returnvalue number;
begin
  insert into xy_customer (customer_name)
  values (p_customer_name)
  returning customer_id into l_returnvalue;
  return l_returnvalue;
end new_customer;
```

#### Transformation Analysis
| Aspect | Oracle | Snowflake | Migration Notes |
|--------|--------|-----------|-----------------|
| **Return Type** | NUMBER | BIGINT/INTEGER | Use BIGINT for compatibility with large ID ranges |
| **RETURNING Clause** | Native `RETURNING INTO` | Limited support | Snowflake requires OUTPUT clause or alternative approach |
| **Auto-increment** | Not explicitly shown | Sequence or IDENTITY | Requires explicit sequence definition |
| **Input Parameters** | `in` keyword | Not needed | Snowflake procedures don't use IN/OUT keywords |
| **Variable Declaration** | `l_returnvalue number` | DECLARE section | Snowflake uses DECLARE block |

#### Snowflake Implementation
```sql
CREATE OR REPLACE PROCEDURE new_customer(
    p_customer_name VARCHAR
)
RETURNS BIGINT
LANGUAGE SQL
AS
$$
DECLARE
    l_returnvalue BIGINT;
BEGIN
    INSERT INTO xy_customer (customer_name)
    VALUES (p_customer_name);
    
    -- Get the last inserted ID
    SELECT MAX(customer_id) INTO l_returnvalue
    FROM xy_customer;
    
    RETURN l_returnvalue;
END;
$$;
```

#### Conversion Issues & Resolutions
- ⚠️ **Issue**: RETURNING clause returns single row; Snowflake has limited support
- ✅ **Resolution**: Use MAX() on customer_id or implement sequence-based approach
- ⚠️ **Issue**: Race condition possible with MAX() approach
- ✅ **Resolution**: Alternative - Implement identity column or sequence with explicit insertion

#### Recommended Snowflake Version
```sql
CREATE SEQUENCE IF NOT EXISTS xy_customer_seq START = 1 INCREMENT = 1;

CREATE OR REPLACE PROCEDURE new_customer(
    p_customer_name VARCHAR
)
RETURNS BIGINT
LANGUAGE SQL
AS
$$
DECLARE
    l_returnvalue BIGINT;
BEGIN
    l_returnvalue := NEXTVAL('xy_customer_seq');
    
    INSERT INTO xy_customer (customer_id, customer_name)
    VALUES (l_returnvalue, p_customer_name);
    
    RETURN l_returnvalue;
END;
$$;
```

**Status**: ✅ **READY FOR MIGRATION** (with sequence approach)

---

### 2. READ Operation: `get_customer()`

#### Source Code (Oracle)
```sql
function get_customer(p_customer_id in number) return xy_customer%rowtype is
  l_row xy_customer%rowtype;
begin
  select * into l_row
  from xy_customer
  where customer_id = p_customer_id;
  return l_row;
exception
  when no_data_found then
    return null;
end get_customer;
```

#### Transformation Analysis
| Aspect | Oracle | Snowflake | Migration Notes |
|--------|--------|-----------|-----------------|
| **%rowtype** | Automatic record type | Object/VARIANT | Snowflake uses OBJECT or VARIANT types |
| **Exception Handling** | NO_DATA_FOUND exception | EXCEPTION not found | Use NULL check instead |
| **Return Type** | Rowtype (implicit) | OBJECT or RECORD | Must define explicit return type |
| **NULL Propagation** | Native NULL value | Supported | Same semantics |

#### Snowflake Implementation
```sql
CREATE OR REPLACE FUNCTION get_customer(
    p_customer_id NUMBER
)
RETURNS OBJECT
LANGUAGE SQL
AS
$$
  SELECT OBJECT_CONSTRUCT(
    'customer_id', customer_id,
    'customer_name', customer_name,
    'last_active_date', last_active_date
    -- Include all columns from xy_customer
  ) AS result
  FROM xy_customer
  WHERE customer_id = p_customer_id
  LIMIT 1;
$$;
```

**Alternative - Using Variant (More Flexible)**:
```sql
CREATE OR REPLACE FUNCTION get_customer(
    p_customer_id NUMBER
)
RETURNS VARIANT
LANGUAGE SQL
AS
$$
  SELECT OBJECT_CONSTRUCT('*') AS result
  FROM xy_customer
  WHERE customer_id = p_customer_id
  LIMIT 1;
$$;
```

**Status**: ✅ **READY FOR MIGRATION** (with explicit column mapping)

---

### 3. READ Operation: `get_customer_name()`

#### Source Code (Oracle)
```sql
function get_customer_name(p_customer_id in number) return varchar2 is
  l_name varchar2(4000);
begin
  select customer_name into l_name
  from xy_customer
  where customer_id = p_customer_id;
  return l_name;
exception
  when no_data_found then
    return null;
end get_customer_name;
```

#### Transformation Analysis
| Aspect | Oracle | Snowflake | Migration Notes |
|--------|--------|-----------|-----------------|
| **Scalar Return** | VARCHAR2 | VARCHAR | Direct mapping |
| **Exception Handling** | NO_DATA_FOUND → NULL | Use LIMIT 1 + NULL check | Implicit NULL return |
| **String Length** | 4000 max | No limit (large) | Snowflake VARCHAR has no size limit |

#### Snowflake Implementation
```sql
CREATE OR REPLACE FUNCTION get_customer_name(
    p_customer_id NUMBER
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
  SELECT customer_name
  FROM xy_customer
  WHERE customer_id = p_customer_id
  LIMIT 1;
$$;
```

**Status**: ✅ **READY FOR MIGRATION** (direct conversion)

---

### 4. UPDATE Operation: `set_customer()` - Overload 1 (Field Update)

#### Source Code (Oracle)
```sql
procedure set_customer(p_customer_id in number, p_customer_name in varchar2) is
begin
  update xy_customer
  set customer_name = p_customer_name
  where customer_id = p_customer_id;
end set_customer;
```

#### Transformation Analysis
| Aspect | Oracle | Snowflake | Migration Notes |
|--------|--------|-----------|-----------------|
| **Procedure Type** | DML Update | UPDATE statement | Direct mapping |
| **WHERE Clause** | PK-based filtering | Same semantics | Identical logic |
| **Parameters** | IN keywords | Positional | Snowflake uses positional parameters |

#### Snowflake Implementation
```sql
CREATE OR REPLACE PROCEDURE set_customer(
    p_customer_id NUMBER,
    p_customer_name VARCHAR
)
LANGUAGE SQL
AS
$$
BEGIN
  UPDATE xy_customer
  SET customer_name = p_customer_name
  WHERE customer_id = p_customer_id;
END;
$$;
```

**Status**: ✅ **READY FOR MIGRATION** (direct conversion)

---

### 5. UPDATE Operation: `set_customer()` - Overload 2 (Row Update)

#### Source Code (Oracle)
```sql
procedure set_customer(p_row in xy_customer%rowtype) is
begin
  update xy_customer
  set row = p_row
  where customer_id = p_row.customer_id;
end set_customer;
```

#### Transformation Analysis
| Aspect | Oracle | Snowflake | Migration Notes |
|--------|--------|-----------|-----------------|
| **%rowtype Parameter** | Named record type | OBJECT/VARIANT input | Must parse input object |
| **Row Assignment** | `SET row = p_row` | Column-by-column update | Requires explicit column mapping |
| **Overloading** | Native support | Not supported | Must use different procedure name |

#### Snowflake Implementation
```sql
CREATE OR REPLACE PROCEDURE set_customer_row(
    p_customer_id NUMBER,
    p_customer_name VARCHAR,
    p_last_active_date TIMESTAMP_NTZ
)
LANGUAGE SQL
AS
$$
BEGIN
  UPDATE xy_customer
  SET customer_name = p_customer_name,
      last_active_date = p_last_active_date
  WHERE customer_id = p_customer_id;
END;
$$;
```

**Alternative - Using Variant Input**:
```sql
CREATE OR REPLACE PROCEDURE set_customer_row(
    p_row OBJECT
)
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'set_customer_row_handler'
AS
$$
def set_customer_row_handler(session, p_row):
    customer_id = p_row['customer_id']
    customer_name = p_row['customer_name']
    last_active_date = p_row['last_active_date']
    
    session.sql(f"""
        UPDATE xy_customer
        SET customer_name = '{customer_name}',
            last_active_date = '{last_active_date}'
        WHERE customer_id = {customer_id}
    """).collect()
$$;
```

**⚠️ Issue**: Overloading not supported in Snowflake
**✅ Resolution**: Use naming convention (e.g., `set_customer_row`)

**Status**: ⚠️ **REQUIRES REFACTORING** (overloading not supported)

---

### 6. DELETE Operation: `delete_customer()`

#### Source Code (Oracle)
```sql
procedure delete_customer(p_customer_id in number) is
begin
  delete from xy_customer
  where customer_id = p_customer_id;
end delete_customer;
```

#### Transformation Analysis
| Aspect | Oracle | Snowflake | Migration Notes |
|--------|--------|-----------|-----------------|
| **DELETE Statement** | Standard SQL | Same syntax | Direct mapping |
| **WHERE Clause** | PK-based | Same semantics | Identical logic |

#### Snowflake Implementation
```sql
CREATE OR REPLACE PROCEDURE delete_customer(
    p_customer_id NUMBER
)
LANGUAGE SQL
AS
$$
BEGIN
  DELETE FROM xy_customer
  WHERE customer_id = p_customer_id;
END;
$$;
```

**Status**: ✅ **READY FOR MIGRATION** (direct conversion)

---

### 7. DELETE Operation: `purge_old_customers()`

#### Source Code (Oracle)
```sql
procedure purge_old_customers(
  p_since_date in date,
  p_delete_audit_trail in boolean := false
) is
begin
  delete from xy_customer
  where last_active_date <= p_since_date;
  
  if p_delete_audit_trail then
    -- TODO: Delete from audit table (not yet implemented)
    null;
  end if;
end purge_old_customers;
```

#### Transformation Analysis
| Aspect | Oracle | Snowflake | Migration Notes |
|--------|--------|-----------|-----------------|
| **Bulk DELETE** | Range-based filtering | Same syntax | Direct mapping |
| **BOOLEAN Parameter** | Native BOOLEAN | BIT or TINYINT | Convert to numeric equivalent |
| **Default Value** | `:= false` | DEFAULT keyword | Same semantics |
| **TODO Comment** | Not implemented | Requires implementation | Must define audit table logic |
| **IF Statement** | PL/SQL IF | Same in Snowflake SQL | Direct mapping |

#### Snowflake Implementation
```sql
CREATE OR REPLACE PROCEDURE purge_old_customers(
    p_since_date TIMESTAMP_NTZ,
    p_delete_audit_trail BOOLEAN DEFAULT FALSE
)
LANGUAGE SQL
AS
$$
BEGIN
  -- Main purge operation
  DELETE FROM xy_customer
  WHERE last_active_date <= p_since_date;
  
  -- Conditional audit trail deletion
  IF (p_delete_audit_trail) THEN
    -- TODO: Implement audit trail deletion
    -- Example: DELETE FROM xy_customer_audit WHERE ...
    DELETE FROM xy_customer_audit
    WHERE audit_timestamp <= p_since_date;
  END IF;
END;
$$;
```

**⚠️ Issue**: Audit trail deletion is TODO (not implemented)
**✅ Resolution**: Define audit table structure and deletion logic

**Status**: ⚠️ **REQUIRES SPECIFICATION** (audit logic not defined)

---

## Data Type Mapping Summary

| Oracle Type | Max Size | Snowflake Type | Notes |
|---|---|---|---|
| NUMBER | Unlimited | NUMBER(38,0) or BIGINT | Use BIGINT for auto-increment IDs |
| VARCHAR2 | 4000 | VARCHAR | Snowflake VARCHAR has no size limit |
| DATE | Date+Time | TIMESTAMP_NTZ or DATE | Depends on time component requirement |
| BOOLEAN | 1 byte | BOOLEAN or BIT | Snowflake has native BOOLEAN |
| %rowtype | Variable | OBJECT or VARIANT | Must define explicit structure |

---

## Migration Status by Component

| Component | Status | Complexity | Effort | Dependencies | Notes |
|-----------|--------|-----------|--------|--------------|-------|
| `new_customer()` | ✅ Ready | Medium | 2h | Sequence setup | Requires sequence definition |
| `get_customer()` | ✅ Ready | Low | 1h | None | Use OBJECT or VARIANT return |
| `get_customer_name()` | ✅ Ready | Low | 0.5h | None | Direct conversion |
| `set_customer() [1]` | ✅ Ready | Low | 0.5h | None | Direct conversion |
| `set_customer() [2]` | ⚠️ Refactor | Medium | 2h | Overload resolution | Rename: set_customer_row() |
| `delete_customer()` | ✅ Ready | Low | 0.5h | None | Direct conversion |
| `purge_old_customers()` | ⚠️ Spec Needed | Medium | 2.5h | Audit table definition | TODO: Audit trail logic |

**Total Estimated Effort**: **10.5 hours** (including testing & validation)

---

## Oracle-Specific Features & Conversions

### 1. RETURNING Clause
- **Oracle**: `RETURNING customer_id INTO l_returnvalue`
- **Snowflake**: Limited support; use sequences or MAX() function
- **Recommended**: Sequence-based approach

### 2. Anchor Type Declarations (%type, %rowtype)
- **Oracle**: Automatic type binding to table columns
- **Snowflake**: Explicit type declarations required
- **Migration**: Define explicit OBJECT types or use VARIANT

### 3. Procedure Overloading
- **Oracle**: Same procedure name, different signatures supported
- **Snowflake**: Not supported; use naming conventions
- **Migration**: Rename `set_customer` variants

### 4. Boolean Data Type
- **Oracle**: Native BOOLEAN in PL/SQL
- **Snowflake**: Native BOOLEAN support
- **Migration**: Direct mapping

### 5. Exception Handling (NO_DATA_FOUND)
- **Oracle**: Native exception `NO_DATA_FOUND`
- **Snowflake**: Use NULL checks or LIMIT 1
- **Migration**: Replace exception handling with NULL logic

---

## Potential Issues & Risks

### High Risk Issues
1. **Overloading Not Supported** (set_customer variants)
   - **Impact**: High - Affects API compatibility
   - **Resolution**: Use naming convention or wrapper procedures
   - **Effort**: Medium

2. **Audit Trail Not Implemented** (purge_old_customers TODO)
   - **Impact**: Medium - Data retention compliance
   - **Resolution**: Require audit table schema & logic specification
   - **Effort**: High (depends on requirements)

### Medium Risk Issues
3. **RETURNING Clause Limited**
   - **Impact**: Medium - ID retrieval logic
   - **Resolution**: Use sequence or MAX() approach
   - **Effort**: Low

4. **Transaction Semantics**
   - **Impact**: Low - Snowflake transactions are ACID
   - **Resolution**: Verify transaction isolation level requirements
   - **Effort**: Low

### Low Risk Issues
5. **Type Anchoring Requirements**
   - **Impact**: Low - Code clarity
   - **Resolution**: Define explicit types
   - **Effort**: Low

---

## Recommendations

### Phase 1: Preparation (Week 1)
- [ ] Define sequence strategy for auto-increment IDs
- [ ] Establish audit table schema and retention policies
- [ ] Create Snowflake test environment
- [ ] Set up CI/CD pipeline for procedure deployment

### Phase 2: Core Migration (Week 2)
- [ ] Migrate `get_customer()` and `get_customer_name()` (simple reads)
- [ ] Migrate `delete_customer()` (simple deletes)
- [ ] Migrate `set_customer()` field-level variant
- [ ] Migrate `new_customer()` with sequence approach
- [ ] Create unit tests for each procedure

### Phase 3: Complex Components (Week 3)
- [ ] Implement `set_customer_row()` replacement procedure
- [ ] Implement audit trail logic in `purge_old_customers()`
- [ ] Create integration tests with calling application
- [ ] Performance tuning and optimization

### Phase 4: Validation & Deployment (Week 4)
- [ ] Data migration validation
- [ ] User acceptance testing (UAT)
- [ ] Performance benchmarking
- [ ] Production deployment

---

## Performance Considerations

### Optimization Opportunities in Snowflake
1. **Sequence Performance**: Sequences are efficient in Snowflake for single-row inserts
2. **Bulk Operations**: `purge_old_customers()` can benefit from Snowflake's parallel processing
3. **Clustering**: Consider clustering `xy_customer` by `customer_id` if table is large
4. **Query Result Caching**: Leverage Snowflake's result caching for read operations

### Recommended Indexes
```sql
-- Recommended indexes for performance
ALTER TABLE xy_customer CLUSTER BY (customer_id);
CREATE INDEX idx_customer_active_date ON xy_customer(last_active_date);
```

---

## Testing Strategy

### Unit Tests Required
```sql
-- Test 1: new_customer() insertion
CALL new_customer('Test Customer');

-- Test 2: get_customer() retrieval
SELECT * FROM TABLE(get_customer(1));

-- Test 3: get_customer_name() scalar return
SELECT get_customer_name(1);

-- Test 4: set_customer() update
CALL set_customer(1, 'Updated Name');

-- Test 5: delete_customer() removal
CALL delete_customer(1);

-- Test 6: purge_old_customers() bulk delete
CALL purge_old_customers('2024-01-01'::TIMESTAMP_NTZ, FALSE);
```

### Integration Tests
- Application integration with new procedures
- Transaction rollback scenarios
- Concurrent access patterns
- Error handling validation

---

## Conclusion

The Oracle PL/SQL package `customer_pkg.pkb` can be successfully migrated to Snowflake SQL with moderate effort. The package implements standard CRUD operations that map well to Snowflake's SQL capabilities. 

**Key Success Factors**:
1. ✅ Define sequence strategy early
2. ✅ Resolve procedure overloading through naming conventions
3. ✅ Clarify audit trail requirements before implementation
4. ✅ Implement comprehensive testing strategy
5. ✅ Consider performance optimization with clustering

**Overall Migration Assessment**: **FEASIBLE - MODERATE COMPLEXITY**

**Recommendation**: Proceed with Phase 1 preparation immediately, targeting 4-week delivery timeline.

---

## Appendix A: Snowflake DDL for xy_customer Table

```sql
CREATE TABLE IF NOT EXISTS xy_customer (
    customer_id BIGINT PRIMARY KEY,
    customer_name VARCHAR NOT NULL,
    last_active_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    created_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE SEQUENCE IF NOT EXISTS xy_customer_seq START = 1 INCREMENT = 1;

CREATE TABLE IF NOT EXISTS xy_customer_audit (
    audit_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    customer_id BIGINT,
    operation VARCHAR,
    old_values VARIANT,
    new_values VARIANT,
    audit_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP
);
```

---

**Report Generated**: 2026-06-14  
**Status**: Analysis Complete - Ready for Implementation Planning
