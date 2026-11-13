<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.time.LocalDate, com.hospital.util.DBConnection, com.hospital.util.PasswordUtil, com.hospital.util.SecurityUtil" %>
<%
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect("register.jsp");
        return;
    }

    if (!SecurityUtil.verifyCsrfToken(request)) {
        response.sendRedirect("register.jsp?error=Security+token+mismatch.+Please+resubmit+form.");
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
    String confirmPassword = request.getParameter("confirmPassword");

    // Validation
    if (fullName.isEmpty() || dobStr.isEmpty() || gender.isEmpty() || phone.isEmpty() || email.isEmpty() || username.isEmpty() || password == null || password.isEmpty()) {
        response.sendRedirect("register.jsp?error=Please+fill+in+all+required+fields.");
        return;
    }

    if (!phone.matches("^[0-9]{10}$")) {
        response.sendRedirect("register.jsp?error=Phone+number+must+be+exactly+10+digits.");
        return;
    }

    if (!email.matches("^[A-Za-z0-9+_.-]+@(.+)$")) {
        response.sendRedirect("register.jsp?error=Please+enter+a+valid+email+address.");
        return;
    }

    if (password.length() < 6) {
        response.sendRedirect("register.jsp?error=Password+must+be+at+least+6+characters.");
        return;
    }

    if (!password.equals(confirmPassword)) {
        response.sendRedirect("register.jsp?error=Passwords+do+not+match.");
        return;
    }

    Connection conn = null;
    PreparedStatement checkStmt = null;
    PreparedStatement patStmt = null;
    PreparedStatement userStmt = null;
    PreparedStatement seqStmt = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        conn.setAutoCommit(false); // Begin ACID transaction

        // 1. Check if username already exists
        checkStmt = conn.prepareStatement("SELECT COUNT(*) FROM USERS WHERE LOWER(USERNAME) = LOWER(?)");
        checkStmt.setString(1, username);
        rs = checkStmt.executeQuery();
        if (rs.next() && rs.getInt(1) > 0) {
            conn.rollback();
            response.sendRedirect("register.jsp?error=The+username+'" + SecurityUtil.escapeHtml(username) + "'+is+already+taken.+Please+choose+another.");
            return;
        }
        DBConnection.close(rs, checkStmt);

        // 2. Obtain next patient ID from sequence
        int newPatientId = 0;
        seqStmt = conn.prepareStatement("SELECT SEQ_PATIENTS.NEXTVAL FROM DUAL");
        rs = seqStmt.executeQuery();
        if (rs.next()) {
            newPatientId = rs.getInt(1);
        }
        DBConnection.close(rs, seqStmt);

        // 3. Insert into PATIENTS
        String insertPatSql = "INSERT INTO PATIENTS (PATIENT_ID, PATIENT_NAME, DOB, GENDER, PHONE, EMAIL, ADDRESS, BLOOD_GROUP, EMERGENCY_CONTACT, ACTIVE) " +
                              "VALUES (?, ?, TO_DATE(?, 'YYYY-MM-DD'), ?, ?, ?, ?, ?, ?, 1)";
        patStmt = conn.prepareStatement(insertPatSql);
        patStmt.setInt(1, newPatientId);
        patStmt.setString(2, fullName);
        patStmt.setString(3, dobStr);
        patStmt.setString(4, gender);
        patStmt.setString(5, phone);
        patStmt.setString(6, email);
        patStmt.setString(7, address);
        patStmt.setString(8, bloodGroup.isEmpty() ? null : bloodGroup);
        patStmt.setString(9, emergencyContact.isEmpty() ? null : emergencyContact);
        patStmt.executeUpdate();

        // 4. Hash password with PBKDF2
        String salt = PasswordUtil.generateSalt();
        String hash = PasswordUtil.hashPassword(password, salt);

        // 5. Insert into USERS
        String insertUserSql = "INSERT INTO USERS (USER_ID, USERNAME, PASSWORD_HASH, PASSWORD_SALT, FULL_NAME, ROLE, PATIENT_ID, DOCTOR_ID, ACTIVE) " +
                              "VALUES (SEQ_USERS.NEXTVAL, ?, ?, ?, ?, 'PATIENT', ?, NULL, 1)";
        userStmt = conn.prepareStatement(insertUserSql);
        userStmt.setString(1, username);
        userStmt.setString(2, hash);
        userStmt.setString(3, salt);
        userStmt.setString(4, fullName);
        userStmt.setInt(5, newPatientId);
        userStmt.executeUpdate();

        // Commit transaction
        conn.commit();

        response.sendRedirect("login.jsp?msg=Registration+successful!+Please+log+in+with+your+username+and+password.");

    } catch (Exception e) {
        if (conn != null) {
            try { conn.rollback(); } catch (SQLException ignored) {}
        }
        System.err.println("[registerPatient] Transaction Error: " + e.getMessage());
        response.sendRedirect("register.jsp?error=Failed+to+complete+registration+due+to+a+system+error.+Please+try+again.");
    } finally {
        DBConnection.close(rs, checkStmt, patStmt, userStmt, seqStmt, conn);
    }
%>
