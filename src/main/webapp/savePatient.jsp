<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.PasswordUtil, com.hospital.util.SecurityUtil" %>
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

    String fullName = SecurityUtil.sanitize(request.getParameter("fullName"));
    String dobStr = SecurityUtil.sanitize(request.getParameter("dob"));
    String gender = SecurityUtil.sanitize(request.getParameter("gender"));
    String phone = SecurityUtil.sanitize(request.getParameter("phone"));
    String email = SecurityUtil.sanitize(request.getParameter("email"));
    String bloodGroup = SecurityUtil.sanitize(request.getParameter("bloodGroup"));
    String emergencyContact = SecurityUtil.sanitize(request.getParameter("emergencyContact"));
    String address = SecurityUtil.sanitize(request.getParameter("address"));
    String username = SecurityUtil.sanitize(request.getParameter("username"));
    String password = request.getParameter("password");

    if (fullName.isEmpty() || dobStr.isEmpty() || gender.isEmpty() || phone.isEmpty() || email.isEmpty() || username.isEmpty() || password == null || password.isEmpty()) {
        response.sendRedirect("patients.jsp?error=Please+complete+all+mandatory+patient+fields.");
        return;
    }

    Connection conn = null;
    PreparedStatement checkStmt = null;
    PreparedStatement seqStmt = null;
    PreparedStatement patStmt = null;
    PreparedStatement userStmt = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        conn.setAutoCommit(false); // Begin Transaction

        // Check if username taken
        checkStmt = conn.prepareStatement("SELECT COUNT(*) FROM USERS WHERE LOWER(USERNAME) = LOWER(?)");
        checkStmt.setString(1, username);
        rs = checkStmt.executeQuery();
        if (rs.next() && rs.getInt(1) > 0) {
            conn.rollback();
            response.sendRedirect("patients.jsp?error=Username+'" + SecurityUtil.escapeHtml(username) + "'+is+already+assigned.");
            return;
        }
        DBConnection.close(rs, checkStmt);

        // Get next patient ID
        int newPatientId = 0;
        seqStmt = conn.prepareStatement("SELECT SEQ_PATIENTS.NEXTVAL FROM DUAL");
        rs = seqStmt.executeQuery();
        if (rs.next()) newPatientId = rs.getInt(1);
        DBConnection.close(rs, seqStmt);

        // Insert Patient
        String insertPat = "INSERT INTO PATIENTS (PATIENT_ID, PATIENT_NAME, DOB, GENDER, PHONE, EMAIL, ADDRESS, BLOOD_GROUP, EMERGENCY_CONTACT, ACTIVE) " +
                           "VALUES (?, ?, TO_DATE(?, 'YYYY-MM-DD'), ?, ?, ?, ?, ?, ?, 1)";
        patStmt = conn.prepareStatement(insertPat);
        patStmt.setInt(1, newPatientId);
        patStmt.setString(2, fullName);
        patStmt.setString(3, dobStr);
        patStmt.setString(4, gender);
        patStmt.setString(5, phone);
        patStmt.setString(6, email);
        patStmt.setString(7, address.isEmpty() ? null : address);
        patStmt.setString(8, bloodGroup.isEmpty() ? null : bloodGroup);
        patStmt.setString(9, emergencyContact.isEmpty() ? null : emergencyContact);
        patStmt.executeUpdate();

        // Hash password
        String salt = PasswordUtil.generateSalt();
        String hash = PasswordUtil.hashPassword(password, salt);

        // Insert User Login
        String insertUser = "INSERT INTO USERS (USER_ID, USERNAME, PASSWORD_HASH, PASSWORD_SALT, FULL_NAME, ROLE, PATIENT_ID, ACTIVE) " +
                            "VALUES (SEQ_USERS.NEXTVAL, ?, ?, ?, ?, 'PATIENT', ?, 1)";
        userStmt = conn.prepareStatement(insertUser);
        userStmt.setString(1, username);
        userStmt.setString(2, hash);
        userStmt.setString(3, salt);
        userStmt.setString(4, fullName);
        userStmt.setInt(5, newPatientId);
        userStmt.executeUpdate();

        conn.commit();
        response.sendRedirect("patients.jsp?msg=Patient+" + SecurityUtil.escapeHtml(fullName) + "+registered+successfully+(ID:+%23" + newPatientId + ").");

    } catch (Exception e) {
        if (conn != null) {
            try { conn.rollback(); } catch (SQLException ignored) {}
        }
        System.err.println("[savePatient] Error: " + e.getMessage());
        response.sendRedirect("patients.jsp?error=Database+error+while+registering+patient.");
    } finally {
        DBConnection.close(rs, checkStmt, seqStmt, patStmt, userStmt, conn);
    }
%>
