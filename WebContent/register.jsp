<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.hospital.util.SecurityUtil" %>
<%
    String errorMsg = request.getParameter("error");
    String successMsg = request.getParameter("msg");
    String csrfToken = SecurityUtil.getCsrfToken(session);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Patient Registration - CityHealth HMS</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/forms.css">
    <link rel="stylesheet" href="css/auth.css">
    <script src="js/validation.js"></script>
</head>
<body class="auth-page">

    <div class="auth-card auth-card-wide">
        <div class="auth-header">
            <a href="index.jsp" class="auth-logo">
                <span class="icon">+</span>
                <span>CityHealth HMS</span>
            </a>
            <h2>New Patient Registration</h2>
            <p>Register your profile to book appointments and track your health records</p>
        </div>

        <% if (errorMsg != null && !errorMsg.trim().isEmpty()) { %>
            <div class="alert alert-danger">
                &#9888; <%= SecurityUtil.escapeHtml(errorMsg) %>
            </div>
        <% } %>

        <% if (successMsg != null && !successMsg.trim().isEmpty()) { %>
            <div class="alert alert-success">
                &#10003; <%= SecurityUtil.escapeHtml(successMsg) %>
            </div>
        <% } %>

        <form name="regForm" action="registerPatient.jsp" method="POST" onsubmit="return validateRegistrationForm();">
            <input type="hidden" name="csrfToken" value="<%= csrfToken %>">

            <h3 style="font-size: 1.05rem; color: var(--primary); margin-bottom: 14px; border-bottom: 1px solid var(--border-color); padding-bottom: 6px;">
                1. Personal &amp; Contact Details
            </h3>

            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Full Name <span class="required">*</span></label>
                    <input type="text" name="fullName" class="form-control" placeholder="e.g. Ramesh Kumar" required>
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
                        <option value="">-- Select Gender --</option>
                        <option value="Male">Male</option>
                        <option value="Female">Female</option>
                        <option value="Other">Other</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">Blood Group</label>
                    <select name="bloodGroup" class="form-control">
                        <option value="">-- Select Blood Group --</option>
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
                    <label class="form-label">Mobile Number (10 digits) <span class="required">*</span></label>
                    <input type="tel" name="phone" class="form-control" placeholder="e.g. 9876543210" maxlength="10" required>
                </div>
                <div class="form-group">
                    <label class="form-label">Email Address <span class="required">*</span></label>
                    <input type="email" name="email" class="form-control" placeholder="e.g. ramesh@example.com" required>
                </div>
            </div>

            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Emergency Contact Phone</label>
                    <input type="tel" name="emergencyContact" class="form-control" placeholder="e.g. 9876543299" maxlength="10">
                </div>
                <div class="form-group">
                    <label class="form-label">Residential Address</label>
                    <input type="text" name="address" class="form-control" placeholder="e.g. Street, Colony, City">
                </div>
            </div>

            <h3 style="font-size: 1.05rem; color: var(--primary); margin: 20px 0 14px 0; border-bottom: 1px solid var(--border-color); padding-bottom: 6px;">
                2. Account Login Credentials
            </h3>

            <div class="form-group">
                <label class="form-label">Desired Username <span class="required">*</span></label>
                <input type="text" name="username" class="form-control" placeholder="e.g. ramesh.kumar" minlength="3" maxlength="30" required>
                <span class="form-text">Choose a unique username containing at least 3 letters or numbers.</span>
            </div>

            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Password <span class="required">*</span></label>
                    <div class="password-wrapper">
                        <input type="password" id="regPassword" name="password" class="form-control" placeholder="At least 6 characters" minlength="6" required>
                        <button type="button" id="toggleRegPass" class="password-toggle-btn" onclick="togglePasswordVisibility('regPassword', 'toggleRegPass')">Show</button>
                    </div>
                </div>
                <div class="form-group">
                    <label class="form-label">Confirm Password <span class="required">*</span></label>
                    <div class="password-wrapper">
                        <input type="password" id="regConfirmPass" name="confirmPassword" class="form-control" placeholder="Re-enter password" minlength="6" required>
                        <button type="button" id="toggleRegConfPass" class="password-toggle-btn" onclick="togglePasswordVisibility('regConfirmPass', 'toggleRegConfPass')">Show</button>
                    </div>
                </div>
            </div>

            <button type="submit" class="btn btn-primary btn-block btn-lg" style="margin-top: 14px;">
                Complete Registration &rarr;
            </button>
        </form>

        <div class="auth-footer">
            <p>Already registered? <a href="login.jsp">Sign in here</a></p>
            <p style="margin-top: 8px;"><a href="index.jsp">&larr; Return to Hospital Home</a></p>
        </div>
    </div>

</body>
</html>
