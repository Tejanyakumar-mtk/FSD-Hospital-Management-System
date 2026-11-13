/**
 * Hospital Management System (HMS) - Patient Portal Interactions
 */

// Filter appointment rows by status in the table
function filterAppointments(status) {
    var rows = document.querySelectorAll("#appointmentTable tbody tr");
    var tabs = document.querySelectorAll(".filter-btn");

    tabs.forEach(function(btn) { btn.classList.remove("active"); });
    if (event && event.target) {
        event.target.classList.add("active");
    }

    rows.forEach(function(row) {
        var rowStatus = row.getAttribute("data-status");
        if (status === "ALL" || rowStatus === status) {
            row.style.display = "";
        } else {
            row.style.display = "none";
        }
    });
}

// Confirm cancellation
function confirmCancelAppointment(appointmentId) {
    return confirm("Are you sure you want to cancel Appointment #" + appointmentId + "? This action cannot be undone.");
}
