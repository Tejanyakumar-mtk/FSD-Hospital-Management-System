<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect("patients.jsp");
        return;
    }

    if (!SecurityUtil.verifyCsrfToken(request)) {
        response.sendRedirect("patients.jsp?error=Security+validation+failed.");
        return;
    }

    String sessionRole = (String) session.getAttribute("userRole");
    if (!"ADMIN".equalsIgnoreCase(sessionRole) && !"RECEPTIONIST".equalsIgnoreCase(sessionRole)) {
        response.sendRedirect("login.jsp?error=Unauthorized.");
        return;
    }

    int patientId = SecurityUtil.parseInt(request.getParameter("patientId"), 0);
    int currentStatus = SecurityUtil.parseInt(request.getParameter("currentStatus"), 1);
    int newStatus = (currentStatus == 1) ? 0 : 1;

    Connection conn = null;
    PreparedStatement patStmt = null;
    PreparedStatement userStmt = null;

    try {
        conn = DBConnection.getConnection();
        conn.setAutoCommit(false);

        patStmt = conn.prepareStatement("UPDATE PATIENTS SET ACTIVE = ? WHERE PATIENT_ID = ?");
        patStmt.setInt(1, newStatus);
        patStmt.setInt(2, patientId);
        patStmt.executeUpdate();

        userStmt = conn.prepareStatement("UPDATE USERS SET ACTIVE = ? WHERE PATIENT_ID = ?");
        userStmt.setInt(1, newStatus);
        userStmt.setInt(2, patientId);
        userStmt.executeUpdate();

        conn.commit();
        String statusLabel = (newStatus == 1) ? "activated" : "deactivated";
        response.sendRedirect("patients.jsp?msg=Patient+%23" + patientId + "+has+been+" + statusLabel + ".");

    } catch (Exception e) {
        if (conn != null) {
            try { conn.rollback(); } catch (SQLException ignored) {}
        }
        System.err.println("[togglePatientStatus] Error: " + e.getMessage());
        response.sendRedirect("patients.jsp?error=System+error+updating+patient+status.");
    } finally {
        DBConnection.close(patStmt, userStmt, conn);
    }
%>
