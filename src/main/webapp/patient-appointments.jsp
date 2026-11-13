<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    String userId = (String) session.getAttribute("userId");
    String userRole = (String) session.getAttribute("userRole");
    String patientIdStr = (String) session.getAttribute("patientId");

    if (userId == null || !"PATIENT".equalsIgnoreCase(userRole) || patientIdStr == null) {
        response.sendRedirect("login.jsp?error=Please+log+in+as+a+patient+to+view+appointments.");
        return;
    }

    int patientId = Integer.parseInt(patientIdStr);
    String filter = request.getParameter("filter");
    if (filter == null) filter = "ALL";

    String msg = request.getParameter("msg");
    String error = request.getParameter("error");
    String csrfToken = SecurityUtil.getCsrfToken(session);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Appointments - CityHealth HMS</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/patient.css">
    <link rel="stylesheet" href="css/tables.css">
    <script src="js/patient.js"></script>
    <script src="js/dashboard.js"></script>
</head>
<body>

    <jsp:include page="includes/navbar.jsp" />

    <div class="app-layout">
        <aside class="sidebar">
            <div class="sidebar-heading">Patient Menu</div>
            <ul class="sidebar-menu">
                <li><a href="patient-dashboard.jsp">&#127968; Dashboard</a></li>
                <li><a href="book-appointment.jsp">&#128197; Book Appointment</a></li>
                <li><a href="patient-appointments.jsp" class="active">&#128203; My Appointments</a></li>
                <li><a href="doctors.jsp">&#128104;&#8205;&#9877;&#65039; Find Doctors</a></li>
                <li><a href="patient-profile.jsp">&#128100; My Profile</a></li>
                <li><a href="logout.jsp">&#128682; Logout</a></li>
            </ul>
        </aside>

        <main class="main-content">
            <div class="flex-between" style="margin-bottom: 24px;">
                <div>
                    <h2>My Consultations &amp; Appointments</h2>
                    <p class="lead">View your scheduled, completed, and past consultation history.</p>
                </div>
                <a href="book-appointment.jsp" class="btn btn-primary">+ Book New Appointment</a>
            </div>

            <% if (msg != null && !msg.trim().isEmpty()) { %>
                <div class="alert alert-success">&#10003; <%= SecurityUtil.escapeHtml(msg) %></div>
            <% } %>
            <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="alert alert-danger">&#9888; <%= SecurityUtil.escapeHtml(error) %></div>
            <% } %>

            <!-- Filter and Search Toolbar -->
            <div class="table-toolbar">
                <div class="table-search">
                    <input type="text" id="apptSearch" placeholder="Search doctor, date, status..." onkeyup="filterTable('apptSearch', 'appointmentTable')">
                </div>
                <div class="table-filters">
                    <a href="patient-appointments.jsp?filter=ALL" class="btn btn-sm <%= "ALL".equals(filter) ? "btn-primary" : "btn-outline" %>">All</a>
                    <a href="patient-appointments.jsp?filter=BOOKED" class="btn btn-sm <%= "BOOKED".equals(filter) ? "btn-primary" : "btn-outline" %>">Upcoming</a>
                    <a href="patient-appointments.jsp?filter=COMPLETED" class="btn btn-sm <%= "COMPLETED".equals(filter) ? "btn-primary" : "btn-outline" %>">Completed</a>
                    <a href="patient-appointments.jsp?filter=CANCELLED" class="btn btn-sm <%= "CANCELLED".equals(filter) ? "btn-primary" : "btn-outline" %>">Cancelled</a>
                </div>
            </div>

            <!-- Appointments Table -->
            <div class="card" style="padding: 0; overflow: hidden;">
                <div class="table-responsive">
                    <table class="table table-hover" id="appointmentTable">
                        <thead>
                            <tr>
                                <th>Appt #</th>
                                <th>Doctor</th>
                                <th>Specialization</th>
                                <th>Department</th>
                                <th>Date &amp; Time</th>
                                <th>Reason</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                Connection conn = null;
                                PreparedStatement stmt = null;
                                ResultSet rs = null;
                                int count = 0;
                                try {
                                    conn = DBConnection.getConnection();
                                    StringBuilder sql = new StringBuilder(
                                        "SELECT a.APPOINTMENT_ID, TO_CHAR(a.APPOINTMENT_DATE, 'YYYY-MM-DD') AS APPT_DATE, " +
                                        "a.APPOINTMENT_TIME, a.REASON, a.STATUS, a.CANCELLATION_REASON, " +
                                        "d.DOCTOR_NAME, d.SPECIALIZATION, dep.DEPARTMENT_NAME " +
                                        "FROM APPOINTMENTS a " +
                                        "JOIN DOCTORS d ON a.DOCTOR_ID = d.DOCTOR_ID " +
                                        "JOIN DEPARTMENTS dep ON d.DEPARTMENT_ID = dep.DEPARTMENT_ID " +
                                        "WHERE a.PATIENT_ID = ? "
                                    );

                                    if ("BOOKED".equalsIgnoreCase(filter)) {
                                        sql.append(" AND a.STATUS = 'BOOKED' ");
                                    } else if ("COMPLETED".equalsIgnoreCase(filter)) {
                                        sql.append(" AND a.STATUS = 'COMPLETED' ");
                                    } else if ("CANCELLED".equalsIgnoreCase(filter)) {
                                        sql.append(" AND a.STATUS = 'CANCELLED' ");
                                    }

                                    sql.append(" ORDER BY a.APPOINTMENT_DATE DESC, a.APPOINTMENT_TIME DESC ");

                                    stmt = conn.prepareStatement(sql.toString());
                                    stmt.setInt(1, patientId);
                                    rs = stmt.executeQuery();

                                    while (rs.next()) {
                                        count++;
                                        int apptId = rs.getInt("APPOINTMENT_ID");
                                        String docName = SecurityUtil.escapeHtml(rs.getString("DOCTOR_NAME"));
                                        String spec = SecurityUtil.escapeHtml(rs.getString("SPECIALIZATION"));
                                        String dept = SecurityUtil.escapeHtml(rs.getString("DEPARTMENT_NAME"));
                                        String apptDate = rs.getString("APPT_DATE");
                                        String apptTime = rs.getString("APPOINTMENT_TIME");
                                        String reason = SecurityUtil.escapeHtml(rs.getString("REASON"));
                                        String status = rs.getString("STATUS");
                                        String cancelReason = SecurityUtil.escapeHtml(rs.getString("CANCELLATION_REASON"));

                                        String badgeClass = "badge-info";
                                        if ("BOOKED".equalsIgnoreCase(status)) badgeClass = "badge-booked";
                                        else if ("COMPLETED".equalsIgnoreCase(status)) badgeClass = "badge-completed";
                                        else if ("CANCELLED".equalsIgnoreCase(status)) badgeClass = "badge-cancelled";
                            %>
                            <tr data-status="<%= status %>">
                                <td><strong>#<%= apptId %></strong></td>
                                <td><strong><%= docName %></strong></td>
                                <td><%= spec %></td>
                                <td><%= dept %></td>
                                <td><%= apptDate %><br><span style="font-size: 12px; color: var(--text-secondary);"><%= apptTime %></span></td>
                                <td><%= (reason != null && !reason.isEmpty()) ? reason : "--" %></td>
                                <td>
                                    <span class="badge <%= badgeClass %>"><%= status %></span>
                                    <% if ("CANCELLED".equalsIgnoreCase(status) && cancelReason != null && !cancelReason.isEmpty()) { %>
                                        <div style="font-size: 11px; color: var(--text-muted); margin-top: 2px;"><%= cancelReason %></div>
                                    <% } %>
                                </td>
                                <td>
                                    <div class="table-actions">
                                        <% if ("BOOKED".equalsIgnoreCase(status)) { %>
                                            <form action="cancelAppointment.jsp" method="POST" style="display:inline;" onsubmit="return confirmCancelAppointment(<%= apptId %>);">
                                                <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                                                <input type="hidden" name="appointmentId" value="<%= apptId %>">
                                                <button type="submit" class="btn btn-danger btn-sm">Cancel</button>
                                            </form>
                                        <% } else if ("COMPLETED".equalsIgnoreCase(status)) { %>
                                            <a href="prescriptions.jsp?appointmentId=<%= apptId %>" class="btn btn-outline btn-sm">Prescription</a>
                                            <a href="invoice.jsp?appointmentId=<%= apptId %>" class="btn btn-secondary btn-sm" target="_blank">Invoice</a>
                                        <% } else { %>
                                            <span style="font-size: 13px; color: var(--text-muted);">Archived</span>
                                        <% } %>
                                    </div>
                                </td>
                            </tr>
                            <%
                                    }
                                } catch (Exception e) {
                                    System.err.println("[patient-appointments] List error: " + e.getMessage());
                            %>
                            <tr>
                                <td colspan="8" style="color: var(--danger); text-align: center; padding: 20px;">
                                    Failed to retrieve appointment history: <%= SecurityUtil.escapeHtml(e.getMessage()) %>
                                </td>
                            </tr>
                            <%
                                } finally {
                                    DBConnection.close(rs, stmt, conn);
                                }

                                if (count == 0) {
                            %>
                            <tr>
                                <td colspan="8" style="text-align: center; padding: 40px; color: var(--text-secondary);">
                                    <div class="empty-state-icon" style="font-size: 36px; margin-bottom: 8px;">&#128197;</div>
                                    <h3>No Appointments Found</h3>
                                    <p>You have no appointments matching the selected filter (<%= SecurityUtil.escapeHtml(filter) %>).</p>
                                    <a href="book-appointment.jsp" class="btn btn-primary btn-sm">Schedule an Appointment</a>
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
