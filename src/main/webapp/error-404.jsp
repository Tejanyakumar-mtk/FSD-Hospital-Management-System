<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Page Not Found - CityHealth HMS</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/public.css">
</head>
<body style="min-height: 100vh; display: flex; flex-direction: column;">
    <jsp:include page="includes/navbar.jsp" />
    <div class="container" style="flex: 1; display: flex; align-items: center; justify-content: center; padding: 60px 20px;">
        <div class="card empty-state" style="max-width: 500px; width: 100%;">
            <div class="empty-state-icon" style="color: var(--primary);">&#9888;</div>
            <h2 style="font-size: 2.2rem; color: var(--secondary);">404</h2>
            <h3>Page Not Found</h3>
            <p>The page or medical record you requested could not be located. It may have been moved, renamed, or is temporarily unavailable.</p>
            <div style="margin-top: 20px; display: flex; gap: 12px; justify-content: center;">
                <a href="index.jsp" class="btn btn-primary">Return to Homepage</a>
                <a href="javascript:history.back()" class="btn btn-outline">Go Back</a>
            </div>
        </div>
    </div>
    <jsp:include page="includes/footer.jsp" />
</body>
</html>
