<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.hospital.util.DBConnection, com.hospital.util.SecurityUtil" %>
<%
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect("billing.jsp");
        return;
    }

    if (!SecurityUtil.verifyCsrfToken(request)) {
        response.sendRedirect("billing.jsp?error=Security+validation+failed.");
        return;
    }

    String sessionRole = (String) session.getAttribute("userRole");
    String sessionUserId = (String) session.getAttribute("userId");
    if (!"ADMIN".equalsIgnoreCase(sessionRole) && !"RECEPTIONIST".equalsIgnoreCase(sessionRole)) {
        response.sendRedirect("login.jsp?error=Unauthorized.");
        return;
    }

    int billId = SecurityUtil.parseInt(request.getParameter("billId"), 0);
    double amount = SecurityUtil.parseDouble(request.getParameter("amount"), 0.00);
    String paymentMethod = SecurityUtil.sanitize(request.getParameter("paymentMethod"));
    String paymentReference = SecurityUtil.sanitize(request.getParameter("paymentReference"));

    if (billId <= 0 || amount <= 0) {
        response.sendRedirect("billing.jsp?error=Please+enter+a+valid+payment+amount+greater+than+zero.");
        return;
    }

    Connection conn = null;
    PreparedStatement lockStmt = null;
    PreparedStatement payStmt = null;
    PreparedStatement updateBillStmt = null;
    PreparedStatement auditStmt = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        conn.setAutoCommit(false); // Begin Transaction

        // Lock & fetch current bill amounts
        lockStmt = conn.prepareStatement("SELECT TOTAL_AMOUNT, PAID_AMOUNT, BALANCE_AMOUNT, STATUS FROM BILLS WHERE BILL_ID = ?");
        lockStmt.setInt(1, billId);
        rs = lockStmt.executeQuery();

        if (!rs.next()) {
            conn.rollback();
            response.sendRedirect("billing.jsp?error=Bill+not+found.");
            return;
        }

        double totalAmount = rs.getDouble("TOTAL_AMOUNT");
        double currentPaid = rs.getDouble("PAID_AMOUNT");
        double currentBalance = rs.getDouble("BALANCE_AMOUNT");
        String currentStatus = rs.getString("STATUS");

        if ("PAID".equalsIgnoreCase(currentStatus) || currentBalance <= 0) {
            conn.rollback();
            response.sendRedirect("billing.jsp?error=This+bill+is+already+fully+settled.");
            return;
        }

        if (amount > currentBalance) {
            conn.rollback();
            response.sendRedirect("billing.jsp?error=Payment+amount+cannot+exceed+the+outstanding+balance+of+INR+" + String.format("%.2f", currentBalance) + ".");
            return;
        }
        DBConnection.close(rs, lockStmt);

        // Insert into PAYMENTS
        String insertPay = "INSERT INTO PAYMENTS (PAYMENT_ID, BILL_ID, AMOUNT, PAYMENT_DATE, PAYMENT_METHOD, PAYMENT_REFERENCE, STATUS) " +
                           "VALUES (SEQ_PAYMENTS.NEXTVAL, ?, ?, CURRENT_TIMESTAMP, ?, ?, 'SUCCESS')";
        payStmt = conn.prepareStatement(insertPay);
        payStmt.setInt(1, billId);
        payStmt.setDouble(2, amount);
        payStmt.setString(3, paymentMethod.isEmpty() ? "Cash" : paymentMethod);
        payStmt.setString(4, paymentReference.isEmpty() ? null : paymentReference);
        payStmt.executeUpdate();

        // Update BILLS
        double newPaid = currentPaid + amount;
        double newBalance = Math.max(0.00, totalAmount - newPaid);
        String newStatus = (newBalance == 0) ? "PAID" : "PARTIAL";

        updateBillStmt = conn.prepareStatement(
            "UPDATE BILLS SET PAID_AMOUNT = ?, BALANCE_AMOUNT = ?, STATUS = ? WHERE BILL_ID = ?"
        );
        updateBillStmt.setDouble(1, newPaid);
        updateBillStmt.setDouble(2, newBalance);
        updateBillStmt.setString(3, newStatus);
        updateBillStmt.setInt(4, billId);
        updateBillStmt.executeUpdate();

        // Audit Log
        auditStmt = conn.prepareStatement(
            "INSERT INTO AUDIT_LOG (USER_ID, ACTION, ENTITY_TYPE, ENTITY_ID, DETAILS) VALUES (?, ?, ?, ?, ?)"
        );
        auditStmt.setInt(1, Integer.parseInt(sessionUserId));
        auditStmt.setString(2, "RECORD_PAYMENT");
        auditStmt.setString(3, "BILLS");
        auditStmt.setInt(4, billId);
        auditStmt.setString(5, "Payment of INR " + String.format("%.2f", amount) + " recorded via " + paymentMethod);
        auditStmt.executeUpdate();

        conn.commit();
        response.sendRedirect("billing.jsp?msg=Payment+of+INR+" + String.format("%.2f", amount) + "+recorded+successfully+for+Bill+%23" + billId + ".");

    } catch (Exception e) {
        if (conn != null) {
            try { conn.rollback(); } catch (SQLException ignored) {}
        }
        System.err.println("[recordPayment] Error: " + e.getMessage());
        response.sendRedirect("billing.jsp?error=System+error+recording+payment.");
    } finally {
        DBConnection.close(rs, lockStmt, payStmt, updateBillStmt, auditStmt, conn);
    }
%>
