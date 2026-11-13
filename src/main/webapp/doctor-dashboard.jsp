<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    String userId = (String) session.getAttribute("userId");
    String userRole = (String) session.getAttribute("userRole");
    String doctorIdStr = (String) session.getAttribute("doctorId");

    if (userId == null || !"DOCTOR".equalsIgnoreCase(userRole) || doctorIdStr == null) {
        response.sendRedirect("login.jsp?error=Please+log+in+as+a+doctor+to+access+the+doctor+portal.");
        return;
    }

    int doctorId = Integer.parseInt(doctorIdStr);
    String doctorName = (String) session.getAttribute("userFullName");
    String msg = request.getParameter("msg");
    String error = request.getParameter("error");
    String csrfToken = SecurityUtil.getCsrfToken(session);

    int todayCount = 0;
    int upcomingCount = 0;
    int completedCount = 0;
    String specialization = "";
    String deptName = "";
    String roomNo = "";

    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();

        // 1. Doctor Profile
        stmt = conn.prepareStatement(
            "SELECT d.SPECIALIZATION, d.ROOM_NO, dep.DEPARTMENT_NAME " +
            "FROM DOCTORS d JOIN DEPARTMENTS dep ON d.DEPARTMENT_ID = dep.DEPARTMENT_ID WHERE d.DOCTOR_ID = ?"
        );
        stmt.setInt(1, doctorId);
        rs = stmt.executeQuery();
        if (rs.next()) {
            specialization = rs.getString("SPECIALIZATION");
            roomNo = rs.getString("ROOM_NO");
            deptName = rs.getString("DEPARTMENT_NAME");
        }
        DBConnection.close(rs, stmt);

        // 2. Doctor Consultation Counts
        stmt = conn.prepareStatement(
            "SELECT " +
            "  SUM(CASE WHEN APPOINTMENT_DATE = TRUNC(SYSDATE) AND STATUS != 'CANCELLED' THEN 1 ELSE 0 END) AS TODAY_CNT, " +
            "  SUM(CASE WHEN APPOINTMENT_DATE > TRUNC(SYSDATE) AND STATUS = 'BOOKED' THEN 1 ELSE 0 END) AS UPCOMING_CNT, " +
            "  SUM(CASE WHEN STATUS = 'COMPLETED' THEN 1 ELSE 0 END) AS COMPLETED_CNT " +
            "FROM APPOINTMENTS WHERE DOCTOR_ID = ?"
        );
        stmt.setInt(1, doctorId);
        rs = stmt.executeQuery();
        if (rs.next()) {
            todayCount = rs.getInt("TODAY_CNT");
            upcomingCount = rs.getInt("UPCOMING_CNT");
            completedCount = rs.getInt("COMPLETED_CNT");
        }
        DBConnection.close(rs, stmt);

    } catch (Exception e) {
        System.err.println("[doctor-dashboard] Error: " + e.getMessage());
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Doctor Portal - CityHealth HMS</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/doctor.css">
    <link rel="stylesheet" href="css/tables.css">
</head>
<body>

    <jsp:include page="includes/navbar.jsp" />

    <div class="app-layout">
        <!-- Doctor Sidebar -->
        <aside class="sidebar">
            <div class="sidebar-heading">Doctor Console</div>
            <ul class="sidebar-menu">
                <li><a href="doctor-dashboard.jsp" class="active">&#127968; Dashboard</a></li>
                <li><a href="doctor-appointments.jsp">&#128197; My Appointments</a></li>
                <li><a href="prescriptions.jsp">&#128221; Prescriptions</a></li>
                <li><a href="logout.jsp">&#128682; Logout</a></li>
            </ul>
        </aside>

        <!-- Main Workspace -->
        <main class="main-content">
            <div class="staff-topbar">
                <div class="staff-title">
                    <h2><%= SecurityUtil.escapeHtml(doctorName) %></h2>
                    <p class="lead"><%= SecurityUtil.escapeHtml(specialization) %> &bull; <%= SecurityUtil.escapeHtml(deptName) %> &bull; Location: <%= roomNo != null ? roomNo : "OPD Wing" %></p>
                </div>
            </div>

            <% if (msg != null && !msg.trim().isEmpty()) { %>
                <div class="alert alert-success">&#10003; <%= SecurityUtil.escapeHtml(msg) %></div>
            <% } %>
            <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="alert alert-danger">&#9888; <%= SecurityUtil.escapeHtml(error) %></div>
            <% } %>

            <!-- Metric Cards -->
            <div class="grid grid-3" style="margin-bottom: 28px;">
                <div class="stat-card">
                    <div class="stat-icon blue">&#128197;</div>
                    <div class="stat-info">
                        <h4>Today's Patients</h4>
                        <div class="stat-value"><%= todayCount %></div>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon amber">&#9200;</div>
                    <div class="stat-info">
                        <h4>Upcoming Bookings</h4>
                        <div class="stat-value"><%= upcomingCount %></div>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon green">&#9989;</div>
                    <div class="stat-info">
                        <h4>Completed Visits</h4>
                        <div class="stat-value"><%= completedCount %></div>
                    </div>
                </div>
            </div>

            <!-- Today's Patient Queue -->
            <div class="card" style="margin-bottom: 28px;">
                <div class="card-header">
                    <h3 class="card-title">Today's Consultation Schedule (<%= java.time.LocalDate.now().toString() %>)</h3>
                    <a href="doctor-appointments.jsp" style="font-size: 13px; font-weight: 600;">View All Assigned &rarr;</a>
                </div>

                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Slot Time</th>
                                <th>Patient Name</th>
                                <th>Gender / Age</th>
                                <th>Blood Group</th>
                                <th>Reported Symptoms</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                int tCount = 0;
                                try {
                                    stmt = conn.prepareStatement(
                                        "SELECT a.APPOINTMENT_ID, a.APPOINTMENT_TIME, a.REASON, a.STATUS, " +
                                        "p.PATIENT_ID, p.PATIENT_NAME, p.GENDER, p.BLOOD_GROUP, " +
                                        "FLOOR(MONTHS_BETWEEN(SYSDATE, p.DOB)/12) AS AGE " +
                                        "FROM APPOINTMENTS a " +
                                        "JOIN PATIENTS p ON a.PATIENT_ID = p.PATIENT_ID " +
                                        "WHERE a.DOCTOR_ID = ? AND a.APPOINTMENT_DATE = TRUNC(SYSDATE) " +
                                        "ORDER BY a.APPOINTMENT_TIME ASC"
                                    );
                                    stmt.setInt(1, doctorId);
                                    rs = stmt.executeQuery();
                                    while (rs.next()) {
                                        tCount++;
                                        int aId = rs.getInt("APPOINTMENT_ID");
                                        int pId = rs.getInt("PATIENT_ID");
                                        String pName = SecurityUtil.escapeHtml(rs.getString("PATIENT_NAME"));
                                        String gender = SecurityUtil.escapeHtml(rs.getString("GENDER"));
                                        String bGroup = SecurityUtil.escapeHtml(rs.getString("BLOOD_GROUP"));
                                        int age = rs.getInt("AGE");
                                        String reason = SecurityUtil.escapeHtml(rs.getString("REASON"));
                                        String st = rs.getString("STATUS");

                                        String badgeCls = "badge-info";
                                        if ("BOOKED".equalsIgnoreCase(st)) badgeCls = "badge-booked";
                                        else if ("COMPLETED".equalsIgnoreCase(st)) badgeCls = "badge-completed";
                                        else if ("CANCELLED".equalsIgnoreCase(st)) badgeCls = "badge-cancelled";
                            %>
                            <tr>
                                <td><strong><%= rs.getString("APPOINTMENT_TIME") %></strong></td>
                                <td><strong><%= pName %></strong></td>
                                <td><%= gender %>, <%= age %> yrs</td>
                                <td><span class="badge badge-info"><%= (bGroup != null) ? bGroup : "N/A" %></span></td>
                                <td><%= (reason != null && !reason.isEmpty()) ? reason : "--" %></td>
                                <td><span class="badge <%= badgeCls %>"><%= st %></span></td>
                                <td>
                                    <div class="table-actions">
                                        <% if ("BOOKED".equalsIgnoreCase(st)) { %>
                                            <a href="prescriptions.jsp?appointmentId=<%= aId %>" class="btn btn-primary btn-sm">&#9998; Prescribe</a>
                                            <form action="adminAppointmentAction.jsp" method="POST" style="display:inline;">
                                                <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                                                <input type="hidden" name="actionType" value="MARK_COMPLETED">
                                                <input type="hidden" name="appointmentId" value="<%= aId %>">
                                                <button type="submit" class="btn btn-success btn-sm">&#10003; Complete</button>
                                            </form>
                                        <% } else if ("COMPLETED".equalsIgnoreCase(st)) { %>
                                            <a href="prescriptions.jsp?appointmentId=<%= aId %>" class="btn btn-outline btn-sm">View Rx</a>
                                        <% } %>
                                        <a href="patient-details.jsp?patientId=<%= pId %>" class="btn btn-secondary btn-sm">History</a>
                                    </div>
                                </td>
                            </tr>
                            <%
                                    }
                                } catch (Exception e) {
                                    System.err.println("[doctor-dashboard] Queue error: " + e.getMessage());
                                } finally {
                                    DBConnection.close(rs, stmt, conn);
                                }

                                if (tCount == 0) {
                            %>
                            <tr>
                                <td colspan="7" style="text-align: center; padding: 30px; color: var(--text-secondary);">
                                    No patients booked on your consultation roster for today.
                                </td>
                            </tr>
                            <%  } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </main>
    </div>

    <jsp:include page="includes/footer.jsp" />

</body>
</html>
