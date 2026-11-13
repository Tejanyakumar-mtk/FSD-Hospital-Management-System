<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    String userId = (String) session.getAttribute("userId");
    String userRole = (String) session.getAttribute("userRole");
    String sessionPatientId = (String) session.getAttribute("patientId");

    if (userId == null) {
        response.sendRedirect("login.jsp?error=Please+log+in+to+view+invoices.");
        return;
    }

    int billId = SecurityUtil.parseInt(request.getParameter("billId"), 0);
    int apptId = SecurityUtil.parseInt(request.getParameter("appointmentId"), 0);

    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;

    int patientId = 0;
    String patientName = "";
    String patientPhone = "";
    String patientEmail = "";
    String patientAddress = "";
    double totalAmount = 0.00;
    double paidAmount = 0.00;
    double balanceAmount = 0.00;
    String billStatus = "";
    String billDate = "";
    int refApptId = 0;
    String doctorName = "";
    String deptName = "";

    try {
        conn = DBConnection.getConnection();

        StringBuilder sql = new StringBuilder(
            "SELECT b.BILL_ID, b.PATIENT_ID, b.APPOINTMENT_ID, b.TOTAL_AMOUNT, b.PAID_AMOUNT, b.BALANCE_AMOUNT, " +
            "b.STATUS, TO_CHAR(b.CREATED_AT, 'YYYY-MM-DD HH24:MI') AS BILL_DATE, " +
            "p.PATIENT_NAME, p.PHONE, p.EMAIL, p.ADDRESS, " +
            "d.DOCTOR_NAME, dep.DEPARTMENT_NAME " +
            "FROM BILLS b " +
            "JOIN PATIENTS p ON b.PATIENT_ID = p.PATIENT_ID " +
            "LEFT JOIN APPOINTMENTS a ON b.APPOINTMENT_ID = a.APPOINTMENT_ID " +
            "LEFT JOIN DOCTORS d ON a.DOCTOR_ID = d.DOCTOR_ID " +
            "LEFT JOIN DEPARTMENTS dep ON d.DEPARTMENT_ID = dep.DEPARTMENT_ID " +
            "WHERE "
        );

        if (billId > 0) {
            sql.append(" b.BILL_ID = ? ");
            stmt = conn.prepareStatement(sql.toString());
            stmt.setInt(1, billId);
        } else if (apptId > 0) {
            sql.append(" b.APPOINTMENT_ID = ? ");
            stmt = conn.prepareStatement(sql.toString());
            stmt.setInt(1, apptId);
        } else {
            response.sendRedirect("billing.jsp?error=No+bill+or+appointment+specified.");
            return;
        }

        rs = stmt.executeQuery();
        if (rs.next()) {
            billId = rs.getInt("BILL_ID");
            patientId = rs.getInt("PATIENT_ID");
            refApptId = rs.getInt("APPOINTMENT_ID");
            totalAmount = rs.getDouble("TOTAL_AMOUNT");
            paidAmount = rs.getDouble("PAID_AMOUNT");
            balanceAmount = rs.getDouble("BALANCE_AMOUNT");
            billStatus = rs.getString("STATUS");
            billDate = rs.getString("BILL_DATE");
            patientName = rs.getString("PATIENT_NAME");
            patientPhone = rs.getString("PHONE");
            patientEmail = rs.getString("EMAIL");
            patientAddress = rs.getString("ADDRESS");
            doctorName = rs.getString("DOCTOR_NAME");
            deptName = rs.getString("DEPARTMENT_NAME");

            // Authorization Ownership Check
            if ("PATIENT".equalsIgnoreCase(userRole)) {
                int myPatId = Integer.parseInt(sessionPatientId);
                if (patientId != myPatId) {
                    response.sendRedirect("patient-dashboard.jsp?error=Unauthorized+access+to+another+patient's+invoice.");
                    return;
                }
            }
        } else {
            response.sendRedirect("billing.jsp?error=Invoice+record+not+found.");
            return;
        }
    } catch (Exception e) {
        System.err.println("[invoice.jsp] Error: " + e.getMessage());
    } finally {
        DBConnection.close(rs, stmt);
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Invoice #<%= billId %> - CityHealth HMS</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/tables.css">
    <link rel="stylesheet" href="css/print.css">
    <style>
        .invoice-box {
            max-width: 820px;
            margin: 30px auto;
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: var(--radius-md);
            padding: 40px;
            box-shadow: var(--shadow-md);
        }
    </style>
</head>
<body style="background-color: var(--bg-body);">

    <jsp:include page="includes/navbar.jsp" />

    <div class="container" style="padding: 20px;">
        <div class="invoice-box">
            <!-- Invoice Header -->
            <div class="flex-between" style="border-bottom: 2px solid var(--secondary); padding-bottom: 20px; margin-bottom: 24px;">
                <div>
                    <div class="brand-logo" style="margin-bottom: 6px;">
                        <span class="brand-icon">+</span>
                        <span style="font-size: 1.4rem;">CityHealth Hospital</span>
                    </div>
                    <p style="font-size: 13px; color: var(--text-secondary); line-height: 1.5; margin: 0;">
                        Plot 12, Healthcare Boulevard, Hyderabad, TS - 500081<br>
                        GSTIN: 36AABCC1234F1Z5 &bull; Phone: +91 (040) 2345-6789<br>
                        Email: billing@cityhealth.org
                    </p>
                </div>
                <div style="text-align: right;">
                    <h2 style="font-size: 1.6rem; color: var(--secondary); margin-bottom: 4px;">TAX INVOICE</h2>
                    <div style="font-size: 14px; font-weight: 700;">Invoice #: CH-INV-<%= billId %></div>
                    <div style="font-size: 13px; color: var(--text-secondary);">Date: <%= billDate %></div>
                    <div style="margin-top: 8px;">
                        <span class="badge <%= "PAID".equalsIgnoreCase(billStatus) ? "badge-paid" : ("PARTIAL".equalsIgnoreCase(billStatus) ? "badge-partial" : "badge-pending") %>">
                            <%= billStatus %>
                        </span>
                    </div>
                </div>
            </div>

            <!-- Billed To & Doctor Assignment -->
            <div class="grid grid-2" style="margin-bottom: 28px;">
                <div style="background: #f8fafc; padding: 16px; border-radius: var(--radius-sm); border: 1px solid var(--border-color);">
                    <span style="font-size: 11px; font-weight: 700; text-transform: uppercase; color: var(--text-secondary); display: block; margin-bottom: 4px;">Billed To (Patient):</span>
                    <strong style="font-size: 15px; color: var(--secondary);"><%= SecurityUtil.escapeHtml(patientName) %></strong>
                    <div style="font-size: 13px; color: var(--text-secondary); margin-top: 2px;">
                        Patient ID: #<%= patientId %><br>
                        Phone: <%= SecurityUtil.escapeHtml(patientPhone) %><br>
                        Email: <%= SecurityUtil.escapeHtml(patientEmail) %><br>
                        Address: <%= patientAddress != null ? SecurityUtil.escapeHtml(patientAddress) : "OPD Walk-in" %>
                    </div>
                </div>

                <div style="background: #f8fafc; padding: 16px; border-radius: var(--radius-sm); border: 1px solid var(--border-color);">
                    <span style="font-size: 11px; font-weight: 700; text-transform: uppercase; color: var(--text-secondary); display: block; margin-bottom: 4px;">Service Information:</span>
                    <div style="font-size: 13px; color: var(--text-secondary); line-height: 1.8;">
                        <strong>Attending Doctor:</strong> <%= (doctorName != null) ? SecurityUtil.escapeHtml(doctorName) : "Hospital Clinical Staff" %><br>
                        <strong>Department:</strong> <%= (deptName != null) ? SecurityUtil.escapeHtml(deptName) : "General Services" %><br>
                        <strong>Appointment Ref:</strong> <%= (refApptId > 0) ? ("#" + refApptId) : "Direct OPD" %><br>
                        <strong>Payment Status:</strong> <%= billStatus %>
                    </div>
                </div>
            </div>

            <!-- Itemized Table -->
            <div style="margin-bottom: 24px;">
                <table class="table" style="background: #ffffff;">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Description of Medical Service / Investigation</th>
                            <th style="text-align: center;">Qty</th>
                            <th style="text-align: right;">Unit Price (&#8377;)</th>
                            <th style="text-align: right;">Amount (&#8377;)</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            PreparedStatement itemStmt = null;
                            ResultSet itemRs = null;
                            int itemNo = 0;
                            try {
                                itemStmt = conn.prepareStatement(
                                    "SELECT DESCRIPTION, QUANTITY, UNIT_PRICE, LINE_TOTAL FROM BILL_ITEMS WHERE BILL_ID = ? ORDER BY ITEM_ID ASC"
                                );
                                itemStmt.setInt(1, billId);
                                itemRs = itemStmt.executeQuery();
                                while (itemRs.next()) {
                                    itemNo++;
                                    String desc = SecurityUtil.escapeHtml(itemRs.getString("DESCRIPTION"));
                                    int qty = itemRs.getInt("QUANTITY");
                                    double uPrice = itemRs.getDouble("UNIT_PRICE");
                                    double lTotal = itemRs.getDouble("LINE_TOTAL");
                        %>
                        <tr>
                            <td><%= itemNo %></td>
                            <td><strong><%= desc %></strong></td>
                            <td style="text-align: center;"><%= qty %></td>
                            <td style="text-align: right;">&#8377; <%= String.format("%.2f", uPrice) %></td>
                            <td style="text-align: right;"><strong>&#8377; <%= String.format("%.2f", lTotal) %></strong></td>
                        </tr>
                        <%
                                }
                            } finally {
                                DBConnection.close(itemRs, itemStmt);
                            }
                        %>
                    </tbody>
                </table>
            </div>

            <!-- Totals & Balances -->
            <div style="display: flex; justify-content: flex-end; margin-bottom: 24px;">
                <div style="width: 320px; font-size: 14px;">
                    <div class="flex-between" style="padding: 6px 0; border-bottom: 1px dashed var(--border-color);">
                        <span style="color: var(--text-secondary);">Subtotal / Total Bill:</span>
                        <strong style="color: var(--secondary); font-size: 15px;">&#8377; <%= String.format("%.2f", totalAmount) %></strong>
                    </div>
                    <div class="flex-between" style="padding: 6px 0; border-bottom: 1px dashed var(--border-color);">
                        <span style="color: var(--text-secondary);">Amount Received:</span>
                        <strong style="color: var(--success); font-size: 15px;">&#8377; <%= String.format("%.2f", paidAmount) %></strong>
                    </div>
                    <div class="flex-between" style="padding: 10px 0; font-size: 16px; border-bottom: 2px solid var(--secondary);">
                        <span style="color: var(--secondary); font-weight: 700;">Balance Due:</span>
                        <strong style="color: (balanceAmount > 0 ? var(--danger) : var(--text-muted)); font-weight: 800;">
                            &#8377; <%= String.format("%.2f", balanceAmount) %>
                        </strong>
                    </div>
                </div>
            </div>

            <!-- Recorded Payment Transactions History -->
            <div style="margin-bottom: 30px;">
                <h4 style="font-size: 13px; text-transform: uppercase; color: var(--primary); letter-spacing: 0.5px; margin-bottom: 8px;">Payment Transaction Receipts</h4>
                <div class="table-responsive">
                    <table class="table" style="font-size: 13px; background: #fafbfc;">
                        <thead>
                            <tr>
                                <th>Txn #</th>
                                <th>Date &amp; Time</th>
                                <th>Payment Method</th>
                                <th>Transaction Ref</th>
                                <th style="text-align: right;">Amount Paid</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                PreparedStatement payStmt = null;
                                ResultSet payRs = null;
                                int payCount = 0;
                                try {
                                    payStmt = conn.prepareStatement(
                                        "SELECT PAYMENT_ID, TO_CHAR(PAYMENT_DATE, 'YYYY-MM-DD HH24:MI') AS PAY_DATE, " +
                                        "AMOUNT, PAYMENT_METHOD, PAYMENT_REFERENCE " +
                                        "FROM PAYMENTS WHERE BILL_ID = ? ORDER BY PAYMENT_ID ASC"
                                    );
                                    payStmt.setInt(1, billId);
                                    payRs = payStmt.executeQuery();
                                    while (payRs.next()) {
                                        payCount++;
                            %>
                            <tr>
                                <td>#<%= payRs.getInt("PAYMENT_ID") %></td>
                                <td><%= payRs.getString("PAY_DATE") %></td>
                                <td><%= SecurityUtil.escapeHtml(payRs.getString("PAYMENT_METHOD")) %></td>
                                <td><%= payRs.getString("PAYMENT_REFERENCE") != null ? SecurityUtil.escapeHtml(payRs.getString("PAYMENT_REFERENCE")) : "--" %></td>
                                <td style="text-align: right; color: var(--success); font-weight: 600;">&#8377; <%= String.format("%.2f", payRs.getDouble("AMOUNT")) %></td>
                            </tr>
                            <%
                                    }
                                } finally {
                                    DBConnection.close(payRs, payStmt);
                                }

                                if (payCount == 0) {
                            %>
                            <tr>
                                <td colspan="5" style="text-align: center; color: var(--text-muted); font-style: italic;">
                                    No payment receipts recorded yet for this invoice.
                                </td>
                            </tr>
                            <%  } %>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Invoice Footer -->
            <div class="flex-between" style="border-top: 1px dashed var(--border-color); padding-top: 20px; font-size: 12px; color: var(--text-secondary);">
                <div>
                    Thank you for choosing CityHealth Hospital.<br>
                    Computer generated receipt &bull; No physical signature required.
                </div>
                <div style="text-align: right;">
                    <strong>Authorized Cashier / Accountant</strong><br>
                    CityHealth Billing Desk
                </div>
            </div>

            <!-- Print Actions -->
            <div style="margin-top: 30px; text-align: center;" class="no-print">
                <button type="button" class="btn btn-primary btn-lg" onclick="window.print()">&#128438; Print / Save Invoice PDF</button>
                <a href="javascript:history.back()" class="btn btn-outline btn-lg" style="margin-left: 10px;">Back</a>
            </div>
        </div>
    </div>

    <jsp:include page="includes/footer.jsp" />

</body>
</html>
<%
    DBConnection.close(conn);
%>
