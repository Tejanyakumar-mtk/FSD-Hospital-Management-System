<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.time.LocalDate, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect("appointments.jsp");
        return;
    }

    if (!SecurityUtil.verifyCsrfToken(request)) {
        response.sendRedirect("appointments.jsp?error=Security+validation+failed.");
        return;
    }

    String sessionRole = (String) session.getAttribute("userRole");
    String sessionUserId = (String) session.getAttribute("userId");
    String sessionDoctorId = (String) session.getAttribute("doctorId");

    // Can be triggered by staff (ADMIN / RECEPTIONIST) or assigned DOCTOR
    if (sessionRole == null) {
        response.sendRedirect("login.jsp?error=Session+expired.");
        return;
    }

    String actionType = request.getParameter("actionType");
    int apptId = SecurityUtil.parseInt(request.getParameter("appointmentId"), 0);

    if (apptId <= 0) {
        response.sendRedirect("appointments.jsp?error=Invalid+appointment+reference.");
        return;
    }

    Connection conn = null;
    PreparedStatement stmt = null;
    PreparedStatement checkStmt = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        conn.setAutoCommit(false);

        // Fetch current appointment
        int doctorId = 0;
        String currentStatus = "";
        stmt = conn.prepareStatement("SELECT DOCTOR_ID, STATUS FROM APPOINTMENTS WHERE APPOINTMENT_ID = ?");
        stmt.setInt(1, apptId);
        rs = stmt.executeQuery();
        if (rs.next()) {
            doctorId = rs.getInt("DOCTOR_ID");
            currentStatus = rs.getString("STATUS");
        } else {
            conn.rollback();
            response.sendRedirect("appointments.jsp?error=Appointment+not+found.");
            return;
        }
        DBConnection.close(rs, stmt);

        // If logged in as Doctor, verify assignment
        if ("DOCTOR".equalsIgnoreCase(sessionRole)) {
            int currentDocId = Integer.parseInt(sessionDoctorId);
            if (doctorId != currentDocId) {
                conn.rollback();
                response.sendRedirect("doctor-appointments.jsp?error=Unauthorized:+You+cannot+modify+another+doctor's+appointments.");
                return;
            }
        }

        if ("MARK_COMPLETED".equalsIgnoreCase(actionType)) {
            stmt = conn.prepareStatement("UPDATE APPOINTMENTS SET STATUS = 'COMPLETED' WHERE APPOINTMENT_ID = ?");
            stmt.setInt(1, apptId);
            stmt.executeUpdate();

            // Audit
            PreparedStatement auditStmt = conn.prepareStatement(
                "INSERT INTO AUDIT_LOG (USER_ID, ACTION, ENTITY_TYPE, ENTITY_ID, DETAILS) VALUES (?, ?, ?, ?, ?)"
            );
            auditStmt.setInt(1, Integer.parseInt(sessionUserId));
            auditStmt.setString(2, "COMPLETE_APPOINTMENT");
            auditStmt.setString(3, "APPOINTMENTS");
            auditStmt.setInt(4, apptId);
            auditStmt.setString(5, "Appointment marked completed by " + sessionRole);
            auditStmt.executeUpdate();
            DBConnection.close(auditStmt);

            conn.commit();

            String redir = "DOCTOR".equalsIgnoreCase(sessionRole) ? "doctor-appointments.jsp" : "appointments.jsp";
            response.sendRedirect(redir + "?msg=Appointment+%23" + apptId + "+marked+as+COMPLETED.");
            return;

        } else if ("RESCHEDULE".equalsIgnoreCase(actionType)) {
            String newDate = SecurityUtil.sanitize(request.getParameter("newDate"));
            String newTime = SecurityUtil.sanitize(request.getParameter("newTime"));

            if (newDate.isEmpty() || newTime.isEmpty()) {
                conn.rollback();
                response.sendRedirect("appointments.jsp?error=Please+provide+both+date+and+time+slot+for+rescheduling.");
                return;
            }

            LocalDate chosenDate = LocalDate.parse(newDate);
            if (chosenDate.isBefore(LocalDate.now())) {
                conn.rollback();
                response.sendRedirect("appointments.jsp?error=Cannot+reschedule+to+a+past+date.");
                return;
            }

            // Check slot conflict
            checkStmt = conn.prepareStatement(
                "SELECT COUNT(*) FROM APPOINTMENTS WHERE DOCTOR_ID = ? AND APPOINTMENT_DATE = TO_DATE(?, 'YYYY-MM-DD') " +
                "AND APPOINTMENT_TIME = ? AND STATUS = 'BOOKED' AND APPOINTMENT_ID != ?"
            );
            checkStmt.setInt(1, doctorId);
            checkStmt.setString(2, newDate);
            checkStmt.setString(3, newTime);
            checkStmt.setInt(4, apptId);
            rs = checkStmt.executeQuery();
            if (rs.next() && rs.getInt(1) > 0) {
                conn.rollback();
                response.sendRedirect("appointments.jsp?error=Doctor+already+has+a+booking+for+" + newDate + "+at+" + newTime + ".");
                return;
            }
            DBConnection.close(rs, checkStmt);

            stmt = conn.prepareStatement(
                "UPDATE APPOINTMENTS SET APPOINTMENT_DATE = TO_DATE(?, 'YYYY-MM-DD'), APPOINTMENT_TIME = ?, STATUS = 'BOOKED' WHERE APPOINTMENT_ID = ?"
            );
            stmt.setString(1, newDate);
            stmt.setString(2, newTime);
            stmt.setInt(3, apptId);
            stmt.executeUpdate();

            // Audit
            PreparedStatement auditStmt = conn.prepareStatement(
                "INSERT INTO AUDIT_LOG (USER_ID, ACTION, ENTITY_TYPE, ENTITY_ID, DETAILS) VALUES (?, ?, ?, ?, ?)"
            );
            auditStmt.setInt(1, Integer.parseInt(sessionUserId));
            auditStmt.setString(2, "RESCHEDULE_APPOINTMENT");
            auditStmt.setString(3, "APPOINTMENTS");
            auditStmt.setInt(4, apptId);
            auditStmt.setString(5, "Rescheduled to " + newDate + " " + newTime + " by " + sessionRole);
            auditStmt.executeUpdate();
            DBConnection.close(auditStmt);

            conn.commit();
            response.sendRedirect("appointments.jsp?msg=Appointment+%23" + apptId + "+rescheduled+to+" + newDate + "+at+" + newTime + ".");
            return;
        }

    } catch (Exception e) {
        if (conn != null) {
            try { conn.rollback(); } catch (SQLException ignored) {}
        }
        System.err.println("[adminAppointmentAction] Error: " + e.getMessage());
        response.sendRedirect("appointments.jsp?error=System+error+updating+appointment.");
    } finally {
        DBConnection.close(rs, checkStmt, stmt, conn);
    }
%>
