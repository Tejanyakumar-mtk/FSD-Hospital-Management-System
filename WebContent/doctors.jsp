<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    String filterDept = request.getParameter("dept");
    String searchKeyword = request.getParameter("search");
    if (searchKeyword == null) searchKeyword = "";
    searchKeyword = searchKeyword.trim();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Our Doctors &amp; Specialists - CityHealth HMS</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/public.css">
    <link rel="stylesheet" href="css/forms.css">
</head>
<body>

    <jsp:include page="includes/navbar.jsp" />

    <section class="hero" style="padding: 45px 0;">
        <div class="container">
            <span class="hero-badge">Clinical Consultants</span>
            <h1>Find a Doctor &amp; Schedule a Consultation</h1>
            <p style="max-width: 600px;">Explore our panel of accredited doctors, view weekly consultation schedules, and book your visit directly.</p>
            <%
                String sRole = (String) session.getAttribute("userRole");
                if ("ADMIN".equalsIgnoreCase(sRole) || "RECEPTIONIST".equalsIgnoreCase(sRole)) {
            %>
            <div style="margin-top: 16px;">
                <a href="manage-doctors.jsp" class="btn btn-secondary btn-sm">&#9881; Switch to Doctor Management Console &rarr;</a>
            </div>
            <% } %>
        </div>
    </section>

    <div class="container" style="padding: 40px 20px 80px 20px;">

        <!-- Search and Filter Bar -->
        <form method="GET" action="doctors.jsp" class="card" style="margin-bottom: 30px; padding: 20px;">
            <div class="grid grid-3" style="align-items: flex-end;">
                <div class="form-group" style="margin-bottom: 0;">
                    <label class="form-label">Search Doctor or Specialty</label>
                    <input type="text" name="search" class="form-control" placeholder="e.g. Sharma, Cardiologist, Ortho..." value="<%= SecurityUtil.escapeHtml(searchKeyword) %>">
                </div>
                <div class="form-group" style="margin-bottom: 0;">
                    <label class="form-label">Filter by Department</label>
                    <select name="dept" class="form-control">
                        <option value="">All Clinical Departments</option>
                        <%
                            Connection deptConn = null;
                            PreparedStatement deptStmt = null;
                            ResultSet deptRs = null;
                            try {
                                deptConn = DBConnection.getConnection();
                                deptStmt = deptConn.prepareStatement("SELECT DEPARTMENT_ID, DEPARTMENT_NAME FROM DEPARTMENTS WHERE ACTIVE = 1 ORDER BY DEPARTMENT_NAME");
                                deptRs = deptStmt.executeQuery();
                                while (deptRs.next()) {
                                    int dId = deptRs.getInt("DEPARTMENT_ID");
                                    String dName = deptRs.getString("DEPARTMENT_NAME");
                                    String selected = (filterDept != null && filterDept.equals(String.valueOf(dId))) ? "selected" : "";
                        %>
                            <option value="<%= dId %>" <%= selected %>><%= SecurityUtil.escapeHtml(dName) %></option>
                        <%
                                }
                            } catch (Exception e) {
                                // fallback
                            } finally {
                                DBConnection.close(deptRs, deptStmt, deptConn);
                            }
                        %>
                    </select>
                </div>
                <div style="display: flex; gap: 10px;">
                    <button type="submit" class="btn btn-primary" style="flex: 1;">Search</button>
                    <a href="doctors.jsp" class="btn btn-outline">Reset</a>
                </div>
            </div>
        </form>

        <!-- Doctors Grid -->
        <div class="grid grid-3">
            <%
                Connection conn = null;
                PreparedStatement stmt = null;
                ResultSet rs = null;
                int count = 0;
                try {
                    conn = DBConnection.getConnection();
                    StringBuilder sql = new StringBuilder(
                        "SELECT d.DOCTOR_ID, d.DOCTOR_NAME, d.EMAIL, d.PHONE, d.SPECIALIZATION, d.CONSULTATION_FEE, " +
                        "d.QUALIFICATION, d.ROOM_NO, dep.DEPARTMENT_NAME " +
                        "FROM DOCTORS d JOIN DEPARTMENTS dep ON d.DEPARTMENT_ID = dep.DEPARTMENT_ID " +
                        "WHERE d.ACTIVE = 1 "
                    );

                    if (filterDept != null && !filterDept.trim().isEmpty()) {
                        sql.append(" AND d.DEPARTMENT_ID = ? ");
                    }
                    if (!searchKeyword.isEmpty()) {
                        sql.append(" AND (LOWER(d.DOCTOR_NAME) LIKE ? OR LOWER(d.SPECIALIZATION) LIKE ? OR LOWER(dep.DEPARTMENT_NAME) LIKE ?) ");
                    }
                    sql.append(" ORDER BY d.DOCTOR_NAME ");

                    stmt = conn.prepareStatement(sql.toString());
                    int paramIdx = 1;
                    if (filterDept != null && !filterDept.trim().isEmpty()) {
                        stmt.setInt(paramIdx++, Integer.parseInt(filterDept.trim()));
                    }
                    if (!searchKeyword.isEmpty()) {
                        String likeParam = "%" + searchKeyword.toLowerCase() + "%";
                        stmt.setString(paramIdx++, likeParam);
                        stmt.setString(paramIdx++, likeParam);
                        stmt.setString(paramIdx++, likeParam);
                    }

                    rs = stmt.executeQuery();
                    while (rs.next()) {
                        count++;
                        int docId = rs.getInt("DOCTOR_ID");
                        String docName = SecurityUtil.escapeHtml(rs.getString("DOCTOR_NAME"));
                        String spec = SecurityUtil.escapeHtml(rs.getString("SPECIALIZATION"));
                        String deptName = SecurityUtil.escapeHtml(rs.getString("DEPARTMENT_NAME"));
                        String qual = SecurityUtil.escapeHtml(rs.getString("QUALIFICATION"));
                        String room = SecurityUtil.escapeHtml(rs.getString("ROOM_NO"));
                        double fee = rs.getDouble("CONSULTATION_FEE");

                        // Fetch Availability days for this doctor
                        StringBuilder availStr = new StringBuilder();
                        PreparedStatement availStmt = null;
                        ResultSet availRs = null;
                        try {
                            availStmt = conn.prepareStatement(
                                "SELECT DAY_OF_WEEK, START_TIME, END_TIME FROM DOCTOR_AVAILABILITY WHERE DOCTOR_ID = ? AND ACTIVE = 1"
                            );
                            availStmt.setInt(1, docId);
                            availRs = availStmt.executeQuery();
                            while (availRs.next()) {
                                if (availStr.length() > 0) availStr.append(", ");
                                availStr.append(availRs.getString("DAY_OF_WEEK").substring(0, 3));
                            }
                        } catch (Exception ignored) {
                        } finally {
                            DBConnection.close(availRs, availStmt);
                        }
            %>
            <div class="doctor-card">
                <div class="doctor-avatar-wrap">
                    <span>&#128104;&#8205;&#9877;&#65039;</span>
                </div>
                <div class="doctor-body">
                    <span class="doctor-specialty"><%= spec %> &bull; <%= deptName %></span>
                    <h3 class="doctor-name"><%= docName %></h3>
                    <p class="doctor-qualification"><%= (qual != null && !qual.isEmpty()) ? qual : "Specialist Consultant" %></p>
                    
                    <div style="font-size: 13px; color: var(--text-secondary); margin-bottom: 12px; line-height: 1.6;">
                        <div><strong>Room:</strong> <%= room != null ? room : "OPD Wing" %></div>
                        <div><strong>Days:</strong> <%= availStr.length() > 0 ? availStr.toString() : "Mon - Fri" %></div>
                    </div>

                    <div class="doctor-meta">
                        <div>
                            <span style="font-size: 11px; color: var(--text-secondary); display:block;">Consultation Fee</span>
                            <span class="doctor-fee">&#8377; <%= String.format("%.2f", fee) %></span>
                        </div>
                        <a href="book-appointment.jsp?doctorId=<%= docId %>" class="btn btn-primary btn-sm">Book Appointment</a>
                    </div>
                </div>
            </div>
            <%
                    }
                } catch (Exception e) {
            %>
                <div class="alert alert-danger" style="grid-column: 1 / -1;">
                    Error loading doctor directory: <%= SecurityUtil.escapeHtml(e.getMessage()) %>
                </div>
            <%
                } finally {
                    DBConnection.close(rs, stmt, conn);
                }

                if (count == 0) {
            %>
                <div class="card empty-state" style="grid-column: 1 / -1;">
                    <div class="empty-state-icon">&#128269;</div>
                    <h3>No Doctors Found</h3>
                    <p>No active doctors matched your search criteria. Try selecting another department or resetting filters.</p>
                    <a href="doctors.jsp" class="btn btn-primary btn-sm">Reset Filter</a>
                </div>
            <%
                }
            %>
        </div>
    </div>

    <jsp:include page="includes/footer.jsp" />

</body>
</html>
