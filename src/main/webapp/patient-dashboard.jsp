<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    // Session Guard: Patient role only
    String userId = (String) session.getAttribute("userId");
    String userRole = (String) session.getAttribute("userRole");
    String patientIdStr = (String) session.getAttribute("patientId");

    if (userId == null || !"PATIENT".equalsIgnoreCase(userRole) || patientIdStr == null) {
        response.sendRedirect("login.jsp?error=Please+login+as+a+patient+to+access+the+dashboard.&returnUrl=patient-dashboard.jsp");
        return;
    }

    int patientId = Integer.parseInt(patientIdStr);
    String patientName = (String) session.getAttribute("userFullName");

    String msg = request.getParameter("msg");
    String error = request.getParameter("error");

    int totalAppts = 0;
    int upcomingAppts = 0;
    int completedAppts = 0;

    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();

        // 1. Fetch Summary Counts
        stmt = conn.prepareStatement(
            "SELECT " +
            "  COUNT(*) AS TOTAL, " +
            "  SUM(CASE WHEN STATUS = 'BOOKED' AND APPOINTMENT_DATE >= TRUNC(SYSDATE) THEN 1 ELSE 0 END) AS UPCOMING, " +
            "  SUM(CASE WHEN STATUS = 'COMPLETED' THEN 1 ELSE 0 END) AS COMPLETED " +
            "FROM APPOINTMENTS WHERE PATIENT_ID = ?"
        );
        stmt.setInt(1, patientId);
        rs = stmt.executeQuery();
        if (rs.next()) {
            totalAppts = rs.getInt("TOTAL");
            upcomingAppts = rs.getInt("UPCOMING");
            completedAppts = rs.getInt("COMPLETED");
        }
    } catch (Exception e) {
        System.err.println("[patient-dashboard] Stats error: " + e.getMessage());
    } finally {
        DBConnection.close(rs, stmt);
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Patient Dashboard - CityHealth HMS</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/patient.css">
    <link rel="stylesheet" href="css/tables.css">
    <script src="js/patient.js"></script>
</head>
<body>

    <jsp:include page="includes/navbar.jsp" />

    <div class="app-layout">
        <!-- Sidebar Navigation -->
        <aside class="sidebar">
            <div class="sidebar-heading">Patient Menu</div>
            <ul class="sidebar-menu">
                <li><a href="patient-dashboard.jsp" class="active">&#127968; Dashboard</a></li>
                <li><a href="book-appointment.jsp">&#128197; Book Appointment</a></li>
                <li><a href="patient-appointments.jsp">&#128203; My Appointments</a></li>
                <li><a href="doctors.jsp">&#128104;&#8205;&#9877;&#65039; Find Doctors</a></li>
                <li><a href="patient-profile.jsp">&#128100; My Profile</a></li>
                <li><a href="logout.jsp">&#128682; Logout</a></li>
            </ul>
        </aside>

        <!-- Main Workspace -->
        <main class="main-content">
            <div class="flex-between" style="margin-bottom: 24px;">
                <div>
                    <h2>Welcome back, <%= SecurityUtil.escapeHtml(patientName) %></h2>
                    <p class="lead">Patient ID: <strong>#<%= patientId %></strong> &bull; Manage your consultations and medical records</p>
                </div>
                <div>
                    <a href="book-appointment.jsp" class="btn btn-primary btn-lg">+ Book New Appointment</a>
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
                    <div class="stat-icon navy">&#128203;</div>
                    <div class="stat-info">
                        <h4>Total Consultations</h4>
                        <div class="stat-value"><%= totalAppts %></div>
                    </div>
                </div>
            </div>

            <!-- Next Upcoming Appointment Banner -->
            <%
                PreparedStatement nextStmt = null;
                ResultSet nextRs = null;
                boolean hasUpcoming = false;
                try {
                    nextStmt = conn.prepareStatement(
                        "SELECT a.APPOINTMENT_ID, TO_CHAR(a.APPOINTMENT_DATE, 'YYYY-MM-DD') AS APPT_DATE, " +
                        "a.APPOINTMENT_TIME, a.REASON, d.DOCTOR_NAME, d.SPECIALIZATION, d.ROOM_NO, dep.DEPARTMENT_NAME " +
                        "FROM APPOINTMENTS a " +
                        "JOIN DOCTORS d ON a.DOCTOR_ID = d.DOCTOR_ID " +
                        "JOIN DEPARTMENTS dep ON d.DEPARTMENT_ID = dep.DEPARTMENT_ID " +
                        "WHERE a.PATIENT_ID = ? AND a.STATUS = 'BOOKED' AND a.APPOINTMENT_DATE >= TRUNC(SYSDATE) " +
                        "ORDER BY a.APPOINTMENT_DATE ASC, a.APPOINTMENT_TIME ASC"
                    );
                    nextStmt.setInt(1, patientId);
                    nextRs = nextStmt.executeQuery();
                    if (nextRs.next()) {
                        hasUpcoming = true;
            %>
            <div class="card" style="border-left: 5px solid var(--primary); margin-bottom: 28px; background: #ffffff;">
                <div class="card-header" style="border: none; margin: 0; padding: 0 0 10px 0;">
                    <span class="badge badge-booked">Next Confirmed Visit</span>
                    <span style="font-size: 13px; color: var(--text-secondary);">Ref ID: #<%= nextRs.getInt("APPOINTMENT_ID") %></span>
                </div>
                <div class="grid grid-3" style="align-items: center;">
                    <div>
                        <h3 style="margin-bottom: 4px;"><%= SecurityUtil.escapeHtml(nextRs.getString("DOCTOR_NAME")) %></h3>
                        <p style="color: var(--text-secondary); font-size: 13.5px;"><%= SecurityUtil.escapeHtml(nextRs.getString("SPECIALIZATION")) %> &bull; <%= SecurityUtil.escapeHtml(nextRs.getString("DEPARTMENT_NAME")) %></p>
                    </div>
                    <div>
                        <div style="font-size: 14px;"><strong>Date:</strong> <%= nextRs.getString("APPT_DATE") %></div>
                        <div style="font-size: 14px;"><strong>Time:</strong> <%= nextRs.getString("APPOINTMENT_TIME") %></div>
                        <div style="font-size: 13px; color: var(--text-secondary);">Room: <%= nextRs.getString("ROOM_NO") != null ? nextRs.getString("ROOM_NO") : "Main OPD" %></div>
                    </div>
                    <div style="text-align: right;">
                        <a href="patient-appointments.jsp" class="btn btn-outline btn-sm">Manage Appointment &rarr;</a>
                    </div>
                </div>
            </div>
            <%
                    }
                } catch (Exception e) {
                    System.err.println("[patient-dashboard] Upcoming lookup error: " + e.getMessage());
                } finally {
                    DBConnection.close(nextRs, nextStmt);
                }

                if (!hasUpcoming) {
            %>
            <div class="card" style="padding: 16px 20px; margin-bottom: 28px; background: #f8fafc; display:flex; justify-content:space-between; align-items:center;">
                <div>
                    <strong style="color: var(--secondary);">No upcoming appointments scheduled.</strong>
                    <p style="font-size: 13px; color: var(--text-secondary); margin: 0;">Need to consult a doctor? Book a slot with our senior physicians.</p>
                </div>
                <a href="book-appointment.jsp" class="btn btn-primary btn-sm">Book Visit</a>
            </div>
            <%  } %>

            <!-- Recent Appointments Table -->
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">Recent Appointment History</h3>
                    <a href="patient-appointments.jsp" style="font-size: 13px; font-weight: 600;">View All &rarr;</a>
                </div>

                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Doctor</th>
                                <th>Department</th>
                                <th>Date &amp; Time</th>
                                <th>Reason</th>
                                <th>Status</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                PreparedStatement histStmt = null;
                                ResultSet histRs = null;
                                int rowCount = 0;
                                try {
                                    histStmt = conn.prepareStatement(
                                        "SELECT a.APPOINTMENT_ID, TO_CHAR(a.APPOINTMENT_DATE, 'YYYY-MM-DD') AS APPT_DATE, " +
                                        "a.APPOINTMENT_TIME, a.REASON, a.STATUS, d.DOCTOR_NAME, dep.DEPARTMENT_NAME " +
                                        "FROM APPOINTMENTS a " +
                                        "JOIN DOCTORS d ON a.DOCTOR_ID = d.DOCTOR_ID " +
                                        "JOIN DEPARTMENTS dep ON d.DEPARTMENT_ID = dep.DEPARTMENT_ID " +
                                        "WHERE a.PATIENT_ID = ? " +
                                        "ORDER BY a.APPOINTMENT_DATE DESC, a.APPOINTMENT_TIME DESC"
                                    );
                                    histStmt.setInt(1, patientId);
                                    histRs = histStmt.executeQuery();
                                    while (histRs.next() && rowCount < 5) {
                                        rowCount++;
                                        int apptId = histRs.getInt("APPOINTMENT_ID");
                                        String docName = SecurityUtil.escapeHtml(histRs.getString("DOCTOR_NAME"));
                                        String deptName = SecurityUtil.escapeHtml(histRs.getString("DEPARTMENT_NAME"));
                                        String apptDate = histRs.getString("APPT_DATE");
                                        String apptTime = histRs.getString("APPOINTMENT_TIME");
                                        String reason = SecurityUtil.escapeHtml(histRs.getString("REASON"));
                                        String status = histRs.getString("STATUS");

                                        String badgeClass = "badge-info";
                                        if ("BOOKED".equalsIgnoreCase(status)) badgeClass = "badge-booked";
                                        else if ("COMPLETED".equalsIgnoreCase(status)) badgeClass = "badge-completed";
                                        else if ("CANCELLED".equalsIgnoreCase(status)) badgeClass = "badge-cancelled";
                            %>
                            <tr>
                                <td>#<%= apptId %></td>
                                <td><strong><%= docName %></strong></td>
                                <td><%= deptName %></td>
                                <td><%= apptDate %> &bull; <%= apptTime %></td>
                                <td><%= (reason != null && !reason.isEmpty()) ? reason : "--" %></td>
                                <td><span class="badge <%= badgeClass %>"><%= status %></span></td>
                                <td>
                                    <% if ("BOOKED".equalsIgnoreCase(status)) { %>
                                        <form action="cancelAppointment.jsp" method="POST" style="display:inline;" onsubmit="return confirmCancelAppointment(<%= apptId %>);">
                                            <input type="hidden" name="csrfToken" value="<%= SecurityUtil.getCsrfToken(session) %>">
                                            <input type="hidden" name="appointmentId" value="<%= apptId %>">
                                            <button type="submit" class="btn btn-danger btn-sm">Cancel</button>
                                        </form>
                                    <% } else if ("COMPLETED".equalsIgnoreCase(status)) { %>
                                        <a href="prescriptions.jsp?appointmentId=<%= apptId %>" class="btn btn-outline btn-sm">Prescription</a>
                                    <% } else { %>
                                        <span style="color: var(--text-muted); font-size: 13px;">None</span>
                                    <% } %>
                                </td>
                            </tr>
                            <%
                                    }
                                } catch (Exception e) {
                                    System.err.println("[patient-dashboard] History error: " + e.getMessage());
                                } finally {
                                    DBConnection.close(histRs, histStmt, conn);
                                }

                                if (rowCount == 0) {
                            %>
                            <tr>
                                <td colspan="7" style="text-align:center; padding: 30px; color: var(--text-secondary);">
                                    You have not booked any appointments yet.
                                    <div style="margin-top: 10px;">
                                        <a href="book-appointment.jsp" class="btn btn-primary btn-sm">Book Your First Appointment</a>
                                    </div>
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
