<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.PasswordUtil, com.hospital.util.SecurityUtil" %>
<%
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect("login.jsp");
        return;
    }

    // CSRF verification
    if (!SecurityUtil.verifyCsrfToken(request)) {
        response.sendRedirect("login.jsp?error=Invalid+security+token.+Please+try+again.");
        return;
    }

    String username = SecurityUtil.sanitize(request.getParameter("username"));
    String password = request.getParameter("password");
    String returnUrl = SecurityUtil.sanitize(request.getParameter("returnUrl"));

    if (username.isEmpty() || password == null || password.isEmpty()) {
        response.sendRedirect("login.jsp?error=Please+enter+both+username+and+password.");
        return;
    }

    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        String sql = "SELECT USER_ID, USERNAME, PASSWORD_HASH, PASSWORD_SALT, FULL_NAME, ROLE, PATIENT_ID, DOCTOR_ID, ACTIVE " +
                     "FROM USERS WHERE LOWER(USERNAME) = LOWER(?)";
        stmt = conn.prepareStatement(sql);
        stmt.setString(1, username);
        rs = stmt.executeQuery();

        if (rs.next()) {
            int active = rs.getInt("ACTIVE");
            if (active != 1) {
                response.sendRedirect("login.jsp?error=Your+account+has+been+deactivated.+Please+contact+administration.");
                return;
            }

            String storedHash = rs.getString("PASSWORD_HASH");
            String storedSalt = rs.getString("PASSWORD_SALT");

            boolean passwordMatch = PasswordUtil.verifyPassword(password, storedSalt, storedHash);

            if (passwordMatch) {
                int userId = rs.getInt("USER_ID");
                String fullName = rs.getString("FULL_NAME");
                String role = rs.getString("ROLE");
                int patientId = rs.getInt("PATIENT_ID");
                boolean patientIdIsNull = rs.wasNull();

                int doctorId = rs.getInt("DOCTOR_ID");
                boolean doctorIdIsNull = rs.wasNull();
                // Invalidate prior session and establish fresh authenticated session
                session.invalidate();
                HttpSession newSession = request.getSession(true);

                newSession.setAttribute("userId", String.valueOf(userId));
                newSession.setAttribute("username", username);
                newSession.setAttribute("userFullName", fullName);
                newSession.setAttribute("userRole", role);
                if (!patientIdIsNull && patientId > 0) {
                    newSession.setAttribute("patientId", String.valueOf(patientId));
                }

                if (!doctorIdIsNull && doctorId > 0) {
                    newSession.setAttribute("doctorId", String.valueOf(doctorId));
                }

               

                // Log successful login into AUDIT_LOG
                PreparedStatement auditStmt = null;
                try {
                    auditStmt = conn.prepareStatement(
                        "INSERT INTO AUDIT_LOG (USER_ID, ACTION, ENTITY_TYPE, ENTITY_ID, DETAILS) VALUES (?, ?, ?, ?, ?)"
                    );
                    auditStmt.setInt(1, userId);
                    auditStmt.setString(2, "USER_LOGIN");
                    auditStmt.setString(3, "USERS");
                    auditStmt.setInt(4, userId);
                    auditStmt.setString(5, "User logged in with role " + role);
                    auditStmt.executeUpdate();
                } catch (Exception ignored) {
                } finally {
                    DBConnection.close(auditStmt);
                }

                // Redirect based on role or intended return destination
                if (returnUrl != null && !returnUrl.isEmpty() && "PATIENT".equalsIgnoreCase(role)) {
                    response.sendRedirect(returnUrl);
                } else if ("PATIENT".equalsIgnoreCase(role)) {
                    response.sendRedirect("patient-dashboard.jsp");
                } else if ("DOCTOR".equalsIgnoreCase(role)) {
                    response.sendRedirect("doctor-dashboard.jsp");
                } else if ("ADMIN".equalsIgnoreCase(role) || "RECEPTIONIST".equalsIgnoreCase(role)) {
                    response.sendRedirect("admin-dashboard.jsp");
                } else {
                    response.sendRedirect("index.jsp");
                }
                return;
            }
        }

        // Generic error message to prevent username enumeration
        response.sendRedirect("login.jsp?error=Invalid+username+or+password.");

    } catch (Exception e) {
        System.err.println("[loginAction] Database error: " + e.getMessage());
        response.sendRedirect("login.jsp?error=System+error+during+authentication.+Please+try+again.");
    } finally {
        DBConnection.close(rs, stmt, conn);
    }
%>
