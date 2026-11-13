/**
 * Hospital Management System (HMS) - Appointment Booking Logic
 */

// Handle Department Filter to show only relevant Doctors
function onDepartmentChange() {
    var deptSelect = document.getElementById("departmentSelect");
    var docSelect = document.getElementById("doctorSelect");
    if (!deptSelect || !docSelect) return;

    var selectedDept = deptSelect.value;
    var options = docSelect.querySelectorAll("option");

    docSelect.value = "";
    resetDoctorDetails();

    options.forEach(function(opt) {
        if (!opt.value) return; // skip default placeholder
        var optDept = opt.getAttribute("data-department-id");
        if (!selectedDept || optDept === selectedDept) {
            opt.style.display = "";
        } else {
            opt.style.display = "none";
        }
    });
}

// Handle Doctor selection to show consultation fee and room
function onDoctorChange() {
    var docSelect = document.getElementById("doctorSelect");
    if (!docSelect) return;

    var selectedOpt = docSelect.options[docSelect.selectedIndex];
    var feeDisplay = document.getElementById("doctorFeeDisplay");
    var specDisplay = document.getElementById("doctorSpecDisplay");
    var summaryDoc = document.getElementById("summaryDoctor");
    var summaryFee = document.getElementById("summaryFee");

    if (selectedOpt && selectedOpt.value) {
        var fee = selectedOpt.getAttribute("data-fee") || "0.00";
        var spec = selectedOpt.getAttribute("data-spec") || "";
        var name = selectedOpt.text;

        if (feeDisplay) feeDisplay.textContent = "₹ " + fee;
        if (specDisplay) specDisplay.textContent = spec;
        if (summaryDoc) summaryDoc.textContent = name;
        if (summaryFee) summaryFee.textContent = "₹ " + fee;
    } else {
        resetDoctorDetails();
    }
    renderTimeSlots();
}

function resetDoctorDetails() {
    var feeDisplay = document.getElementById("doctorFeeDisplay");
    var specDisplay = document.getElementById("doctorSpecDisplay");
    var summaryDoc = document.getElementById("summaryDoctor");
    var summaryFee = document.getElementById("summaryFee");

    if (feeDisplay) feeDisplay.textContent = "--";
    if (specDisplay) specDisplay.textContent = "--";
    if (summaryDoc) summaryDoc.textContent = "Not selected";
    if (summaryFee) summaryFee.textContent = "₹ 0.00";
}

// Handle Date selection to update summary and slots
function onDateChange() {
    var dateInput = document.getElementById("appointmentDate");
    var summaryDate = document.getElementById("summaryDate");
    if (dateInput && summaryDate) {
        summaryDate.textContent = dateInput.value || "Not selected";
    }
    renderTimeSlots();
}

// Render Available Time Slots based on standard slots (09:00 - 17:00)
function renderTimeSlots() {
    var container = document.getElementById("timeSlotsContainer");
    var hiddenTimeInput = document.getElementById("appointmentTime");
    var summaryTime = document.getElementById("summaryTime");
    if (!container) return;

    container.innerHTML = "";
    if (hiddenTimeInput) hiddenTimeInput.value = "";
    if (summaryTime) summaryTime.textContent = "Not selected";

    var defaultSlots = [
        "09:00", "09:30", "10:00", "10:30", "11:00", "11:30",
        "12:00", "12:30", "14:00", "14:30", "15:00", "15:30",
        "16:00", "16:30", "17:00"
    ];

    defaultSlots.forEach(function(slot) {
        var btn = document.createElement("button");
        btn.type = "button";
        btn.className = "slot-btn";
        btn.textContent = slot;
        btn.onclick = function() {
            var allBtns = container.querySelectorAll(".slot-btn");
            allBtns.forEach(function(b) { b.classList.remove("selected"); });
            btn.classList.add("selected");
            if (hiddenTimeInput) hiddenTimeInput.value = slot;
            if (summaryTime) summaryTime.textContent = slot;
        };
        container.appendChild(btn);
    });
}

// Validate complete booking form before submission
function validateBookingForm() {
    var doctor = document.getElementById("doctorSelect") ? document.getElementById("doctorSelect").value : "";
    var date = document.getElementById("appointmentDate") ? document.getElementById("appointmentDate").value : "";
    var time = document.getElementById("appointmentTime") ? document.getElementById("appointmentTime").value : "";

    if (!doctor) {
        alert("Please select a doctor.");
        return false;
    }
    if (!date) {
        alert("Please select an appointment date.");
        return false;
    }

    // Verify date is not in the past
    var selectedDate = new Date(date);
    var today = new Date();
    today.setHours(0, 0, 0, 0);
    if (selectedDate < today) {
        alert("Cannot book an appointment for a past date. Please select today or a future date.");
        return false;
    }

    if (!time) {
        alert("Please choose a time slot for the appointment.");
        return false;
    }

    return true;
}
