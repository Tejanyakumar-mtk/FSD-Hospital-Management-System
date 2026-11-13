/**
 * Hospital Management System (HMS) - Dashboard & Table Management
 */

// Filter table rows by search keyword
function filterTable(inputId, tableId) {
    var input = document.getElementById(inputId);
    var filter = input.value.toLowerCase();
    var table = document.getElementById(tableId);
    if (!table) return;
    var rows = table.getElementsByTagName("tr");

    // Skip the header row (i = 1)
    for (var i = 1; i < rows.length; i++) {
        var rowText = rows[i].textContent || rows[i].innerText;
        if (rowText.toLowerCase().indexOf(filter) > -1) {
            rows[i].style.display = "";
        } else {
            rows[i].style.display = "none";
        }
    }
}

// Modal management
function openModal(modalId) {
    var modal = document.getElementById(modalId);
    if (modal) modal.classList.add("active");
}

function closeModal(modalId) {
    var modal = document.getElementById(modalId);
    if (modal) modal.classList.remove("active");
}

// Prescription Medicine Row Builder
function addMedicineRow() {
    var container = document.getElementById("medicineContainer");
    if (!container) return;

    var row = document.createElement("div");
    row.className = "medicine-row";
    row.innerHTML = `
        <input type="text" name="medicineName" class="form-control" placeholder="Medicine Name" required>
        <input type="text" name="dosage" class="form-control" placeholder="e.g. 500mg" required>
        <input type="text" name="duration" class="form-control" placeholder="e.g. 5 days" required>
        <input type="text" name="instructions" class="form-control" placeholder="e.g. 1 tab after food twice daily">
        <button type="button" class="btn-remove-row" onclick="removeMedicineRow(this)" title="Remove">&times;</button>
    `;
    container.appendChild(row);
}

function removeMedicineRow(button) {
    var container = document.getElementById("medicineContainer");
    var rows = container.getElementsByClassName("medicine-row");
    if (rows.length > 1) {
        button.closest(".medicine-row").remove();
    } else {
        alert("At least one medicine item must be included in the prescription.");
    }
}

// Bill Item Row Builder & Calculations
function addBillItemRow() {
    var container = document.getElementById("billItemsContainer");
    if (!container) return;

    var row = document.createElement("div");
    row.className = "bill-item-row form-row";
    row.innerHTML = `
        <div style="flex: 3;">
            <input type="text" name="itemDescription" class="form-control" placeholder="Item / Service Description" required>
        </div>
        <div style="flex: 1;">
            <input type="number" name="itemQuantity" class="form-control item-qty" value="1" min="1" onchange="recalculateBillTotals()" required>
        </div>
        <div style="flex: 1.5;">
            <input type="number" step="0.01" name="itemUnitPrice" class="form-control item-price" value="0.00" min="0" onchange="recalculateBillTotals()" required>
        </div>
        <div style="flex: 1.5;">
            <input type="number" step="0.01" name="itemLineTotal" class="form-control item-total" value="0.00" readonly>
        </div>
        <div style="flex: 0.5; display:flex; align-items:center;">
            <button type="button" class="btn-remove-row" onclick="removeBillItemRow(this)">&times;</button>
        </div>
    `;
    container.appendChild(row);
    recalculateBillTotals();
}

function removeBillItemRow(btn) {
    var container = document.getElementById("billItemsContainer");
    var rows = container.getElementsByClassName("bill-item-row");
    if (rows.length > 1) {
        btn.closest(".bill-item-row").remove();
        recalculateBillTotals();
    } else {
        alert("A bill must contain at least one item.");
    }
}

function recalculateBillTotals() {
    var rows = document.querySelectorAll(".bill-item-row");
    var grandTotal = 0;

    rows.forEach(function(row) {
        var qtyInput = row.querySelector(".item-qty");
        var priceInput = row.querySelector(".item-price");
        var totalInput = row.querySelector(".item-total");

        var qty = parseFloat(qtyInput ? qtyInput.value : 1) || 0;
        var price = parseFloat(priceInput ? priceInput.value : 0) || 0;
        var lineTotal = (qty * price);

        if (totalInput) totalInput.value = lineTotal.toFixed(2);
        grandTotal += lineTotal;
    });

    var grandTotalInput = document.getElementById("grandTotalDisplay");
    var totalAmountHidden = document.getElementById("totalAmountInput");
    if (grandTotalInput) grandTotalInput.textContent = "₹ " + grandTotal.toFixed(2);
    if (totalAmountHidden) totalAmountHidden.value = grandTotal.toFixed(2);

    updateBalanceCalculation();
}

function updateBalanceCalculation() {
    var totalAmount = parseFloat(document.getElementById("totalAmountInput") ? document.getElementById("totalAmountInput").value : 0) || 0;
    var paidAmount = parseFloat(document.getElementById("paidAmountInput") ? document.getElementById("paidAmountInput").value : 0) || 0;

    var balance = Math.max(0, totalAmount - paidAmount);
    var balanceDisplay = document.getElementById("balanceDisplay");
    if (balanceDisplay) {
        balanceDisplay.textContent = "₹ " + balance.toFixed(2);
    }
}
