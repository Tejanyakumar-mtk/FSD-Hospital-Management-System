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
    String fullName = SecurityUtil.sanitize(request.getParameter("fullName"));
    String dobStr = SecurityUtil.sanitize(request.getParameter("dob"));
    String gender = SecurityUtil.sanitize(request.getParameter("gender"));
    String phone = SecurityUtil.sanitize(request.getParameter("phone"));
    String email = SecurityUtil.sanitize(request.getParameter("email"));
    String bloodGroup = SecurityUtil.sanitize(request.getParameter("bloodGroup"));
    String emergencyContact = SecurityUtil.sanitize(request.getParameter("emergencyContact"));
    String address = SecurityUtil.sanitize(request.getParameter("address"));

    if (patientId <= 0 || fullName.isEmpty() || dobStr.isEmpty() || gender.isEmpty() || phone.isEmpty() || email.isEmpty()) {
        response.sendRedirect("patients.jsp?error=Please+fill+in+all+required+fields.");
        return;
    }

    Connection conn = null;
    PreparedStatement patStmt = null;
    PreparedStatement userStmt = null;

    try {
        conn = DBConnection.getConnection();
        conn.setAutoCommit(false);

        // Update PATIENTS
        String updatePatSql = "UPDATE PATIENTS SET PATIENT_NAME = ?, DOB = TO_DATE(?, 'YYYY-MM-DD'), GENDER = ?, " +
                              "PHONE = ?, EMAIL = ?, BLOOD_GROUP = ?, EMERGENCY_CONTACT = ?, ADDRESS = ? WHERE PATIENT_ID = ?";
        patStmt = conn.prepareStatement(updatePatSql);
        patStmt.setString(1, fullName);
        patStmt.setString(2, dobStr);
        patStmt.setString(3, gender);
        patStmt.setString(4, phone);
        patStmt.setString(5, email);
        patStmt.setString(6, bloodGroup.isEmpty() ? null : bloodGroup);
        patStmt.setString(7, emergencyContact.isEmpty() ? null : emergencyContact);
        patStmt.setString(8, address.isEmpty() ? null : address);
        patStmt.setInt(9, patientId);
        patStmt.executeUpdate();

        // Also sync name in USERS table
        userStmt = conn.prepareStatement("UPDATE USERS SET FULL_NAME = ? WHERE PATIENT_ID = ?");
        userStmt.setString(1, fullName);
        userStmt.setInt(2, patientId);
        userStmt.executeUpdate();

        conn.commit();
        response.sendRedirect("patients.jsp?msg=Patient+%23" + patientId + "+updated+successfully.");

    } catch (Exception e) {
        if (conn != null) {
            try { conn.rollback(); } catch (SQLException ignored) {}
        }
        System.err.println("[updatePatient] Error: " + e.getMessage());
        response.sendRedirect("patients.jsp?error=System+error+updating+patient.");
    } finally {
        DBConnection.close(patStmt, userStmt, conn);
    }
%>
