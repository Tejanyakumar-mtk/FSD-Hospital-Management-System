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

    String msg = request.getParameter("msg");
    String error = request.getParameter("error");
    String csrfToken = SecurityUtil.getCsrfToken(session);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Doctor Management - CityHealth HMS</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/forms.css">
    <link rel="stylesheet" href="css/staff.css">
    <link rel="stylesheet" href="css/tables.css">
    <script src="js/dashboard.js"></script>
</head>
<body>

    <jsp:include page="includes/navbar.jsp" />

    <div class="app-layout">
        <aside class="sidebar">
            <div class="sidebar-heading">Staff Console (<%= userRole %>)</div>
            <ul class="sidebar-menu">
                <li><a href="admin-dashboard.jsp">&#127968; Dashboard</a></li>
                <li><a href="patients.jsp">&#128101; Patients</a></li>
                <li><a href="manage-doctors.jsp" class="active">&#128104;&#8205;&#9877;&#65039; Doctors</a></li>
                <li><a href="departments.jsp">&#127973; Departments</a></li>
                <li><a href="appointments.jsp">&#128197; Appointments</a></li>
                <li><a href="billing.jsp">&#128179; Billing &amp; Invoices</a></li>
                <li><a href="reports.jsp">&#128200; Reports &amp; Analytics</a></li>
                <li><a href="logout.jsp">&#128682; Logout</a></li>
            </ul>
        </aside>

        <main class="main-content">
            <div class="staff-topbar">
                <div class="staff-title">
                    <h2>Doctor Directory &amp; Schedules</h2>
                    <p>Manage medical consultants, departments, consultation fees, and active clinical status.</p>
                </div>
                <button type="button" class="btn btn-primary" onclick="openModal('newDoctorModal')">+ Add New Doctor</button>
            </div>

            <% if (msg != null && !msg.trim().isEmpty()) { %>
                <div class="alert alert-success">&#10003; <%= SecurityUtil.escapeHtml(msg) %></div>
            <% } %>
            <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="alert alert-danger">&#9888; <%= SecurityUtil.escapeHtml(error) %></div>
            <% } %>

            <!-- Search Bar -->
            <form method="GET" action="manage-doctors.jsp" class="table-toolbar">
                <div class="table-search" style="max-width: 380px;">
                    <input type="text" name="search" placeholder="Search doctor, department, specialty..." value="<%= SecurityUtil.escapeHtml(search) %>">
                </div>
                <div class="table-filters">
                    <button type="submit" class="btn btn-primary btn-sm">Search</button>
                    <a href="manage-doctors.jsp" class="btn btn-outline btn-sm">Reset</a>
                </div>
            </form>

            <!-- Doctors Table -->
            <div class="card" style="padding: 0; overflow: hidden;">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Doctor ID</th>
                                <th>Name &amp; Qualification</th>
                                <th>Department</th>
                                <th>Specialization</th>
                                <th>Contact</th>
                                <th>Room</th>
                                <th>Fee</th>
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
                                        "SELECT d.DOCTOR_ID, d.DOCTOR_NAME, d.EMAIL, d.PHONE, d.SPECIALIZATION, d.DEPARTMENT_ID, " +
                                        "d.CONSULTATION_FEE, d.QUALIFICATION, d.ROOM_NO, d.ACTIVE, dep.DEPARTMENT_NAME " +
                                        "FROM DOCTORS d JOIN DEPARTMENTS dep ON d.DEPARTMENT_ID = dep.DEPARTMENT_ID WHERE 1=1 "
                                    );

                                    if (!search.isEmpty()) {
                                        sql.append(" AND (LOWER(d.DOCTOR_NAME) LIKE ? OR LOWER(d.SPECIALIZATION) LIKE ? OR LOWER(dep.DEPARTMENT_NAME) LIKE ?) ");
                                    }
                                    sql.append(" ORDER BY d.DOCTOR_ID ASC ");

                                    stmt = conn.prepareStatement(sql.toString());
                                    if (!search.isEmpty()) {
                                        String likeP = "%" + search.toLowerCase() + "%";
                                        stmt.setString(1, likeP);
                                        stmt.setString(2, likeP);
                                        stmt.setString(3, likeP);
                                    }

                                    rs = stmt.executeQuery();
                                    while (rs.next()) {
                                        count++;
                                        int dId = rs.getInt("DOCTOR_ID");
                                        String dName = SecurityUtil.escapeHtml(rs.getString("DOCTOR_NAME"));
                                        String email = SecurityUtil.escapeHtml(rs.getString("EMAIL"));
                                        String phone = SecurityUtil.escapeHtml(rs.getString("PHONE"));
                                        String spec = SecurityUtil.escapeHtml(rs.getString("SPECIALIZATION"));
                                        int deptId = rs.getInt("DEPARTMENT_ID");
                                        String deptName = SecurityUtil.escapeHtml(rs.getString("DEPARTMENT_NAME"));
                                        double fee = rs.getDouble("CONSULTATION_FEE");
                                        String qual = SecurityUtil.escapeHtml(rs.getString("QUALIFICATION"));
                                        String room = SecurityUtil.escapeHtml(rs.getString("ROOM_NO"));
                                        int active = rs.getInt("ACTIVE");
                            %>
                            <tr>
                                <td><strong>#<%= dId %></strong></td>
                                <td><strong><%= dName %></strong><br><span style="font-size: 12px; color: var(--text-secondary);"><%= qual != null ? qual : "" %></span></td>
                                <td><%= deptName %></td>
                                <td><%= spec %></td>
                                <td><%= phone %><br><span style="font-size: 12px; color: var(--text-secondary);"><%= email %></span></td>
                                <td><%= room != null ? room : "OPD" %></td>
                                <td><strong>&#8377; <%= String.format("%.2f", fee) %></strong></td>
                                <td>
                                    <span class="badge <%= (active == 1) ? "badge-success" : "badge-danger" %>">
                                        <%= (active == 1) ? "ACTIVE" : "INACTIVE" %>
                                    </span>
                                </td>
                                <td>
                                    <div class="table-actions">
                                        <button type="button" class="btn btn-outline btn-sm"
                                                onclick="openEditDoctorModal(<%= dId %>, '<%= dName %>', '<%= email %>', '<%= phone %>', '<%= spec %>', <%= deptId %>, <%= fee %>, '<%= qual %>', '<%= room %>')">
                                            Edit
                                        </button>
                                        <form action="toggleDoctorStatus.jsp" method="POST" style="display:inline;">
                                            <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                                            <input type="hidden" name="doctorId" value="<%= dId %>">
                                            <input type="hidden" name="currentStatus" value="<%= active %>">
                                            <button type="submit" class="btn <%= (active == 1) ? "btn-danger" : "btn-success" %> btn-sm"
                                                    onclick="return confirm('Change status of <%= dName %>?');">
                                                <%= (active == 1) ? "Deactivate" : "Activate" %>
                                            </button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                            <%
                                    }
                                } catch (Exception e) {
                                    System.err.println("[manage-doctors] Error: " + e.getMessage());
                            %>
                            <tr>
                                <td colspan="9" style="color: var(--danger); text-align: center; padding: 20px;">
                                    Failed to retrieve doctor list: <%= SecurityUtil.escapeHtml(e.getMessage()) %>
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

    <!-- Modal: Add New Doctor -->
    <div id="newDoctorModal" class="modal-overlay">
        <div class="modal-card">
            <div class="modal-header">
                <h3 class="card-title">Add New Doctor</h3>
                <button type="button" class="btn-remove-row" onclick="closeModal('newDoctorModal')">&times;</button>
            </div>
            <form action="saveDoctor.jsp" method="POST">
                <div class="modal-body">
                    <input type="hidden" name="csrfToken" value="<%= csrfToken %>">

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Doctor Full Name <span class="required">*</span></label>
                            <input type="text" name="doctorName" class="form-control" placeholder="e.g. Dr. Ramesh Gupta" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Specialization <span class="required">*</span></label>
                            <input type="text" name="specialization" class="form-control" placeholder="e.g. Cardiologist" required>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Department <span class="required">*</span></label>
                            <select name="departmentId" class="form-control" required>
                                <option value="">-- Select Department --</option>
                                <%
                                    PreparedStatement dDeptStmt = null;
                                    ResultSet dDeptRs = null;
                                    Connection dConn = null;
                                    try {
                                        dConn = DBConnection.getConnection();
                                        dDeptStmt = dConn.prepareStatement("SELECT DEPARTMENT_ID, DEPARTMENT_NAME FROM DEPARTMENTS WHERE ACTIVE = 1 ORDER BY DEPARTMENT_NAME");
                                        dDeptRs = dDeptStmt.executeQuery();
                                        while (dDeptRs.next()) {
                                %>
                                <option value="<%= dDeptRs.getInt("DEPARTMENT_ID") %>"><%= SecurityUtil.escapeHtml(dDeptRs.getString("DEPARTMENT_NAME")) %></option>
                                <%
                                        }
                                    } catch (Exception ignored) {
                                    } finally {
                                        DBConnection.close(dDeptRs, dDeptStmt, dConn);
                                    }
                                %>
                            </select>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Consultation Fee (&#8377;) <span class="required">*</span></label>
                            <input type="number" step="0.01" name="consultationFee" class="form-control" placeholder="500.00" min="0" required>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Phone Number <span class="required">*</span></label>
                            <input type="tel" name="phone" class="form-control" placeholder="10 digits" maxlength="10" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Email Address <span class="required">*</span></label>
                            <input type="email" name="email" class="form-control" placeholder="doctor@hospital.com" required>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Medical Qualification</label>
                            <input type="text" name="qualification" class="form-control" placeholder="e.g. MBBS, MD (Medicine)">
                        </div>
                        <div class="form-group">
                            <label class="form-label">Consultation Room No</label>
                            <input type="text" name="roomNo" class="form-control" placeholder="e.g. Room 204">
                        </div>
                    </div>

                    <div class="form-row" style="background: #f8fafc; padding: 12px; border-radius: var(--radius-sm); border: 1px dashed var(--border-color);">
                        <div class="form-group" style="margin-bottom: 0;">
                            <label class="form-label">Doctor Portal Username <span class="required">*</span></label>
                            <input type="text" name="username" class="form-control" placeholder="e.g. dr.ramesh" required>
                        </div>
                        <div class="form-group" style="margin-bottom: 0;">
                            <label class="form-label">Portal Password <span class="required">*</span></label>
                            <input type="password" name="password" class="form-control" placeholder="At least 6 chars" minlength="6" required>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline" onclick="closeModal('newDoctorModal')">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Doctor</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Modal: Edit Doctor -->
    <div id="editDoctorModal" class="modal-overlay">
        <div class="modal-card">
            <div class="modal-header">
                <h3 class="card-title">Edit Doctor Record #<span id="editDisplayDocId"></span></h3>
                <button type="button" class="btn-remove-row" onclick="closeModal('editDoctorModal')">&times;</button>
            </div>
            <form action="updateDoctor.jsp" method="POST">
                <div class="modal-body">
                    <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                    <input type="hidden" id="editDoctorId" name="doctorId" value="">

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Doctor Name <span class="required">*</span></label>
                            <input type="text" id="editDocName" name="doctorName" class="form-control" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Specialization <span class="required">*</span></label>
                            <input type="text" id="editSpec" name="specialization" class="form-control" required>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Department <span class="required">*</span></label>
                            <select id="editDeptSelect" name="departmentId" class="form-control" required>
                                <%
                                    try {
                                        dConn = DBConnection.getConnection();
                                        dDeptStmt = dConn.prepareStatement("SELECT DEPARTMENT_ID, DEPARTMENT_NAME FROM DEPARTMENTS WHERE ACTIVE = 1 ORDER BY DEPARTMENT_NAME");
                                        dDeptRs = dDeptStmt.executeQuery();
                                        while (dDeptRs.next()) {
                                %>
                                <option value="<%= dDeptRs.getInt("DEPARTMENT_ID") %>"><%= SecurityUtil.escapeHtml(dDeptRs.getString("DEPARTMENT_NAME")) %></option>
                                <%
                                        }
                                    } catch (Exception ignored) {
                                    } finally {
                                        DBConnection.close(dDeptRs, dDeptStmt, dConn);
                                    }
                                %>
                            </select>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Consultation Fee (&#8377;) <span class="required">*</span></label>
                            <input type="number" step="0.01" id="editFee" name="consultationFee" class="form-control" min="0" required>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Phone Number <span class="required">*</span></label>
                            <input type="tel" id="editDocPhone" name="phone" class="form-control" maxlength="10" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Email Address <span class="required">*</span></label>
                            <input type="email" id="editDocEmail" name="email" class="form-control" required>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Qualification</label>
                            <input type="text" id="editQual" name="qualification" class="form-control">
                        </div>
                        <div class="form-group">
                            <label class="form-label">Room Number</label>
                            <input type="text" id="editRoom" name="roomNo" class="form-control">
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline" onclick="closeModal('editDoctorModal')">Cancel</button>
                    <button type="submit" class="btn btn-primary">Update Doctor Details</button>
                </div>
            </form>
        </div>
    </div>

    <jsp:include page="includes/footer.jsp" />

    <script>
        function openEditDoctorModal(id, name, email, phone, spec, deptId, fee, qual, room) {
            document.getElementById('editDisplayDocId').textContent = id;
            document.getElementById('editDoctorId').value = id;
            document.getElementById('editDocName').value = name;
            document.getElementById('editDocEmail').value = email;
            document.getElementById('editDocPhone').value = phone;
            document.getElementById('editSpec').value = spec;
            document.getElementById('editDeptSelect').value = deptId;
            document.getElementById('editFee').value = fee.toFixed(2);
            document.getElementById('editQual').value = qual || "";
            document.getElementById('editRoom').value = room || "";
            openModal('editDoctorModal');
        }
    </script>
</body>
</html>
