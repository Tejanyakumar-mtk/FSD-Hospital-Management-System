<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CityHealth Hospital Management System</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/public.css">
</head>
<body>

    <!-- Header Navigation -->
    <jsp:include page="includes/navbar.jsp" />

    <!-- Hero Section -->
    <section class="hero">
        <div class="container flex-between">
            <div class="hero-content">
                <span class="hero-badge">Excellence in Patient Care &bull; 24/7 Availability</span>
                <h1>Your Health, Our Highest Commitment</h1>
                <p>Welcome to CityHealth Hospital Management System. Book appointments with senior specialists, manage your medical history, and experience world-class healthcare with transparent care and digital records.</p>
                <div class="hero-actions">
                    <a href="book-appointment.jsp" class="btn btn-secondary btn-lg">Book an Appointment</a>
                    <a href="doctors.jsp" class="btn btn-outline btn-lg" style="color: #ffffff; border-color: #ffffff;">Meet Our Doctors</a>
                </div>
            </div>
        </div>
    </section>

    <!-- Highlighted Feature Strip -->
    <div class="container features-strip">
        <div class="grid grid-4">
            <div class="feature-card">
                <div class="feature-icon">&#10010;</div>
                <h3>24/7 Emergency</h3>
                <p>Equipped trauma center and ICU with dedicated emergency response doctors on duty 24/7.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon">&#9733;</div>
                <h3>Board Specialists</h3>
                <p>Experienced consultants across Cardiology, Neurology, Orthopedics, Pediatrics, and more.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon">&#9742;</div>
                <h3>Online Appointments</h3>
                <p>Real-time slot scheduling with immediate confirmation and zero waiting room delays.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon">&#9776;</div>
                <h3>Digital Records</h3>
                <p>Secure online medical history, electronic prescriptions, and transparent billing.</p>
            </div>
        </div>
    </div>

    <!-- Clinical Departments (Loaded dynamically from Oracle) -->
    <section class="container" style="margin-bottom: 70px;">
        <div class="section-header">
            <span class="section-tag">Clinical Centers</span>
            <h2>Our Specialized Departments</h2>
            <p>From routine health screenings to advanced surgical interventions, our multidisciplinary teams deliver comprehensive care.</p>
        </div>
        <div class="grid grid-3">
            <%
                Connection conn = null;
                PreparedStatement stmt = null;
                ResultSet rs = null;
                try {
                    conn = DBConnection.getConnection();
                    stmt = conn.prepareStatement("SELECT DEPARTMENT_ID, DEPARTMENT_NAME, DESCRIPTION FROM DEPARTMENTS WHERE ACTIVE = 1 ORDER BY DEPARTMENT_NAME");
                    rs = stmt.executeQuery();
                    while (rs.next()) {
                        int deptId = rs.getInt("DEPARTMENT_ID");
                        String deptName = SecurityUtil.escapeHtml(rs.getString("DEPARTMENT_NAME"));
                        String desc = SecurityUtil.escapeHtml(rs.getString("DESCRIPTION"));
            %>
            <div class="dept-card">
                <h3><%= deptName %></h3>
                <p><%= (desc != null && !desc.isEmpty()) ? desc : "Specialized diagnostic and surgical clinical department." %></p>
                <div style="margin-top: 16px;">
                    <a href="doctors.jsp?dept=<%= deptId %>" class="btn btn-outline btn-sm">View Doctors &rarr;</a>
                </div>
            </div>
            <%
                    }
                } catch (Exception e) {
            %>
                <div class="alert alert-warning" style="grid-column: 1 / -1;">
                    Departments are currently being updated. Please check back shortly.
                </div>
            <%
                } finally {
                    DBConnection.close(rs, stmt, conn);
                }
            %>
        </div>
    </section>

    <!-- Featured Doctors (Loaded from Oracle) -->
    <section style="background-color: #f1f5f9; padding: 70px 0;">
        <div class="container">
            <div class="section-header">
                <span class="section-tag">Medical Staff</span>
                <h2>Meet Our Experienced Doctors</h2>
                <p>Our consultants bring decades of clinical experience from leading medical institutions.</p>
            </div>
            <div class="grid grid-3">
                <%
                    try {
                        conn = DBConnection.getConnection();
                        stmt = conn.prepareStatement(
                            "SELECT d.DOCTOR_ID, d.DOCTOR_NAME, d.SPECIALIZATION, d.QUALIFICATION, d.CONSULTATION_FEE, dep.DEPARTMENT_NAME " +
                            "FROM DOCTORS d JOIN DEPARTMENTS dep ON d.DEPARTMENT_ID = dep.DEPARTMENT_ID " +
                            "WHERE d.ACTIVE = 1 AND ROWNUM <= 6 ORDER BY d.DOCTOR_ID"
                        );
                        rs = stmt.executeQuery();
                        while (rs.next()) {
                            int docId = rs.getInt("DOCTOR_ID");
                            String docName = SecurityUtil.escapeHtml(rs.getString("DOCTOR_NAME"));
                            String spec = SecurityUtil.escapeHtml(rs.getString("SPECIALIZATION"));
                            String qual = SecurityUtil.escapeHtml(rs.getString("QUALIFICATION"));
                            String deptName = SecurityUtil.escapeHtml(rs.getString("DEPARTMENT_NAME"));
                            double fee = rs.getDouble("CONSULTATION_FEE");
                %>
                <div class="doctor-card">
                    <div class="doctor-avatar-wrap">
                        <span>&#128104;&#8205;&#9877;&#65039;</span>
                    </div>
                    <div class="doctor-body">
                        <span class="doctor-specialty"><%= spec %></span>
                        <h3 class="doctor-name"><%= docName %></h3>
                        <p class="doctor-qualification"><%= qual != null ? qual : deptName %></p>
                        <div class="doctor-meta">
                            <div>
                                <span style="font-size: 11px; color: var(--text-secondary); display:block;">Consultation Fee</span>
                                <span class="doctor-fee">&#8377; <%= String.format("%.2f", fee) %></span>
                            </div>
                            <a href="book-appointment.jsp?doctorId=<%= docId %>" class="btn btn-primary btn-sm">Book Visit</a>
                        </div>
                    </div>
                </div>
                <%
                        }
                    } catch (Exception e) {
                %>
                    <div class="alert alert-warning" style="grid-column: 1 / -1;">
                        Doctor schedule is loading. Please refresh or visit the Doctors page.
                    </div>
                <%
                    } finally {
                        DBConnection.close(rs, stmt, conn);
                    }
                %>
            </div>
            <div style="text-align: center; margin-top: 36px;">
                <a href="doctors.jsp" class="btn btn-secondary">View All Doctors &amp; Schedules &rarr;</a>
            </div>
        </div>
    </section>

    <!-- How Appointment Booking Works -->
    <section class="container" style="padding: 70px 0;">
        <div class="section-header">
            <span class="section-tag">Simple Process</span>
            <h2>How It Works</h2>
            <p>Booking an outpatient consultation at CityHealth takes less than two minutes.</p>
        </div>
        <div class="grid grid-3">
            <div class="card" style="text-align: center;">
                <div class="feature-icon" style="background-color: var(--primary-light); color: var(--primary);">1</div>
                <h3>Choose Specialty</h3>
                <p>Browse our medical departments and select your preferred consultant or physician.</p>
            </div>
            <div class="card" style="text-align: center;">
                <div class="feature-icon" style="background-color: var(--success-light); color: var(--success);">2</div>
                <h3>Select Date &amp; Slot</h3>
                <p>Pick a convenient consultation date and choose from live available time slots.</p>
            </div>
            <div class="card" style="text-align: center;">
                <div class="feature-icon" style="background-color: var(--warning-light); color: var(--warning);">3</div>
                <h3>Instant Confirmation</h3>
                <p>Receive your appointment reference ID immediately with zero queue or registration hassle.</p>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <jsp:include page="includes/footer.jsp" />

</body>
</html>
