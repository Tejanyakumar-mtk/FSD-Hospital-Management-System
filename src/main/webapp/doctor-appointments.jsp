<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    String userId = (String) session.getAttribute("userId");
    String userRole = (String) session.getAttribute("userRole");
    String doctorIdStr = (String) session.getAttribute("doctorId");

    if (userId == null || !"DOCTOR".equalsIgnoreCase(userRole) || doctorIdStr == null) {
        response.sendRedirect("login.jsp?error=Please+log+in+as+a+doctor.");
        return;
    }

    int doctorId = Integer.parseInt(doctorIdStr);
    String filter = request.getParameter("filter");
    if (filter == null) filter = "ALL";

    String search = request.getParameter("search");
    if (search == null) search = "";
    search = search.trim();

    String msg = request.getParameter("msg");
    String error = request.getParameter("error");
    String csrfToken = SecurityUtil.getCsrfToken(session);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Assigned Consultations - CityHealth HMS</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/doctor.css">
    <link rel="stylesheet" href="css/tables.css">
    <script src="js/dashboard.js"></script>
</head>
<body>

    <jsp:include page="includes/navbar.jsp" />

    <div class="app-layout">
        <aside class="sidebar">
            <div class="sidebar-heading">Doctor Console</div>
            <ul class="sidebar-menu">
                <li><a href="doctor-dashboard.jsp">&#127968; Dashboard</a></li>
                <li><a href="doctor-appointments.jsp" class="active">&#128197; My Appointments</a></li>
                <li><a href="prescriptions.jsp">&#128221; Prescriptions</a></li>
                <li><a href="logout.jsp">&#128682; Logout</a></li>
            </ul>
        </aside>

        <main class="main-content">
            <div class="staff-topbar">
                <div class="staff-title">
                    <h2>My Assigned Consultations</h2>
                    <p class="lead">View your complete patient consultation schedule and diagnosis records.</p>
                </div>
            </div>

            <% if (msg != null && !msg.trim().isEmpty()) { %>
                <div class="alert alert-success">&#10003; <%= SecurityUtil.escapeHtml(msg) %></div>
            <% } %>
            <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="alert alert-danger">&#9888; <%= SecurityUtil.escapeHtml(error) %></div>
            <% } %>

            <!-- Filters -->
            <form method="GET" action="doctor-appointments.jsp" class="table-toolbar">
                <div class="table-search" style="max-width: 360px;">
                    <input type="text" name="search" placeholder="Search patient name, date..." value="<%= SecurityUtil.escapeHtml(search) %>">
                </div>
                <div class="table-filters">
                    <button type="submit" class="btn btn-primary btn-sm">Search</button>
                    <a href="doctor-appointments.jsp?filter=ALL" class="btn btn-sm <%= "ALL".equalsIgnoreCase(filter) ? "btn-primary" : "btn-outline" %>">All</a>
                    <a href="doctor-appointments.jsp?filter=BOOKED" class="btn btn-sm <%= "BOOKED".equalsIgnoreCase(filter) ? "btn-primary" : "btn-outline" %>">Booked</a>
                    <a href="doctor-appointments.jsp?filter=COMPLETED" class="btn btn-sm <%= "COMPLETED".equalsIgnoreCase(filter) ? "btn-primary" : "btn-outline" %>">Completed</a>
                    <a href="doctor-appointments.jsp" class="btn btn-outline btn-sm">Reset</a>
                </div>
            </form>

            <!-- Table -->
            <div class="card" style="padding: 0; overflow: hidden;">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Ref #</th>
                                <th>Patient Name</th>
                                <th>Date &amp; Slot</th>
                                <th>Age / Gender</th>
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
                                        "a.APPOINTMENT_TIME, a.REASON, a.STATUS, " +
                                        "p.PATIENT_ID, p.PATIENT_NAME, p.GENDER, FLOOR(MONTHS_BETWEEN(SYSDATE, p.DOB)/12) AS AGE " +
                                        "FROM APPOINTMENTS a " +
                                        "JOIN PATIENTS p ON a.PATIENT_ID = p.PATIENT_ID " +
                                        "WHERE a.DOCTOR_ID = ? "
                                    );

                                    if ("BOOKED".equalsIgnoreCase(filter)) {
                                        sql.append(" AND a.STATUS = 'BOOKED' ");
                                    } else if ("COMPLETED".equalsIgnoreCase(filter)) {
                                        sql.append(" AND a.STATUS = 'COMPLETED' ");
                                    }

                                    if (!search.isEmpty()) {
                                        sql.append(" AND (LOWER(p.PATIENT_NAME) LIKE ? OR TO_CHAR(a.APPOINTMENT_DATE, 'YYYY-MM-DD') LIKE ?) ");
                                    }

                                    sql.append(" ORDER BY a.APPOINTMENT_DATE DESC, a.APPOINTMENT_TIME DESC ");

                                    stmt = conn.prepareStatement(sql.toString());
                                    stmt.setInt(1, doctorId);
                                    if (!search.isEmpty()) {
                                        stmt.setString(2, "%" + search.toLowerCase() + "%");
                                        stmt.setString(3, "%" + search + "%");
                                    }

                                    rs = stmt.executeQuery();
                                    while (rs.next()) {
                                        count++;
                                        int aId = rs.getInt("APPOINTMENT_ID");
                                        int pId = rs.getInt("PATIENT_ID");
                                        String pName = SecurityUtil.escapeHtml(rs.getString("PATIENT_NAME"));
                                        String gender = SecurityUtil.escapeHtml(rs.getString("GENDER"));
                                        int age = rs.getInt("AGE");
                                        String aDate = rs.getString("APPT_DATE");
                                        String aTime = rs.getString("APPOINTMENT_TIME");
                                        String reason = SecurityUtil.escapeHtml(rs.getString("REASON"));
                                        String st = rs.getString("STATUS");

                                        String badgeCls = "badge-info";
                                        if ("BOOKED".equalsIgnoreCase(st)) badgeCls = "badge-booked";
                                        else if ("COMPLETED".equalsIgnoreCase(st)) badgeCls = "badge-completed";
                                        else if ("CANCELLED".equalsIgnoreCase(st)) badgeCls = "badge-cancelled";
                            %>
                            <tr>
                                <td>#<%= aId %></td>
                                <td><strong><%= pName %></strong></td>
                                <td><%= aDate %> &bull; <strong><%= aTime %></strong></td>
                                <td><%= gender %>, <%= age %> yrs</td>
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
                                    System.err.println("[doctor-appointments] Error: " + e.getMessage());
                            %>
                            <tr>
                                <td colspan="7" style="color: var(--danger); text-align: center; padding: 20px;">
                                    Failed to retrieve assigned appointments: <%= SecurityUtil.escapeHtml(e.getMessage()) %>
                                </td>
                            </tr>
                            <%
                                } finally {
                                    DBConnection.close(rs, stmt, conn);
                                }

                                if (count == 0) {
                            %>
                            <tr>
                                <td colspan="7" style="text-align: center; padding: 36px; color: var(--text-secondary);">
                                    No appointments found matching your filter criteria.
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
