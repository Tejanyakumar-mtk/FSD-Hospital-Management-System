<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect("departments.jsp");
        return;
    }

    if (!SecurityUtil.verifyCsrfToken(request)) {
        response.sendRedirect("departments.jsp?error=Security+validation+failed.");
        return;
    }

    String sessionRole = (String) session.getAttribute("userRole");
    if (!"ADMIN".equalsIgnoreCase(sessionRole) && !"RECEPTIONIST".equalsIgnoreCase(sessionRole)) {
        response.sendRedirect("login.jsp?error=Unauthorized.");
        return;
    }

    String actionType = request.getParameter("actionType");
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();

        if ("CREATE".equalsIgnoreCase(actionType)) {
            String deptName = SecurityUtil.sanitize(request.getParameter("departmentName"));
            String desc = SecurityUtil.sanitize(request.getParameter("description"));

            if (deptName.isEmpty()) {
                response.sendRedirect("departments.jsp?error=Department+name+is+required.");
                return;
            }

            stmt = conn.prepareStatement(
                "INSERT INTO DEPARTMENTS (DEPARTMENT_ID, DEPARTMENT_NAME, DESCRIPTION, ACTIVE) VALUES (SEQ_DEPARTMENTS.NEXTVAL, ?, ?, 1)"
            );
            stmt.setString(1, deptName);
            stmt.setString(2, desc.isEmpty() ? null : desc);
            stmt.executeUpdate();

            response.sendRedirect("departments.jsp?msg=Department+'" + SecurityUtil.escapeHtml(deptName) + "'+created+successfully.");
            return;

        } else if ("UPDATE".equalsIgnoreCase(actionType)) {
            int deptId = SecurityUtil.parseInt(request.getParameter("departmentId"), 0);
            String deptName = SecurityUtil.sanitize(request.getParameter("departmentName"));
            String desc = SecurityUtil.sanitize(request.getParameter("description"));

            if (deptId <= 0 || deptName.isEmpty()) {
                response.sendRedirect("departments.jsp?error=Invalid+department+data.");
                return;
            }

            stmt = conn.prepareStatement(
                "UPDATE DEPARTMENTS SET DEPARTMENT_NAME = ?, DESCRIPTION = ? WHERE DEPARTMENT_ID = ?"
            );
            stmt.setString(1, deptName);
            stmt.setString(2, desc.isEmpty() ? null : desc);
            stmt.setInt(3, deptId);
            stmt.executeUpdate();

            response.sendRedirect("departments.jsp?msg=Department+%23" + deptId + "+updated+successfully.");
            return;

        } else if ("TOGGLE_STATUS".equalsIgnoreCase(actionType)) {
            int deptId = SecurityUtil.parseInt(request.getParameter("departmentId"), 0);
            int currentStatus = SecurityUtil.parseInt(request.getParameter("currentStatus"), 1);
            int newStatus = (currentStatus == 1) ? 0 : 1;

            // If deactivating, check if active doctors belong to it
            if (newStatus == 0) {
                stmt = conn.prepareStatement("SELECT COUNT(*) FROM DOCTORS WHERE DEPARTMENT_ID = ? AND ACTIVE = 1");
                stmt.setInt(1, deptId);
                rs = stmt.executeQuery();
                if (rs.next() && rs.getInt(1) > 0) {
                    response.sendRedirect("departments.jsp?error=Cannot+deactivate+department+while+active+doctors+are+still+assigned+to+it.");
                    return;
                }
                DBConnection.close(rs, stmt);
            }

            stmt = conn.prepareStatement("UPDATE DEPARTMENTS SET ACTIVE = ? WHERE DEPARTMENT_ID = ?" );
            stmt.setInt(1, newStatus);
            stmt.setInt(2, deptId);
            stmt.executeUpdate();

            String lbl = (newStatus == 1) ? "activated" : "deactivated";
            response.sendRedirect("departments.jsp?msg=Department+%23" + deptId + "+has+been+" + lbl + ".");
            return;
        }

    } catch (Exception e) {
        System.err.println("[saveDepartment] Error: " + e.getMessage());
        response.sendRedirect("departments.jsp?error=Database+error+processing+department.");
    } finally {
        DBConnection.close(rs, stmt, conn);
    }
%>
