<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    String userId = (String) session.getAttribute("userId");
    String userRole = (String) session.getAttribute("userRole");

    if (userId == null || (!"ADMIN".equalsIgnoreCase(userRole) && !"RECEPTIONIST".equalsIgnoreCase(userRole))) {
        response.sendRedirect("login.jsp?error=Access+restricted+to+authorized+hospital+staff.");
        return;
    }

    String staffName = (String) session.getAttribute("userFullName");
    String msg = request.getParameter("msg");
    String error = request.getParameter("error");

    int totalPatients = 0;
    int activeDoctors = 0;
    int todayAppts = 0;
    int upcomingAppts = 0;
    int completedAppts = 0;
    int cancelledAppts = 0;
    double collectedRevenue = 0.00;
    double pendingRevenue = 0.00;

    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();

        // 1. Total Active Patients
        stmt = conn.prepareStatement("SELECT COUNT(*) FROM PATIENTS WHERE ACTIVE = 1");
        rs = stmt.executeQuery();
        if (rs.next()) totalPatients = rs.getInt(1);
        DBConnection.close(rs, stmt);

        // 2. Active Doctors
        stmt = conn.prepareStatement("SELECT COUNT(*) FROM DOCTORS WHERE ACTIVE = 1");
        rs = stmt.executeQuery();
        if (rs.next()) activeDoctors = rs.getInt(1);
        DBConnection.close(rs, stmt);

        // 3. Appointment Metrics
        stmt = conn.prepareStatement(
            "SELECT " +
            "  SUM(CASE WHEN APPOINTMENT_DATE = TRUNC(SYSDATE) AND STATUS != 'CANCELLED' THEN 1 ELSE 0 END) AS TODAY_CNT, " +
            "  SUM(CASE WHEN APPOINTMENT_DATE > TRUNC(SYSDATE) AND STATUS = 'BOOKED' THEN 1 ELSE 0 END) AS UPCOMING_CNT, " +
            "  SUM(CASE WHEN STATUS = 'COMPLETED' THEN 1 ELSE 0 END) AS COMPLETED_CNT, " +
            "  SUM(CASE WHEN STATUS = 'CANCELLED' THEN 1 ELSE 0 END) AS CANCELLED_CNT " +
            "FROM APPOINTMENTS"
        );
        rs = stmt.executeQuery();
        if (rs.next()) {
            todayAppts = rs.getInt("TODAY_CNT");
            upcomingAppts = rs.getInt("UPCOMING_CNT");
            completedAppts = rs.getInt("COMPLETED_CNT");
            cancelledAppts = rs.getInt("CANCELLED_CNT");
        }
        DBConnection.close(rs, stmt);

        // 4. Financial Metrics (Real figures from BILLS and PAYMENTS)
        stmt = conn.prepareStatement(
            "SELECT NVL(SUM(PAID_AMOUNT), 0) AS COLLECTED, NVL(SUM(BALANCE_AMOUNT), 0) AS PENDING FROM BILLS WHERE STATUS != 'CANCELLED'"
        );
        rs = stmt.executeQuery();
        if (rs.next()) {
            collectedRevenue = rs.getDouble("COLLECTED");
            pendingRevenue = rs.getDouble("PENDING");
        }
        DBConnection.close(rs, stmt);

    } catch (Exception e) {
        System.err.println("[admin-dashboard] Metrics error: " + e.getMessage());
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Staff Dashboard - CityHealth HMS</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/staff.css">
    <link rel="stylesheet" href="css/tables.css">
    <script src="js/dashboard.js"></script>
</head>
<body>

    <jsp:include page="includes/navbar.jsp" />

    <div class="app-layout">
        <!-- Staff Sidebar -->
        <aside class="sidebar">
            <div class="sidebar-heading">Staff Console (<%= userRole %>)</div>
            <ul class="sidebar-menu">
                <li><a href="admin-dashboard.jsp" class="active">&#127968; Dashboard</a></li>
                <li><a href="patients.jsp">&#128101; Patients</a></li>
                <li><a href="manage-doctors.jsp">&#128104;&#8205;&#9877;&#65039; Doctors</a></li>
                <li><a href="departments.jsp">&#127973; Departments</a></li>
                <li><a href="appointments.jsp">&#128197; Appointments</a></li>
                <li><a href="billing.jsp">&#128179; Billing &amp; Invoices</a></li>
                <li><a href="reports.jsp">&#128200; Reports &amp; Analytics</a></li>
                <li><a href="logout.jsp">&#128682; Logout</a></li>
            </ul>
        </aside>

        <!-- Main Content -->
        <main class="main-content">
            <div class="staff-topbar">
                <div class="staff-title">
                    <h2>Hospital Administration &amp; Operations</h2>
                    <p>Live operational overview &bull; Logged in as <strong><%= SecurityUtil.escapeHtml(staffName) %></strong> (<%= userRole %>)</p>
                </div>
                <div style="display: flex; gap: 10px;">
                    <a href="patients.jsp?action=new" class="btn btn-primary">+ Register Patient</a>
                    <a href="appointments.jsp?action=new" class="btn btn-secondary">+ Book Visit</a>
                    <a href="billing.jsp?action=new" class="btn btn-success">+ Create Bill</a>
                </div>
            </div>

            <% if (msg != null && !msg.trim().isEmpty()) { %>
                <div class="alert alert-success">&#10003; <%= SecurityUtil.escapeHtml(msg) %></div>
            <% } %>
            <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="alert alert-danger">&#9888; <%= SecurityUtil.escapeHtml(error) %></div>
            <% } %>

            <!-- Live Statistical Metrics (8 Cards) -->
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon blue">&#128101;</div>
                    <div class="stat-info">
                        <h4>Total Patients</h4>
                        <div class="stat-value"><%= totalPatients %></div>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon green">&#128104;&#8205;&#9877;&#65039;</div>
                    <div class="stat-info">
                        <h4>Active Doctors</h4>
                        <div class="stat-value"><%= activeDoctors %></div>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon navy">&#128197;</div>
                    <div class="stat-info">
                        <h4>Today's Visits</h4>
                        <div class="stat-value"><%= todayAppts %></div>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon amber">&#9200;</div>
                    <div class="stat-info">
                        <h4>Upcoming Visits</h4>
                        <div class="stat-value"><%= upcomingAppts %></div>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon green">&#9989;</div>
                    <div class="stat-info">
                        <h4>Completed Visits</h4>
                        <div class="stat-value"><%= completedAppts %></div>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon red">&#10060;</div>
                    <div class="stat-info">
                        <h4>Cancelled Visits</h4>
                        <div class="stat-value"><%= cancelledAppts %></div>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon green">&#8377;</div>
                    <div class="stat-info">
                        <h4>Collected Revenue</h4>
                        <div class="stat-value">&#8377; <%= String.format("%.2f", collectedRevenue) %></div>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon amber">&#128179;</div>
                    <div class="stat-info">
                        <h4>Pending Dues</h4>
                        <div class="stat-value">&#8377; <%= String.format("%.2f", pendingRevenue) %></div>
                    </div>
                </div>
            </div>

            <!-- Today's Appointments List -->
            <div class="card" style="margin-bottom: 28px;">
                <div class="card-header">
                    <h3 class="card-title">Today's Appointment Schedule (<%= java.time.LocalDate.now().toString() %>)</h3>
                    <a href="appointments.jsp" style="font-size: 13px; font-weight: 600;">Manage All Appointments &rarr;</a>
                </div>

                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Ref #</th>
                                <th>Patient Name</th>
                                <th>Doctor</th>
                                <th>Department</th>
                                <th>Slot Time</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                int todayCount = 0;
                                try {
                                    stmt = conn.prepareStatement(
                                        "SELECT a.APPOINTMENT_ID, a.APPOINTMENT_TIME, a.STATUS, " +
                                        "p.PATIENT_NAME, p.PHONE, d.DOCTOR_NAME, dep.DEPARTMENT_NAME " +
                                        "FROM APPOINTMENTS a " +
                                        "JOIN PATIENTS p ON a.PATIENT_ID = p.PATIENT_ID " +
                                        "JOIN DOCTORS d ON a.DOCTOR_ID = d.DOCTOR_ID " +
                                        "JOIN DEPARTMENTS dep ON d.DEPARTMENT_ID = dep.DEPARTMENT_ID " +
                                        "WHERE a.APPOINTMENT_DATE = TRUNC(SYSDATE) " +
                                        "ORDER BY a.APPOINTMENT_TIME ASC"
                                    );
                                    rs = stmt.executeQuery();
                                    while (rs.next()) {
                                        todayCount++;
                                        int aId = rs.getInt("APPOINTMENT_ID");
                                        String pName = SecurityUtil.escapeHtml(rs.getString("PATIENT_NAME"));
                                        String phone = SecurityUtil.escapeHtml(rs.getString("PHONE"));
                                        String dName = SecurityUtil.escapeHtml(rs.getString("DOCTOR_NAME"));
                                        String dept = SecurityUtil.escapeHtml(rs.getString("DEPARTMENT_NAME"));
                                        String aTime = rs.getString("APPOINTMENT_TIME");
                                        String st = rs.getString("STATUS");

                                        String badgeCls = "badge-info";
                                        if ("BOOKED".equalsIgnoreCase(st)) badgeCls = "badge-booked";
                                        else if ("COMPLETED".equalsIgnoreCase(st)) badgeCls = "badge-completed";
                                        else if ("CANCELLED".equalsIgnoreCase(st)) badgeCls = "badge-cancelled";
                            %>
                            <tr>
                                <td>#<%= aId %></td>
                                <td><strong><%= pName %></strong><br><span style="font-size: 12px; color: var(--text-secondary);"><%= phone %></span></td>
                                <td><%= dName %></td>
                                <td><%= dept %></td>
                                <td><strong><%= aTime %></strong></td>
                                <td><span class="badge <%= badgeCls %>"><%= st %></span></td>
                                <td>
                                    <div class="table-actions">
                                        <% if ("BOOKED".equalsIgnoreCase(st)) { %>
                                            <a href="appointments.jsp?markCompleted=<%= aId %>" class="btn btn-success btn-sm">&#10003; Complete</a>
                                            <a href="cancelAppointment.jsp?appointmentId=<%= aId %>" class="btn btn-danger btn-sm">Cancel</a>
                                        <% } else { %>
                                            <span style="font-size: 13px; color: var(--text-muted);">&#10003; Logged</span>
                                        <% } %>
                                    </div>
                                </td>
                            </tr>
                            <%
                                    }
                                } catch (Exception e) {
                                    System.err.println("[admin-dashboard] Today appt error: " + e.getMessage());
                                } finally {
                                    DBConnection.close(rs, stmt);
                                }

                                if (todayCount == 0) {
                            %>
                            <tr>
                                <td colspan="7" style="text-align: center; padding: 24px; color: var(--text-secondary);">
                                    No appointments scheduled for today yet.
                                </td>
                            </tr>
                            <%  } %>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Recent Patient Registrations -->
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">Recent Patient Registrations</h3>
                    <a href="patients.jsp" style="font-size: 13px; font-weight: 600;">View Patient Directory &rarr;</a>
                </div>

                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Patient ID</th>
                                <th>Name</th>
                                <th>Gender / Age</th>
                                <th>Phone</th>
                                <th>Email</th>
                                <th>Registered On</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                int patCount = 0;
                                try {
                                    stmt = conn.prepareStatement(
                                        "SELECT PATIENT_ID, PATIENT_NAME, GENDER, PHONE, EMAIL, ACTIVE, " +
                                        "TO_CHAR(CREATED_AT, 'YYYY-MM-DD HH24:MI') AS REG_DATE " +
                                        "FROM PATIENTS ORDER BY PATIENT_ID DESC"
                                    );
                                    rs = stmt.executeQuery();
                                    while (rs.next() && patCount < 5) {
                                        patCount++;
                                        int pId = rs.getInt("PATIENT_ID");
                                        String pName = SecurityUtil.escapeHtml(rs.getString("PATIENT_NAME"));
                                        String gender = SecurityUtil.escapeHtml(rs.getString("GENDER"));
                                        String phone = SecurityUtil.escapeHtml(rs.getString("PHONE"));
                                        String email = SecurityUtil.escapeHtml(rs.getString("EMAIL"));
                                        String regDate = rs.getString("REG_DATE");
                                        int act = rs.getInt("ACTIVE");
                            %>
                            <tr>
                                <td>#<%= pId %></td>
                                <td><strong><%= pName %></strong></td>
                                <td><%= gender %></td>
                                <td><%= phone %></td>
                                <td><%= email %></td>
                                <td><%= regDate %></td>
                                <td>
                                    <span class="badge <%= (act == 1) ? "badge-success" : "badge-danger" %>">
                                        <%= (act == 1) ? "ACTIVE" : "INACTIVE" %>
                                    </span>
                                </td>
                            </tr>
                            <%
                                    }
                                } catch (Exception e) {
                                    System.err.println("[admin-dashboard] Recent patients error: " + e.getMessage());
                                } finally {
                                    DBConnection.close(rs, stmt, conn);
                                }
                            %>
                        </tbody>
                    </table>
                </div>
            </div>
        </main>
    </div>

    <jsp:include page="includes/footer.jsp" />

</body>
</html>
