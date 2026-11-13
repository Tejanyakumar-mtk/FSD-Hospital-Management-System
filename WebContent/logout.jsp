<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection" %>
<%
    String userIdStr = (String) session.getAttribute("userId");
    String userRole = (String) session.getAttribute("userRole");

    if (userIdStr != null) {
        Connection conn = null;
        PreparedStatement stmt = null;
        try {
            conn = DBConnection.getConnection();
            stmt = conn.prepareStatement(
                "INSERT INTO AUDIT_LOG (USER_ID, ACTION, ENTITY_TYPE, ENTITY_ID, DETAILS) VALUES (?, ?, ?, ?, ?)"
            );
            stmt.setInt(1, Integer.parseInt(userIdStr));
            stmt.setString(2, "USER_LOGOUT");
            stmt.setString(3, "USERS");
            stmt.setInt(4, Integer.parseInt(userIdStr));
            stmt.setString(5, "User logged out");
            stmt.executeUpdate();
        } catch (Exception ignored) {
        } finally {
            DBConnection.close(stmt, conn);
        }
    }

    // Invalidate the session
    session.invalidate();

    response.sendRedirect("login.jsp?msg=You+have+been+successfully+logged+out.");
%>
