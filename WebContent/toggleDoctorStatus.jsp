<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect("manage-doctors.jsp");
        return;
    }

    if (!SecurityUtil.verifyCsrfToken(request)) {
        response.sendRedirect("manage-doctors.jsp?error=Security+validation+failed.");
        return;
    }

    String sessionRole = (String) session.getAttribute("userRole");
    if (!"ADMIN".equalsIgnoreCase(sessionRole) && !"RECEPTIONIST".equalsIgnoreCase(sessionRole)) {
        response.sendRedirect("login.jsp?error=Unauthorized.");
        return;
    }

    int doctorId = SecurityUtil.parseInt(request.getParameter("doctorId"), 0);
    int currentStatus = SecurityUtil.parseInt(request.getParameter("currentStatus"), 1);
    int newStatus = (currentStatus == 1) ? 0 : 1;

    Connection conn = null;
    PreparedStatement docStmt = null;
    PreparedStatement userStmt = null;

    try {
        conn = DBConnection.getConnection();
        conn.setAutoCommit(false);

        docStmt = conn.prepareStatement("UPDATE DOCTORS SET ACTIVE = ? WHERE DOCTOR_ID = ?");
        docStmt.setInt(1, newStatus);
        docStmt.setInt(2, doctorId);
        docStmt.executeUpdate();

        userStmt = conn.prepareStatement("UPDATE USERS SET ACTIVE = ? WHERE DOCTOR_ID = ?");
        userStmt.setInt(1, newStatus);
        userStmt.setInt(2, doctorId);
        userStmt.executeUpdate();

        conn.commit();
        String lbl = (newStatus == 1) ? "activated" : "deactivated";
        response.sendRedirect("manage-doctors.jsp?msg=Doctor+%23" + doctorId + "+has+been+" + lbl + ".");

    } catch (Exception e) {
        if (conn != null) {
            try { conn.rollback(); } catch (SQLException ignored) {}
        }
        System.err.println("[toggleDoctorStatus] Error: " + e.getMessage());
        response.sendRedirect("manage-doctors.jsp?error=System+error+updating+doctor+status.");
    } finally {
        DBConnection.close(docStmt, userStmt, conn);
    }
%>
