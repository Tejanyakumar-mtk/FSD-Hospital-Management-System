# Test Cases & Verification Report - Hospital Management System

This document contains test specifications, preconditions, steps, expected outcomes, and verification results across all modules of the system.

---

## 1. Authentication & Security Test Cases

| Test ID | Module | Description | Preconditions | Test Steps | Expected Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-AUTH-01** | Auth | Valid Administrator Login | Admin account exists in Oracle | 1. Enter `admin`<br>2. Enter `Admin@123`<br>3. Submit form | Authenticated, new session ID created, redirected to `admin-dashboard.jsp` | **PASS** |
| **TC-AUTH-02** | Auth | Valid Patient Login | Patient account exists | 1. Enter `john.doe`<br>2. Enter `Patient@123`<br>3. Submit | Authenticated, session stores `patientId`, redirected to `patient-dashboard.jsp` | **PASS** |
| **TC-AUTH-03** | Auth | Valid Doctor Login | Doctor account exists | 1. Enter `dr.sharma`<br>2. Enter `Doctor@123`<br>3. Submit | Authenticated, session stores `doctorId`, redirected to `doctor-dashboard.jsp` | **PASS** |
| **TC-AUTH-04** | Auth | Invalid Password Attempt | Registered user exists | 1. Enter `admin`<br>2. Enter `WrongPass!`<br>3. Submit | Access denied, generic error "Invalid username or password" displayed | **PASS** |
| **TC-AUTH-05** | Auth | Non-existent Username | User does not exist | 1. Enter `unknown_user`<br>2. Enter `AnyPass123`<br>3. Submit | Access denied, generic error displayed without revealing username existence | **PASS** |
| **TC-AUTH-06** | Auth | Role Access Enforcement | Active patient session | 1. Direct URL access to `admin-dashboard.jsp` | Access rejected; redirected to login with unauthorized error | **PASS** |
| **TC-AUTH-07** | Auth | Patient Self-Registration | Fresh browser session | 1. Open `register.jsp`<br>2. Fill demographics<br>3. Enter unique username & password<br>4. Submit | Transaction commits records to `PATIENTS` and `USERS`; redirected to login with success | **PASS** |
| **TC-AUTH-08** | Auth | Duplicate Username Rejection | Existing username `john.doe` | 1. Open `register.jsp`<br>2. Enter username `john.doe`<br>3. Submit | Transaction rolls back; error "Username is already taken" displayed | **PASS** |
| **TC-AUTH-09** | Auth | CSRF Token Validation | State-changing POST form | 1. Submit POST request with tampered or omitted `csrfToken` | Request rejected; error "Security token validation failed" returned | **PASS** |
| **TC-AUTH-10** | Auth | Logout Invalidation | Active session | 1. Click Logout link | Session invalidated, `AUDIT_LOG` entry recorded, redirected to login | **PASS** |

---

## 2. Patient Management Test Cases

| Test ID | Module | Description | Preconditions | Test Steps | Expected Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-PAT-01** | Patient | Staff Registers Patient | Logged in as Admin/Receptionist | 1. Open `patients.jsp`<br>2. Click "+ Register New Patient"<br>3. Fill details and credentials<br>4. Submit | Record inserted with `SEQ_PATIENTS.NEXTVAL`, appears immediately in directory | **PASS** |
| **TC-PAT-02** | Patient | Search by Name / Phone / ID | Patients exist in database | 1. Enter "John" or "9876543210" in search bar<br>2. Click Search | Table filters dynamically to matching patients | **PASS** |
| **TC-PAT-03** | Patient | Edit Patient Demographics | Patient record exists | 1. Click "Edit" on patient row<br>2. Modify phone and address<br>3. Submit update | Database updated; reflects on patient table and invoice | **PASS** |
| **TC-PAT-04** | Patient | Deactivate Patient Record | Active patient exists | 1. Click "Deactivate" button<br>2. Confirm dialog | `ACTIVE` set to 0 in both `PATIENTS` and `USERS`; status shows INACTIVE | **PASS** |
| **TC-PAT-05** | Patient | Patient Updates Own Profile | Logged in as Patient | 1. Open `patient-profile.jsp`<br>2. Update residential address<br>3. Save | Profile updated; changes persisted in Oracle | **PASS** |

---

## 3. Doctor & Department Management Test Cases

| Test ID | Module | Description | Preconditions | Test Steps | Expected Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-DOC-01** | Doctor | Add New Medical Doctor | Logged in as Admin | 1. Open `manage-doctors.jsp`<br>2. Fill doctor info, fee, room, and credentials<br>3. Submit | Doctor record created, user login generated, default schedules added | **PASS** |
| **TC-DOC-02** | Doctor | Update Consultation Fee & Room | Doctor exists | 1. Click "Edit" on doctor row<br>2. Change fee to `650.00`<br>3. Submit | Oracle updated; new fee reflects on booking page and billing | **PASS** |
| **TC-DOC-03** | Dept | Create New Department | Logged in as Admin | 1. Open `departments.jsp`<br>2. Click "+ Add Department"<br>3. Enter "Oncology"<br>4. Save | Department inserted with `SEQ_DEPARTMENTS.NEXTVAL`; visible in dropdowns | **PASS** |
| **TC-DOC-04** | Dept | Prevent Unsafe Dept Deactivation | Active doctors belong to department | 1. Attempt to deactivate "Cardiology" | Deactivation blocked with warning: "Cannot deactivate department while active doctors are assigned" | **PASS** |

---

## 4. Appointment Scheduling Test Cases

| Test ID | Module | Description | Preconditions | Test Steps | Expected Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-APT-01** | Booking | Patient Books Appointment | Logged in as Patient | 1. Open `book-appointment.jsp`<br>2. Select doctor & future date<br>3. Choose slot `11:00`<br>4. Confirm | Appointment saved (`STATUS = 'BOOKED'`), initial pending bill generated | **PASS** |
| **TC-APT-02** | Booking | Prevent Past Date Selection | Logged in as Patient | 1. Enter past date in appointment form | Browser & server validation rejects date earlier than `LocalDate.now()` | **PASS** |
| **TC-APT-03** | Booking | Prevent Double-Booking (Conflict) | Existing booking for Dr. Sharma at `10:00` | 1. Attempt to book same doctor on same date at `10:00` | Server-side transaction detects conflict, rolls back, displays slot unavailable error | **PASS** |
| **TC-APT-04** | Booking | Patient Cancels Own Appointment | Patient has active `BOOKED` visit | 1. Click "Cancel" in `patient-appointments.jsp`<br>2. Confirm | `STATUS` set to `CANCELLED`, pending uncollected bill marked cancelled | **PASS** |
| **TC-APT-05** | Booking | Prevent Unauthorized Cancellation | Patient A logged in | 1. Attempt to POST cancellation for Patient B's appointment | Server verifies ownership against session `patientId`; unauthorized rejection returned | **PASS** |
| **TC-APT-06** | Booking | Staff Reschedules Appointment | Active booking exists | 1. Open `appointments.jsp`<br>2. Click Reschedule<br>3. Choose new date & slot<br>4. Save | Date and time updated in Oracle; logged in `AUDIT_LOG` | **PASS** |

---

## 5. Clinical & Prescription Test Cases

| Test ID | Module | Description | Preconditions | Test Steps | Expected Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-RX-01** | Doctor | Author Prescription & Complete Visit | Doctor logged in with assigned visit | 1. Open `prescriptions.jsp?appointmentId=5001`<br>2. Enter diagnosis<br>3. Add 2 medicine rows<br>4. Submit | Prescription and items saved in transaction; appointment status auto-updates to `COMPLETED` | **PASS** |
| **TC-RX-02** | Doctor | Prevent Prescribing for Another Doctor's Patient | Doctor A logged in | 1. Doctor A attempts to prescribe for Doctor B's appointment ID | Access rejected: "Unauthorized: You cannot prescribe for another doctor's patient" | **PASS** |
| **TC-RX-03** | Doctor | View Authorized Patient History | Attending doctor logged in | 1. Open `patient-details.jsp?patientId=1001` | Displays demographics and previous diagnosis history | **PASS** |

---

## 6. Billing & Reports Test Cases

| Test ID | Module | Description | Preconditions | Test Steps | Expected Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-BIL-01** | Billing | Create Itemized Bill | Logged in as Staff | 1. Open `billing.jsp`<br>2. Select patient<br>3. Add 2 services (500 + 200)<br>4. Save | Server calculates total 700.00; inserts into `BILLS` and `BILL_ITEMS` | **PASS** |
| **TC-BIL-02** | Billing | Record Partial Payment | Bill with balance 700.00 | 1. Click "+ Pay"<br>2. Pay 400.00 via UPI<br>3. Submit | `PAID_AMOUNT = 400.00`, `BALANCE_AMOUNT = 300.00`, status set to `PARTIAL` | **PASS** |
| **TC-BIL-03** | Billing | Settle Full Balance | Bill with balance 300.00 | 1. Pay 300.00 via Cash<br>2. Submit | `BALANCE_AMOUNT = 0.00`, status updates to `PAID` | **PASS** |
| **TC-BIL-04** | Billing | Prevent Overpayment | Bill with balance 250.00 | 1. Attempt to record payment of 300.00 | Server blocks submission: "Payment amount cannot exceed outstanding balance" | **PASS** |
| **TC-BIL-05** | Billing | Generate Printable Invoice | Valid bill exists | 1. Click "Invoice" button | Invoice displays patient details, doctor, itemized lines, and payments with `@media print` layout | **PASS** |
| **TC-REP-01** | Reports | Financial Collections Report | Billing transactions exist | 1. Open `reports.jsp?tab=FINANCIAL`<br>2. Select date range | Aggregates total billed, realized collections, and payment modes breakdown | **PASS** |
| **TC-REP-02** | Reports | Appointment Status Summary | Consultations exist | 1. Open `reports.jsp?tab=APPOINTMENTS` | Displays visit counts by department and doctor across Booked, Completed, Cancelled | **PASS** |
| **TC-REP-03** | Reports | Empty Date Range Graceful Handling | Future date range selected | 1. Select date range with no records | Displays clean empty state without exceptions or SQL errors | **PASS** |
