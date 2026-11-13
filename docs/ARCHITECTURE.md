# Hospital Management System (HMS) - System Architecture & Database Design

## 1. System Overview

The **CityHealth Hospital Management System (HMS)** is built following the traditional Java EE Dynamic Web Application architecture for **Apache Tomcat 9**, using **JSP and JDBC** for server-side processing, **HTML5/CSS3/Vanilla JavaScript** on the client, and **Oracle Database (10g/11g/12c/19c/21c)** for persistent storage.

---

## 2. System Architecture Diagram

```mermaid
flowchart TD
    subgraph ClientLayer["Client Layer (Browser)"]
        UI_Public["Public Web Portal (Home, About, Doctors)"]
        UI_Patient["Patient Portal (Dashboard, Booking, My Appts, Profile)"]
        UI_Doctor["Doctor Portal (Dashboard, Consultation, Prescriptions)"]
        UI_Staff["Staff Portal (Patients, Doctors, Depts, Billing, Reports)"]
    end

    subgraph PresentationLayer["Presentation & Middleware (Tomcat 9)"]
        JSP_Pages["JSP Processing Engine (javax-compatible)"]
        Sec_Util["SecurityUtil (CSRF, XSS Escaping, Role Guards)"]
        Pass_Util["PasswordUtil (PBKDF2WithHmacSHA256)"]
        DB_Conn["DBConnection (JDBC Connection Manager)"]
    end

    subgraph DataAccessLayer["Data Access Layer"]
        JDBC_Driver["Oracle JDBC Driver (ojdbc8.jar)"]
    end

    subgraph StorageLayer["Database Layer (Oracle XE)"]
        direction TB
        TBL_Users[(USERS)]
        TBL_Patients[(PATIENTS)]
        TBL_Doctors[(DOCTORS)]
        TBL_Depts[(DEPARTMENTS)]
        TBL_Avail[(DOCTOR_AVAILABILITY)]
        TBL_Appts[(APPOINTMENTS)]
        TBL_Presc[(PRESCRIPTIONS)]
        TBL_Items[(PRESCRIPTION_ITEMS)]
        TBL_Bills[(BILLS)]
        TBL_BItems[(BILL_ITEMS)]
        TBL_Payments[(PAYMENTS)]
        TBL_Audit[(AUDIT_LOG)]
    end

    ClientLayer -->|HTTP / HTTPS GET & POST| JSP_Pages
    JSP_Pages --> Sec_Util
    JSP_Pages --> Pass_Util
    JSP_Pages --> DB_Conn
    DB_Conn --> JDBC_Driver
    JDBC_Driver --> StorageLayer
```

---

## 3. Entity-Relationship (ER) Diagram

```mermaid
erDiagram
    DEPARTMENTS ||--o{ DOCTORS : "houses"
    DOCTORS ||--o{ DOCTOR_AVAILABILITY : "scheduled on"
    DOCTORS ||--o{ APPOINTMENTS : "attends"
    PATIENTS ||--o{ APPOINTMENTS : "books"
    APPOINTMENTS ||--o| PRESCRIPTIONS : "results in"
    PRESCRIPTIONS ||--|{ PRESCRIPTION_ITEMS : "contains"
    PATIENTS ||--o{ BILLS : "billed to"
    APPOINTMENTS ||--o| BILLS : "invoiced for"
    BILLS ||--|{ BILL_ITEMS : "details"
    BILLS ||--o{ PAYMENTS : "paid via"
    PATIENTS ||--o| USERS : "authenticates as"
    DOCTORS ||--o| USERS : "authenticates as"
    USERS ||--o{ AUDIT_LOG : "triggers"

    DEPARTMENTS {
        NUMBER DEPARTMENT_ID PK
        VARCHAR2 DEPARTMENT_NAME
        VARCHAR2 DESCRIPTION
        NUMBER ACTIVE
    }

    DOCTORS {
        NUMBER DOCTOR_ID PK
        VARCHAR2 DOCTOR_NAME
        VARCHAR2 EMAIL
        VARCHAR2 PHONE
        VARCHAR2 SPECIALIZATION
        NUMBER DEPARTMENT_ID FK
        NUMBER CONSULTATION_FEE
        VARCHAR2 QUALIFICATION
        VARCHAR2 ROOM_NO
        NUMBER ACTIVE
    }

    PATIENTS {
        NUMBER PATIENT_ID PK
        VARCHAR2 PATIENT_NAME
        DATE DOB
        VARCHAR2 GENDER
        VARCHAR2 PHONE
        VARCHAR2 EMAIL
        VARCHAR2 ADDRESS
        VARCHAR2 BLOOD_GROUP
        VARCHAR2 EMERGENCY_CONTACT
        NUMBER ACTIVE
    }

    USERS {
        NUMBER USER_ID PK
        VARCHAR2 USERNAME
        VARCHAR2 PASSWORD_HASH
        VARCHAR2 PASSWORD_SALT
        VARCHAR2 FULL_NAME
        VARCHAR2 ROLE
        NUMBER PATIENT_ID FK
        NUMBER DOCTOR_ID FK
        NUMBER ACTIVE
    }

    DOCTOR_AVAILABILITY {
        NUMBER AVAILABILITY_ID PK
        NUMBER DOCTOR_ID FK
        VARCHAR2 DAY_OF_WEEK
        VARCHAR2 START_TIME
        VARCHAR2 END_TIME
        NUMBER SLOT_DURATION
        NUMBER ACTIVE
    }

    APPOINTMENTS {
        NUMBER APPOINTMENT_ID PK
        NUMBER PATIENT_ID FK
        NUMBER DOCTOR_ID FK
        DATE APPOINTMENT_DATE
        VARCHAR2 APPOINTMENT_TIME
        VARCHAR2 REASON
        VARCHAR2 STATUS
        TIMESTAMP CREATED_AT
        TIMESTAMP CANCELLED_AT
        VARCHAR2 CANCELLATION_REASON
    }

    PRESCRIPTIONS {
        NUMBER PRESCRIPTION_ID PK
        NUMBER APPOINTMENT_ID FK
        NUMBER DOCTOR_ID FK
        NUMBER PATIENT_ID FK
        VARCHAR2 DIAGNOSIS
        VARCHAR2 NOTES
        TIMESTAMP CREATED_AT
    }

    PRESCRIPTION_ITEMS {
        NUMBER ITEM_ID PK
        NUMBER PRESCRIPTION_ID FK
        VARCHAR2 MEDICINE_NAME
        VARCHAR2 DOSAGE
        VARCHAR2 DURATION
        VARCHAR2 INSTRUCTIONS
    }

    BILLS {
        NUMBER BILL_ID PK
        NUMBER PATIENT_ID FK
        NUMBER APPOINTMENT_ID FK
        NUMBER TOTAL_AMOUNT
        NUMBER PAID_AMOUNT
        NUMBER BALANCE_AMOUNT
        VARCHAR2 STATUS
        TIMESTAMP CREATED_AT
    }

    BILL_ITEMS {
        NUMBER ITEM_ID PK
        NUMBER BILL_ID FK
        VARCHAR2 DESCRIPTION
        NUMBER QUANTITY
        NUMBER UNIT_PRICE
        NUMBER LINE_TOTAL
    }

    PAYMENTS {
        NUMBER PAYMENT_ID PK
        NUMBER BILL_ID FK
        NUMBER AMOUNT
        TIMESTAMP PAYMENT_DATE
        VARCHAR2 PAYMENT_METHOD
        VARCHAR2 PAYMENT_REFERENCE
        VARCHAR2 STATUS
    }

    AUDIT_LOG {
        NUMBER AUDIT_ID PK
        NUMBER USER_ID FK
        VARCHAR2 ACTION
        VARCHAR2 ENTITY_TYPE
        NUMBER ENTITY_ID
        VARCHAR2 DETAILS
        TIMESTAMP CREATED_AT
    }
```

---

## 4. Role-Based Access Control (RBAC) Matrix

| Operation / Module | Public Guest | Patient | Doctor | Receptionist | Administrator |
| :--- | :---: | :---: | :---: | :---: | :---: |
| Browse Public Home / About | Yes | Yes | Yes | Yes | Yes |
| Browse Doctors & Catalog | Yes | Yes | Yes | Yes | Yes |
| Patient Self-Registration | Yes | No | No | No | No |
| Login / Logout | Yes | Yes | Yes | Yes | Yes |
| Book Own Appointment | No | Yes | No | No | No |
| View Own Appointments | No | Yes | No | No | No |
| Cancel Own Booked Visit | No | Yes | No | Yes | Yes |
| Update Own Contact Profile | No | Yes | Yes | Yes | Yes |
| View Doctor Assigned Appts | No | No | Yes | No | No |
| Author Electronic Prescription | No | No | Yes | No | No |
| View Patient Clinical History | No | Own | Authorized | Yes | Yes |
| Patient Management (CRUD) | No | No | No | Yes | Yes |
| Doctor Management (CRUD) | No | No | No | Yes | Yes |
| Department Management | No | No | No | Yes | Yes |
| Book on Behalf of Patient | No | No | No | Yes | Yes |
| Reschedule Appointments | No | No | No | Yes | Yes |
| Billing & Payments Management | No | View Own | No | Yes | Yes |
| Print Tax Invoice | No | Own | No | Yes | Yes |
| Access Reports & Analytics | No | No | No | Yes | Yes |

---

## 5. Security Architecture

1. **Authentication:**
   - Pre-computed random 16-byte cryptographic salt per user (`SecureRandom`).
   - `PBKDF2WithHmacSHA256` hashing with 65,536 iterations.
   - Constant-time string comparison (`slowEquals`) to defeat timing analysis.
2. **Session Hijacking Mitigation:**
   - Session invalidation and identifier regeneration on login.
   - 30-minute session timeout configured in `web.xml`.
   - `HttpOnly` cookie protection prevents JavaScript cookie theft.
3. **Cross-Site Request Forgery (CSRF):**
   - Synchronizer Token Pattern implemented with `SecurityUtil.getCsrfToken()` and `verifyCsrfToken()`.
4. **Cross-Site Scripting (XSS):**
   - All user-controlled text rendered via `SecurityUtil.escapeHtml()`.
5. **SQL Injection Defense:**
   - 100% of JDBC SQL queries use parameterized `PreparedStatement`.
