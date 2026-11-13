<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    String userId = (String) session.getAttribute("userId");
    String userRole = (String) session.getAttribute("userRole");

    if (userId == null || (!"DOCTOR".equalsIgnoreCase(userRole) && !"ADMIN".equalsIgnoreCase(userRole) && !"RECEPTIONIST".equalsIgnoreCase(userRole))) {
        response.sendRedirect("login.jsp?error=Unauthorized.");
        return;
    }

    int patientId = SecurityUtil.parseInt(request.getParameter("patientId"), 0);
    if (patientId <= 0) {
        response.sendRedirect("doctor-dashboard.jsp?error=Invalid+patient+reference.");
        return;
    }

    String pName = "", gender = "", bGroup = "", phone = "", emerg = "", dob = "";
    int age = 0;

    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        stmt = conn.prepareStatement(
            "SELECT PATIENT_NAME, GENDER, BLOOD_GROUP, PHONE, EMERGENCY_CONTACT, " +
            "TO_CHAR(DOB, 'YYYY-MM-DD') AS DOB_STR, FLOOR(MONTHS_BETWEEN(SYSDATE, DOB)/12) AS AGE " +
            "FROM PATIENTS WHERE PATIENT_ID = ?"
        );
        stmt.setInt(1, patientId);
        rs = stmt.executeQuery();
        if (rs.next()) {
            pName = rs.getString("PATIENT_NAME");
            gender = rs.getString("GENDER");
            bGroup = rs.getString("BLOOD_GROUP");
            phone = rs.getString("PHONE");
            emerg = rs.getString("EMERGENCY_CONTACT");
            dob = rs.getString("DOB_STR");
            age = rs.getInt("AGE");
        } else {
            response.sendRedirect("doctor-dashboard.jsp?error=Patient+not+found.");
            return;
        }
    } catch (Exception e) {
        System.err.println("[patient-details] Error: " + e.getMessage());
    } finally {
        DBConnection.close(rs, stmt);
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Clinical History: <%= SecurityUtil.escapeHtml(pName) %> - CityHealth HMS</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/tables.css">
    <link rel="stylesheet" href="css/doctor.css">
</head>
<body>

    <jsp:include page="includes/navbar.jsp" />

    <div class="container" style="padding: 40px 20px 80px 20px;">
        <div class="flex-between" style="margin-bottom: 24px;">
            <div>
                <h2>Clinical History: <%= SecurityUtil.escapeHtml(pName) %></h2>
                <p class="lead">Medical profile &bull; Patient ID: <strong>#<%= patientId %></strong></p>
            </div>
            <a href="javascript:history.back()" class="btn btn-outline">&larr; Back</a>
        </div>

        <!-- Demographics Box -->
        <div class="card" style="margin-bottom: 30px;">
            <div class="card-header">
                <h3 class="card-title">Patient Medical Demographics</h3>
            </div>
            <div class="grid grid-4">
                <div>
                    <span style="font-size: 12px; font-weight: 700; color: var(--text-secondary); text-transform: uppercase;">Age &amp; Gender</span>
                    <div style="font-size: 15px; font-weight: 600; color: var(--secondary);"><%= gender %>, <%= age %> years (<%= dob %>)</div>
                </div>
                <div>
                    <span style="font-size: 12px; font-weight: 700; color: var(--text-secondary); text-transform: uppercase;">Blood Group</span>
                    <div><span class="badge badge-info" style="font-size: 14px;"><%= bGroup != null ? bGroup : "N/A" %></span></div>
                </div>
                <div>
                    <span style="font-size: 12px; font-weight: 700; color: var(--text-secondary); text-transform: uppercase;">Primary Phone</span>
                    <div style="font-size: 15px; font-weight: 600; color: var(--secondary);"><%= phone %></div>
                </div>
                <div>
                    <span style="font-size: 12px; font-weight: 700; color: var(--text-secondary); text-transform: uppercase;">Emergency Contact</span>
                    <div style="font-size: 15px; font-weight: 600; color: var(--secondary);"><%= emerg != null ? emerg : "--" %></div>
                </div>
            </div>
        </div>

        <!-- Clinical Consultation & Prescription Timeline -->
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">Previous Consultation &amp; Prescription Records</h3>
            </div>

            <%
                PreparedStatement histStmt = null;
                ResultSet histRs = null;
                int hCount = 0;
                try {
                    histStmt = conn.prepareStatement(
                        "SELECT a.APPOINTMENT_ID, TO_CHAR(a.APPOINTMENT_DATE, 'YYYY-MM-DD') AS APPT_DATE, " +
                        "a.APPOINTMENT_TIME, a.REASON, a.STATUS, d.DOCTOR_NAME, dep.DEPARTMENT_NAME, " +
                        "pr.PRESCRIPTION_ID, pr.DIAGNOSIS, pr.NOTES " +
                        "FROM APPOINTMENTS a " +
                        "JOIN DOCTORS d ON a.DOCTOR_ID = d.DOCTOR_ID " +
                        "JOIN DEPARTMENTS dep ON d.DEPARTMENT_ID = dep.DEPARTMENT_ID " +
                        "LEFT JOIN PRESCRIPTIONS pr ON a.APPOINTMENT_ID = pr.APPOINTMENT_ID " +
                        "WHERE a.PATIENT_ID = ? " +
                        "ORDER BY a.APPOINTMENT_DATE DESC, a.APPOINTMENT_TIME DESC"
                    );
                    histStmt.setInt(1, patientId);
                    histRs = histStmt.executeQuery();

                    while (histRs.next()) {
                        hCount++;
                        int aId = histRs.getInt("APPOINTMENT_ID");
                        String aDate = histRs.getString("APPT_DATE");
                        String aTime = histRs.getString("APPOINTMENT_TIME");
                        String dName = SecurityUtil.escapeHtml(histRs.getString("DOCTOR_NAME"));
                        String dept = SecurityUtil.escapeHtml(histRs.getString("DEPARTMENT_NAME"));
                        String reason = SecurityUtil.escapeHtml(histRs.getString("REASON"));
                        String status = histRs.getString("STATUS");
                        int prescId = histRs.getInt("PRESCRIPTION_ID");
                        String diag = SecurityUtil.escapeHtml(histRs.getString("DIAGNOSIS"));
                        String notes = SecurityUtil.escapeHtml(histRs.getString("NOTES"));
            %>
            <div style="border-bottom: 1px solid var(--border-color); padding: 20px 0;">
                <div class="flex-between" style="margin-bottom: 8px;">
                    <div>
                        <strong style="font-size: 15px; color: var(--secondary);">Consultation with <%= dName %> (<%= dept %>)</strong>
                        <span style="font-size: 13px; color: var(--text-secondary); margin-left: 10px;">Date: <%= aDate %> at <%= aTime %> (Ref #<%= aId %>)</span>
                    </div>
                    <span class="badge <%= "COMPLETED".equalsIgnoreCase(status) ? "badge-success" : ("BOOKED".equalsIgnoreCase(status) ? "badge-booked" : "badge-cancelled") %>">
                        <%= status %>
                    </span>
                </div>

                <p style="font-size: 13.5px; color: var(--text-secondary); margin-bottom: 10px;">
                    <strong>Presented Symptoms:</strong> <%= (reason != null && !reason.isEmpty()) ? reason : "Routine Checkup" %>
                </p>

                <% if (prescId > 0) { %>
                    <div style="background: #f8fafc; border: 1px solid var(--border-color); border-radius: var(--radius-sm); padding: 14px; margin-top: 10px;">
                        <div style="margin-bottom: 6px;">
                            <strong style="color: var(--primary);">Clinical Diagnosis:</strong> <%= diag %>
                        </div>
                        <% if (notes != null && !notes.isEmpty()) { %>
                            <div style="font-size: 13px; color: var(--text-secondary); margin-bottom: 10px;">
                                <strong>Physician Notes:</strong> <%= notes %>
                            </div>
                        <% } %>

                        <!-- Prescribed Medicines -->
                        <table class="table" style="font-size: 13px; margin-top: 10px; background: #ffffff;">
                            <thead>
                                <tr>
                                    <th>Medicine</th>
                                    <th>Dosage</th>
                                    <th>Duration</th>
                                    <th>Instructions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <%
                                    PreparedStatement itemStmt = conn.prepareStatement(
                                        "SELECT MEDICINE_NAME, DOSAGE, DURATION, INSTRUCTIONS FROM PRESCRIPTION_ITEMS WHERE PRESCRIPTION_ID = ?"
                                    );
                                    itemStmt.setInt(1, prescId);
                                    ResultSet itemRs = itemStmt.executeQuery();
                                    while (itemRs.next()) {
                                %>
                                <tr>
                                    <td><strong><%= SecurityUtil.escapeHtml(itemRs.getString("MEDICINE_NAME")) %></strong></td>
                                    <td><%= SecurityUtil.escapeHtml(itemRs.getString("DOSAGE")) %></td>
                                    <td><%= SecurityUtil.escapeHtml(itemRs.getString("DURATION")) %></td>
                                    <td><%= SecurityUtil.escapeHtml(itemRs.getString("INSTRUCTIONS")) %></td>
                                </tr>
                                <%
                                    }
                                    DBConnection.close(itemRs, itemStmt);
                                %>
                            </tbody>
                        </table>
                    </div>
                <% } else { %>
                    <p style="font-size: 13px; color: var(--text-muted); font-style: italic;">No electronic prescription recorded for this visit.</p>
                <% } %>
            </div>
            <%
                    }
                } catch (Exception e) {
                    System.err.println("[patient-details] History error: " + e.getMessage());
                } finally {
                    DBConnection.close(histRs, histStmt, conn);
                }

                if (hCount == 0) {
            %>
            <div style="padding: 30px; text-align: center; color: var(--text-secondary);">
                No previous clinical records logged for this patient.
            </div>
            <%  } %>
        </div>
    </div>

    <jsp:include page="includes/footer.jsp" />

</body>
</html>
