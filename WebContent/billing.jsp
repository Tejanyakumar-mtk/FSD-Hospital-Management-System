<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    String userId = (String) session.getAttribute("userId");
    String userRole = (String) session.getAttribute("userRole");

    if (userId == null || (!"ADMIN".equalsIgnoreCase(userRole) && !"RECEPTIONIST".equalsIgnoreCase(userRole))) {
        response.sendRedirect("login.jsp?error=Access+restricted+to+authorized+billing+staff.");
        return;
    }

    String search = request.getParameter("search");
    if (search == null) search = "";
    search = search.trim();

    String statusFilter = request.getParameter("status");
    if (statusFilter == null) statusFilter = "ALL";

    String actionParam = request.getParameter("action");
    String msg = request.getParameter("msg");
    String error = request.getParameter("error");
    String csrfToken = SecurityUtil.getCsrfToken(session);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Billing &amp; Invoices - CityHealth HMS</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/forms.css">
    <link rel="stylesheet" href="css/staff.css">
    <link rel="stylesheet" href="css/tables.css">
    <script src="js/dashboard.js"></script>
</head>
<body>

    <jsp:include page="includes/navbar.jsp" />

    <div class="app-layout">
        <aside class="sidebar">
            <div class="sidebar-heading">Staff Console (<%= userRole %>)</div>
            <ul class="sidebar-menu">
                <li><a href="admin-dashboard.jsp">&#127968; Dashboard</a></li>
                <li><a href="patients.jsp">&#128101; Patients</a></li>
                <li><a href="manage-doctors.jsp">&#128104;&#8205;&#9877;&#65039; Doctors</a></li>
                <li><a href="departments.jsp">&#127973; Departments</a></li>
                <li><a href="appointments.jsp">&#128197; Appointments</a></li>
                <li><a href="billing.jsp" class="active">&#128179; Billing &amp; Invoices</a></li>
                <li><a href="reports.jsp">&#128200; Reports &amp; Analytics</a></li>
                <li><a href="logout.jsp">&#128682; Logout</a></li>
            </ul>
        </aside>

        <main class="main-content">
            <div class="staff-topbar">
                <div class="staff-title">
                    <h2>Billing &amp; Revenue Management</h2>
                    <p>Generate patient invoices, record fee collections, and track outstanding balances.</p>
                </div>
                <button type="button" class="btn btn-primary" onclick="openModal('newBillModal')">+ Create New Bill</button>
            </div>

            <% if (msg != null && !msg.trim().isEmpty()) { %>
                <div class="alert alert-success">&#10003; <%= SecurityUtil.escapeHtml(msg) %></div>
            <% } %>
            <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="alert alert-danger">&#9888; <%= SecurityUtil.escapeHtml(error) %></div>
            <% } %>

            <!-- Search and Filter Bar -->
            <form method="GET" action="billing.jsp" class="table-toolbar">
                <div class="table-search" style="max-width: 360px;">
                    <input type="text" name="search" placeholder="Search bill ID, patient name..." value="<%= SecurityUtil.escapeHtml(search) %>">
                </div>
                <div class="table-filters">
                    <button type="submit" class="btn btn-primary btn-sm">Search</button>
                    <a href="billing.jsp?status=ALL" class="btn btn-sm <%= "ALL".equalsIgnoreCase(statusFilter) ? "btn-primary" : "btn-outline" %>">All</a>
                    <a href="billing.jsp?status=PENDING" class="btn btn-sm <%= "PENDING".equalsIgnoreCase(statusFilter) ? "btn-primary" : "btn-outline" %>">Pending</a>
                    <a href="billing.jsp?status=PARTIAL" class="btn btn-sm <%= "PARTIAL".equalsIgnoreCase(statusFilter) ? "btn-primary" : "btn-outline" %>">Partial</a>
                    <a href="billing.jsp?status=PAID" class="btn btn-sm <%= "PAID".equalsIgnoreCase(statusFilter) ? "btn-primary" : "btn-outline" %>">Paid</a>
                    <a href="billing.jsp" class="btn btn-outline btn-sm">Reset</a>
                </div>
            </form>

            <!-- Bills Master Table -->
            <div class="card" style="padding: 0; overflow: hidden;">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Bill #</th>
                                <th>Patient Name</th>
                                <th>Appt Ref</th>
                                <th>Total (&#8377;)</th>
                                <th>Paid (&#8377;)</th>
                                <th>Balance (&#8377;)</th>
                                <th>Date</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                Connection conn = null;
                                PreparedStatement stmt = null;
                                ResultSet rs = null;
                                int count = 0;
                                try {
                                    conn = DBConnection.getConnection();
                                    StringBuilder sql = new StringBuilder(
                                        "SELECT b.BILL_ID, b.PATIENT_ID, b.APPOINTMENT_ID, b.TOTAL_AMOUNT, b.PAID_AMOUNT, " +
                                        "b.BALANCE_AMOUNT, b.STATUS, TO_CHAR(b.CREATED_AT, 'YYYY-MM-DD') AS BILL_DATE, " +
                                        "p.PATIENT_NAME, p.PHONE " +
                                        "FROM BILLS b " +
                                        "JOIN PATIENTS p ON b.PATIENT_ID = p.PATIENT_ID WHERE 1=1 "
                                    );

                                    if ("PENDING".equalsIgnoreCase(statusFilter)) {
                                        sql.append(" AND b.STATUS = 'PENDING' ");
                                    } else if ("PARTIAL".equalsIgnoreCase(statusFilter)) {
                                        sql.append(" AND b.STATUS = 'PARTIAL' ");
                                    } else if ("PAID".equalsIgnoreCase(statusFilter)) {
                                        sql.append(" AND b.STATUS = 'PAID' ");
                                    }

                                    if (!search.isEmpty()) {
                                        sql.append(" AND (LOWER(p.PATIENT_NAME) LIKE ? OR p.PHONE LIKE ? ");
                                        if (search.matches("^[0-9]+$")) {
                                            sql.append(" OR b.BILL_ID = ? ");
                                        }
                                        sql.append(") ");
                                    }

                                    sql.append(" ORDER BY b.BILL_ID DESC ");

                                    stmt = conn.prepareStatement(sql.toString());
                                    int pIdx = 1;
                                    if (!search.isEmpty()) {
                                        String likeP = "%" + search.toLowerCase() + "%";
                                        stmt.setString(pIdx++, likeP);
                                        stmt.setString(pIdx++, "%" + search + "%");
                                        if (search.matches("^[0-9]+$")) {
                                            stmt.setInt(pIdx++, Integer.parseInt(search));
                                        }
                                    }

                                    rs = stmt.executeQuery();
                                    while (rs.next()) {
                                        count++;
                                        int bId = rs.getInt("BILL_ID");
                                        int pId = rs.getInt("PATIENT_ID");
                                        int apptRef = rs.getInt("APPOINTMENT_ID");
                                        String pName = SecurityUtil.escapeHtml(rs.getString("PATIENT_NAME"));
                                        String phone = SecurityUtil.escapeHtml(rs.getString("PHONE"));
                                        double total = rs.getDouble("TOTAL_AMOUNT");
                                        double paid = rs.getDouble("PAID_AMOUNT");
                                        double balance = rs.getDouble("BALANCE_AMOUNT");
                                        String bDate = rs.getString("BILL_DATE");
                                        String st = rs.getString("STATUS");

                                        String badgeCls = "badge-pending";
                                        if ("PAID".equalsIgnoreCase(st)) badgeCls = "badge-paid";
                                        else if ("PARTIAL".equalsIgnoreCase(st)) badgeCls = "badge-partial";
                                        else if ("CANCELLED".equalsIgnoreCase(st)) badgeCls = "badge-cancelled";
                            %>
                            <tr>
                                <td><strong>#<%= bId %></strong></td>
                                <td><strong><%= pName %></strong><br><span style="font-size: 12px; color: var(--text-secondary);">#<%= pId %> &bull; <%= phone %></span></td>
                                <td><%= (apptRef > 0) ? ("#" + apptRef) : "Direct OPD" %></td>
                                <td><strong>&#8377; <%= String.format("%.2f", total) %></strong></td>
                                <td><span style="color: var(--success); font-weight: 600;">&#8377; <%= String.format("%.2f", paid) %></span></td>
                                <td><span style="color: (balance > 0 ? var(--danger) : var(--text-muted)); font-weight: 600;">&#8377; <%= String.format("%.2f", balance) %></span></td>
                                <td><%= bDate %></td>
                                <td><span class="badge <%= badgeCls %>"><%= st %></span></td>
                                <td>
                                    <div class="table-actions">
                                        <% if (balance > 0 && !"CANCELLED".equalsIgnoreCase(st)) { %>
                                            <button type="button" class="btn btn-success btn-sm"
                                                    onclick="openPaymentModal(<%= bId %>, '<%= pName %>', <%= balance %>)">
                                                + Pay
                                            </button>
                                        <% } %>
                                        <a href="invoice.jsp?billId=<%= bId %>" class="btn btn-outline btn-sm" target="_blank">Invoice</a>
                                    </div>
                                </td>
                            </tr>
                            <%
                                    }
                                } catch (Exception e) {
                                    System.err.println("[billing.jsp] Error: " + e.getMessage());
                            %>
                            <tr>
                                <td colspan="9" style="color: var(--danger); text-align: center; padding: 20px;">
                                    Failed to retrieve bills: <%= SecurityUtil.escapeHtml(e.getMessage()) %>
                                </td>
                            </tr>
                            <%
                                } finally {
                                    DBConnection.close(rs, stmt, conn);
                                }

                                if (count == 0) {
                            %>
                            <tr>
                                <td colspan="9" style="text-align: center; padding: 36px; color: var(--text-secondary);">
                                    No billing records found matching your filters.
                                </td>
                            </tr>
                            <%  } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </main>
    </div>

    <!-- Modal: Create New Bill -->
    <div id="newBillModal" class="modal-overlay <%= "new".equalsIgnoreCase(actionParam) ? "active" : "" %>">
        <div class="modal-card" style="max-width: 750px;">
            <div class="modal-header">
                <h3 class="card-title">Create New Hospital Bill</h3>
                <button type="button" class="btn-remove-row" onclick="closeModal('newBillModal')">&times;</button>
            </div>
            <form action="saveBill.jsp" method="POST">
                <div class="modal-body">
                    <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                    <input type="hidden" id="totalAmountInput" name="totalAmount" value="0.00">

                    <div class="form-row">
                        <div class="form-group" style="flex: 2;">
                            <label class="form-label">Patient <span class="required">*</span></label>
                            <select name="patientId" class="form-control" required>
                                <option value="">-- Select Patient --</option>
                                <%
                                    Connection bConn = null;
                                    PreparedStatement bStmt = null;
                                    ResultSet bRs = null;
                                    try {
                                        bConn = DBConnection.getConnection();
                                        bStmt = bConn.prepareStatement("SELECT PATIENT_ID, PATIENT_NAME, PHONE FROM PATIENTS WHERE ACTIVE = 1 ORDER BY PATIENT_NAME");
                                        bRs = bStmt.executeQuery();
                                        while (bRs.next()) {
                                %>
                                <option value="<%= bRs.getInt("PATIENT_ID") %>"><%= SecurityUtil.escapeHtml(bRs.getString("PATIENT_NAME")) %> (#<%= bRs.getInt("PATIENT_ID") %> - <%= bRs.getString("PHONE") %>)</option>
                                <%
                                        }
                                    } catch (Exception ignored) {
                                    } finally {
                                        DBConnection.close(bRs, bStmt, bConn);
                                    }
                                %>
                            </select>
                        </div>
                        <div class="form-group" style="flex: 1;">
                            <label class="form-label">Appointment Ref (Optional)</label>
                            <input type="number" name="appointmentId" class="form-control" placeholder="e.g. 5001">
                        </div>
                    </div>

                    <!-- Bill Items List -->
                    <div class="form-group">
                        <div class="flex-between" style="margin-bottom: 8px;">
                            <label class="form-label" style="margin: 0;">Itemized Charges &amp; Services <span class="required">*</span></label>
                            <button type="button" class="btn btn-outline btn-sm" onclick="addBillItemRow()">+ Add Service / Item</button>
                        </div>

                        <div id="billItemsContainer">
                            <div class="bill-item-row form-row">
                                <div style="flex: 3;">
                                    <input type="text" name="itemDescription" class="form-control" placeholder="Service (e.g. General OPD Consultation)" required>
                                </div>
                                <div style="flex: 1;">
                                    <input type="number" name="itemQuantity" class="form-control item-qty" value="1" min="1" onchange="recalculateBillTotals()" required>
                                </div>
                                <div style="flex: 1.5;">
                                    <input type="number" step="0.01" name="itemUnitPrice" class="form-control item-price" placeholder="Fee" value="500.00" min="0" onchange="recalculateBillTotals()" required>
                                </div>
                                <div style="flex: 1.5;">
                                    <input type="number" step="0.01" name="itemLineTotal" class="form-control item-total" value="500.00" readonly>
                                </div>
                                <div style="flex: 0.5; display:flex; align-items:center;">
                                    <button type="button" class="btn-remove-row" onclick="removeBillItemRow(this)">&times;</button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Payment & Totals -->
                    <div style="background: #f8fafc; border: 1px solid var(--border-color); border-radius: var(--radius-sm); padding: 16px; margin-top: 14px;">
                        <div class="flex-between" style="font-size: 16px; font-weight: 700; margin-bottom: 12px;">
                            <span>Calculated Grand Total:</span>
                            <span id="grandTotalDisplay" style="color: var(--secondary); font-size: 1.25rem;">&#8377; 500.00</span>
                        </div>

                        <div class="form-row">
                            <div class="form-group" style="margin-bottom: 0;">
                                <label class="form-label">Initial Amount Paid (&#8377;)</label>
                                <input type="number" step="0.01" id="paidAmountInput" name="paidAmount" class="form-control" value="0.00" min="0" onchange="updateBalanceCalculation()">
                            </div>
                            <div class="form-group" style="margin-bottom: 0;">
                                <label class="form-label">Payment Method</label>
                                <select name="paymentMethod" class="form-control">
                                    <option value="Cash">Cash</option>
                                    <option value="UPI / NetBanking">UPI / NetBanking</option>
                                    <option value="Credit Card">Credit Card</option>
                                    <option value="Debit Card">Debit Card</option>
                                    <option value="Insurance">Insurance TPA</option>
                                </select>
                            </div>
                            <div class="form-group" style="margin-bottom: 0;">
                                <label class="form-label">Reference / Receipt #</label>
                                <input type="text" name="paymentReference" class="form-control" placeholder="e.g. TXN-10294">
                            </div>
                        </div>

                        <div class="flex-between" style="font-size: 14px; margin-top: 12px; padding-top: 10px; border-top: 1px dashed var(--border-color);">
                            <span>Remaining Outstanding Balance:</span>
                            <span id="balanceDisplay" style="font-weight: 700; color: var(--danger);">&#8377; 500.00</span>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline" onclick="closeModal('newBillModal')">Cancel</button>
                    <button type="submit" class="btn btn-primary">Generate Bill &amp; Save</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Modal: Record Payment on Existing Bill -->
    <div id="paymentModal" class="modal-overlay">
        <div class="modal-card">
            <div class="modal-header">
                <h3 class="card-title">Record Payment for Bill #<span id="payDisplayBillId"></span></h3>
                <button type="button" class="btn-remove-row" onclick="closeModal('paymentModal')">&times;</button>
            </div>
            <form action="recordPayment.jsp" method="POST">
                <div class="modal-body">
                    <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                    <input type="hidden" id="payBillId" name="billId" value="">

                    <div style="background: var(--warning-light); border: 1px solid #fde68a; padding: 12px; border-radius: var(--radius-sm); margin-bottom: 16px; font-size: 13.5px;">
                        Patient: <strong id="payPatientName"></strong><br>
                        Current Outstanding Balance: <strong id="payBalanceAmount" style="color: #92400e;"></strong>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Payment Amount (&#8377;) <span class="required">*</span></label>
                        <input type="number" step="0.01" id="payAmountInput" name="amount" class="form-control" min="1" required>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Payment Mode <span class="required">*</span></label>
                        <select name="paymentMethod" class="form-control" required>
                            <option value="Cash">Cash</option>
                            <option value="UPI / NetBanking">UPI / NetBanking</option>
                            <option value="Credit Card">Credit Card</option>
                            <option value="Debit Card">Debit Card</option>
                            <option value="Insurance">Insurance TPA</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Transaction / Bank Reference No</label>
                        <input type="text" name="paymentReference" class="form-control" placeholder="e.g. UPI-98421, CASH-REC-01">
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline" onclick="closeModal('paymentModal')">Cancel</button>
                    <button type="submit" class="btn btn-success">&#10003; Record Payment</button>
                </div>
            </form>
        </div>
    </div>

    <jsp:include page="includes/footer.jsp" />

    <script>
        function openPaymentModal(billId, patientName, balance) {
            document.getElementById('payDisplayBillId').textContent = billId;
            document.getElementById('payBillId').value = billId;
            document.getElementById('payPatientName').textContent = patientName;
            document.getElementById('payBalanceAmount').textContent = "₹ " + balance.toFixed(2);
            var payInput = document.getElementById('payAmountInput');
            payInput.value = balance.toFixed(2);
            payInput.max = balance.toFixed(2);
            openModal('paymentModal');
        }

        window.addEventListener("DOMContentLoaded", function() {
            recalculateBillTotals();
        });
    </script>
</body>
</html>
