<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    String userId = (String) session.getAttribute("userId");
    String userRole = (String) session.getAttribute("userRole");

    if (userId == null || (!"ADMIN".equalsIgnoreCase(userRole) && !"RECEPTIONIST".equalsIgnoreCase(userRole))) {
        response.sendRedirect("login.jsp?error=Access+restricted+to+authorized+hospital+staff.");
        return;
    }

    String search = request.getParameter("search");
    if (search == null) search = "";
    search = search.trim();

    String msg = request.getParameter("msg");
    String error = request.getParameter("error");
    String action = request.getParameter("action");
    String csrfToken = SecurityUtil.getCsrfToken(session);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Patient Management - CityHealth HMS</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/forms.css">
    <link rel="stylesheet" href="css/staff.css">
    <link rel="stylesheet" href="css/tables.css">
    <script src="js/dashboard.js"></script>
    <script src="js/validation.js"></script>
</head>
<body>

    <jsp:include page="includes/navbar.jsp" />

    <div class="app-layout">
        <aside class="sidebar">
            <div class="sidebar-heading">Staff Console (<%= userRole %>)</div>
            <ul class="sidebar-menu">
                <li><a href="admin-dashboard.jsp">&#127968; Dashboard</a></li>
                <li><a href="patients.jsp" class="active">&#128101; Patients</a></li>
                <li><a href="manage-doctors.jsp">&#128104;&#8205;&#9877;&#65039; Doctors</a></li>
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
                    <h2>Patient Management Directory</h2>
                    <p>Register, view, search, and update patient medical demographics.</p>
                </div>
                <button type="button" class="btn btn-primary" onclick="openModal('newPatientModal')">+ Register New Patient</button>
            </div>

            <% if (msg != null && !msg.trim().isEmpty()) { %>
                <div class="alert alert-success">&#10003; <%= SecurityUtil.escapeHtml(msg) %></div>
            <% } %>
            <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="alert alert-danger">&#9888; <%= SecurityUtil.escapeHtml(error) %></div>
            <% } %>

            <!-- Search and Filter Toolbar -->
            <form method="GET" action="patients.jsp" class="table-toolbar">
                <div class="table-search" style="max-width: 400px;">
                    <input type="text" name="search" placeholder="Search by ID, name, phone, email..." value="<%= SecurityUtil.escapeHtml(search) %>">
                </div>
                <div class="table-filters">
                    <button type="submit" class="btn btn-primary btn-sm">Search</button>
                    <a href="patients.jsp" class="btn btn-outline btn-sm">Reset</a>
                </div>
            </form>

            <!-- Patients Table -->
            <div class="card" style="padding: 0; overflow: hidden;">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Patient ID</th>
                                <th>Name</th>
                                <th>DOB / Gender</th>
                                <th>Phone</th>
                                <th>Email</th>
                                <th>Blood Group</th>
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
                                        "SELECT PATIENT_ID, PATIENT_NAME, TO_CHAR(DOB, 'YYYY-MM-DD') AS DOB_STR, GENDER, PHONE, EMAIL, " +
                                        "ADDRESS, BLOOD_GROUP, EMERGENCY_CONTACT, ACTIVE FROM PATIENTS WHERE 1=1 "
                                    );

                                    if (!search.isEmpty()) {
                                        sql.append(" AND (LOWER(PATIENT_NAME) LIKE ? OR PHONE LIKE ? OR LOWER(EMAIL) LIKE ? ");
                                        if (search.matches("^[0-9]+$")) {
                                            sql.append(" OR PATIENT_ID = ? ");
                                        }
                                        sql.append(") ");
                                    }
                                    sql.append(" ORDER BY PATIENT_ID DESC ");

                                    stmt = conn.prepareStatement(sql.toString());
                                    int pIdx = 1;
                                    if (!search.isEmpty()) {
                                        String likeP = "%" + search.toLowerCase() + "%";
                                        stmt.setString(pIdx++, likeP);
                                        stmt.setString(pIdx++, "%" + search + "%");
                                        stmt.setString(pIdx++, likeP);
                                        if (search.matches("^[0-9]+$")) {
                                            stmt.setInt(pIdx++, Integer.parseInt(search));
                                        }
                                    }

                                    rs = stmt.executeQuery();
                                    while (rs.next()) {
                                        count++;
                                        int pId = rs.getInt("PATIENT_ID");
                                        String pName = SecurityUtil.escapeHtml(rs.getString("PATIENT_NAME"));
                                        String dob = rs.getString("DOB_STR");
                                        String gender = SecurityUtil.escapeHtml(rs.getString("GENDER"));
                                        String phone = SecurityUtil.escapeHtml(rs.getString("PHONE"));
                                        String email = SecurityUtil.escapeHtml(rs.getString("EMAIL"));
                                        String bGroup = SecurityUtil.escapeHtml(rs.getString("BLOOD_GROUP"));
                                        String addr = SecurityUtil.escapeHtml(rs.getString("ADDRESS"));
                                        String emerg = SecurityUtil.escapeHtml(rs.getString("EMERGENCY_CONTACT"));
                                        int active = rs.getInt("ACTIVE");
                            %>
                            <tr>
                                <td><strong>#<%= pId %></strong></td>
                                <td><strong><%= pName %></strong></td>
                                <td><%= dob %><br><span style="font-size: 12px; color: var(--text-secondary);"><%= gender %></span></td>
                                <td><%= phone %></td>
                                <td><%= email %></td>
                                <td><span class="badge badge-info"><%= (bGroup != null && !bGroup.isEmpty()) ? bGroup : "N/A" %></span></td>
                                <td>
                                    <span class="badge <%= (active == 1) ? "badge-success" : "badge-danger" %>">
                                        <%= (active == 1) ? "ACTIVE" : "INACTIVE" %>
                                    </span>
                                </td>
                                <td>
                                    <div class="table-actions">
                                        <button type="button" class="btn btn-outline btn-sm"
                                                onclick="openEditPatientModal(<%= pId %>, '<%= pName %>', '<%= dob %>', '<%= gender %>', '<%= phone %>', '<%= email %>', '<%= bGroup %>', '<%= addr %>', '<%= emerg %>')">
                                            Edit
                                        </button>
                                        <a href="appointments.jsp?patientId=<%= pId %>" class="btn btn-secondary btn-sm" title="View Patient Appointments">Visits</a>
                                        <form action="togglePatientStatus.jsp" method="POST" style="display:inline;">
                                            <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                                            <input type="hidden" name="patientId" value="<%= pId %>">
                                            <input type="hidden" name="currentStatus" value="<%= active %>">
                                            <button type="submit" class="btn <%= (active == 1) ? "btn-danger" : "btn-success" %> btn-sm"
                                                    onclick="return confirm('Change active status for <%= pName %>?');">
                                                <%= (active == 1) ? "Deactivate" : "Activate" %>
                                            </button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                            <%
                                    }
                                } catch (Exception e) {
                                    System.err.println("[patients.jsp] List error: " + e.getMessage());
                            %>
                            <tr>
                                <td colspan="8" style="color: var(--danger); text-align: center; padding: 20px;">
                                    Database query error: <%= SecurityUtil.escapeHtml(e.getMessage()) %>
                                </td>
                            </tr>
                            <%
                                } finally {
                                    DBConnection.close(rs, stmt, conn);
                                }

                                if (count == 0) {
                            %>
                            <tr>
                                <td colspan="8" style="text-align: center; padding: 36px; color: var(--text-secondary);">
                                    No patients matched your search criteria.
                                </td>
                            </tr>
                            <%  } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </main>
    </div>

    <!-- Modal: Register New Patient -->
    <div id="newPatientModal" class="modal-overlay <%= "new".equalsIgnoreCase(action) ? "active" : "" %>">
        <div class="modal-card">
            <div class="modal-header">
                <h3 class="card-title">Register New Patient</h3>
                <button type="button" class="btn-remove-row" onclick="closeModal('newPatientModal')">&times;</button>
            </div>
            <form action="savePatient.jsp" method="POST" onsubmit="return validateRegistrationForm();">
                <div class="modal-body">
                    <input type="hidden" name="csrfToken" value="<%= csrfToken %>">

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Full Name <span class="required">*</span></label>
                            <input type="text" name="fullName" class="form-control" placeholder="e.g. Anand Varma" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Date of Birth <span class="required">*</span></label>
                            <input type="date" name="dob" class="form-control" max="<%= java.time.LocalDate.now().toString() %>" required>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Gender <span class="required">*</span></label>
                            <select name="gender" class="form-control" required>
                                <option value="">Select Gender</option>
                                <option value="Male">Male</option>
                                <option value="Female">Female</option>
                                <option value="Other">Other</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Blood Group</label>
                            <select name="bloodGroup" class="form-control">
                                <option value="">Select Blood Group</option>
                                <option value="A+">A+</option>
                                <option value="A-">A-</option>
                                <option value="B+">B+</option>
                                <option value="B-">B-</option>
                                <option value="O+">O+</option>
                                <option value="O-">O-</option>
                                <option value="AB+">AB+</option>
                                <option value="AB-">AB-</option>
                            </select>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Phone Number <span class="required">*</span></label>
                            <input type="tel" name="phone" class="form-control" placeholder="10 digits" maxlength="10" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Email Address <span class="required">*</span></label>
                            <input type="email" name="email" class="form-control" placeholder="patient@example.com" required>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Emergency Contact</label>
                            <input type="tel" name="emergencyContact" class="form-control" placeholder="10 digits" maxlength="10">
                        </div>
                        <div class="form-group">
                            <label class="form-label">Address</label>
                            <input type="text" name="address" class="form-control" placeholder="Residential City / Area">
                        </div>
                    </div>

                    <div class="form-row" style="background: #f8fafc; padding: 12px; border-radius: var(--radius-sm); border: 1px dashed var(--border-color);">
                        <div class="form-group" style="margin-bottom: 0;">
                            <label class="form-label">Initial Portal Username <span class="required">*</span></label>
                            <input type="text" name="username" class="form-control" placeholder="e.g. anand.varma" required>
                        </div>
                        <div class="form-group" style="margin-bottom: 0;">
                            <label class="form-label">Initial Password <span class="required">*</span></label>
                            <input type="password" name="password" class="form-control" placeholder="At least 6 chars" minlength="6" required>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline" onclick="closeModal('newPatientModal')">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Patient Record</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Modal: Edit Patient Demographics -->
    <div id="editPatientModal" class="modal-overlay">
        <div class="modal-card">
            <div class="modal-header">
                <h3 class="card-title">Edit Patient Record #<span id="editDisplayPatientId"></span></h3>
                <button type="button" class="btn-remove-row" onclick="closeModal('editPatientModal')">&times;</button>
            </div>
            <form action="updatePatient.jsp" method="POST">
                <div class="modal-body">
                    <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                    <input type="hidden" id="editPatientId" name="patientId" value="">

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Full Name <span class="required">*</span></label>
                            <input type="text" id="editFullName" name="fullName" class="form-control" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Date of Birth <span class="required">*</span></label>
                            <input type="date" id="editDob" name="dob" class="form-control" max="<%= java.time.LocalDate.now().toString() %>" required>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Gender <span class="required">*</span></label>
                            <select id="editGender" name="gender" class="form-control" required>
                                <option value="Male">Male</option>
                                <option value="Female">Female</option>
                                <option value="Other">Other</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Blood Group</label>
                            <select id="editBloodGroup" name="bloodGroup" class="form-control">
                                <option value="">Select Blood Group</option>
                                <option value="A+">A+</option>
                                <option value="A-">A-</option>
                                <option value="B+">B+</option>
                                <option value="B-">B-</option>
                                <option value="O+">O+</option>
                                <option value="O-">O-</option>
                                <option value="AB+">AB+</option>
                                <option value="AB-">AB-</option>
                            </select>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Phone Number <span class="required">*</span></label>
                            <input type="tel" id="editPhone" name="phone" class="form-control" maxlength="10" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Email Address <span class="required">*</span></label>
                            <input type="email" id="editEmail" name="email" class="form-control" required>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Emergency Contact Phone</label>
                            <input type="tel" id="editEmergency" name="emergencyContact" class="form-control" maxlength="10">
                        </div>
                        <div class="form-group">
                            <label class="form-label">Address</label>
                            <input type="text" id="editAddress" name="address" class="form-control">
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline" onclick="closeModal('editPatientModal')">Cancel</button>
                    <button type="submit" class="btn btn-primary">Update Demographics</button>
                </div>
            </form>
        </div>
    </div>

    <jsp:include page="includes/footer.jsp" />

    <script>
        function openEditPatientModal(id, name, dob, gender, phone, email, bGroup, addr, emerg) {
            document.getElementById('editDisplayPatientId').textContent = id;
            document.getElementById('editPatientId').value = id;
            document.getElementById('editFullName').value = name;
            document.getElementById('editDob').value = dob;
            document.getElementById('editGender').value = gender;
            document.getElementById('editPhone').value = phone;
            document.getElementById('editEmail').value = email;
            document.getElementById('editBloodGroup').value = bGroup || "";
            document.getElementById('editAddress').value = addr || "";
            document.getElementById('editEmergency').value = emerg || "";
            openModal('editPatientModal');
        }
    </script>
</body>
</html>
