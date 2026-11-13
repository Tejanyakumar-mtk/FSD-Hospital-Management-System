# Oracle Database Setup Guide - Hospital Management System

This guide provides instructions for configuring and populating the Oracle Database schema for the Hospital Management System.

---

## 1. Database Connection Parameters

| Parameter | Configuration Value |
| :--- | :--- |
| **Database Server** | Oracle Database Express Edition (XE) / Enterprise / Standard |
| **Host** | `localhost` (127.0.0.1) |
| **Port** | `1521` |
| **SID / Service Name** | `xe` (or `orcl`) |
| **JDBC Driver URL** | `jdbc:oracle:thin:@localhost:1521:xe` |
| **Database User** | `hospital_db` |
| **Password** | `hospital123` |
| **Default Tablespace** | `USERS` |
| **Temporary Tablespace** | `TEMP` |

---

## 2. Creating the Dedicated Database Account

Run the following commands in SQL*Plus logged in as `SYS` (`sys as sysdba`):

```sql
-- 1. Create the dedicated schema
CREATE USER hospital_db IDENTIFIED BY hospital123
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON USERS;

-- 2. Grant required privileges
GRANT CONNECT, RESOURCE, CREATE VIEW TO hospital_db;

EXIT;
```

---

## 3. SQL Scripts Execution Order

All SQL scripts are organized inside the `database/` folder at the project root:

| Script | Purpose |
| :--- | :--- |
| `00_reset_database.sql` | *(Optional / Destructive)* Drops existing HMS tables and sequences if starting completely fresh. |
| `01_create_tables.sql` | Creates sequences, 12 normalized tables, and auto-increment triggers. |
| `02_constraints_indexes.sql` | Adds referential integrity foreign keys and search performance indexes. |
| `03_sample_data.sql` | Seeds realistic clinical demonstration data with pre-calculated PBKDF2 user hashes. |
| `04_verification_queries.sql`| Executes record counts, relational joins, and revenue verification diagnostics. |

### Running the Scripts via Command Line / PowerShell

Connect to Oracle using the newly created `hospital_db` account and run:

```powershell
# From the project root:
sqlplus hospital_db/hospital123@localhost:1521/xe

-- Inside SQL*Plus:
@database/01_create_tables.sql
@database/02_constraints_indexes.sql
@database/03_sample_data.sql
@database/04_verification_queries.sql
EXIT;
```

---

## 4. Default Demonstration User Credentials

All passwords in `03_sample_data.sql` are cryptographically hashed using **PBKDF2WithHmacSHA256** and individual random salts:

| Role | Username | Plain Password | Linked Profile | Description |
| :--- | :--- | :--- | :--- | :--- |
| **ADMIN** | `admin` | `Admin@123` | System Administrator | Full access to all hospital modules |
| **RECEPTIONIST** | `reception` | `Recep@123` | Front Desk Staff | Patient registration, visits, billing |
| **DOCTOR** | `dr.sharma` | `Doctor@123` | Dr. Rajesh Sharma (Cardiology) | Assigned visits, electronic prescriptions |
| **DOCTOR** | `dr.patel` | `Doctor@123` | Dr. Priya Patel (Neurology) | Assigned visits, electronic prescriptions |
| **DOCTOR** | `dr.rao` | `Doctor@123` | Dr. Vikram Rao (Orthopedics) | Assigned visits, electronic prescriptions |
| **PATIENT** | `john.doe` | `Patient@123` | John Doe (#1001) | Booking visits, viewing prescriptions |
| **PATIENT** | `jane.smith` | `Patient@123` | Jane Smith (#1002) | Booking visits, viewing prescriptions |

---

## 5. Verification Checklist

After executing the scripts, running `database/04_verification_queries.sql` should output:

- **DEPARTMENTS:** 6 records
- **DOCTORS:** 6 records
- **DOCTOR_AVAILABILITY:** 22 schedules
- **PATIENTS:** 4 records
- **USERS:** 7 accounts
- **APPOINTMENTS:** 5 consultations
- **PRESCRIPTIONS:** 2 prescriptions
- **PRESCRIPTION_ITEMS:** 4 medicines
- **BILLS:** 3 invoices
- **BILL_ITEMS:** 5 charge items
- **PAYMENTS:** 2 payment receipts
- **AUDIT_LOG:** 1 init entry
