<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Server Error - CityHealth HMS</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/public.css">
</head>
<body style="min-height: 100vh; display: flex; flex-direction: column;">
    <jsp:include page="includes/navbar.jsp" />
    <div class="container" style="flex: 1; display: flex; align-items: center; justify-content: center; padding: 60px 20px;">
        <div class="card empty-state" style="max-width: 520px; width: 100%;">
            <div class="empty-state-icon" style="color: var(--danger);">&#9888;</div>
            <h2 style="font-size: 2.2rem; color: var(--danger);">Server Error</h2>
            <h3>An unexpected system condition occurred</h3>
            <p>Our technical team has been notified. For security, internal stack traces and database paths are not displayed.</p>
            <div style="margin-top: 20px; display: flex; gap: 12px; justify-content: center;">
                <a href="index.jsp" class="btn btn-primary">Return to Homepage</a>
                <a href="login.jsp" class="btn btn-outline">Go to Login</a>
            </div>
        </div>
    </div>
    <jsp:include page="includes/footer.jsp" />
</body>
</html>
