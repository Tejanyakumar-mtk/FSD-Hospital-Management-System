<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.PasswordUtil, com.hospital.util.SecurityUtil" %>
<%
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect("patient-profile.jsp");
        return;
    }

    if (!SecurityUtil.verifyCsrfToken(request)) {
        response.sendRedirect("patient-profile.jsp?error=Security+validation+failed.");
        return;
    }

    String sessionRole = (String) session.getAttribute("userRole");
    String sessionUserId = (String) session.getAttribute("userId");
    String sessionPatientId = (String) session.getAttribute("patientId");

    if (sessionUserId == null || !"PATIENT".equalsIgnoreCase(sessionRole) || sessionPatientId == null) {
        response.sendRedirect("login.jsp?error=Session+expired.");
        return;
    }

    int patientId = Integer.parseInt(sessionPatientId);
    int userId = Integer.parseInt(sessionUserId);
    String actionType = request.getParameter("actionType");

    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();

        if ("UPDATE_CONTACT".equalsIgnoreCase(actionType)) {
            String phone = SecurityUtil.sanitize(request.getParameter("phone"));
            String email = SecurityUtil.sanitize(request.getParameter("email"));
            String emergencyContact = SecurityUtil.sanitize(request.getParameter("emergencyContact"));
            String address = SecurityUtil.sanitize(request.getParameter("address"));

            if (phone.isEmpty() || !phone.matches("^[0-9]{10}$")) {
                response.sendRedirect("patient-profile.jsp?error=Invalid+10-digit+phone+number.");
                return;
            }
            if (email.isEmpty() || !email.matches("^[A-Za-z0-9+_.-]+@(.+)$")) {
                response.sendRedirect("patient-profile.jsp?error=Invalid+email+format.");
                return;
            }

            stmt = conn.prepareStatement(
                "UPDATE PATIENTS SET PHONE = ?, EMAIL = ?, EMERGENCY_CONTACT = ?, ADDRESS = ? WHERE PATIENT_ID = ?"
            );
            stmt.setString(1, phone);
            stmt.setString(2, email);
            stmt.setString(3, emergencyContact.isEmpty() ? null : emergencyContact);
            stmt.setString(4, address.isEmpty() ? null : address);
            stmt.setInt(5, patientId);
            stmt.executeUpdate();

            response.sendRedirect("patient-profile.jsp?msg=Contact+details+updated+successfully.");
            return;

        } else if ("CHANGE_PASSWORD".equalsIgnoreCase(actionType)) {
            String currentPassword = request.getParameter("currentPassword");
            String newPassword = request.getParameter("newPassword");
            String confirmNewPassword = request.getParameter("confirmNewPassword");

            if (currentPassword == null || newPassword == null || confirmNewPassword == null) {
                response.sendRedirect("patient-profile.jsp?error=Please+complete+all+password+fields.");
                return;
            }

            if (newPassword.length() < 6) {
                response.sendRedirect("patient-profile.jsp?error=New+password+must+be+at+least+6+characters.");
                return;
            }

            if (!newPassword.equals(confirmNewPassword)) {
                response.sendRedirect("patient-profile.jsp?error=New+passwords+do+not+match.");
                return;
            }

            // Verify current password
            stmt = conn.prepareStatement("SELECT PASSWORD_HASH, PASSWORD_SALT FROM USERS WHERE USER_ID = ?");
            stmt.setInt(1, userId);
            rs = stmt.executeQuery();

            if (rs.next()) {
                String storedHash = rs.getString("PASSWORD_HASH");
                String storedSalt = rs.getString("PASSWORD_SALT");

                if (!PasswordUtil.verifyPassword(currentPassword, storedSalt, storedHash)) {
                    response.sendRedirect("patient-profile.jsp?error=Current+password+is+incorrect.");
                    return;
                }
            } else {
                response.sendRedirect("patient-profile.jsp?error=User+account+not+found.");
                return;
            }
            DBConnection.close(rs, stmt);

            // Hash new password
            String newSalt = PasswordUtil.generateSalt();
            String newHash = PasswordUtil.hashPassword(newPassword, newSalt);

            stmt = conn.prepareStatement("UPDATE USERS SET PASSWORD_HASH = ?, PASSWORD_SALT = ? WHERE USER_ID = ?");
            stmt.setString(1, newHash);
            stmt.setString(2, newSalt);
            stmt.setInt(3, userId);
            stmt.executeUpdate();

            response.sendRedirect("patient-profile.jsp?msg=Password+updated+successfully.");
            return;
        }

    } catch (Exception e) {
        System.err.println("[updatePatientProfile] Error: " + e.getMessage());
        response.sendRedirect("patient-profile.jsp?error=System+error+updating+profile.");
    } finally {
        DBConnection.close(rs, stmt, conn);
    }
%>
