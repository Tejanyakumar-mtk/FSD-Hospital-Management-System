<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    String userId = (String) session.getAttribute("userId");
    String userRole = (String) session.getAttribute("userRole");

    if (userId == null || (!"ADMIN".equalsIgnoreCase(userRole) && !"RECEPTIONIST".equalsIgnoreCase(userRole))) {
        response.sendRedirect("login.jsp?error=Access+restricted+to+authorized+staff.");
        return;
    }

    String msg = request.getParameter("msg");
    String error = request.getParameter("error");
    String csrfToken = SecurityUtil.getCsrfToken(session);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Department Management - CityHealth HMS</title>
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
                <li><a href="manage-doctors.jsp">&#128104;&#8205;&#9877;&#65039; Doctors</a></li>
                <li><a href="departments.jsp" class="active">&#127973; Departments</a></li>
                <li><a href="appointments.jsp">&#128197; Appointments</a></li>
                <li><a href="billing.jsp">&#128179; Billing &amp; Invoices</a></li>
                <li><a href="reports.jsp">&#128200; Reports &amp; Analytics</a></li>
                <li><a href="logout.jsp">&#128682; Logout</a></li>
            </ul>
        </aside>

        <main class="main-content">
            <div class="staff-topbar">
                <div class="staff-title">
                    <h2>Medical Departments</h2>
                    <p>Configure hospital clinical departments, medical disciplines, and specialties.</p>
                </div>
                <button type="button" class="btn btn-primary" onclick="openModal('newDeptModal')">+ Add Department</button>
            </div>

            <% if (msg != null && !msg.trim().isEmpty()) { %>
                <div class="alert alert-success">&#10003; <%= SecurityUtil.escapeHtml(msg) %></div>
            <% } %>
            <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="alert alert-danger">&#9888; <%= SecurityUtil.escapeHtml(error) %></div>
            <% } %>

            <!-- Departments Table -->
            <div class="card" style="padding: 0; overflow: hidden;">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Dept ID</th>
                                <th>Department Name</th>
                                <th>Description</th>
                                <th>Doctors Assigned</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                Connection conn = null;
                                PreparedStatement stmt = null;
                                ResultSet rs = null;
                                try {
                                    conn = DBConnection.getConnection();
                                    String sql = "SELECT dep.DEPARTMENT_ID, dep.DEPARTMENT_NAME, dep.DESCRIPTION, dep.ACTIVE, " +
                                                 "COUNT(d.DOCTOR_ID) AS DOC_COUNT " +
                                                 "FROM DEPARTMENTS dep " +
                                                 "LEFT JOIN DOCTORS d ON dep.DEPARTMENT_ID = d.DEPARTMENT_ID AND d.ACTIVE = 1 " +
                                                 "GROUP BY dep.DEPARTMENT_ID, dep.DEPARTMENT_NAME, dep.DESCRIPTION, dep.ACTIVE " +
                                                 "ORDER BY dep.DEPARTMENT_NAME";
                                    stmt = conn.prepareStatement(sql);
                                    rs = stmt.executeQuery();

                                    while (rs.next()) {
                                        int deptId = rs.getInt("DEPARTMENT_ID");
                                        String deptName = SecurityUtil.escapeHtml(rs.getString("DEPARTMENT_NAME"));
                                        String desc = SecurityUtil.escapeHtml(rs.getString("DESCRIPTION"));
                                        int docCount = rs.getInt("DOC_COUNT");
                                        int active = rs.getInt("ACTIVE");
                            %>
                            <tr>
                                <td><strong>#<%= deptId %></strong></td>
                                <td><strong><%= deptName %></strong></td>
                                <td><%= (desc != null && !desc.isEmpty()) ? desc : "--" %></td>
                                <td><span class="badge badge-info"><%= docCount %> Doctors</span></td>
                                <td>
                                    <span class="badge <%= (active == 1) ? "badge-success" : "badge-danger" %>">
                                        <%= (active == 1) ? "ACTIVE" : "INACTIVE" %>
                                    </span>
                                </td>
                                <td>
                                    <div class="table-actions">
                                        <button type="button" class="btn btn-outline btn-sm"
                                                onclick="openEditDeptModal(<%= deptId %>, '<%= deptName %>', '<%= desc %>')">
                                            Edit
                                        </button>
                                        <form action="saveDepartment.jsp" method="POST" style="display:inline;">
                                            <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                                            <input type="hidden" name="actionType" value="TOGGLE_STATUS">
                                            <input type="hidden" name="departmentId" value="<%= deptId %>">
                                            <input type="hidden" name="currentStatus" value="<%= active %>">
                                            <button type="submit" class="btn <%= (active == 1) ? "btn-danger" : "btn-success" %> btn-sm"
                                                    onclick="return confirm('Change status of department <%= deptName %>?');">
                                                <%= (active == 1) ? "Deactivate" : "Activate" %>
                                            </button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                            <%
                                    }
                                } catch (Exception e) {
                                    System.err.println("[departments.jsp] Error: " + e.getMessage());
                            %>
                            <tr>
                                <td colspan="6" style="color: var(--danger); text-align: center; padding: 20px;">
                                    Failed to retrieve departments: <%= SecurityUtil.escapeHtml(e.getMessage()) %>
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

    <!-- Modal: New Department -->
    <div id="newDeptModal" class="modal-overlay">
        <div class="modal-card">
            <div class="modal-header">
                <h3 class="card-title">Add Medical Department</h3>
                <button type="button" class="btn-remove-row" onclick="closeModal('newDeptModal')">&times;</button>
            </div>
            <form action="saveDepartment.jsp" method="POST">
                <div class="modal-body">
                    <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                    <input type="hidden" name="actionType" value="CREATE">

                    <div class="form-group">
                        <label class="form-label">Department Name <span class="required">*</span></label>
                        <input type="text" name="departmentName" class="form-control" placeholder="e.g. Oncology, Ophthalmology" required>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Clinical Description</label>
                        <textarea name="description" class="form-control" rows="3" placeholder="Scope of clinical care and diagnostic facilities..."></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline" onclick="closeModal('newDeptModal')">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Department</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Modal: Edit Department -->
    <div id="editDeptModal" class="modal-overlay">
        <div class="modal-card">
            <div class="modal-header">
                <h3 class="card-title">Edit Department #<span id="editDisplayDeptId"></span></h3>
                <button type="button" class="btn-remove-row" onclick="closeModal('editDeptModal')">&times;</button>
            </div>
            <form action="saveDepartment.jsp" method="POST">
                <div class="modal-body">
                    <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                    <input type="hidden" name="actionType" value="UPDATE">
                    <input type="hidden" id="editDeptId" name="departmentId" value="">

                    <div class="form-group">
                        <label class="form-label">Department Name <span class="required">*</span></label>
                        <input type="text" id="editDeptName" name="departmentName" class="form-control" required>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Clinical Description</label>
                        <textarea id="editDeptDesc" name="description" class="form-control" rows="3"></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline" onclick="closeModal('editDeptModal')">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Changes</button>
                </div>
            </form>
        </div>
    </div>

    <jsp:include page="includes/footer.jsp" />

    <script>
        function openEditDeptModal(id, name, desc) {
            document.getElementById('editDisplayDeptId').textContent = id;
            document.getElementById('editDeptId').value = id;
            document.getElementById('editDeptName').value = name;
            document.getElementById('editDeptDesc').value = desc || "";
            openModal('editDeptModal');
        }
    </script>
</body>
</html>
