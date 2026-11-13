<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    String userId = (String) session.getAttribute("userId");
    String userRole = (String) session.getAttribute("userRole");
    String patientIdStr = (String) session.getAttribute("patientId");

    if (userId == null || !"PATIENT".equalsIgnoreCase(userRole) || patientIdStr == null) {
        response.sendRedirect("login.jsp?error=Please+log+in+as+a+patient.");
        return;
    }

    int patientId = Integer.parseInt(patientIdStr);
    String msg = request.getParameter("msg");
    String error = request.getParameter("error");
    String csrfToken = SecurityUtil.getCsrfToken(session);

    String name = "", dob = "", gender = "", phone = "", email = "", address = "", bloodGroup = "", emergencyContact = "";
    String username = (String) session.getAttribute("username");

    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        stmt = conn.prepareStatement(
            "SELECT PATIENT_NAME, TO_CHAR(DOB, 'YYYY-MM-DD') AS DOB_STR, GENDER, PHONE, EMAIL, ADDRESS, BLOOD_GROUP, EMERGENCY_CONTACT " +
            "FROM PATIENTS WHERE PATIENT_ID = ?"
        );
        stmt.setInt(1, patientId);
        rs = stmt.executeQuery();
        if (rs.next()) {
            name = rs.getString("PATIENT_NAME");
            dob = rs.getString("DOB_STR");
            gender = rs.getString("GENDER");
            phone = rs.getString("PHONE");
            email = rs.getString("EMAIL");
            address = rs.getString("ADDRESS");
            bloodGroup = rs.getString("BLOOD_GROUP");
            emergencyContact = rs.getString("EMERGENCY_CONTACT");
        }
    } catch (Exception e) {
        System.err.println("[patient-profile] Fetch error: " + e.getMessage());
    } finally {
        DBConnection.close(rs, stmt, conn);
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Profile - CityHealth HMS</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/forms.css">
    <link rel="stylesheet" href="css/patient.css">
    <script src="js/validation.js"></script>
</head>
<body>

    <jsp:include page="includes/navbar.jsp" />

    <div class="app-layout">
        <aside class="sidebar">
            <div class="sidebar-heading">Patient Menu</div>
            <ul class="sidebar-menu">
                <li><a href="patient-dashboard.jsp">&#127968; Dashboard</a></li>
                <li><a href="book-appointment.jsp">&#128197; Book Appointment</a></li>
                <li><a href="patient-appointments.jsp">&#128203; My Appointments</a></li>
                <li><a href="doctors.jsp">&#128104;&#8205;&#9877;&#65039; Find Doctors</a></li>
                <li><a href="patient-profile.jsp" class="active">&#128100; My Profile</a></li>
                <li><a href="logout.jsp">&#128682; Logout</a></li>
            </ul>
        </aside>

        <main class="main-content">
            <div style="margin-bottom: 24px;">
                <h2>Patient Profile &amp; Settings</h2>
                <p class="lead">View your hospital demographics and update your contact info or security password.</p>
            </div>

            <% if (msg != null && !msg.trim().isEmpty()) { %>
                <div class="alert alert-success">&#10003; <%= SecurityUtil.escapeHtml(msg) %></div>
            <% } %>
            <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="alert alert-danger">&#9888; <%= SecurityUtil.escapeHtml(error) %></div>
            <% } %>

            <div class="grid grid-2" style="align-items: start;">
                <!-- Profile Details Form -->
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title">Demographics &amp; Contact Details</h3>
                    </div>

                    <form action="updatePatientProfile.jsp" method="POST">
                        <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                        <input type="hidden" name="actionType" value="UPDATE_CONTACT">

                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Patient ID</label>
                                <input type="text" class="form-control" value="#<%= patientId %>" disabled>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Username</label>
                                <input type="text" class="form-control" value="<%= SecurityUtil.escapeHtml(username) %>" disabled>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Full Name</label>
                                <input type="text" class="form-control" value="<%= SecurityUtil.escapeHtml(name) %>" disabled>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Date of Birth</label>
                                <input type="text" class="form-control" value="<%= dob %>" disabled>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Gender</label>
                                <input type="text" class="form-control" value="<%= SecurityUtil.escapeHtml(gender) %>" disabled>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Blood Group</label>
                                <input type="text" class="form-control" value="<%= bloodGroup != null ? SecurityUtil.escapeHtml(bloodGroup) : "--" %>" disabled>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Phone Number <span class="required">*</span></label>
                                <input type="tel" name="phone" class="form-control" value="<%= SecurityUtil.escapeHtml(phone) %>" maxlength="10" required>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Email Address <span class="required">*</span></label>
                                <input type="email" name="email" class="form-control" value="<%= SecurityUtil.escapeHtml(email) %>" required>
                            </div>
                        </div>

                        <div class="form-group">
                            <label class="form-label">Emergency Contact Phone</label>
                            <input type="tel" name="emergencyContact" class="form-control" value="<%= emergencyContact != null ? SecurityUtil.escapeHtml(emergencyContact) : "" %>" maxlength="10">
                        </div>

                        <div class="form-group">
                            <label class="form-label">Residential Address</label>
                            <textarea name="address" class="form-control" rows="3"><%= address != null ? SecurityUtil.escapeHtml(address) : "" %></textarea>
                        </div>

                        <button type="submit" class="btn btn-primary">Save Profile Updates</button>
                    </form>
                </div>

                <!-- Security & Password Change Card -->
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title">Security &amp; Password</h3>
                    </div>

                    <form action="updatePatientProfile.jsp" method="POST">
                        <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                        <input type="hidden" name="actionType" value="CHANGE_PASSWORD">

                        <div class="form-group">
                            <label class="form-label">Current Password <span class="required">*</span></label>
                            <div class="password-wrapper">
                                <input type="password" id="currPass" name="currentPassword" class="form-control" required>
                                <button type="button" id="toggleCurr" class="password-toggle-btn" onclick="togglePasswordVisibility('currPass', 'toggleCurr')">Show</button>
                            </div>
                        </div>

                        <div class="form-group">
                            <label class="form-label">New Password <span class="required">*</span></label>
                            <div class="password-wrapper">
                                <input type="password" id="newPass" name="newPassword" class="form-control" minlength="6" required>
                                <button type="button" id="toggleNew" class="password-toggle-btn" onclick="togglePasswordVisibility('newPass', 'toggleNew')">Show</button>
                            </div>
                            <span class="form-text">Minimum 6 characters.</span>
                        </div>

                        <div class="form-group">
                            <label class="form-label">Confirm New Password <span class="required">*</span></label>
                            <div class="password-wrapper">
                                <input type="password" id="confNewPass" name="confirmNewPassword" class="form-control" minlength="6" required>
                                <button type="button" id="toggleConfNew" class="password-toggle-btn" onclick="togglePasswordVisibility('confNewPass', 'toggleConfNew')">Show</button>
                            </div>
                        </div>

                        <button type="submit" class="btn btn-secondary">Update Password</button>
                    </form>
                </div>
            </div>
        </main>
    </div>

    <jsp:include page="includes/footer.jsp" />

</body>
</html>
