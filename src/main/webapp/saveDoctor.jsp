<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.PasswordUtil, com.hospital.util.SecurityUtil" %>
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

    String doctorName = SecurityUtil.sanitize(request.getParameter("doctorName"));
    String specialization = SecurityUtil.sanitize(request.getParameter("specialization"));
    int departmentId = SecurityUtil.parseInt(request.getParameter("departmentId"), 0);
    double consultationFee = SecurityUtil.parseDouble(request.getParameter("consultationFee"), 0.00);
    String phone = SecurityUtil.sanitize(request.getParameter("phone"));
    String email = SecurityUtil.sanitize(request.getParameter("email"));
    String qualification = SecurityUtil.sanitize(request.getParameter("qualification"));
    String roomNo = SecurityUtil.sanitize(request.getParameter("roomNo"));
    String username = SecurityUtil.sanitize(request.getParameter("username"));
    String password = request.getParameter("password");

    if (doctorName.isEmpty() || specialization.isEmpty() || departmentId <= 0 || phone.isEmpty() || email.isEmpty() || username.isEmpty() || password == null || password.isEmpty()) {
        response.sendRedirect("manage-doctors.jsp?error=Please+complete+all+mandatory+doctor+fields.");
        return;
    }

    Connection conn = null;
    PreparedStatement checkStmt = null;
    PreparedStatement seqStmt = null;
    PreparedStatement docStmt = null;
    PreparedStatement userStmt = null;
    PreparedStatement availStmt = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        conn.setAutoCommit(false); // Begin Transaction

        // Check if username already taken
        checkStmt = conn.prepareStatement("SELECT COUNT(*) FROM USERS WHERE LOWER(USERNAME) = LOWER(?)");
        checkStmt.setString(1, username);
        rs = checkStmt.executeQuery();
        if (rs.next() && rs.getInt(1) > 0) {
            conn.rollback();
            response.sendRedirect("manage-doctors.jsp?error=The+username+'" + SecurityUtil.escapeHtml(username) + "'+is+already+taken.");
            return;
        }
        DBConnection.close(rs, checkStmt);

        // Get next doctor ID
        int newDoctorId = 0;
        seqStmt = conn.prepareStatement("SELECT SEQ_DOCTORS.NEXTVAL FROM DUAL");
        rs = seqStmt.executeQuery();
        if (rs.next()) newDoctorId = rs.getInt(1);
        DBConnection.close(rs, seqStmt);

        // Insert Doctor
        String insertDoc = "INSERT INTO DOCTORS (DOCTOR_ID, DOCTOR_NAME, EMAIL, PHONE, SPECIALIZATION, DEPARTMENT_ID, " +
                           "CONSULTATION_FEE, QUALIFICATION, ROOM_NO, ACTIVE) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)";
        docStmt = conn.prepareStatement(insertDoc);
        docStmt.setInt(1, newDoctorId);
        docStmt.setString(2, doctorName);
        docStmt.setString(3, email);
        docStmt.setString(4, phone);
        docStmt.setString(5, specialization);
        docStmt.setInt(6, departmentId);
        docStmt.setDouble(7, consultationFee);
        docStmt.setString(8, qualification.isEmpty() ? null : qualification);
        docStmt.setString(9, roomNo.isEmpty() ? null : roomNo);
        docStmt.executeUpdate();

        // Hash password
        String salt = PasswordUtil.generateSalt();
        String hash = PasswordUtil.hashPassword(password, salt);

        // Insert User Login for Doctor
        String insertUser = "INSERT INTO USERS (USER_ID, USERNAME, PASSWORD_HASH, PASSWORD_SALT, FULL_NAME, ROLE, DOCTOR_ID, ACTIVE) " +
                            "VALUES (SEQ_USERS.NEXTVAL, ?, ?, ?, ?, 'DOCTOR', ?, 1)";
        userStmt = conn.prepareStatement(insertUser);
        userStmt.setString(1, username);
        userStmt.setString(2, hash);
        userStmt.setString(3, salt);
        userStmt.setString(4, doctorName);
        userStmt.setInt(5, newDoctorId);
        userStmt.executeUpdate();

        // Create standard default weekly availability schedule (Mon-Fri 09:00 - 13:00)
        String[] defaultDays = {"Monday", "Wednesday", "Friday"};
        String insertAvail = "INSERT INTO DOCTOR_AVAILABILITY (AVAILABILITY_ID, DOCTOR_ID, DAY_OF_WEEK, START_TIME, END_TIME, SLOT_DURATION, ACTIVE) " +
                             "VALUES (SEQ_DOCTOR_AVAILABILITY.NEXTVAL, ?, ?, '09:00', '13:00', 30, 1)";
        availStmt = conn.prepareStatement(insertAvail);
        for (String day : defaultDays) {
            availStmt.setInt(1, newDoctorId);
            availStmt.setString(2, day);
            availStmt.executeUpdate();
        }

        conn.commit();
        response.sendRedirect("manage-doctors.jsp?msg=Doctor+" + SecurityUtil.escapeHtml(doctorName) + "+added+successfully+(ID:+%23" + newDoctorId + ").");

    } catch (Exception e) {
        if (conn != null) {
            try { conn.rollback(); } catch (SQLException ignored) {}
        }
        System.err.println("[saveDoctor] Error: " + e.getMessage());
        response.sendRedirect("manage-doctors.jsp?error=System+error+while+creating+doctor+profile.");
    } finally {
        DBConnection.close(rs, checkStmt, seqStmt, docStmt, userStmt, availStmt, conn);
    }
%>
