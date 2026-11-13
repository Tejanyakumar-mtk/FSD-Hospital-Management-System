<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.time.LocalDate, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect("book-appointment.jsp");
        return;
    }

    if (!SecurityUtil.verifyCsrfToken(request)) {
        response.sendRedirect("book-appointment.jsp?error=Security+validation+failed.+Please+try+booking+again.");
        return;
    }

    String sessionRole = (String) session.getAttribute("userRole");
    String sessionPatientId = (String) session.getAttribute("patientId");

    // Must be logged in as Patient or Admin/Receptionist
    if (sessionRole == null) {
        response.sendRedirect("login.jsp?error=Session+expired.+Please+log+in.");
        return;
    }

    int patientId = 0;
    if ("PATIENT".equalsIgnoreCase(sessionRole)) {
        if (sessionPatientId == null) {
            response.sendRedirect("login.jsp?error=Invalid+patient+session.");
            return;
        }
        patientId = Integer.parseInt(sessionPatientId);
    } else if ("ADMIN".equalsIgnoreCase(sessionRole) || "RECEPTIONIST".equalsIgnoreCase(sessionRole)) {
        patientId = SecurityUtil.parseInt(request.getParameter("patientId"), 0);
        if (patientId <= 0) {
            response.sendRedirect("appointments.jsp?error=Please+select+a+valid+patient.");
            return;
        }
    } else {
        response.sendRedirect("login.jsp?error=Unauthorized+role+for+booking.");
        return;
    }

    int doctorId = SecurityUtil.parseInt(request.getParameter("doctorId"), 0);
    String apptDateStr = SecurityUtil.sanitize(request.getParameter("appointmentDate"));
    String apptTime = SecurityUtil.sanitize(request.getParameter("appointmentTime"));
    String reason = SecurityUtil.sanitize(request.getParameter("reason"));

    if (doctorId <= 0 || apptDateStr.isEmpty() || apptTime.isEmpty()) {
        String redir = "PATIENT".equalsIgnoreCase(sessionRole) ? "book-appointment.jsp" : "appointments.jsp";
        response.sendRedirect(redir + "?error=Please+fill+in+all+required+appointment+fields.");
        return;
    }

    // Validate date is not past
    try {
        LocalDate chosenDate = LocalDate.parse(apptDateStr);
        if (chosenDate.isBefore(LocalDate.now())) {
            String redir = "PATIENT".equalsIgnoreCase(sessionRole) ? "book-appointment.jsp" : "appointments.jsp";
            response.sendRedirect(redir + "?error=Cannot+book+an+appointment+for+a+past+date.");
            return;
        }
    } catch (Exception e) {
        String redir = "PATIENT".equalsIgnoreCase(sessionRole) ? "book-appointment.jsp" : "appointments.jsp";
        response.sendRedirect(redir + "?error=Invalid+date+format.");
        return;
    }

    Connection conn = null;
    PreparedStatement checkStmt = null;
    PreparedStatement apptStmt = null;
    PreparedStatement docFeeStmt = null;
    PreparedStatement billStmt = null;
    PreparedStatement itemStmt = null;
    PreparedStatement seqStmt = null;
    ResultSet rs = null;

    int newApptId = 0;

    try {
        conn = DBConnection.getConnection();
        conn.setAutoCommit(false); // Begin ACID transaction

        // 1. Concurrency Check: Ensure doctor is not already booked for the exact date and slot
        String checkSql = "SELECT COUNT(*) FROM APPOINTMENTS " +
                          "WHERE DOCTOR_ID = ? AND APPOINTMENT_DATE = TO_DATE(?, 'YYYY-MM-DD') " +
                          "AND APPOINTMENT_TIME = ? AND STATUS = 'BOOKED'";
        checkStmt = conn.prepareStatement(checkSql);
        checkStmt.setInt(1, doctorId);
        checkStmt.setString(2, apptDateStr);
        checkStmt.setString(3, apptTime);
        rs = checkStmt.executeQuery();

        if (rs.next() && rs.getInt(1) > 0) {
            conn.rollback();
            String redir = "PATIENT".equalsIgnoreCase(sessionRole) ? "book-appointment.jsp" : "appointments.jsp";
            response.sendRedirect(redir + "?error=The+selected+time+slot+(" + apptTime + ")+is+already+booked+for+this+doctor.+Please+choose+another+slot.");
            return;
        }
        DBConnection.close(rs, checkStmt);

        // 2. Fetch Doctor Consultation Fee and Doctor Name
        double consultationFee = 0.00;
        String doctorName = "";
        docFeeStmt = conn.prepareStatement("SELECT DOCTOR_NAME, CONSULTATION_FEE FROM DOCTORS WHERE DOCTOR_ID = ? AND ACTIVE = 1");
        docFeeStmt.setInt(1, doctorId);
        rs = docFeeStmt.executeQuery();
        if (rs.next()) {
            doctorName = rs.getString("DOCTOR_NAME");
            consultationFee = rs.getDouble("CONSULTATION_FEE");
        } else {
            conn.rollback();
            String redir = "PATIENT".equalsIgnoreCase(sessionRole) ? "book-appointment.jsp" : "appointments.jsp";
            response.sendRedirect(redir + "?error=The+selected+doctor+is+not+currently+active.");
            return;
        }
        DBConnection.close(rs, docFeeStmt);

        // 3. Obtain next appointment ID
        seqStmt = conn.prepareStatement("SELECT SEQ_APPOINTMENTS.NEXTVAL FROM DUAL");
        rs = seqStmt.executeQuery();
        if (rs.next()) {
            newApptId = rs.getInt(1);
        }
        DBConnection.close(rs, seqStmt);

        // 4. Insert Appointment
        String insertApptSql = "INSERT INTO APPOINTMENTS (APPOINTMENT_ID, PATIENT_ID, DOCTOR_ID, APPOINTMENT_DATE, APPOINTMENT_TIME, REASON, STATUS, CREATED_AT) " +
                               "VALUES (?, ?, ?, TO_DATE(?, 'YYYY-MM-DD'), ?, ?, 'BOOKED', CURRENT_TIMESTAMP)";
        apptStmt = conn.prepareStatement(insertApptSql);
        apptStmt.setInt(1, newApptId);
        apptStmt.setInt(2, patientId);
        apptStmt.setInt(3, doctorId);
        apptStmt.setString(4, apptDateStr);
        apptStmt.setString(5, apptTime);
        apptStmt.setString(6, reason.isEmpty() ? null : reason);
        apptStmt.executeUpdate();

        // 5. Automatically create Initial Billing record for Consultation Fee
        int newBillId = 0;
        seqStmt = conn.prepareStatement("SELECT SEQ_BILLS.NEXTVAL FROM DUAL");
        rs = seqStmt.executeQuery();
        if (rs.next()) {
            newBillId = rs.getInt(1);
        }
        DBConnection.close(rs, seqStmt);

        String insertBillSql = "INSERT INTO BILLS (BILL_ID, PATIENT_ID, APPOINTMENT_ID, TOTAL_AMOUNT, PAID_AMOUNT, BALANCE_AMOUNT, STATUS, CREATED_AT) " +
                               "VALUES (?, ?, ?, ?, 0.00, ?, 'PENDING', CURRENT_TIMESTAMP)";
        billStmt = conn.prepareStatement(insertBillSql);
        billStmt.setInt(1, newBillId);
        billStmt.setInt(2, patientId);
        billStmt.setInt(3, newApptId);
        billStmt.setDouble(4, consultationFee);
        billStmt.setDouble(5, consultationFee);
        billStmt.executeUpdate();

        // 6. Insert Bill Item
        String insertItemSql = "INSERT INTO BILL_ITEMS (ITEM_ID, BILL_ID, DESCRIPTION, QUANTITY, UNIT_PRICE, LINE_TOTAL) " +
                               "VALUES (SEQ_BILL_ITEMS.NEXTVAL, ?, ?, 1, ?, ?)";
        itemStmt = conn.prepareStatement(insertItemSql);
        itemStmt.setInt(1, newBillId);
        itemStmt.setString(2, "Consultation Fee - " + doctorName);
        itemStmt.setDouble(3, consultationFee);
        itemStmt.setDouble(4, consultationFee);
        itemStmt.executeUpdate();

        // Commit full transaction
        conn.commit();

        if ("PATIENT".equalsIgnoreCase(sessionRole)) {
            response.sendRedirect("patient-appointments.jsp?msg=Appointment+booked+successfully!+Appointment+ID:+%23" + newApptId);
        } else {
            response.sendRedirect("appointments.jsp?msg=Appointment+%23" + newApptId + "+successfully+booked+for+patient.");
        }

    } catch (Exception e) {
        if (conn != null) {
            try { conn.rollback(); } catch (SQLException ignored) {}
        }
        System.err.println("[saveAppointment] Transaction error: " + e.getMessage());
        String redir = "PATIENT".equalsIgnoreCase(sessionRole) ? "book-appointment.jsp" : "appointments.jsp";
        response.sendRedirect(redir + "?error=System+error+while+booking+appointment.+Please+try+again.");
    } finally {
        DBConnection.close(rs, checkStmt, apptStmt, docFeeStmt, billStmt, itemStmt, seqStmt, conn);
    }
%>
