<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    String userId = (String) session.getAttribute("userId");
    String userRole = (String) session.getAttribute("userRole");
    String doctorIdStr = (String) session.getAttribute("doctorId");
    String patientIdStr = (String) session.getAttribute("patientId");

    if (userId == null) {
        response.sendRedirect("login.jsp?error=Please+log+in+to+view+prescriptions.");
        return;
    }

    String apptIdParam = request.getParameter("appointmentId");
    String msg = request.getParameter("msg");
    String error = request.getParameter("error");
    String csrfToken = SecurityUtil.getCsrfToken(session);

    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;

    int apptId = SecurityUtil.parseInt(apptIdParam, 0);
    boolean hasExistingPrescription = false;
    int prescriptionId = 0;
    String diagnosis = "";
    String notes = "";
    String docName = "";
    String docQual = "";
    String docSpec = "";
    String patName = "";
    String patGender = "";
    String patDob = "";
    int patId = 0;
    int docId = 0;
    String apptDate = "";

    try {
        conn = DBConnection.getConnection();

        if (apptId > 0) {
            // Check appointment and existing prescription
            String query = 
                "SELECT a.APPOINTMENT_ID, TO_CHAR(a.APPOINTMENT_DATE, 'YYYY-MM-DD') AS APPT_DATE, " +
                "d.DOCTOR_ID, d.DOCTOR_NAME, d.QUALIFICATION, d.SPECIALIZATION, " +
                "p.PATIENT_ID, p.PATIENT_NAME, p.GENDER, TO_CHAR(p.DOB, 'YYYY-MM-DD') AS DOB_STR, " +
                "pr.PRESCRIPTION_ID, pr.DIAGNOSIS, pr.NOTES " +
                "FROM APPOINTMENTS a " +
                "JOIN DOCTORS d ON a.DOCTOR_ID = d.DOCTOR_ID " +
                "JOIN PATIENTS p ON a.PATIENT_ID = p.PATIENT_ID " +
                "LEFT JOIN PRESCRIPTIONS pr ON a.APPOINTMENT_ID = pr.APPOINTMENT_ID " +
                "WHERE a.APPOINTMENT_ID = ?";
            stmt = conn.prepareStatement(query);
            stmt.setInt(1, apptId);
            rs = stmt.executeQuery();

            if (rs.next()) {
                docId = rs.getInt("DOCTOR_ID");
                patId = rs.getInt("PATIENT_ID");
                docName = rs.getString("DOCTOR_NAME");
                docQual = rs.getString("QUALIFICATION");
                docSpec = rs.getString("SPECIALIZATION");
                patName = rs.getString("PATIENT_NAME");
                patGender = rs.getString("GENDER");
                patDob = rs.getString("DOB_STR");
                apptDate = rs.getString("APPT_DATE");

                // Security Authorization Checks:
                // If patient, must be their own appointment
                if ("PATIENT".equalsIgnoreCase(userRole)) {
                    int myPatientId = Integer.parseInt(patientIdStr);
                    if (patId != myPatientId) {
                        response.sendRedirect("patient-dashboard.jsp?error=Unauthorized+access+to+another+patient's+prescription.");
                        return;
                    }
                }
                // If doctor, must be assigned doctor
                if ("DOCTOR".equalsIgnoreCase(userRole)) {
                    int myDoctorId = Integer.parseInt(doctorIdStr);
                    if (docId != myDoctorId) {
                        response.sendRedirect("doctor-dashboard.jsp?error=Unauthorized+access+to+another+doctor's+prescription.");
                        return;
                    }
                }

                prescriptionId = rs.getInt("PRESCRIPTION_ID");
                if (!rs.wasNull() && prescriptionId > 0) {
                    hasExistingPrescription = true;
                    diagnosis = rs.getString("DIAGNOSIS");
                    notes = rs.getString("NOTES");
                }
            } else {
                response.sendRedirect("doctor-dashboard.jsp?error=Appointment+not+found.");
                return;
            }
        }
    } catch (Exception e) {
        System.err.println("[prescriptions.jsp] Lookup error: " + e.getMessage());
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Electronic Prescription - CityHealth HMS</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/forms.css">
    <link rel="stylesheet" href="css/doctor.css">
    <link rel="stylesheet" href="css/tables.css">
    <link rel="stylesheet" href="css/print.css">
    <script src="js/dashboard.js"></script>
</head>
<body>

    <jsp:include page="includes/navbar.jsp" />

    <div class="container" style="padding: 40px 20px 80px 20px;">
        <% if (msg != null && !msg.trim().isEmpty()) { %>
            <div class="alert alert-success no-print">&#10003; <%= SecurityUtil.escapeHtml(msg) %></div>
        <% } %>
        <% if (error != null && !error.trim().isEmpty()) { %>
            <div class="alert alert-danger no-print">&#9888; <%= SecurityUtil.escapeHtml(error) %></div>
        <% } %>

        <% if (apptId > 0) { %>
            <!-- Single Prescription View or Authoring Form -->

            <% if (hasExistingPrescription) { %>
                <!-- Render Formatted Clinical Prescription Sheet -->
                <div class="card" style="max-width: 850px; margin: 0 auto; padding: 40px;">
                    <div class="flex-between" style="border-bottom: 2px solid var(--secondary); padding-bottom: 16px; margin-bottom: 24px;">
                        <div>
                            <div class="brand-logo" style="margin-bottom: 4px;">
                                <span class="brand-icon">+</span>
                                <span>CityHealth Hospital</span>
                            </div>
                            <p style="font-size: 13px; color: var(--text-secondary); margin: 0;">Multi-Specialty Healthcare &bull; OPD Prescription Sheet</p>
                        </div>
                        <div style="text-align: right;">
                            <h3 style="margin: 0; color: var(--secondary);"><%= SecurityUtil.escapeHtml(docName) %></h3>
                            <p style="font-size: 13px; color: var(--text-secondary); margin: 0;"><%= SecurityUtil.escapeHtml(docSpec) %> (<%= docQual != null ? SecurityUtil.escapeHtml(docQual) : "" %>)</p>
                            <span style="font-size: 12px; color: var(--text-muted);">Rx ID: #<%= prescriptionId %> &bull; Appt Ref: #<%= apptId %></span>
                        </div>
                    </div>

                    <!-- Patient Demographics Strip -->
                    <div class="prescription-meta-grid">
                        <div class="meta-field">
                            <label>Patient Name</label>
                            <span><%= SecurityUtil.escapeHtml(patName) %></span>
                        </div>
                        <div class="meta-field">
                            <label>Patient ID / Gender</label>
                            <span>#<%= patId %> (<%= SecurityUtil.escapeHtml(patGender) %>)</span>
                        </div>
                        <div class="meta-field">
                            <label>Consultation Date</label>
                            <span><%= apptDate %></span>
                        </div>
                    </div>

                    <!-- Diagnosis -->
                    <div style="margin-bottom: 24px;">
                        <h4 style="color: var(--primary); text-transform: uppercase; font-size: 12px; letter-spacing: 0.5px; margin-bottom: 6px;">Clinical Diagnosis</h4>
                        <div style="font-size: 16px; font-weight: 600; color: var(--secondary); background: #f8fafc; padding: 12px 16px; border-radius: var(--radius-sm); border-left: 4px solid var(--primary);">
                            <%= SecurityUtil.escapeHtml(diagnosis) %>
                        </div>
                    </div>

                    <!-- Medicines Table -->
                    <div style="margin-bottom: 24px;">
                        <h4 style="color: var(--primary); text-transform: uppercase; font-size: 12px; letter-spacing: 0.5px; margin-bottom: 10px;">Prescribed Medication (Rx)</h4>
                        <div class="table-responsive">
                            <table class="table" style="background: #ffffff;">
                                <thead>
                                    <tr>
                                        <th>#</th>
                                        <th>Medicine Name</th>
                                        <th>Dosage</th>
                                        <th>Duration</th>
                                        <th>Instructions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        PreparedStatement pItemStmt = null;
                                        ResultSet pItemRs = null;
                                        int itemIdx = 0;
                                        try {
                                            pItemStmt = conn.prepareStatement(
                                                "SELECT MEDICINE_NAME, DOSAGE, DURATION, INSTRUCTIONS FROM PRESCRIPTION_ITEMS WHERE PRESCRIPTION_ID = ? ORDER BY ITEM_ID ASC"
                                            );
                                            pItemStmt.setInt(1, prescriptionId);
                                            pItemRs = pItemStmt.executeQuery();
                                            while (pItemRs.next()) {
                                                itemIdx++;
                                    %>
                                    <tr>
                                        <td><%= itemIdx %></td>
                                        <td><strong><%= SecurityUtil.escapeHtml(pItemRs.getString("MEDICINE_NAME")) %></strong></td>
                                        <td><%= SecurityUtil.escapeHtml(pItemRs.getString("DOSAGE")) %></td>
                                        <td><%= SecurityUtil.escapeHtml(pItemRs.getString("DURATION")) %></td>
                                        <td><%= SecurityUtil.escapeHtml(pItemRs.getString("INSTRUCTIONS")) %></td>
                                    </tr>
                                    <%
                                            }
                                        } finally {
                                            DBConnection.close(pItemRs, pItemStmt);
                                        }
                                    %>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <!-- Clinical Notes -->
                    <% if (notes != null && !notes.trim().isEmpty()) { %>
                    <div style="margin-bottom: 30px;">
                        <h4 style="color: var(--primary); text-transform: uppercase; font-size: 12px; letter-spacing: 0.5px; margin-bottom: 6px;">Doctor's Advice &amp; Lifestyle Notes</h4>
                        <p style="color: var(--text-secondary); font-size: 14px; background: #fafbfc; padding: 12px; border-radius: var(--radius-sm);">
                            <%= SecurityUtil.escapeHtml(notes) %>
                        </p>
                    </div>
                    <% } %>

                    <!-- Signature & Print Bar -->
                    <div class="flex-between" style="margin-top: 40px; padding-top: 20px; border-top: 1px dashed var(--border-color);">
                        <div>
                            <span style="font-size: 12px; color: var(--text-muted);">Electronically generated by CityHealth HMS &bull; Valid without physical stamp</span>
                        </div>
                        <div style="text-align: right;">
                            <div style="font-weight: 700; color: var(--secondary);"><%= SecurityUtil.escapeHtml(docName) %></div>
                            <div style="font-size: 12px; color: var(--text-secondary);">Attending Physician</div>
                        </div>
                    </div>

                    <div style="margin-top: 30px; text-align: center;" class="no-print">
                        <button type="button" class="btn btn-primary" onclick="window.print()">&#128438; Print Prescription</button>
                        <a href="javascript:history.back()" class="btn btn-outline" style="margin-left: 10px;">Back</a>
                    </div>
                </div>

            <% } else if ("DOCTOR".equalsIgnoreCase(userRole)) { %>
                <!-- Authoring Form: Only the assigned doctor can author -->
                <div class="card" style="max-width: 900px; margin: 0 auto; padding: 36px;">
                    <div class="card-header">
                        <div>
                            <h3 class="card-title">Author Medical Prescription</h3>
                            <p style="font-size: 13.5px; color: var(--text-secondary); margin: 0;">Consultation Ref: #<%= apptId %> &bull; Date: <%= apptDate %></p>
                        </div>
                        <span class="badge badge-booked">Ready for Diagnosis</span>
                    </div>

                    <!-- Patient Meta Preview -->
                    <div class="prescription-meta-grid">
                        <div class="meta-field">
                            <label>Patient</label>
                            <span><%= SecurityUtil.escapeHtml(patName) %> (#<%= patId %>)</span>
                        </div>
                        <div class="meta-field">
                            <label>Gender / DOB</label>
                            <span><%= SecurityUtil.escapeHtml(patGender) %> &bull; <%= patDob %></span>
                        </div>
                        <div class="meta-field">
                            <label>Doctor</label>
                            <span><%= SecurityUtil.escapeHtml(docName) %></span>
                        </div>
                    </div>

                    <form action="savePrescription.jsp" method="POST">
                        <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                        <input type="hidden" name="appointmentId" value="<%= apptId %>">
                        <input type="hidden" name="patientId" value="<%= patId %>">

                        <div class="form-group">
                            <label class="form-label">Clinical Diagnosis <span class="required">*</span></label>
                            <input type="text" name="diagnosis" class="form-control" placeholder="e.g. Acute Bronchitis, Type 2 Diabetes, Migraine with aura..." required>
                        </div>

                        <div class="form-group">
                            <label class="form-label">Consultation Notes &amp; Advice</label>
                            <textarea name="notes" class="form-control" rows="3" placeholder="Dietary instructions, physical therapy, follow-up advice..."></textarea>
                        </div>

                        <!-- Dynamic Medicine Item Builder -->
                        <div class="form-group">
                            <div class="flex-between" style="margin-bottom: 8px;">
                                <label class="form-label" style="margin: 0;">Prescribed Medicines &amp; Dosage <span class="required">*</span></label>
                                <button type="button" class="btn btn-outline btn-sm" onclick="addMedicineRow()">+ Add Medicine</button>
                            </div>

                            <div id="medicineContainer">
                                <div class="medicine-row">
                                    <input type="text" name="medicineName" class="form-control" placeholder="Medicine Name (e.g. Paracetamol 650mg)" required>
                                    <input type="text" name="dosage" class="form-control" placeholder="Dosage (e.g. 1 tablet)" required>
                                    <input type="text" name="duration" class="form-control" placeholder="Duration (e.g. 5 days)" required>
                                    <input type="text" name="instructions" class="form-control" placeholder="Instructions (e.g. After food twice daily)">
                                    <button type="button" class="btn-remove-row" onclick="removeMedicineRow(this)">&times;</button>
                                </div>
                            </div>
                        </div>

                        <div class="flex-between" style="margin-top: 30px; border-top: 1px solid var(--border-color); padding-top: 20px;">
                            <a href="doctor-appointments.jsp" class="btn btn-outline">Cancel</a>
                            <button type="submit" class="btn btn-primary btn-lg">&#10003; Save &amp; Complete Visit</button>
                        </div>
                    </form>
                </div>

            <% } else { %>
                <div class="card empty-state" style="max-width: 600px; margin: 40px auto;">
                    <div class="empty-state-icon">&#128221;</div>
                    <h3>No Prescription Logged</h3>
                    <p>The attending doctor has not issued an electronic prescription for this consultation yet.</p>
                    <a href="javascript:history.back()" class="btn btn-primary btn-sm">Return</a>
                </div>
            <% } %>

        <% } else { %>
            <!-- Master Prescriptions List View -->
            <div class="flex-between" style="margin-bottom: 24px;">
                <div>
                    <h2>Prescription Records</h2>
                    <p class="lead">Archive of electronic prescriptions and treatment regimens.</p>
                </div>
            </div>

            <div class="card" style="padding: 0; overflow: hidden;">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Rx ID</th>
                                <th>Appt #</th>
                                <th>Patient Name</th>
                                <th>Doctor</th>
                                <th>Diagnosis</th>
                                <th>Date Prescribed</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                PreparedStatement listStmt = null;
                                ResultSet listRs = null;
                                int pCount = 0;
                                try {
                                    StringBuilder sql = new StringBuilder(
                                        "SELECT pr.PRESCRIPTION_ID, pr.APPOINTMENT_ID, pr.DIAGNOSIS, " +
                                        "TO_CHAR(pr.CREATED_AT, 'YYYY-MM-DD') AS PRESC_DATE, " +
                                        "p.PATIENT_NAME, d.DOCTOR_NAME " +
                                        "FROM PRESCRIPTIONS pr " +
                                        "JOIN PATIENTS p ON pr.PATIENT_ID = p.PATIENT_ID " +
                                        "JOIN DOCTORS d ON pr.DOCTOR_ID = d.DOCTOR_ID WHERE 1=1 "
                                    );

                                    if ("DOCTOR".equalsIgnoreCase(userRole)) {
                                        sql.append(" AND pr.DOCTOR_ID = ? ");
                                    } else if ("PATIENT".equalsIgnoreCase(userRole)) {
                                        sql.append(" AND pr.PATIENT_ID = ? ");
                                    }
                                    sql.append(" ORDER BY pr.PRESCRIPTION_ID DESC ");

                                    listStmt = conn.prepareStatement(sql.toString());
                                    if ("DOCTOR".equalsIgnoreCase(userRole)) {
                                        listStmt.setInt(1, Integer.parseInt(doctorIdStr));
                                    } else if ("PATIENT".equalsIgnoreCase(userRole)) {
                                        listStmt.setInt(1, Integer.parseInt(patientIdStr));
                                    }

                                    listRs = listStmt.executeQuery();
                                    while (listRs.next()) {
                                        pCount++;
                                        int rxId = listRs.getInt("PRESCRIPTION_ID");
                                        int refAppt = listRs.getInt("APPOINTMENT_ID");
                                        String pat = SecurityUtil.escapeHtml(listRs.getString("PATIENT_NAME"));
                                        String doc = SecurityUtil.escapeHtml(listRs.getString("DOCTOR_NAME"));
                                        String diag = SecurityUtil.escapeHtml(listRs.getString("DIAGNOSIS"));
                                        String pDate = listRs.getString("PRESC_DATE");
                            %>
                            <tr>
                                <td><strong>#<%= rxId %></strong></td>
                                <td>#<%= refAppt %></td>
                                <td><strong><%= pat %></strong></td>
                                <td><%= doc %></td>
                                <td><%= diag %></td>
                                <td><%= pDate %></td>
                                <td>
                                    <a href="prescriptions.jsp?appointmentId=<%= refAppt %>" class="btn btn-outline btn-sm">View Rx Sheet</a>
                                </td>
                            </tr>
                            <%
                                    }
                                } catch (Exception e) {
                                    System.err.println("[prescriptions.jsp] List error: " + e.getMessage());
                                } finally {
                                    DBConnection.close(listRs, listStmt);
                                }

                                if (pCount == 0) {
                            %>
                            <tr>
                                <td colspan="7" style="text-align: center; padding: 36px; color: var(--text-secondary);">
                                    No prescriptions recorded yet.
                                </td>
                            </tr>
                            <%  } %>
                        </tbody>
                    </table>
                </div>
            </div>
        <% } %>
    </div>

    <jsp:include page="includes/footer.jsp" />

</body>
</html>
<%
    DBConnection.close(rs, stmt, conn);
%>
