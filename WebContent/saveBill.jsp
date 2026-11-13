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

    int patientId = SecurityUtil.parseInt(request.getParameter("patientId"), 0);
    int appointmentId = SecurityUtil.parseInt(request.getParameter("appointmentId"), 0);
    double initialPaid = SecurityUtil.parseDouble(request.getParameter("paidAmount"), 0.00);
    String paymentMethod = SecurityUtil.sanitize(request.getParameter("paymentMethod"));
    String paymentReference = SecurityUtil.sanitize(request.getParameter("paymentReference"));

    String[] descriptions = request.getParameterValues("itemDescription");
    String[] quantities = request.getParameterValues("itemQuantity");
    String[] unitPrices = request.getParameterValues("itemUnitPrice");

    if (patientId <= 0 || descriptions == null || descriptions.length == 0) {
        response.sendRedirect("billing.jsp?error=Please+select+a+patient+and+add+at+least+one+billing+item.");
        return;
    }

    // Server-side precise line calculation
    double calculatedTotal = 0.00;
    for (int i = 0; i < descriptions.length; i++) {
        String desc = SecurityUtil.sanitize(descriptions[i]);
        if (desc.isEmpty()) continue;
        int qty = (quantities != null && quantities.length > i) ? SecurityUtil.parseInt(quantities[i], 1) : 1;
        double price = (unitPrices != null && unitPrices.length > i) ? SecurityUtil.parseDouble(unitPrices[i], 0.00) : 0.00;
        calculatedTotal += (qty * price);
    }

    if (calculatedTotal <= 0) {
        response.sendRedirect("billing.jsp?error=Total+bill+amount+must+be+greater+than+zero.");
        return;
    }

    if (initialPaid < 0 || initialPaid > calculatedTotal) {
        response.sendRedirect("billing.jsp?error=Paid+amount+cannot+exceed+total+bill+amount.");
        return;
    }

    double balance = calculatedTotal - initialPaid;
    String status = (balance == 0) ? "PAID" : (initialPaid > 0 ? "PARTIAL" : "PENDING");

    Connection conn = null;
    PreparedStatement seqStmt = null;
    PreparedStatement billStmt = null;
    PreparedStatement itemStmt = null;
    PreparedStatement payStmt = null;
    PreparedStatement auditStmt = null;
    ResultSet rs = null;

    int newBillId = 0;

    try {
        conn = DBConnection.getConnection();
        conn.setAutoCommit(false); // Begin Transaction

        // Get next Bill ID
        seqStmt = conn.prepareStatement("SELECT SEQ_BILLS.NEXTVAL FROM DUAL");
        rs = seqStmt.executeQuery();
        if (rs.next()) newBillId = rs.getInt(1);
        DBConnection.close(rs, seqStmt);

        // Insert into BILLS
        String insertBill = "INSERT INTO BILLS (BILL_ID, PATIENT_ID, APPOINTMENT_ID, TOTAL_AMOUNT, PAID_AMOUNT, BALANCE_AMOUNT, STATUS, CREATED_AT) " +
                            "VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)";
        billStmt = conn.prepareStatement(insertBill);
        billStmt.setInt(1, newBillId);
        billStmt.setInt(2, patientId);
        if (appointmentId > 0) {
            billStmt.setInt(3, appointmentId);
        } else {
            billStmt.setNull(3, Types.INTEGER);
        }
        billStmt.setDouble(4, calculatedTotal);
        billStmt.setDouble(5, initialPaid);
        billStmt.setDouble(6, balance);
        billStmt.setString(7, status);
        billStmt.executeUpdate();

        // Insert Bill Items
        String insertItem = "INSERT INTO BILL_ITEMS (ITEM_ID, BILL_ID, DESCRIPTION, QUANTITY, UNIT_PRICE, LINE_TOTAL) " +
                            "VALUES (SEQ_BILL_ITEMS.NEXTVAL, ?, ?, ?, ?, ?)";
        itemStmt = conn.prepareStatement(insertItem);

        for (int i = 0; i < descriptions.length; i++) {
            String desc = SecurityUtil.sanitize(descriptions[i]);
            if (desc.isEmpty()) continue;
            int qty = (quantities != null && quantities.length > i) ? SecurityUtil.parseInt(quantities[i], 1) : 1;
            double price = (unitPrices != null && unitPrices.length > i) ? SecurityUtil.parseDouble(unitPrices[i], 0.00) : 0.00;
            double lineTotal = qty * price;

            itemStmt.setInt(1, newBillId);
            itemStmt.setString(2, desc);
            itemStmt.setInt(3, qty);
            itemStmt.setDouble(4, price);
            itemStmt.setDouble(5, lineTotal);
            itemStmt.executeUpdate();
        }

        // Insert initial payment if paid > 0
        if (initialPaid > 0) {
            String insertPay = "INSERT INTO PAYMENTS (PAYMENT_ID, BILL_ID, AMOUNT, PAYMENT_DATE, PAYMENT_METHOD, PAYMENT_REFERENCE, STATUS) " +
                               "VALUES (SEQ_PAYMENTS.NEXTVAL, ?, ?, CURRENT_TIMESTAMP, ?, ?, 'SUCCESS')";
            payStmt = conn.prepareStatement(insertPay);
            payStmt.setInt(1, newBillId);
            payStmt.setDouble(2, initialPaid);
            payStmt.setString(3, paymentMethod.isEmpty() ? "Cash" : paymentMethod);
            payStmt.setString(4, paymentReference.isEmpty() ? null : paymentReference);
            payStmt.executeUpdate();
        }

        // Audit Log
        auditStmt = conn.prepareStatement(
            "INSERT INTO AUDIT_LOG (USER_ID, ACTION, ENTITY_TYPE, ENTITY_ID, DETAILS) VALUES (?, ?, ?, ?, ?)"
        );
        auditStmt.setInt(1, Integer.parseInt(sessionUserId));
        auditStmt.setString(2, "CREATE_BILL");
        auditStmt.setString(3, "BILLS");
        auditStmt.setInt(4, newBillId);
        auditStmt.setString(5, "Bill #" + newBillId + " generated for amount INR " + String.format("%.2f", calculatedTotal));
        auditStmt.executeUpdate();

        conn.commit();
        response.sendRedirect("billing.jsp?msg=Bill+%23" + newBillId + "+generated+successfully+for+INR+" + String.format("%.2f", calculatedTotal) + ".");

    } catch (Exception e) {
        if (conn != null) {
            try { conn.rollback(); } catch (SQLException ignored) {}
        }
        System.err.println("[saveBill] Error: " + e.getMessage());
        response.sendRedirect("billing.jsp?error=System+error+while+generating+bill.");
    } finally {
        DBConnection.close(rs, seqStmt, billStmt, itemStmt, payStmt, auditStmt, conn);
    }
%>
