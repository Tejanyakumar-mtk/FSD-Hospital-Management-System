# Deployment & Configuration Guide - Hospital Management System

This guide outlines the exact steps to configure, deploy, and execute the Hospital Management System in **Eclipse IDE** with **Apache Tomcat 9** and **Oracle Database**.

---

## 1. System Requirements & Compatibility

| Software Component | Verified Specification |
| :--- | :--- |
| **Operating System** | Windows 10 / 11 (64-bit) |
| **Java Development Kit** | Java SE 21 LTS (or Java 11/17) |
| **Web Server / Servlet Engine** | Apache Tomcat 9.0 (Java EE / `javax.servlet` compliant) |
| **Database Server** | Oracle Database Express Edition 10g / 11g / 19c / 21c XE |
| **JDBC Driver** | Oracle JDBC Driver `ojdbc8.jar` (located in `WebContent/WEB-INF/lib/`) |
| **Development Environment** | Eclipse IDE for Enterprise Java and Web Developers |

---

## 2. Server Port Configuration (Port 8089)

> [!IMPORTANT]
> Oracle Database Express Edition (XE) includes an embedded HTTP listener that defaults to port `8080`. To avoid port collision, Apache Tomcat 9 on this system is configured to listen on HTTP port **`8089`**.

Verify this in Tomcat's `conf/server.xml`:
```xml
<Connector port="8089" protocol="HTTP/1.1"
           connectionTimeout="20000"
           redirectPort="8443" />
```

---

## 3. Database Connectivity Configuration

Database credentials are maintained in `WebContent/WEB-INF/classes/db.properties` and `src/main/java/db.properties`:

```properties
db.driver=oracle.jdbc.driver.OracleDriver
db.url=jdbc:oracle:thin:@localhost:1521:xe
db.user=hospital_db
db.password=hospital123
```

Ensure Oracle services are running:
```powershell
Get-Service -Name "OracleServiceXE", "OracleXETNSListener"
```
If stopped, start them via Windows Services (`services.msc`) or PowerShell:
```powershell
Start-Service OracleServiceXE
Start-Service OracleXETNSListener
```

---

## 4. Running the Project in Eclipse IDE

### Step 1: Open Eclipse Workspace
1. Launch **Eclipse IDE**.
2. Select workspace: `C:\Users\Teja\eclipse-workspace1`.
3. The project `HospitalManagementSystem` will appear directly in the **Project Explorer**.

### Step 2: Verify Server Runtime in Eclipse
1. Go to **Window** &rarr; **Preferences** &rarr; **Server** &rarr; **Runtime Environments**.
2. Confirm **Apache Tomcat v9.0** is registered and points to `C:\Program Files\Apache Software Foundation\Tomcat 9.0`.
3. In the **Servers** tab at the bottom of Eclipse, double-click the Tomcat v9.0 server and ensure the HTTP port matches `8089`.

### Step 3: Run the Application
1. In the **Project Explorer**, right-click `HospitalManagementSystem`.
2. Click **Run As** &rarr; **1 Run on Server**.
3. Select **Apache Tomcat v9.0 at localhost** and click **Finish**.
4. Eclipse will automatically compile the classes into `build/classes`, publish resources, and launch Tomcat.

---

## 5. Accessing the Application

Open your browser and navigate to:
```
http://localhost:8089/HospitalManagementSystem/
```

### Demonstration Workflows:

1. **Patient Booking Flow:**
   - Go to `http://localhost:8089/HospitalManagementSystem/`
   - Click **Book an Appointment** &rarr; logs in with `john.doe` / `Patient@123`.
   - Select Department (e.g., Cardiology), Specialist (Dr. Rajesh Sharma), Date, and Slot (`10:00`).
   - Confirm booking &rarr; see immediate appointment ID generation and booking confirmation.
2. **Doctor Consultation Flow:**
   - Log out &rarr; log in with `dr.sharma` / `Doctor@123`.
   - View assigned patient roster on the Doctor Dashboard.
   - Click **Prescribe** &rarr; enter diagnosis and add prescribed medications &rarr; save prescription.
3. **Staff & Billing Flow:**
   - Log out &rarr; log in with `admin` / `Admin@123` or `reception` / `Recep@123`.
   - Access **Billing & Invoices** &rarr; generate bill or record payment receipt &rarr; print printable invoice.
   - Access **Reports & Analytics** &rarr; generate financial and appointment statistics.

---

## 6. Troubleshooting Common Issues

### Issue 1: `java.lang.ClassNotFoundException: oracle.jdbc.driver.OracleDriver`
- **Cause:** Oracle JDBC driver JAR is missing from deployment library.
- **Fix:** Confirm `ojdbc8.jar` exists inside `WebContent/WEB-INF/lib/`. In Eclipse, right-click project &rarr; **Properties** &rarr; **Deployment Assembly** &rarr; verify `WebContent/WEB-INF/lib` is mapped.

### Issue 2: `ORA-12541: TNS:no listener` or `Connection refused`
- **Cause:** Oracle TNS Listener service is stopped.
- **Fix:** Run `Start-Service OracleXETNSListener` in an Administrator PowerShell.

### Issue 3: `ORA-01017: invalid username/password; logon denied`
- **Cause:** Mismatched database credentials in `db.properties`.
- **Fix:** Verify user `hospital_db` and password `hospital123` match what was created in Oracle.

### Issue 4: `Address already in use: bind` (Tomcat fails to start)
- **Cause:** Another process or background Tomcat instance is occupying port 8089.
- **Fix:** Run `Get-Process -Id (Get-NetTCPConnection -LocalPort 8089).OwningProcess | Stop-Process -Force` to free the port.
