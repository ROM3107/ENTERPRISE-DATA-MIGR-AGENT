# Library Database System - Flow Diagram & Entity Relationship Analysis

## Document Overview
This comprehensive analysis covers the Oracle SQL Library Database System, detailing all entity relationships, data types, primary keys, foreign keys, and cardinality mapping for migration and system understanding.

---

## 1. Complete Entity Relationship Diagram

```mermaid
erDiagram
    LOCATION ||--o{ BRANCH : has
    LOCATION ||--o{ BOOK : stores
    LOCATION ||--o{ VIDEO : stores
    CARD ||--o{ CUSTOMER : assigned_to
    CARD ||--o{ EMPLOYEE : assigned_to
    CARD ||--o{ RENT : "initiates"
    BRANCH ||--o{ EMPLOYEE : employs
    BOOK ||--o{ RENT : "rented_via"
    VIDEO ||--o{ RENT : "rented_via"
    
    CARD {
        number cardID PK
        string status "CHECK: A|B"
        number fines
    }
    
    CUSTOMER {
        number customerID PK
        string name
        string customerAddress
        number phone
        string password
        string userName
        date dateSignUp
        number cardNumber FK
    }
    
    EMPLOYEE {
        number employeeID PK
        string name
        string employeeAddress
        number phone
        string password
        string userName
        number paycheck
        string branchName FK
        number cardNumber FK
    }
    
    BRANCH {
        string name PK
        string address FK
        number phone
    }
    
    LOCATION {
        string address PK
    }
    
    BOOK {
        string ISBN PK
        string bookID PK
        string state
        string avalability "CHECK: A|O"
        number debyCost
        number lostCost
        string address FK
    }
    
    VIDEO {
        string title PK
        number year PK
        string videoID PK
        string state
        string avalability "CHECK: A|O"
        number debyCost
        number lostCost
        string address FK
    }
    
    RENT {
        number cardID PK_FK
        string itemID PK_FK
        date apporpriationDate
        date returnDate
    }
```

---

## 2. Data Flow Diagram - Complete System Architecture

```mermaid
graph TB
    subgraph LOCATION_LAYER["📍 Location Layer"]
        LOC["Location Table<br/>(address: VARCHAR2(50))"]
    end
    
    subgraph ORGANIZATIONAL["🏢 Organizational Entities"]
        BRANCH["Branch Table<br/>(name: VARCHAR2(40)<br/>address: FK→Location<br/>phone: NUMBER)"]
        EMP["Employee Table<br/>(employeeID, name, paycheck<br/>branchName: FK→Branch<br/>cardNumber: FK→Card)"]
    end
    
    subgraph USER_MANAGEMENT["👥 User Management Layer"]
        CARD["Card Table (Core)<br/>(cardID: PK<br/>status: A|B<br/>fines: NUMBER)"]
        CUST["Customer Table<br/>(customerID, name<br/>cardNumber: FK→Card)"]
    end
    
    subgraph INVENTORY["📚 Inventory Layer"]
        BOOK["Book Table<br/>(ISBN, bookID: PK<br/>state, avalability: A|O<br/>debyCost, lostCost<br/>address: FK→Location)"]
        VIDEO["Video Table<br/>(title, year, videoID: PK<br/>state, avalability: A|O<br/>debyCost, lostCost<br/>address: FK→Location)"]
    end
    
    subgraph TRANSACTION["💳 Transaction/Rental Layer"]
        RENT["Rent Table<br/>(cardID: FK→Card<br/>itemID: FK→Book.bookID<br/>itemID: FK→Video.videoID<br/>appropriationDate, returnDate)"]
    end
    
    LOC -->|1:N| BRANCH
    LOC -->|1:N| BOOK
    LOC -->|1:N| VIDEO
    
    BRANCH -->|N:1| EMP
    CARD -->|1:1| CUST
    CARD -->|1:1| EMP
    
    CARD -->|1:N| RENT
    BOOK -->|1:N| RENT
    VIDEO -->|1:N| RENT
    
    CUST -->|queries| BOOK
    CUST -->|queries| VIDEO
    CUST -->|initiates| RENT
    EMP -->|manages| RENT
    EMP -->|manages| BOOK
    EMP -->|manages| VIDEO
    
    style LOC fill:#e1f5ff
    style BRANCH fill:#f3e5f5
    style EMP fill:#f3e5f5
    style CARD fill:#fff3e0
    style CUST fill:#fff3e0
    style BOOK fill:#e8f5e9
    style VIDEO fill:#e8f5e9
    style RENT fill:#fce4ec
```

---

## 3. Primary & Foreign Key Relationship Map

```mermaid
graph LR
    subgraph PK["🔑 Primary Keys"]
        PK1["Card.cardID"]
        PK2["Customer.customerID"]
        PK3["Employee.employeeID"]
        PK4["Branch.name"]
        PK5["Location.address"]
        PK6["Book(ISBN, bookID)"]
        PK7["Video(title, year, videoID)"]
        PK8["Rent(cardID, itemID)"]
    end
    
    subgraph FK["🔗 Foreign Key References"]
        FK1["Customer.cardNumber<br/>→ Card.cardID<br/>(1:1)"]
        FK2["Employee.cardNumber<br/>→ Card.cardID<br/>(1:1)"]
        FK3["Employee.branchName<br/>→ Branch.name<br/>(N:1)"]
        FK4["Branch.address<br/>→ Location.address<br/>(N:1)"]
        FK5["Book.address<br/>→ Location.address<br/>(N:1)"]
        FK6["Video.address<br/>→ Location.address<br/>(N:1)"]
        FK7["Rent.cardID<br/>→ Card.cardID<br/>(N:1)"]
        FK8["Rent.itemID<br/>→ Book.bookID<br/>(N:1)"]
        FK9["Rent.itemID<br/>→ Video.videoID<br/>(N:1)"]
    end
    
    PK1 -.->|referenced by| FK1
    PK1 -.->|referenced by| FK2
    PK1 -.->|referenced by| FK7
    PK4 -.->|referenced by| FK3
    PK5 -.->|referenced by| FK4
    PK5 -.->|referenced by| FK5
    PK5 -.->|referenced by| FK6
    PK6 -.->|referenced by| FK8
    PK7 -.->|referenced by| FK9
    
    style PK1 fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style PK2 fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style PK3 fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style PK4 fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style PK5 fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style PK6 fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style PK7 fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style PK8 fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    
    style FK1 fill:#c8e6c9,stroke:#558b2f,stroke-width:2px
    style FK2 fill:#c8e6c9,stroke:#558b2f,stroke-width:2px
    style FK3 fill:#c8e6c9,stroke:#558b2f,stroke-width:2px
    style FK4 fill:#c8e6c9,stroke:#558b2f,stroke-width:2px
    style FK5 fill:#c8e6c9,stroke:#558b2f,stroke-width:2px
    style FK6 fill:#c8e6c9,stroke:#558b2f,stroke-width:2px
    style FK7 fill:#c8e6c9,stroke:#558b2f,stroke-width:2px
    style FK8 fill:#c8e6c9,stroke:#558b2f,stroke-width:2px
    style FK9 fill:#c8e6c9,stroke:#558b2f,stroke-width:2px
```

---

## 4. Cardinality Matrix

```mermaid
graph TB
    subgraph CARD_RELATIONSHIPS["Card → * Relationships"]
        C1["Card (1) : Customer (1)<br/>Cardinality: 1:1<br/>Constraint: Customer.cardNumber → Card.cardID"]
        C2["Card (1) : Employee (1)<br/>Cardinality: 1:1<br/>Constraint: Employee.cardNumber → Card.cardID"]
        C3["Card (1) : Rent (N)<br/>Cardinality: 1:N<br/>Constraint: Rent.cardID → Card.cardID<br/>Usage: One card can have multiple rentals"]
    end
    
    subgraph LOCATION_RELATIONSHIPS["Location → * Relationships"]
        L1["Location (1) : Branch (N)<br/>Cardinality: 1:N<br/>Constraint: Branch.address → Location.address"]
        L2["Location (1) : Book (N)<br/>Cardinality: 1:N<br/>Constraint: Book.address → Location.address<br/>Usage: Books stored at different locations"]
        L3["Location (1) : Video (N)<br/>Cardinality: 1:N<br/>Constraint: Video.address → Location.address<br/>Usage: Videos stored at different locations"]
    end
    
    subgraph INVENTORY_RELATIONSHIPS["Inventory → Rent Relationships"]
        I1["Book (1) : Rent (N)<br/>Cardinality: 1:N<br/>Constraint: Rent.itemID → Book.bookID<br/>Usage: One book item can be rented multiple times"]
        I2["Video (1) : Rent (N)<br/>Cardinality: 1:N<br/>Constraint: Rent.itemID → Video.videoID<br/>Usage: One video item can be rented multiple times"]
    end
    
    subgraph ORGANIZATIONAL_RELATIONSHIPS["Organizational Relationships"]
        O1["Branch (1) : Employee (N)<br/>Cardinality: 1:N<br/>Constraint: Employee.branchName → Branch.name<br/>Usage: Multiple employees per branch"]
    end
    
    style C1 fill:#ffccbc
    style C2 fill:#ffccbc
    style C3 fill:#ffccbc
    style L1 fill:#bbdefb
    style L2 fill:#bbdefb
    style L3 fill:#bbdefb
    style I1 fill:#c8e6c9
    style I2 fill:#c8e6c9
    style O1 fill:#f8bbd0
```

---

## 5. Data Transformation Flow - Transaction Processing

```mermaid
graph LR
    subgraph INPUT["Input/Query Phase"]
        A1["Customer/Employee<br/>Initiates Rental Request"]
        A2["Query Available Items<br/>FROM Book/Video<br/>WHERE avalability = 'A'"]
    end
    
    subgraph VALIDATION["Validation Phase"]
        B1["Check Card Status<br/>FROM Card<br/>WHERE cardID = customer.cardNumber"]
        B2["Validate Availability<br/>status = 'A' or 'B'?<br/>item avalability = 'A' or 'O'?"]
        B3{Decision Point}
        B3_YES["Status=A AND<br/>Item=Available"]
        B3_NO["Status=B OR<br/>Item=Not Available"]
    end
    
    subgraph TRANSACTION["Transaction Phase"]
        C1["CREATE Rent Record<br/>INSERT INTO Rent<br/>(cardID, itemID,<br/>appropriationDate, returnDate)"]
        C2["UPDATE Item Availability<br/>UPDATE Book/Video<br/>SET avalability = 'O'"]
    end
    
    subgraph RESULT["Result/Output Phase"]
        D1["Return Success<br/>Item Rented"]
        D2["Return Error<br/>Rental Blocked"]
    end
    
    A1 -->|check| A2
    A2 -->|validate| B1
    B1 -->|check| B2
    B2 -->|evaluate| B3
    B3 -->|proceed| B3_YES
    B3 -->|reject| B3_NO
    B3_YES -->|create| C1
    C1 -->|update| C2
    C2 -->|return| D1
    B3_NO -->|return| D2
    
    style A1 fill:#e0e0e0
    style A2 fill:#e0e0e0
    style B1 fill:#fff9c4
    style B2 fill:#fff9c4
    style B3 fill:#ffccbc,stroke:#d84315,stroke-width:2px
    style C1 fill:#bbdefb,stroke:#1565c0,stroke-width:2px
    style C2 fill:#bbdefb,stroke:#1565c0,stroke-width:2px
    style D1 fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style D2 fill:#ffcdd2,stroke:#c62828,stroke-width:2px
```

---

## 6. Entity Attributes & Data Type Schema

```
┌─────────────────────────────────────────────────────────────────────┐
│                          CARD TABLE (Core)                          │
├────────────┬──────────────┬──────────┬────────────────────────────┤
│ Attribute  │ Data Type    │ Nullable │ Constraints                │
├────────────┼──────────────┼──────────┼────────────────────────────┤
│ cardID     │ NUMBER       │ NO       │ PRIMARY KEY                │
│ status     │ VARCHAR2(1)  │ YES      │ CHECK('A' OR 'B')          │
│ fines      │ NUMBER       │ YES      │ None                       │
└────────────┴──────────────┴──────────┴────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      CUSTOMER TABLE                                  │
├───────────────────┬──────────────┬──────────┬───────────────────────┤
│ Attribute         │ Data Type    │ Nullable │ Constraints           │
├───────────────────┼──────────────┼──────────┼───────────────────────┤
│ customerID        │ NUMBER       │ NO       │ PRIMARY KEY           │
│ name              │ VARCHAR2(40) │ YES      │ None                  │
│ customerAddress   │ VARCHAR2(50) │ YES      │ None                  │
│ phone             │ NUMBER(9)    │ YES      │ None                  │
│ password          │ VARCHAR2(20) │ YES      │ None                  │
│ userName          │ VARCHAR2(10) │ YES      │ None                  │
│ dateSignUp        │ DATE         │ YES      │ None                  │
│ cardNumber        │ NUMBER       │ YES      │ FOREIGN KEY→Card.cardID│
└───────────────────┴──────────────┴──────────┴───────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      EMPLOYEE TABLE                                  │
├───────────────────┬──────────────┬──────────┬───────────────────────┤
│ Attribute         │ Data Type    │ Nullable │ Constraints           │
├───────────────────┼──────────────┼──────────┼───────────────────────┤
│ employeeID        │ NUMBER       │ NO       │ PRIMARY KEY           │
│ name              │ VARCHAR2(40) │ YES      │ None                  │
│ employeeAddress   │ VARCHAR2(50) │ YES      │ None                  │
│ phone             │ NUMBER(9)    │ YES      │ None                  │
│ password          │ VARCHAR2(20) │ YES      │ None                  │
│ userName          │ VARCHAR2(10) │ YES      │ None                  │
│ paycheck          │ NUMBER(8,2)  │ YES      │ None                  │
│ branchName        │ VARCHAR2(40) │ YES      │ FOREIGN KEY→Branch.name│
│ cardNumber        │ NUMBER       │ YES      │ FOREIGN KEY→Card.cardID│
└───────────────────┴──────────────┴──────────┴───────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                       BRANCH TABLE                                   │
├────────────┬──────────────┬──────────┬────────────────────────────┤
│ Attribute  │ Data Type    │ Nullable │ Constraints                │
├────────────┼──────────────┼──────────┼────────────────────────────┤
│ name       │ VARCHAR2(40) │ NO       │ PRIMARY KEY                │
│ address    │ VARCHAR2(50) │ YES      │ FOREIGN KEY→Location.address│
│ phone      │ NUMBER(9)    │ YES      │ None                       │
└────────────┴──────────────┴──────────┴────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      LOCATION TABLE                                  │
├────────────┬──────────────┬──────────┬────────────────────────────┤
│ Attribute  │ Data Type    │ Nullable │ Constraints                │
├────────────┼──────────────┼──────────┼────────────────────────────┤
│ address    │ VARCHAR2(50) │ NO       │ PRIMARY KEY                │
└────────────┴──────────────┴──────────┴────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                         BOOK TABLE                                   │
├─────────────────┬──────────────┬──────────┬─────────────────────────┤
│ Attribute       │ Data Type    │ Nullable │ Constraints             │
├─────────────────┼──────────────┼──────────┼─────────────────────────┤
│ ISBN            │ VARCHAR2(4)  │ NO       │ PRIMARY KEY             │
│ bookID          │ VARCHAR2(6)  │ NO       │ PRIMARY KEY             │
│ state           │ VARCHAR2(10) │ YES      │ None                    │
│ avalability     │ VARCHAR2(1)  │ YES      │ CHECK('A' OR 'O')       │
│ debyCost        │ NUMBER(10,2) │ YES      │ None                    │
│ lostCost        │ NUMBER(10,2) │ YES      │ None                    │
│ address         │ VARCHAR2(50) │ YES      │ FOREIGN KEY→Location    │
└─────────────────┴──────────────┴──────────┴─────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                         VIDEO TABLE                                  │
├─────────────────┬──────────────┬──────────┬─────────────────────────┤
│ Attribute       │ Data Type    │ Nullable │ Constraints             │
├─────────────────┼──────────────┼──────────┼─────────────────────────┤
│ title           │ VARCHAR2(50) │ NO       │ PRIMARY KEY             │
│ year            │ INT          │ NO       │ PRIMARY KEY             │
│ videoID         │ VARCHAR2(6)  │ NO       │ PRIMARY KEY             │
│ state           │ VARCHAR2(10) │ YES      │ None                    │
│ avalability     │ VARCHAR2(1)  │ YES      │ CHECK('A' OR 'O')       │
│ debyCost        │ NUMBER(10,2) │ YES      │ None                    │
│ lostCost        │ NUMBER(10,2) │ YES      │ None                    │
│ address         │ VARCHAR2(50) │ YES      │ FOREIGN KEY→Location    │
└─────────────────┴──────────────┴──────────┴─────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                         RENT TABLE                                   │
├────────────────────┬──────────────┬──────────┬──────────────────────┤
│ Attribute          │ Data Type    │ Nullable │ Constraints          │
├────────────────────┼──────────────┼──────────┼──────────────────────┤
│ cardID             │ NUMBER       │ NO       │ PRIMARY KEY + FK     │
│ itemID             │ VARCHAR2(6)  │ NO       │ PRIMARY KEY + FK     │
│ apporpriationDate  │ DATE         │ YES      │ None                 │
│ returnDate         │ DATE         │ YES      │ None                 │
└────────────────────┴──────────────┴──────────┴──────────────────────┘
```

---

## 7. System Operations & Business Logic Flow

```mermaid
graph TB
    subgraph OPS["Core System Operations"]
        OP1["Login Process<br/>→ loginCustomer_library()<br/>→ loginEmployee_library()"]
        OP2["View Item Details<br/>→ viewItem_library()"]
        OP3["Account Management<br/>→ customerAccount_library()<br/>→ employeeAccount_library()"]
        OP4["Rental Management<br/>→ rentItem_library()"]
        OP5["Fine Processing<br/>→ payFines_library()"]
        OP6["Profile Updates<br/>→ updateInfoCusto_library()<br/>→ updateInfoEmp_library()"]
        OP7["New User Registration<br/>→ addCustomer_library()"]
        OP8["Auto Card Creation<br/>→ addCardCusto_library (TRIGGER)<br/>→ addCardEmp_library (TRIGGER)"]
        OP9["Media Listing<br/>→ allMedia_library()"]
    end
    
    OP1 -.->|validates| OP3
    OP1 -.->|enables| OP4
    OP2 -.->|precedes| OP4
    OP4 -.->|may incur| OP5
    OP7 -.->|triggers| OP8
    OP6 -.->|updates| OP3
    OP2 -.->|from| OP9
    
    style OP1 fill:#fff3e0
    style OP2 fill:#e8f5e9
    style OP3 fill:#bbdefb
    style OP4 fill:#fce4ec,stroke:#c2185b,stroke-width:2px
    style OP5 fill:#ffccbc
    style OP6 fill:#e1bee7
    style OP7 fill:#fff9c4
    style OP8 fill:#fff9c4
    style OP9 fill:#c8e6c9
```

---

## 8. Data Integrity Constraints Summary

| Constraint Type | Details |
|---|---|
| **CHECK Constraints** | Card.status ∈ {'A', 'B'} (Active/Blocked) |
| | Book.avalability ∈ {'A', 'O'} (Available/Out) |
| | Video.avalability ∈ {'A', 'O'} (Available/Out) |
| **Primary Keys** | Card(cardID), Customer(customerID), Employee(employeeID) |
| | Branch(name), Location(address) |
| | Book(ISBN, bookID) - Composite |
| | Video(title, year, videoID) - Composite |
| | Rent(cardID, itemID) - Composite |
| **Foreign Keys** | Customer.cardNumber → Card.cardID |
| | Employee.cardNumber → Card.cardID |
| | Employee.branchName → Branch.name |
| | Branch.address → Location.address |
| | Book.address → Location.address |
| | Video.address → Location.address |
| | Rent.cardID → Card.cardID |
| | Rent.itemID → Book.bookID \| Video.videoID |

---

## 9. Data Flow Mapping Summary

### Source Systems:
- **Operational Users**: Customer & Employee entities
- **Inventory Systems**: Book & Video tables
- **Location Management**: Branch & Location tables

### Target Systems:
- **Transaction Records**: Rent table (core transaction log)
- **Account Management**: Card table (user account status)
- **Fine Management**: Card.fines (financial tracking)

### Key Transformation Points:
1. **User Registration** → Card Creation (Trigger)
2. **Item Request** → Availability Check (Validation)
3. **Rental Initiation** → Record Creation + Availability Update
4. **Return Processing** → Rent Record + Fine Calculation
5. **Account Updates** → User Information Synchronization

---

## Document Information
- **Database Type**: Oracle SQL
- **Analysis Date**: 2026-06-14
- **Entity Count**: 8 tables
- **Relationship Count**: 13 foreign key relationships
- **Sample Data Records**: 65+ inserts across all tables
- **Procedures**: 9 stored procedures + 2 triggers
