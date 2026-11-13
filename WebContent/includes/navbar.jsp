<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String navUserId = (String) session.getAttribute("userId");
    String navUserRole = (String) session.getAttribute("userRole");
    String navFullName = (String) session.getAttribute("userFullName");
%>
<nav class="navbar">
    <div class="container nav-container">
        <a href="index.jsp" class="brand-logo">
            <span class="brand-icon">+</span>
            <span>CityHealth HMS</span>
        </a>
        <ul class="nav-links">
            <li><a href="index.jsp">Home</a></li>
            <li><a href="about.jsp">About</a></li>
            <li><a href="doctors.jsp">Doctors</a></li>

            <% if (navUserId == null) { %>
                <li><a href="login.jsp">Login</a></li>
                <li><a href="register.jsp">Register</a></li>
                <li><a href="book-appointment.jsp" class="btn btn-primary btn-sm">Book Appointment</a></li>
            <% } else if ("PATIENT".equalsIgnoreCase(navUserRole)) { %>
                <li><a href="patient-dashboard.jsp">Dashboard</a></li>
                <li><a href="patient-appointments.jsp">My Appointments</a></li>
                <li><a href="book-appointment.jsp" class="btn btn-primary btn-sm">Book Appointment</a></li>
                <li><a href="patient-profile.jsp">Profile</a></li>
                <li><a href="logout.jsp" class="btn btn-outline btn-sm">Logout (<%= navFullName != null ? navFullName.split(" ")[0] : "Patient" %>)</a></li>
            <% } else if ("DOCTOR".equalsIgnoreCase(navUserRole)) { %>
                <li><a href="doctor-dashboard.jsp">Doctor Portal</a></li>
                <li><a href="doctor-appointments.jsp">Appointments</a></li>
                <li><a href="prescriptions.jsp">Prescriptions</a></li>
                <li><a href="logout.jsp" class="btn btn-outline btn-sm">Logout (Dr. <%= navFullName != null ? navFullName.split(" ")[navFullName.split(" ").length-1] : "" %>)</a></li>
            <% } else if ("ADMIN".equalsIgnoreCase(navUserRole) || "RECEPTIONIST".equalsIgnoreCase(navUserRole)) { %>
                <li><a href="admin-dashboard.jsp">Staff Dashboard</a></li>
                <li><a href="patients.jsp">Patients</a></li>
                <li><a href="appointments.jsp">Appointments</a></li>
                <li><a href="billing.jsp">Billing</a></li>
                <li><a href="reports.jsp">Reports</a></li>
                <li><a href="logout.jsp" class="btn btn-outline btn-sm">Logout (<%= navUserRole %>)</a></li>
            <% } %>
        </ul>
    </div>
</nav>
