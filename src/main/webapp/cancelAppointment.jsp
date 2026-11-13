<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect("patient-appointments.jsp");
        return;
    }

    if (!SecurityUtil.verifyCsrfToken(request)) {
        response.sendRedirect("patient-appointments.jsp?error=Security+token+validation+failed.");
        return;
    }

    String sessionRole = (String) session.getAttribute("userRole");
    String sessionPatientId = (String) session.getAttribute("patientId");
    String sessionUserId = (String) session.getAttribute("userId");

    if (sessionRole == null) {
        response.sendRedirect("login.jsp?error=Session+expired.");
        return;
    }

    int apptId = SecurityUtil.parseInt(request.getParameter("appointmentId"), 0);
    if (apptId <= 0) {
        response.sendRedirect("patient-appointments.jsp?error=Invalid+appointment+reference.");
        return;
    }

    Connection conn = null;
    PreparedStatement verifyStmt = null;
    PreparedStatement updateStmt = null;
    
    PreparedStatement auditStmt = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        conn.setAutoCommit(false); // Transaction

        // 1. Verify Appointment & Ownership
        verifyStmt = conn.prepareStatement("SELECT PATIENT_ID, STATUS FROM APPOINTMENTS WHERE APPOINTMENT_ID = ?");
        verifyStmt.setInt(1, apptId);
        rs = verifyStmt.executeQuery();

        if (!rs.next()) {
            conn.rollback();
            String redir = "PATIENT".equalsIgnoreCase(sessionRole) ? "patient-appointments.jsp" : "appointments.jsp";
            response.sendRedirect(redir + "?error=Appointment+not+found.");
            return;
        }

        int ownerPatientId = rs.getInt("PATIENT_ID");
        String currentStatus = rs.getString("STATUS");

        // Enforce ownership if user is a patient
        if ("PATIENT".equalsIgnoreCase(sessionRole)) {
            int currentPatientId = Integer.parseInt(sessionPatientId);
            if (ownerPatientId != currentPatientId) {
                conn.rollback();
                response.sendRedirect("patient-appointments.jsp?error=Unauthorized:+You+cannot+modify+another+patient's+appointment.");
                return;
            }
        }

        if (!"BOOKED".equalsIgnoreCase(currentStatus)) {
            conn.rollback();
            String redir = "PATIENT".equalsIgnoreCase(sessionRole) ? "patient-appointments.jsp" : "appointments.jsp";
            response.sendRedirect(redir + "?error=Only+active+BOOKED+appointments+can+be+cancelled.");
            return;
        }

        // 2. Update Appointment to CANCELLED
        String cancelBy = "PATIENT".equalsIgnoreCase(sessionRole) ? "Cancelled by patient" : "Cancelled by hospital staff";
        updateStmt = conn.prepareStatement(
            "UPDATE APPOINTMENTS SET STATUS = 'CANCELLED', CANCELLED_AT = CURRENT_TIMESTAMP, CANCELLATION_REASON = ? WHERE APPOINTMENT_ID = ?"
        );
        updateStmt.setString(1, cancelBy);
        updateStmt.setInt(2, apptId);
        updateStmt.executeUpdate();

     // 3. Preserve billing status when cancelling an appointment.
     // Appointment status and bill payment status are managed separately.
     // Do not mark the bill as CANCELLED or erase its outstanding balance.
        // 4. Audit Log
        auditStmt = conn.prepareStatement(
            "INSERT INTO AUDIT_LOG (USER_ID, ACTION, ENTITY_TYPE, ENTITY_ID, DETAILS) VALUES (?, ?, ?, ?, ?)"
        );
        auditStmt.setInt(1, Integer.parseInt(sessionUserId));
        auditStmt.setString(2, "CANCEL_APPOINTMENT");
        auditStmt.setString(3, "APPOINTMENTS");
        auditStmt.setInt(4, apptId);
        auditStmt.setString(5, "Appointment cancelled by " + sessionRole);
        auditStmt.executeUpdate();

        conn.commit();

        String redir = "PATIENT".equalsIgnoreCase(sessionRole) ? "patient-appointments.jsp" : "appointments.jsp";
        response.sendRedirect(redir + "?msg=Appointment+%23" + apptId + "+has+been+successfully+cancelled.");

    } catch (Exception e) {
        if (conn != null) {
            try { conn.rollback(); } catch (SQLException ignored) {}
        }
        System.err.println("[cancelAppointment] Error: " + e.getMessage());
        String redir = "PATIENT".equalsIgnoreCase(sessionRole) ? "patient-appointments.jsp" : "appointments.jsp";
        response.sendRedirect(redir + "?error=System+error+while+cancelling+appointment.");
    } finally {
        DBConnection.close(rs, verifyStmt, updateStmt, auditStmt, conn);
    }
%>
