<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    String userId = (String) session.getAttribute("userId");
    String userRole = (String) session.getAttribute("userRole");
    String patientIdStr = (String) session.getAttribute("patientId");

    // Unauthenticated patients redirected to login, returning here afterwards
    if (userId == null || !"PATIENT".equalsIgnoreCase(userRole) || patientIdStr == null) {
        response.sendRedirect("login.jsp?returnUrl=book-appointment.jsp&error=Please+log+in+as+a+patient+to+book+an+appointment.");
        return;
    }

    String preselectedDoctorId = request.getParameter("doctorId");
    String csrfToken = SecurityUtil.getCsrfToken(session);
    String todayDate = java.time.LocalDate.now().toString();
    String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Book Doctor Appointment - CityHealth HMS</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/forms.css">
    <link rel="stylesheet" href="css/patient.css">
    <script src="js/appointments.js"></script>
</head>
<body>

    <jsp:include page="includes/navbar.jsp" />

    <div class="app-layout">
        <aside class="sidebar">
            <div class="sidebar-heading">Patient Menu</div>
            <ul class="sidebar-menu">
                <li><a href="patient-dashboard.jsp">&#127968; Dashboard</a></li>
                <li><a href="book-appointment.jsp" class="active">&#128197; Book Appointment</a></li>
                <li><a href="patient-appointments.jsp">&#128203; My Appointments</a></li>
                <li><a href="doctors.jsp">&#128104;&#8205;&#9877;&#65039; Find Doctors</a></li>
                <li><a href="patient-profile.jsp">&#128100; My Profile</a></li>
                <li><a href="logout.jsp">&#128682; Logout</a></li>
            </ul>
        </aside>

        <main class="main-content">
            <div style="margin-bottom: 24px;">
                <h2>Book Doctor Consultation</h2>
                <p class="lead">Select your medical department, specialist, date, and preferred time slot.</p>
            </div>

            <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="alert alert-danger">&#9888; <%= SecurityUtil.escapeHtml(error) %></div>
            <% } %>

            <!-- Booking Stepper Indicator -->
            <div class="booking-steps">
                <div class="step-item active">
                    <div class="step-circle">1</div>
                    <div class="step-label">Department &amp; Doctor</div>
                </div>
                <div class="step-item active">
                    <div class="step-circle">2</div>
                    <div class="step-label">Date &amp; Time Slot</div>
                </div>
                <div class="step-item active">
                    <div class="step-circle">3</div>
                    <div class="step-label">Summary &amp; Confirm</div>
                </div>
            </div>

            <div class="grid grid-2" style="align-items: start;">
                <!-- Booking Form Card -->
                <div class="card">
                    <form action="saveAppointment.jsp" method="POST" onsubmit="return validateBookingForm();">
                        <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                        <input type="hidden" id="appointmentTime" name="appointmentTime" value="">

                        <!-- Step 1: Department -->
                        <div class="form-group">
                            <label class="form-label">Step 1: Medical Department</label>
                            <select id="departmentSelect" class="form-control" onchange="onDepartmentChange()">
                                <option value="">-- All Departments --</option>
                                <%
                                    Connection conn = null;
                                    PreparedStatement deptStmt = null;
                                    ResultSet deptRs = null;
                                    try {
                                        conn = DBConnection.getConnection();
                                        deptStmt = conn.prepareStatement("SELECT DEPARTMENT_ID, DEPARTMENT_NAME FROM DEPARTMENTS WHERE ACTIVE = 1 ORDER BY DEPARTMENT_NAME");
                                        deptRs = deptStmt.executeQuery();
                                        while (deptRs.next()) {
                                            int dId = deptRs.getInt("DEPARTMENT_ID");
                                            String dName = deptRs.getString("DEPARTMENT_NAME");
                                %>
                                <option value="<%= dId %>"><%= SecurityUtil.escapeHtml(dName) %></option>
                                <%
                                        }
                                    } catch (Exception e) {
                                        System.err.println("[book-appointment] Dept error: " + e.getMessage());
                                    } finally {
                                        DBConnection.close(deptRs, deptStmt);
                                    }
                                %>
                            </select>
                        </div>

                        <!-- Step 2: Doctor -->
                        <div class="form-group">
                            <label class="form-label">Step 2: Choose Specialist Doctor <span class="required">*</span></label>
                            <select id="doctorSelect" name="doctorId" class="form-control" onchange="onDoctorChange()" required>
                                <option value="">-- Select Specialist --</option>
                                <%
                                    PreparedStatement docStmt = null;
                                    ResultSet docRs = null;
                                    try {
                                        docStmt = conn.prepareStatement(
                                            "SELECT d.DOCTOR_ID, d.DOCTOR_NAME, d.SPECIALIZATION, d.DEPARTMENT_ID, d.CONSULTATION_FEE, dep.DEPARTMENT_NAME " +
                                            "FROM DOCTORS d JOIN DEPARTMENTS dep ON d.DEPARTMENT_ID = dep.DEPARTMENT_ID " +
                                            "WHERE d.ACTIVE = 1 ORDER BY d.DOCTOR_NAME"
                                        );
                                        docRs = docStmt.executeQuery();
                                        while (docRs.next()) {
                                            int docId = docRs.getInt("DOCTOR_ID");
                                            String docName = docRs.getString("DOCTOR_NAME");
                                            String spec = docRs.getString("SPECIALIZATION");
                                            int deptId = docRs.getInt("DEPARTMENT_ID");
                                            double fee = docRs.getDouble("CONSULTATION_FEE");
                                            boolean isPreselected = (preselectedDoctorId != null && preselectedDoctorId.equals(String.valueOf(docId)));
                                %>
                                <option value="<%= docId %>"
                                        data-department-id="<%= deptId %>"
                                        data-fee="<%= String.format("%.2f", fee) %>"
                                        data-spec="<%= SecurityUtil.escapeHtml(spec) %>"
                                        <%= isPreselected ? "selected" : "" %>>
                                    <%= SecurityUtil.escapeHtml(docName) %> (<%= SecurityUtil.escapeHtml(spec) %>)
                                </option>
                                <%
                                        }
                                    } catch (Exception e) {
                                        System.err.println("[book-appointment] Doc error: " + e.getMessage());
                                    } finally {
                                        DBConnection.close(docRs, docStmt, conn);
                                    }
                                %>
                            </select>
                        </div>

                        <!-- Step 3: Date -->
                        <div class="form-group">
                            <label class="form-label">Step 3: Appointment Date <span class="required">*</span></label>
                            <input type="date" id="appointmentDate" name="appointmentDate" class="form-control" min="<%= todayDate %>" onchange="onDateChange()" required>
                            <span class="form-text">Select today or an upcoming consultation date.</span>
                        </div>

                        <!-- Step 4: Available Time Slots -->
                        <div class="form-group">
                            <label class="form-label">Step 4: Select Available Time Slot <span class="required">*</span></label>
                            <div id="timeSlotsContainer" class="slot-grid">
                                <span style="font-size: 13px; color: var(--text-muted); grid-column: 1 / -1;">
                                    Please select a doctor and date first to load slots.
                                </span>
                            </div>
                        </div>

                        <!-- Step 5: Reason for Visit -->
                        <div class="form-group">
                            <label class="form-label">Step 5: Reason for Visit / Chief Symptoms</label>
                            <textarea name="reason" class="form-control" rows="3" placeholder="Briefly describe your health concern, symptoms, or follow-up reason..."></textarea>
                        </div>

                        <button type="submit" class="btn btn-primary btn-block btn-lg" style="margin-top: 10px;">
                            Confirm &amp; Book Appointment &rarr;
                        </button>
                    </form>
                </div>

                <!-- Booking Summary Card -->
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title">Booking Summary</h3>
                    </div>

                    <div class="booking-summary-box">
                        <div class="summary-row">
                            <span style="color: var(--text-secondary);">Selected Doctor:</span>
                            <span id="summaryDoctor" style="font-weight: 600;">Not selected</span>
                        </div>
                        <div class="summary-row">
                            <span style="color: var(--text-secondary);">Specialization:</span>
                            <span id="doctorSpecDisplay">--</span>
                        </div>
                        <div class="summary-row">
                            <span style="color: var(--text-secondary);">Consultation Date:</span>
                            <span id="summaryDate">Not selected</span>
                        </div>
                        <div class="summary-row">
                            <span style="color: var(--text-secondary);">Time Slot:</span>
                            <span id="summaryTime">Not selected</span>
                        </div>
                        <div class="summary-row">
                            <span style="color: var(--text-secondary);">Consultation Fee:</span>
                            <span id="summaryFee" style="color: var(--primary);">&#8377; 0.00</span>
                        </div>
                    </div>

                    <div style="background-color: var(--info-light); border: 1px solid #bae6fd; border-radius: var(--radius-sm); padding: 14px; font-size: 13px; color: #0369a1; line-height: 1.6;">
                        <strong>Important Booking Guidelines:</strong>
                        <ul style="margin: 6px 0 0 18px;">
                            <li>Appointments can be cancelled or rescheduled up to 2 hours prior to slot time.</li>
                            <li>Consultation fee can be paid at the hospital reception desk on arrival or recorded in billing.</li>
                            <li>Please arrive 15 minutes prior to your allocated slot for vitals recording.</li>
                        </ul>
                    </div>
                </div>
            </div>
        </main>
    </div>

    <jsp:include page="includes/footer.jsp" />

    <script>
        // Trigger initial doctor change if doctorId pre-selected from catalog
        window.addEventListener("DOMContentLoaded", function() {
            var docSelect = document.getElementById("doctorSelect");
            if (docSelect && docSelect.value) {
                onDoctorChange();
            }
        });
    </script>
</body>
</html>
