<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<footer>
    <div class="container">
        <div class="grid grid-4">
            <div>
                <div class="brand-logo" style="color: #ffffff; margin-bottom: 14px;">
                    <span class="brand-icon">+</span>
                    <span>CityHealth HMS</span>
                </div>
                <p style="color: #cbd5e1; font-size: 13.5px; line-height: 1.6;">
                    Providing high-quality compassionate healthcare, state-of-the-art facilities, and certified medical specialists around the clock.
                </p>
            </div>
            <div>
                <h4 style="color: #ffffff; margin-bottom: 14px;">Quick Links</h4>
                <ul style="list-style: none; font-size: 13.5px; line-height: 2;">
                    <li><a href="index.jsp">Home</a></li>
                    <li><a href="about.jsp">About Us</a></li>
                    <li><a href="doctors.jsp">Our Doctors</a></li>
                    <li><a href="book-appointment.jsp">Book Appointment</a></li>
                </ul>
            </div>
            <div>
                <h4 style="color: #ffffff; margin-bottom: 14px;">Clinical Centers</h4>
                <ul style="list-style: none; font-size: 13.5px; line-height: 2;">
                    <li><a href="doctors.jsp">Cardiology & Heart Care</a></li>
                    <li><a href="doctors.jsp">Neurology & Spine Care</a></li>
                    <li><a href="doctors.jsp">Orthopedics & Joint Surgery</a></li>
                    <li><a href="doctors.jsp">Pediatrics & Neonatal Care</a></li>
                </ul>
            </div>
            <div>
                <h4 style="color: #ffffff; margin-bottom: 14px;">Emergency & Contact</h4>
                <p style="color: #cbd5e1; font-size: 13.5px; line-height: 1.8;">
                    <strong>Emergency Helpline:</strong><br>
                    +91 (040) 2345-6789<br>
                    <strong>Email:</strong><br>
                    support@cityhealth.org<br>
                    <strong>Address:</strong><br>
                    Plot 12, Healthcare Boulevard, Hyderabad
                </p>
            </div>
        </div>
        <div class="footer-bottom">
            <p>&copy; <%= java.time.Year.now().getValue() %> CityHealth Hospital Management System. Developed with JSP, JDBC, Oracle &amp; Tomcat 9.</p>
        </div>
    </div>
</footer>
