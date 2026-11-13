<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect("doctor-dashboard.jsp");
        return;
    }

    if (!SecurityUtil.verifyCsrfToken(request)) {
        response.sendRedirect("doctor-dashboard.jsp?error=Security+validation+failed.");
        return;
    }

    String sessionRole = (String) session.getAttribute("userRole");
    String sessionDoctorId = (String) session.getAttribute("doctorId");
    String sessionUserId = (String) session.getAttribute("userId");

    if (sessionDoctorId == null || !"DOCTOR".equalsIgnoreCase(sessionRole)) {
        response.sendRedirect("login.jsp?error=Only+authorized+doctors+can+issue+prescriptions.");
        return;
    }

    int doctorId = Integer.parseInt(sessionDoctorId);
    int apptId = SecurityUtil.parseInt(request.getParameter("appointmentId"), 0);
    String diagnosis = SecurityUtil.sanitize(request.getParameter("diagnosis"));
    String notes = SecurityUtil.sanitize(request.getParameter("notes"));

    String[] medicineNames = request.getParameterValues("medicineName");
    String[] dosages = request.getParameterValues("dosage");
    String[] durations = request.getParameterValues("duration");
    String[] instructions = request.getParameterValues("instructions");

    if (apptId <= 0 || diagnosis.isEmpty() || medicineNames == null || medicineNames.length == 0) {
        response.sendRedirect("prescriptions.jsp?appointmentId=" + apptId + "&error=Please+enter+diagnosis+and+at+least+one+medicine.");
        return;
    }

    Connection conn = null;
    PreparedStatement verifyStmt = null;
    PreparedStatement prescStmt = null;
    PreparedStatement itemStmt = null;
    PreparedStatement apptStmt = null;
    PreparedStatement auditStmt = null;
    PreparedStatement seqStmt = null;
    ResultSet rs = null;

    int newPrescriptionId = 0;

    try {
        conn = DBConnection.getConnection();
        conn.setAutoCommit(false); // Begin Transaction

        // 1. Verify Appointment Assignment
        verifyStmt = conn.prepareStatement("SELECT PATIENT_ID, DOCTOR_ID FROM APPOINTMENTS WHERE APPOINTMENT_ID = ?");
        verifyStmt.setInt(1, apptId);
        rs = verifyStmt.executeQuery();

        int patientId = 0;
        int assignedDoctorId = 0;

        if (rs.next()) {
            patientId = rs.getInt("PATIENT_ID");
            assignedDoctorId = rs.getInt("DOCTOR_ID");
        } else {
            conn.rollback();
            response.sendRedirect("doctor-dashboard.jsp?error=Appointment+not+found.");
            return;
        }
        DBConnection.close(rs, verifyStmt);

        if (assignedDoctorId != doctorId) {
            conn.rollback();
            response.sendRedirect("doctor-dashboard.jsp?error=Unauthorized:+You+cannot+prescribe+for+another+doctor's+patient.");
            return;
        }

        // 2. Obtain next prescription ID
        seqStmt = conn.prepareStatement("SELECT SEQ_PRESCRIPTIONS.NEXTVAL FROM DUAL");
        rs = seqStmt.executeQuery();
        if (rs.next()) newPrescriptionId = rs.getInt(1);
        DBConnection.close(rs, seqStmt);

        // 3. Insert into PRESCRIPTIONS
        String insertPresc = "INSERT INTO PRESCRIPTIONS (PRESCRIPTION_ID, APPOINTMENT_ID, DOCTOR_ID, PATIENT_ID, DIAGNOSIS, NOTES, CREATED_AT) " +
                             "VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)";
        prescStmt = conn.prepareStatement(insertPresc);
        prescStmt.setInt(1, newPrescriptionId);
        prescStmt.setInt(2, apptId);
        prescStmt.setInt(3, doctorId);
        prescStmt.setInt(4, patientId);
        prescStmt.setString(5, diagnosis);
        prescStmt.setString(6, notes.isEmpty() ? null : notes);
        prescStmt.executeUpdate();

        // 4. Insert Prescription Items
        String insertItem = "INSERT INTO PRESCRIPTION_ITEMS (ITEM_ID, PRESCRIPTION_ID, MEDICINE_NAME, DOSAGE, DURATION, INSTRUCTIONS) " +
                            "VALUES (SEQ_PRESCRIPTION_ITEMS.NEXTVAL, ?, ?, ?, ?, ?)";
        itemStmt = conn.prepareStatement(insertItem);

        for (int i = 0; i < medicineNames.length; i++) {
            String med = SecurityUtil.sanitize(medicineNames[i]);
            if (med.isEmpty()) continue;
            String dose = (dosages != null && dosages.length > i) ? SecurityUtil.sanitize(dosages[i]) : "1 dose";
            String dur = (durations != null && durations.length > i) ? SecurityUtil.sanitize(durations[i]) : "3 days";
            String inst = (instructions != null && instructions.length > i) ? SecurityUtil.sanitize(instructions[i]) : "";

            itemStmt.setInt(1, newPrescriptionId);
            itemStmt.setString(2, med);
            itemStmt.setString(3, dose);
            itemStmt.setString(4, dur);
            itemStmt.setString(5, inst.isEmpty() ? null : inst);
            itemStmt.executeUpdate();
        }

        // 5. Automatically mark Appointment as COMPLETED
        apptStmt = conn.prepareStatement("UPDATE APPOINTMENTS SET STATUS = 'COMPLETED' WHERE APPOINTMENT_ID = ?");
        apptStmt.setInt(1, apptId);
        apptStmt.executeUpdate();

        // 6. Audit Log
        auditStmt = conn.prepareStatement(
            "INSERT INTO AUDIT_LOG (USER_ID, ACTION, ENTITY_TYPE, ENTITY_ID, DETAILS) VALUES (?, ?, ?, ?, ?)"
        );
        auditStmt.setInt(1, Integer.parseInt(sessionUserId));
        auditStmt.setString(2, "CREATE_PRESCRIPTION");
        auditStmt.setString(3, "PRESCRIPTIONS");
        auditStmt.setInt(4, newPrescriptionId);
        auditStmt.setString(5, "Prescription created for appointment #" + apptId);
        auditStmt.executeUpdate();

        conn.commit();
        response.sendRedirect("prescriptions.jsp?appointmentId=" + apptId + "&msg=Prescription+successfully+issued+and+appointment+completed.");

    } catch (Exception e) {
        if (conn != null) {
            try { conn.rollback(); } catch (SQLException ignored) {}
        }
        System.err.println("[savePrescription] Error: " + e.getMessage());
        response.sendRedirect("prescriptions.jsp?appointmentId=" + apptId + "&error=System+error+saving+prescription.");
    } finally {
        DBConnection.close(rs, verifyStmt, seqStmt, prescStmt, itemStmt, apptStmt, auditStmt, conn);
    }
%>
