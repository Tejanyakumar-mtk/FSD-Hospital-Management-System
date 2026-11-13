<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.hospital.util.SecurityUtil" %>
<%
    // If already logged in, redirect to respective dashboard
    String loggedRole = (String) session.getAttribute("userRole");
    if (loggedRole != null) {
        if ("PATIENT".equalsIgnoreCase(loggedRole)) {
            response.sendRedirect("patient-dashboard.jsp");
            return;
        } else if ("DOCTOR".equalsIgnoreCase(loggedRole)) {
            response.sendRedirect("doctor-dashboard.jsp");
            return;
        } else if ("ADMIN".equalsIgnoreCase(loggedRole) || "RECEPTIONIST".equalsIgnoreCase(loggedRole)) {
            response.sendRedirect("admin-dashboard.jsp");
            return;
        }
    }

    String errorMsg = request.getParameter("error");
    String successMsg = request.getParameter("msg");
    String returnUrl = request.getParameter("returnUrl");
    if (returnUrl == null) returnUrl = "";

    String csrfToken = SecurityUtil.getCsrfToken(session);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - CityHealth Hospital Management System</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/forms.css">
    <link rel="stylesheet" href="css/auth.css">
    <script src="js/validation.js"></script>
</head>
<body class="auth-page">

    <div class="auth-card">
        <div class="auth-header">
            <a href="index.jsp" class="auth-logo">
                <span class="icon">+</span>
                <span>CityHealth HMS</span>
            </a>
            <h2>Sign In to Your Account</h2>
            <p>Access your health records or hospital management workspace</p>
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

        <!-- Demo Account Credentials Box for Evaluator / Professor -->
        <div class="demo-credentials-box">
            <strong>Demonstration Accounts (Click or type to test):</strong>
            <ul>
                <li><a href="javascript:void(0)" onclick="fillCredentials('admin', 'Admin@123')">Admin: <code>admin</code></a></li>
                <li><a href="javascript:void(0)" onclick="fillCredentials('reception', 'Recep@123')">Staff: <code>reception</code></a></li>
                <li><a href="javascript:void(0)" onclick="fillCredentials('dr.sharma', 'Doctor@123')">Doctor: <code>dr.sharma</code></a></li>
                <li><a href="javascript:void(0)" onclick="fillCredentials('john.doe', 'Patient@123')">Patient: <code>john.doe</code></a></li>
            </ul>
        </div>

        <form action="loginAction.jsp" method="POST" class="login-form" onsubmit="return validateLoginForm();">
            <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
            <input type="hidden" name="returnUrl" value="<%= SecurityUtil.escapeHtml(returnUrl) %>">

            <div class="form-group">
                <label class="form-label" for="loginUsername">Username <span class="required">*</span></label>
                <input type="text" id="loginUsername" name="username" class="form-control" placeholder="Enter your username" required autofocus>
            </div>

            <div class="form-group">
                <div class="flex-between" style="margin-bottom: 6px;">
                    <label class="form-label" for="loginPassword" style="margin-bottom: 0;">Password <span class="required">*</span></label>
                </div>
                <div class="password-wrapper">
                    <input type="password" id="loginPassword" name="password" class="form-control" placeholder="Enter your password" required>
                    <button type="button" id="togglePassBtn" class="password-toggle-btn" onclick="togglePasswordVisibility('loginPassword', 'togglePassBtn')">Show</button>
                </div>
            </div>

            <button type="submit" class="btn btn-primary btn-block btn-lg" style="margin-top: 10px;">
                Sign In &rarr;
            </button>
        </form>

        <div class="auth-footer">
            <p>New patient at CityHealth? <a href="register.jsp">Create an Account</a></p>
            <p style="margin-top: 8px;"><a href="index.jsp">&larr; Return to Hospital Home</a></p>
        </div>
    </div>

    <script>
        function fillCredentials(user, pass) {
            document.getElementById('loginUsername').value = user;
            document.getElementById('loginPassword').value = pass;
        }
    </script>
</body>
</html>
