<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.time.LocalDate, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    String userId = (String) session.getAttribute("userId");
    String userRole = (String) session.getAttribute("userRole");

    if (userId == null || (!"ADMIN".equalsIgnoreCase(userRole) && !"RECEPTIONIST".equalsIgnoreCase(userRole))) {
        response.sendRedirect("login.jsp?error=Access+restricted+to+authorized+staff.");
        return;
    }

    String tab = request.getParameter("tab");
    if (tab == null) tab = "FINANCIAL";

    String fromDate = request.getParameter("fromDate");
    if (fromDate == null || fromDate.trim().isEmpty()) {
        fromDate = LocalDate.now().minusDays(30).toString();
    }

    String toDate = request.getParameter("toDate");
    if (toDate == null || toDate.trim().isEmpty()) {
        toDate = LocalDate.now().plusDays(1).toString();
    }

    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reports &amp; Analytics - CityHealth HMS</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/forms.css">
    <link rel="stylesheet" href="css/staff.css">
    <link rel="stylesheet" href="css/tables.css">
    <link rel="stylesheet" href="css/print.css">
</head>
<body>

    <jsp:include page="includes/navbar.jsp" />

    <div class="app-layout">
        <aside class="sidebar no-print">
            <div class="sidebar-heading">Staff Console (<%= userRole %>)</div>
            <ul class="sidebar-menu">
                <li><a href="admin-dashboard.jsp">&#127968; Dashboard</a></li>
                <li><a href="patients.jsp">&#128101; Patients</a></li>
                <li><a href="manage-doctors.jsp">&#128104;&#8205;&#9877;&#65039; Doctors</a></li>
                <li><a href="departments.jsp">&#127973; Departments</a></li>
                <li><a href="appointments.jsp">&#128197; Appointments</a></li>
                <li><a href="billing.jsp">&#128179; Billing &amp; Invoices</a></li>
                <li><a href="reports.jsp" class="active">&#128200; Reports &amp; Analytics</a></li>
                <li><a href="logout.jsp">&#128682; Logout</a></li>
            </ul>
        </aside>

        <main class="main-content">
            <div class="staff-topbar">
                <div class="staff-title">
                    <h2>Hospital Analytics &amp; Reports</h2>
                    <p>Financial revenue statements, patient demographics, and appointment audits.</p>
                </div>
                <button type="button" class="btn btn-outline btn-sm no-print" onclick="window.print()">&#128438; Print Report</button>
            </div>

            <!-- Date Range Filter Form -->
            <form method="GET" action="reports.jsp" class="card no-print" style="margin-bottom: 24px; padding: 20px;">
                <input type="hidden" name="tab" value="<%= tab %>">
                <div class="grid grid-3" style="align-items: flex-end;">
                    <div class="form-group" style="margin-bottom: 0;">
                        <label class="form-label">From Date</label>
                        <input type="date" name="fromDate" class="form-control" value="<%= fromDate %>">
                    </div>
                    <div class="form-group" style="margin-bottom: 0;">
                        <label class="form-label">To Date</label>
                        <input type="date" name="toDate" class="form-control" value="<%= toDate %>">
                    </div>
                    <div style="display: flex; gap: 10px;">
                        <button type="submit" class="btn btn-primary" style="flex: 1;">Generate Report</button>
                        <a href="reports.jsp?tab=<%= tab %>" class="btn btn-outline">Reset Dates</a>
                    </div>
                </div>
            </form>

            <!-- Navigation Tabs -->
            <div class="table-toolbar no-print">
                <div class="table-filters">
                    <a href="reports.jsp?tab=FINANCIAL&fromDate=<%= fromDate %>&toDate=<%= toDate %>"
                       class="btn btn-sm <%= "FINANCIAL".equalsIgnoreCase(tab) ? "btn-primary" : "btn-outline" %>">
                        &#8377; Financial &amp; Collections
                    </a>
                    <a href="reports.jsp?tab=APPOINTMENTS&fromDate=<%= fromDate %>&toDate=<%= toDate %>"
                       class="btn btn-sm <%= "APPOINTMENTS".equalsIgnoreCase(tab) ? "btn-primary" : "btn-outline" %>">
                        &#128197; Appointments Summary
                    </a>
                    <a href="reports.jsp?tab=PATIENTS&fromDate=<%= fromDate %>&toDate=<%= toDate %>"
                       class="btn btn-sm <%= "PATIENTS".equalsIgnoreCase(tab) ? "btn-primary" : "btn-outline" %>">
                        &#128101; Patient Registrations
                    </a>
                </div>
            </div>

            <%
                try {
                    conn = DBConnection.getConnection();

                    if ("FINANCIAL".equalsIgnoreCase(tab)) {
                        // Financial Report
                        double totalBilled = 0.00;
                        double totalCollected = 0.00;
                        double totalOutstanding = 0.00;
                        int billCount = 0;

                        stmt = conn.prepareStatement(
                            "SELECT COUNT(*) AS CNT, NVL(SUM(TOTAL_AMOUNT), 0) AS BILLED, " +
                            "NVL(SUM(PAID_AMOUNT), 0) AS COLLECTED, NVL(SUM(BALANCE_AMOUNT), 0) AS BALANCE " +
                            "FROM BILLS WHERE CREATED_AT >= TO_DATE(?, 'YYYY-MM-DD') AND CREATED_AT <= TO_DATE(?, 'YYYY-MM-DD') + 1"
                        );
                        stmt.setString(1, fromDate);
                        stmt.setString(2, toDate);
                        rs = stmt.executeQuery();
                        if (rs.next()) {
                            billCount = rs.getInt("CNT");
                            totalBilled = rs.getDouble("BILLED");
                            totalCollected = rs.getDouble("COLLECTED");
                            totalOutstanding = rs.getDouble("BALANCE");
                        }
                        DBConnection.close(rs, stmt);
            %>
            <!-- Summary Metric Cards -->
            <div class="grid grid-3" style="margin-bottom: 24px;">
                <div class="stat-card">
                    <div class="stat-icon blue">&#128203;</div>
                    <div class="stat-info">
                        <h4>Total Invoices Raised</h4>
                        <div class="stat-value">&#8377; <%= String.format("%.2f", totalBilled) %> (<%= billCount %>)</div>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon green">&#9989;</div>
                    <div class="stat-info">
                        <h4>Realized Collections</h4>
                        <div class="stat-value" style="color: var(--success);">&#8377; <%= String.format("%.2f", totalCollected) %></div>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon amber">&#9200;</div>
                    <div class="stat-info">
                        <h4>Outstanding Receivables</h4>
                        <div class="stat-value" style="color: var(--danger);">&#8377; <%= String.format("%.2f", totalOutstanding) %></div>
                    </div>
                </div>
            </div>

            <!-- Revenue Breakdown by Payment Method -->
            <div class="card" style="margin-bottom: 24px;">
                <div class="card-header">
                    <h3 class="card-title">Collections by Payment Mode (<%= fromDate %> to <%= toDate %>)</h3>
                </div>
                <div class="table-responsive">
                    <table class="table">
                        <thead>
                            <tr>
                                <th>Payment Method</th>
                                <th>Number of Transactions</th>
                                <th style="text-align: right;">Total Amount Collected</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                stmt = conn.prepareStatement(
                                    "SELECT PAYMENT_METHOD, COUNT(*) AS TXN_COUNT, SUM(AMOUNT) AS TOTAL_AMT " +
                                    "FROM PAYMENTS " +
                                    "WHERE PAYMENT_DATE >= TO_DATE(?, 'YYYY-MM-DD') AND PAYMENT_DATE <= TO_DATE(?, 'YYYY-MM-DD') + 1 " +
                                    "GROUP BY PAYMENT_METHOD ORDER BY TOTAL_AMT DESC"
                                );
                                stmt.setString(1, fromDate);
                                stmt.setString(2, toDate);
                                rs = stmt.executeQuery();
                                int pRows = 0;
                                while (rs.next()) {
                                    pRows++;
                            %>
                            <tr>
                                <td><strong><%= SecurityUtil.escapeHtml(rs.getString("PAYMENT_METHOD")) %></strong></td>
                                <td><%= rs.getInt("TXN_COUNT") %> Transactions</td>
                                <td style="text-align: right; font-weight: 700; color: var(--success);">&#8377; <%= String.format("%.2f", rs.getDouble("TOTAL_AMT")) %></td>
                            </tr>
                            <%
                                }
                                DBConnection.close(rs, stmt);
                                if (pRows == 0) {
                            %>
                            <tr>
                                <td colspan="3" style="text-align: center; color: var(--text-secondary); padding: 20px;">
                                    No payment transactions recorded within this date range.
                                </td>
                            </tr>
                            <%  } %>
                        </tbody>
                    </table>
                </div>
            </div>

            <% } else if ("APPOINTMENTS".equalsIgnoreCase(tab)) { %>
            <!-- Appointments Report -->
            <div class="card" style="margin-bottom: 24px;">
                <div class="card-header">
                    <h3 class="card-title">Appointments by Department &amp; Status (<%= fromDate %> to <%= toDate %>)</h3>
                </div>
                <div class="table-responsive">
                    <table class="table">
                        <thead>
                            <tr>
                                <th>Department</th>
                                <th>Doctor</th>
                                <th>Total Visits</th>
                                <th>Booked</th>
                                <th>Completed</th>
                                <th>Cancelled</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                stmt = conn.prepareStatement(
                                    "SELECT dep.DEPARTMENT_NAME, d.DOCTOR_NAME, COUNT(a.APPOINTMENT_ID) AS TOTAL_APPTS, " +
                                    "SUM(CASE WHEN a.STATUS = 'BOOKED' THEN 1 ELSE 0 END) AS BOOKED_CNT, " +
                                    "SUM(CASE WHEN a.STATUS = 'COMPLETED' THEN 1 ELSE 0 END) AS COMPL_CNT, " +
                                    "SUM(CASE WHEN a.STATUS = 'CANCELLED' THEN 1 ELSE 0 END) AS CANC_CNT " +
                                    "FROM DOCTORS d " +
                                    "JOIN DEPARTMENTS dep ON d.DEPARTMENT_ID = dep.DEPARTMENT_ID " +
                                    "LEFT JOIN APPOINTMENTS a ON d.DOCTOR_ID = a.DOCTOR_ID " +
                                    "AND a.APPOINTMENT_DATE >= TO_DATE(?, 'YYYY-MM-DD') AND a.APPOINTMENT_DATE <= TO_DATE(?, 'YYYY-MM-DD') " +
                                    "GROUP BY dep.DEPARTMENT_NAME, d.DOCTOR_NAME ORDER BY dep.DEPARTMENT_NAME, TOTAL_APPTS DESC"
                                );
                                stmt.setString(1, fromDate);
                                stmt.setString(2, toDate);
                                rs = stmt.executeQuery();
                                int aRows = 0;
                                while (rs.next()) {
                                    aRows++;
                            %>
                            <tr>
                                <td><strong><%= SecurityUtil.escapeHtml(rs.getString("DEPARTMENT_NAME")) %></strong></td>
                                <td><%= SecurityUtil.escapeHtml(rs.getString("DOCTOR_NAME")) %></td>
                                <td><strong><%= rs.getInt("TOTAL_APPTS") %></strong></td>
                                <td><span class="badge badge-booked"><%= rs.getInt("BOOKED_CNT") %></span></td>
                                <td><span class="badge badge-completed"><%= rs.getInt("COMPL_CNT") %></span></td>
                                <td><span class="badge badge-cancelled"><%= rs.getInt("CANC_CNT") %></span></td>
                            </tr>
                            <%
                                }
                                DBConnection.close(rs, stmt);
                            %>
                        </tbody>
                    </table>
                </div>
            </div>

            <% } else if ("PATIENTS".equalsIgnoreCase(tab)) { %>
            <!-- Patient Registrations Report -->
            <div class="card" style="margin-bottom: 24px;">
                <div class="card-header">
                    <h3 class="card-title">Patient Registrations by Blood Group &amp; Gender (<%= fromDate %> to <%= toDate %>)</h3>
                </div>
                <div class="table-responsive">
                    <table class="table">
                        <thead>
                            <tr>
                                <th>Blood Group</th>
                                <th>Male</th>
                                <th>Female</th>
                                <th>Other</th>
                                <th>Total Patients</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                stmt = conn.prepareStatement(
                                    "SELECT NVL(BLOOD_GROUP, 'Unknown') AS B_GROUP, " +
                                    "SUM(CASE WHEN GENDER = 'Male' THEN 1 ELSE 0 END) AS M_CNT, " +
                                    "SUM(CASE WHEN GENDER = 'Female' THEN 1 ELSE 0 END) AS F_CNT, " +
                                    "SUM(CASE WHEN GENDER NOT IN ('Male', 'Female') THEN 1 ELSE 0 END) AS O_CNT, " +
                                    "COUNT(*) AS TOTAL " +
                                    "FROM PATIENTS " +
                                    "WHERE CREATED_AT >= TO_DATE(?, 'YYYY-MM-DD') AND CREATED_AT <= TO_DATE(?, 'YYYY-MM-DD') + 1 " +
                                    "GROUP BY BLOOD_GROUP ORDER BY TOTAL DESC"
                                );
                                stmt.setString(1, fromDate);
                                stmt.setString(2, toDate);
                                rs = stmt.executeQuery();
                                int pRows = 0;
                                while (rs.next()) {
                                    pRows++;
                            %>
                            <tr>
                                <td><span class="badge badge-info"><%= SecurityUtil.escapeHtml(rs.getString("B_GROUP")) %></span></td>
                                <td><%= rs.getInt("M_CNT") %></td>
                                <td><%= rs.getInt("F_CNT") %></td>
                                <td><%= rs.getInt("O_CNT") %></td>
                                <td><strong><%= rs.getInt("TOTAL") %></strong></td>
                            </tr>
                            <%
                                }
                                DBConnection.close(rs, stmt);
                                if (pRows == 0) {
                            %>
                            <tr>
                                <td colspan="5" style="text-align: center; color: var(--text-secondary); padding: 20px;">
                                    No patient registrations recorded within this date range.
                                </td>
                            </tr>
                            <%  } %>
                        </tbody>
                    </table>
                </div>
            </div>
            <% } %>

            <%
                } catch (Exception e) {
                    System.err.println("[reports.jsp] Error: " + e.getMessage());
            %>
                <div class="alert alert-danger">Report Generation Error: <%= SecurityUtil.escapeHtml(e.getMessage()) %></div>
            <%
                } finally {
                    DBConnection.close(rs, stmt, conn);
                }
            %>
        </main>
    </div>

    <jsp:include page="includes/footer.jsp" />

</body>
</html>
