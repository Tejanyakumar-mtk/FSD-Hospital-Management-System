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
    String doctorName = SecurityUtil.sanitize(request.getParameter("doctorName"));
    String specialization = SecurityUtil.sanitize(request.getParameter("specialization"));
    int departmentId = SecurityUtil.parseInt(request.getParameter("departmentId"), 0);
    double consultationFee = SecurityUtil.parseDouble(request.getParameter("consultationFee"), 0.00);
    String phone = SecurityUtil.sanitize(request.getParameter("phone"));
    String email = SecurityUtil.sanitize(request.getParameter("email"));
    String qualification = SecurityUtil.sanitize(request.getParameter("qualification"));
    String roomNo = SecurityUtil.sanitize(request.getParameter("roomNo"));

    if (doctorId <= 0 || doctorName.isEmpty() || specialization.isEmpty() || departmentId <= 0 || phone.isEmpty() || email.isEmpty()) {
        response.sendRedirect("manage-doctors.jsp?error=Please+complete+all+required+fields.");
        return;
    }

    Connection conn = null;
    PreparedStatement docStmt = null;
    PreparedStatement userStmt = null;

    try {
        conn = DBConnection.getConnection();
        conn.setAutoCommit(false);

        String updateSql = "UPDATE DOCTORS SET DOCTOR_NAME = ?, EMAIL = ?, PHONE = ?, SPECIALIZATION = ?, " +
                           "DEPARTMENT_ID = ?, CONSULTATION_FEE = ?, QUALIFICATION = ?, ROOM_NO = ? WHERE DOCTOR_ID = ?";
        docStmt = conn.prepareStatement(updateSql);
        docStmt.setString(1, doctorName);
        docStmt.setString(2, email);
        docStmt.setString(3, phone);
        docStmt.setString(4, specialization);
        docStmt.setInt(5, departmentId);
        docStmt.setDouble(6, consultationFee);
        docStmt.setString(7, qualification.isEmpty() ? null : qualification);
        docStmt.setString(8, roomNo.isEmpty() ? null : roomNo);
        docStmt.setInt(9, doctorId);
        docStmt.executeUpdate();

        userStmt = conn.prepareStatement("UPDATE USERS SET FULL_NAME = ? WHERE DOCTOR_ID = ?");
        userStmt.setString(1, doctorName);
        userStmt.setInt(2, doctorId);
        userStmt.executeUpdate();

        conn.commit();
        response.sendRedirect("manage-doctors.jsp?msg=Doctor+%23" + doctorId + "+updated+successfully.");

    } catch (Exception e) {
        if (conn != null) {
            try { conn.rollback(); } catch (SQLException ignored) {}
        }
        System.err.println("[updateDoctor] Error: " + e.getMessage());
        response.sendRedirect("manage-doctors.jsp?error=Database+error+updating+doctor.");
    } finally {
        DBConnection.close(docStmt, userStmt, conn);
    }
%>
