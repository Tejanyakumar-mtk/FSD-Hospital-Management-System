<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    String userId = (String) session.getAttribute("userId");
    String userRole = (String) session.getAttribute("userRole");

    if (userId == null || (!"ADMIN".equalsIgnoreCase(userRole) && !"RECEPTIONIST".equalsIgnoreCase(userRole))) {
        response.sendRedirect("login.jsp?error=Access+restricted+to+authorized+staff.");
        return;
    }

    String search = request.getParameter("search");
    if (search == null) search = "";
    search = search.trim();

    String filter = request.getParameter("filter");
    if (filter == null) filter = "ALL";

    String patientFilter = request.getParameter("patientId");
    String actionParam = request.getParameter("action");
    String markCompletedId = request.getParameter("markCompleted");

    String msg = request.getParameter("msg");
    String error = request.getParameter("error");
    String csrfToken = SecurityUtil.getCsrfToken(session);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Appointment Administration - CityHealth HMS</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/forms.css">
    <link rel="stylesheet" href="css/staff.css">
    <link rel="stylesheet" href="css/tables.css">
    <link rel="stylesheet" href="css/patient.css">
    <script src="js/dashboard.js"></script>
    <script src="js/appointments.js"></script>
</head>
<body>

    <jsp:include page="includes/navbar.jsp" />

    <div class="app-layout">
        <aside class="sidebar">
            <div class="sidebar-heading">Staff Console (<%= userRole %>)</div>
            <ul class="sidebar-menu">
                <li><a href="admin-dashboard.jsp">&#127968; Dashboard</a></li>
                <li><a href="patients.jsp">&#128101; Patients</a></li>
                <li><a href="manage-doctors.jsp">&#128104;&#8205;&#9877;&#65039; Doctors</a></li>
                <li><a href="departments.jsp">&#127973; Departments</a></li>
                <li><a href="appointments.jsp" class="active">&#128197; Appointments</a></li>
                <li><a href="billing.jsp">&#128179; Billing &amp; Invoices</a></li>
                <li><a href="reports.jsp">&#128200; Reports &amp; Analytics</a></li>
                <li><a href="logout.jsp">&#128682; Logout</a></li>
            </ul>
        </aside>

        <main class="main-content">
            <div class="staff-topbar">
                <div class="staff-title">
                    <h2>Appointment Scheduling &amp; Operations</h2>
                    <p>Manage all hospital consultations, book on behalf of patients, reschedule, and update visit status.</p>
                </div>
                <button type="button" class="btn btn-primary" onclick="openModal('bookOnBehalfModal')">+ Schedule Appointment</button>
            </div>

            <% if (msg != null && !msg.trim().isEmpty()) { %>
                <div class="alert alert-success">&#10003; <%= SecurityUtil.escapeHtml(msg) %></div>
            <% } %>
            <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="alert alert-danger">&#9888; <%= SecurityUtil.escapeHtml(error) %></div>
            <% } %>

            <!-- Search and Filter Bar -->
            <form method="GET" action="appointments.jsp" class="table-toolbar">
                <div class="table-search" style="max-width: 380px;">
                    <input type="text" name="search" placeholder="Search patient, doctor, date..." value="<%= SecurityUtil.escapeHtml(search) %>">
                </div>
                <div class="table-filters">
                    <button type="submit" class="btn btn-primary btn-sm">Search</button>
                    <a href="appointments.jsp?filter=ALL" class="btn btn-sm <%= "ALL".equalsIgnoreCase(filter) ? "btn-primary" : "btn-outline" %>">All</a>
                    <a href="appointments.jsp?filter=BOOKED" class="btn btn-sm <%= "BOOKED".equalsIgnoreCase(filter) ? "btn-primary" : "btn-outline" %>">Booked</a>
                    <a href="appointments.jsp?filter=COMPLETED" class="btn btn-sm <%= "COMPLETED".equalsIgnoreCase(filter) ? "btn-primary" : "btn-outline" %>">Completed</a>
                    <a href="appointments.jsp?filter=CANCELLED" class="btn btn-sm <%= "CANCELLED".equalsIgnoreCase(filter) ? "btn-primary" : "btn-outline" %>">Cancelled</a>
                    <a href="appointments.jsp" class="btn btn-outline btn-sm">Reset</a>
                </div>
            </form>

            <!-- Appointments Master Table -->
            <div class="card" style="padding: 0; overflow: hidden;">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Ref #</th>
                                <th>Patient Name</th>
                                <th>Doctor</th>
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
                                        "a.APPOINTMENT_TIME, a.REASON, a.STATUS, " +
                                        "p.PATIENT_ID, p.PATIENT_NAME, p.PHONE, d.DOCTOR_NAME, dep.DEPARTMENT_NAME " +
                                        "FROM APPOINTMENTS a " +
                                        "JOIN PATIENTS p ON a.PATIENT_ID = p.PATIENT_ID " +
                                        "JOIN DOCTORS d ON a.DOCTOR_ID = d.DOCTOR_ID " +
                                        "JOIN DEPARTMENTS dep ON d.DEPARTMENT_ID = dep.DEPARTMENT_ID WHERE 1=1 "
                                    );

                                    if (patientFilter != null && !patientFilter.trim().isEmpty()) {
                                        sql.append(" AND a.PATIENT_ID = ? ");
                                    }
                                    if ("BOOKED".equalsIgnoreCase(filter)) {
                                        sql.append(" AND a.STATUS = 'BOOKED' ");
                                    } else if ("COMPLETED".equalsIgnoreCase(filter)) {
                                        sql.append(" AND a.STATUS = 'COMPLETED' ");
                                    } else if ("CANCELLED".equalsIgnoreCase(filter)) {
                                        sql.append(" AND a.STATUS = 'CANCELLED' ");
                                    }

                                    if (!search.isEmpty()) {
                                        sql.append(" AND (LOWER(p.PATIENT_NAME) LIKE ? OR LOWER(d.DOCTOR_NAME) LIKE ? OR TO_CHAR(a.APPOINTMENT_DATE, 'YYYY-MM-DD') LIKE ?) ");
                                    }

                                    sql.append(" ORDER BY a.APPOINTMENT_DATE DESC, a.APPOINTMENT_TIME DESC ");

                                    stmt = conn.prepareStatement(sql.toString());
                                    int pIdx = 1;
                                    if (patientFilter != null && !patientFilter.trim().isEmpty()) {
                                        stmt.setInt(pIdx++, Integer.parseInt(patientFilter.trim()));
                                    }
                                    if (!search.isEmpty()) {
                                        String likeP = "%" + search.toLowerCase() + "%";
                                        stmt.setString(pIdx++, likeP);
                                        stmt.setString(pIdx++, likeP);
                                        stmt.setString(pIdx++, "%" + search + "%");
                                    }

                                    rs = stmt.executeQuery();
                                    while (rs.next()) {
                                        count++;
                                        int aId = rs.getInt("APPOINTMENT_ID");
                                        int pId = rs.getInt("PATIENT_ID");
                                        String pName = SecurityUtil.escapeHtml(rs.getString("PATIENT_NAME"));
                                        String phone = SecurityUtil.escapeHtml(rs.getString("PHONE"));
                                        String dName = SecurityUtil.escapeHtml(rs.getString("DOCTOR_NAME"));
                                        String dept = SecurityUtil.escapeHtml(rs.getString("DEPARTMENT_NAME"));
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
                                <td><strong>#<%= aId %></strong></td>
                                <td><strong><%= pName %></strong><br><span style="font-size: 12px; color: var(--text-secondary);">(ID: #<%= pId %> &bull; <%= phone %>)</span></td>
                                <td><%= dName %></td>
                                <td><%= dept %></td>
                                <td><%= aDate %><br><span style="font-size: 12px; color: var(--text-secondary);"><%= aTime %></span></td>
                                <td><%= (reason != null && !reason.isEmpty()) ? reason : "--" %></td>
                                <td><span class="badge <%= badgeCls %>"><%= st %></span></td>
                                <td>
                                    <div class="table-actions">
                                        <% if ("BOOKED".equalsIgnoreCase(st)) { %>
                                            <form action="adminAppointmentAction.jsp" method="POST" style="display:inline;">
                                                <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                                                <input type="hidden" name="actionType" value="MARK_COMPLETED">
                                                <input type="hidden" name="appointmentId" value="<%= aId %>">
                                                <button type="submit" class="btn btn-success btn-sm" title="Mark as Completed">&#10003; Complete</button>
                                            </form>
                                            <button type="button" class="btn btn-outline btn-sm"
                                                    onclick="openRescheduleModal(<%= aId %>, '<%= aDate %>', '<%= aTime %>')">
                                                Reschedule
                                            </button>
                                            <form action="cancelAppointment.jsp" method="POST" style="display:inline;">
                                                <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                                                <input type="hidden" name="appointmentId" value="<%= aId %>">
                                                <button type="submit" class="btn btn-danger btn-sm" onclick="return confirm('Cancel appointment #<%= aId %>?');">
                                                    Cancel
                                                </button>
                                            </form>
                                        <% } else if ("COMPLETED".equalsIgnoreCase(st)) { %>
                                            <a href="prescriptions.jsp?appointmentId=<%= aId %>" class="btn btn-outline btn-sm">Rx</a>
                                            <a href="invoice.jsp?appointmentId=<%= aId %>" class="btn btn-secondary btn-sm" target="_blank">Bill</a>
                                        <% } else { %>
                                            <span style="font-size: 13px; color: var(--text-muted);">Cancelled</span>
                                        <% } %>
                                    </div>
                                </td>
                            </tr>
                            <%
                                    }
                                } catch (Exception e) {
                                    System.err.println("[appointments.jsp] Error: " + e.getMessage());
                            %>
                            <tr>
                                <td colspan="8" style="color: var(--danger); text-align: center; padding: 20px;">
                                    Failed to retrieve appointments: <%= SecurityUtil.escapeHtml(e.getMessage()) %>
                                </td>
                            </tr>
                            <%
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

    <!-- Modal: Book on Behalf of Patient -->
    <div id="bookOnBehalfModal" class="modal-overlay <%= "new".equalsIgnoreCase(actionParam) ? "active" : "" %>">
        <div class="modal-card">
            <div class="modal-header">
                <h3 class="card-title">Schedule Appointment for Patient</h3>
                <button type="button" class="btn-remove-row" onclick="closeModal('bookOnBehalfModal')">&times;</button>
            </div>
            <form action="saveAppointment.jsp" method="POST" onsubmit="return validateBookingForm();">
                <div class="modal-body">
                    <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                    <input type="hidden" id="appointmentTime" name="appointmentTime" value="">

                    <!-- Select Patient -->
                    <div class="form-group">
                        <label class="form-label">Patient <span class="required">*</span></label>
                        <select name="patientId" class="form-control" required>
                            <option value="">-- Select Registered Patient --</option>
                            <%
                                Connection pConn = null;
                                PreparedStatement pStmt = null;
                                ResultSet pRs = null;
                                try {
                                    pConn = DBConnection.getConnection();
                                    pStmt = pConn.prepareStatement("SELECT PATIENT_ID, PATIENT_NAME, PHONE FROM PATIENTS WHERE ACTIVE = 1 ORDER BY PATIENT_NAME");
                                    pRs = pStmt.executeQuery();
                                    while (pRs.next()) {
                                        int pId = pRs.getInt("PATIENT_ID");
                                        String pName = pRs.getString("PATIENT_NAME");
                                        String pPhone = pRs.getString("PHONE");
                            %>
                            <option value="<%= pId %>"><%= SecurityUtil.escapeHtml(pName) %> (#<%= pId %> - <%= pPhone %>)</option>
                            <%
                                    }
                                } catch (Exception ignored) {
                                } finally {
                                    DBConnection.close(pRs, pStmt, pConn);
                                }
                            %>
                        </select>
                    </div>

                    <!-- Department -->
                    <div class="form-group">
                        <label class="form-label">Department</label>
                        <select id="departmentSelect" class="form-control" onchange="onDepartmentChange()">
                            <option value="">-- All Departments --</option>
                            <%
                                try {
                                    pConn = DBConnection.getConnection();
                                    pStmt = pConn.prepareStatement("SELECT DEPARTMENT_ID, DEPARTMENT_NAME FROM DEPARTMENTS WHERE ACTIVE = 1 ORDER BY DEPARTMENT_NAME");
                                    pRs = pStmt.executeQuery();
                                    while (pRs.next()) {
                            %>
                            <option value="<%= pRs.getInt("DEPARTMENT_ID") %>"><%= SecurityUtil.escapeHtml(pRs.getString("DEPARTMENT_NAME")) %></option>
                            <%
                                    }
                                } catch (Exception ignored) {
                                } finally {
                                    DBConnection.close(pRs, pStmt, pConn);
                                }
                            %>
                        </select>
                    </div>

                    <!-- Doctor -->
                    <div class="form-group">
                        <label class="form-label">Doctor <span class="required">*</span></label>
                        <select id="doctorSelect" name="doctorId" class="form-control" onchange="onDoctorChange()" required>
                            <option value="">-- Select Doctor --</option>
                            <%
                                try {
                                    pConn = DBConnection.getConnection();
                                    pStmt = pConn.prepareStatement(
                                        "SELECT DOCTOR_ID, DOCTOR_NAME, SPECIALIZATION, DEPARTMENT_ID, CONSULTATION_FEE " +
                                        "FROM DOCTORS WHERE ACTIVE = 1 ORDER BY DOCTOR_NAME"
                                    );
                                    pRs = pStmt.executeQuery();
                                    while (pRs.next()) {
                            %>
                            <option value="<%= pRs.getInt("DOCTOR_ID") %>"
                                    data-department-id="<%= pRs.getInt("DEPARTMENT_ID") %>"
                                    data-fee="<%= String.format("%.2f", pRs.getDouble("CONSULTATION_FEE")) %>"
                                    data-spec="<%= SecurityUtil.escapeHtml(pRs.getString("SPECIALIZATION")) %>">
                                <%= SecurityUtil.escapeHtml(pRs.getString("DOCTOR_NAME")) %> (<%= SecurityUtil.escapeHtml(pRs.getString("SPECIALIZATION")) %>)
                            </option>
                            <%
                                    }
                                } catch (Exception ignored) {
                                } finally {
                                    DBConnection.close(pRs, pStmt, pConn);
                                }
                            %>
                        </select>
                    </div>

                    <!-- Date & Slots -->
                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Appointment Date <span class="required">*</span></label>
                            <input type="date" id="appointmentDate" name="appointmentDate" class="form-control" min="<%= java.time.LocalDate.now().toString() %>" onchange="onDateChange()" required>
                        </div>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Available Time Slot <span class="required">*</span></label>
                        <div id="timeSlotsContainer" class="slot-grid">
                            <span style="font-size: 13px; color: var(--text-muted); grid-column: 1 / -1;">
                                Select doctor and date to load slots.
                            </span>
                        </div>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Reason for Visit</label>
                        <textarea name="reason" class="form-control" rows="2" placeholder="Clinical concern or consultation purpose..."></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline" onclick="closeModal('bookOnBehalfModal')">Cancel</button>
                    <button type="submit" class="btn btn-primary">Book Consultation</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Modal: Reschedule Appointment -->
    <div id="rescheduleModal" class="modal-overlay">
        <div class="modal-card">
            <div class="modal-header">
                <h3 class="card-title">Reschedule Appointment #<span id="reschedDisplayId"></span></h3>
                <button type="button" class="btn-remove-row" onclick="closeModal('rescheduleModal')">&times;</button>
            </div>
            <form action="adminAppointmentAction.jsp" method="POST">
                <div class="modal-body">
                    <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                    <input type="hidden" name="actionType" value="RESCHEDULE">
                    <input type="hidden" id="reschedApptId" name="appointmentId" value="">

                    <div class="form-group">
                        <label class="form-label">New Appointment Date <span class="required">*</span></label>
                        <input type="date" id="reschedDate" name="newDate" class="form-control" min="<%= java.time.LocalDate.now().toString() %>" required>
                    </div>

                    <div class="form-group">
                        <label class="form-label">New Time Slot <span class="required">*</span></label>
                        <select name="newTime" class="form-control" required>
                            <option value="">-- Select Time Slot --</option>
                            <option value="09:00">09:00 AM</option>
                            <option value="09:30">09:30 AM</option>
                            <option value="10:00">10:00 AM</option>
                            <option value="10:30">10:30 AM</option>
                            <option value="11:00">11:00 AM</option>
                            <option value="11:30">11:30 AM</option>
                            <option value="12:00">12:00 PM</option>
                            <option value="14:00">02:00 PM</option>
                            <option value="14:30">02:30 PM</option>
                            <option value="15:00">03:00 PM</option>
                            <option value="15:30">03:30 PM</option>
                            <option value="16:00">04:00 PM</option>
                            <option value="16:30">04:30 PM</option>
                            <option value="17:00">05:00 PM</option>
                        </select>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline" onclick="closeModal('rescheduleModal')">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save New Schedule</button>
                </div>
            </form>
        </div>
    </div>

    <jsp:include page="includes/footer.jsp" />

    <script>
        function openRescheduleModal(id, date, time) {
            document.getElementById('reschedDisplayId').textContent = id;
            document.getElementById('reschedApptId').value = id;
            document.getElementById('reschedDate').value = date;
            openModal('rescheduleModal');
        }
    </script>
</body>
</html>
