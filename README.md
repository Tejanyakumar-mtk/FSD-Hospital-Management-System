# CityHealth Hospital Management System (HMS)

> **BTech Computer Science & Engineering Final Year Project**  
> **Architecture:** Java EE Dynamic Web Application (Tomcat 9) &bull; JSP &amp; JDBC &bull; Oracle Database &bull; Vanilla HTML5/CSS3/JavaScript

---

## 1. Project Abstract

The **CityHealth Hospital Management System (HMS)** is a full-stack, enterprise-grade healthcare management application designed to automate outpatient operations, clinical consultation scheduling, electronic prescription generation, and revenue billing. Built with a pure **JSP and JDBC** middleware architecture interacting with an **Oracle Database**, the system provides specialized, secure portals for **Patients**, **Doctors**, and **Hospital Staff / Administrators**.

---

## 2. Technology Stack & Compliance

| Layer | Technologies Used | Notes |
| :--- | :--- | :--- |
| **Frontend** | HTML5, CSS3, Vanilla JavaScript | Responsive design system, zero external UI framework dependencies |
| **Middleware** | JSP (JavaServer Pages) with JDBC only | Standard `javax.servlet` APIs compatible with Apache Tomcat 9 |
| **Database** | Oracle Database Express Edition (XE) | 12 Normalized relational tables, sequences, triggers, constraints, indexes |
| **JDBC Driver** | Oracle JDBC Driver `ojdbc8.jar` | Placed in `WebContent/WEB-INF/lib/` |
| **Application Server**| Apache Tomcat 9.0 (Port 8089) | Configured to prevent conflict with Oracle XE HTTP listener on port 8080 |
| **Java Platform** | Java SE 21 LTS | Fully compatible with Java 11, 17, and 21 runtimes |

---

## 3. Key Functional Modules

### A. Public Website
- **Home (`index.jsp`):** Welcoming hero section, hospital key services, dynamically queried clinical departments, featured medical specialists, booking workflow guide, emergency contact details.
- **About (`about.jsp`):** Hospital background, accreditations (NABH/NABL), clinical philosophy, bed capacity.
- **Doctor Catalog (`doctors.jsp`):** Real-time doctor directory queried from Oracle with specialization, room, consultation fee, and weekly schedules.
- **Authentication (`login.jsp` &amp; `register.jsp`):** Role-based authentication with quick-fill demo buttons for examiners. Patient self-registration with PBKDF2 cryptographic hashing.

### B. Patient Portal
- **Dashboard (`patient-dashboard.jsp`):** Next confirmed appointment banner, statistical cards, recent consultation history.
- **Book Appointment (`book-appointment.jsp`):** Multi-step wizard (Department &rarr; Doctor &rarr; Date &rarr; Available time slot pills &rarr; Reason &rarr; Summary preview). Concurrency-safe slot booking.
- **My Appointments (`patient-appointments.jsp`):** Filter by status (Upcoming, Completed, Cancelled). Cancellation with ownership verification and uncollected bill auto-cancellation.
- **Patient Profile (`patient-profile.jsp`):** Demographics viewer, contact updater, secure PBKDF2 password change.

### C. Doctor Portal
- **Dashboard (`doctor-dashboard.jsp`):** Consultation queue for today, patient vitals summary, quick action buttons.
- **My Consultations (`doctor-appointments.jsp`):** Assigned patient appointments strictly filtered to the authenticated doctor.
- **Patient Details (`patient-details.jsp`):** Authorized access to medical demographics and chronological diagnosis/medication history.
- **Electronic Prescriptions (`prescriptions.jsp` &amp; `savePrescription.jsp`):** Interactive prescription builder with diagnosis, clinical advice, and dynamic multi-medicine item rows. Automatically marks visit `COMPLETED`.

### D. Staff & Administrative Portal
- **Dashboard (`admin-dashboard.jsp`):** 8 Live operational and financial metric cards (Patients, Doctors, Today's Visits, Upcoming, Completed, Cancelled, Realized Revenue, Outstanding Dues).
- **Patient Directory (`patients.jsp`):** Complete CRUD console. Search by ID, name, phone, email. Edit demographics, toggle active/inactive status.
- **Doctor Management (`manage-doctors.jsp`):** Add doctors with consultation fee, room no, qualification, user account, and weekly schedule. Edit and toggle status.
- **Department Management (`departments.jsp`):** Add and configure clinical departments. Referential safety prevents deleting departments with active doctors.
- **Appointment Operations (`appointments.jsp`):** Master appointment schedule, schedule visit on behalf of patient, reschedule dates/slots, update status.

### E. Billing & Financial Module
- **Billing Console (`billing.jsp` &amp; `saveBill.jsp`):** Generate itemized bills with dynamic charge items (Description, Quantity, Unit Price, Line Total). Server-side arithmetic verification.
- **Payment Collection (`recordPayment.jsp`):** Record cash, card, UPI, or insurance payments. Real-time balance recalculation and status tracking (`PENDING`, `PARTIAL`, `PAID`).
- **Tax Invoice (`invoice.jsp`):** Professional, print-ready hospital invoice with `@media print` CSS layout and payment transaction receipt log.

### F. Reports & Analytics Module
- **Reports Console (`reports.jsp`):** Parameterized date-range reporting:
  - Realized revenue vs outstanding balances by date range.
  - Payment collections broken down by payment mode.
  - Appointment distribution across departments, doctors, and completion statuses.
  - Patient demographics by blood group and gender.

---

## 4. Database Schema Structure

The database consists of **12 normalized relational tables** in Oracle:

1. `DEPARTMENTS` - Clinical departments and service centers
2. `DOCTORS` - Doctor credentials, department assignment, fees, rooms
3. `DOCTOR_AVAILABILITY` - Weekly schedule days, start/end times, slot durations
4. `PATIENTS` - Patient demographics, blood groups, emergency contacts
5. `USERS` - Authentication accounts with PBKDF2 hashes, salts, and roles
6. `APPOINTMENTS` - Consultation bookings, dates, times, statuses
7. `PRESCRIPTIONS` - Clinical diagnoses, advice, timestamps
8. `PRESCRIPTION_ITEMS` - Prescribed medicines, dosages, durations, instructions
9. `BILLS` - Patient financial invoices, totals, amounts paid, balances
10. `BILL_ITEMS` - Itemized service and investigation charges
11. `PAYMENTS` - Transaction logs, payment methods, reference numbers
12. `AUDIT_LOG` - System audit trail for security-sensitive events

---

## 5. Security Implementations

- **PBKDF2 Password Hashing:** Utilizes `PBKDF2WithHmacSHA256` with 65,536 iterations and unique 16-byte cryptographic salts generated via `java.security.SecureRandom`.
- **Timing Attack Resistance:** Implements `slowEquals` constant-time string comparison.
- **SQL Injection Prevention:** 100% of database interactions execute through parameterized `java.sql.PreparedStatement`.
- **CSRF Defense:** Synchronizer Token Pattern verified on all state-changing POST forms.
- **XSS Defense:** Context-aware HTML character escaping through `SecurityUtil.escapeHtml()`.
- **Session Protection:** Session fixation defense with identifier regeneration on login and 30-minute idle expiration.

---

## 6. How to Run in Eclipse IDE

1. **Verify Services:** Ensure `OracleServiceXE` and `OracleXETNSListener` are Running.
2. **Execute Database Scripts:** Run `database/01_create_tables.sql`, `02_constraints_indexes.sql`, and `03_sample_data.sql` in Oracle.
3. **Open Project in Eclipse:** Eclipse automatically recognizes the project at `c:\Users\Teja\eclipse-workspace1\HospitalManagementSystem`.
4. **Deploy to Tomcat:** Right click project &rarr; **Run As** &rarr; **Run on Server** &rarr; **Apache Tomcat v9.0**.
5. **Open Browser:** Navigate to `http://localhost:8089/HospitalManagementSystem/`.

---

## 7. Sample Demonstration Credentials

| Role | Username | Password | Purpose |
| :--- | :--- | :--- | :--- |
| **System Admin** | `admin` | `Admin@123` | Full administrative and reporting access |
| **Front Desk Staff** | `reception` | `Recep@123` | Patient registrations, scheduling, billing |
| **Cardiologist** | `dr.sharma` | `Doctor@123` | Doctor consultation queue, electronic prescribing |
| **Neurologist** | `dr.patel` | `Doctor@123` | Doctor consultation queue, electronic prescribing |
| **Patient** | `john.doe` | `Patient@123` | Online booking, appointment management, invoices |

---

## 8. Future Enhancements

- **Telemedicine Integration:** WebRTC-based secure video consultation between doctor and patient.
- **SMS / WhatsApp Gateway:** Automated appointment reminders and SMS verification for password recovery.
- **Laboratory Information System (LIS):** Direct upload of diagnostic radiology images (DICOM) and pathology reports.
- **Inpatient & ICU Bed Tracker:** Real-time bed occupancy and ward admission workflows.
  ---

## Contributors

- Contributed to project development and documentation.
- GitHub: @avinashsai09

- ## Project Documentation

This section provides additional information
about the Hospital Management System.
