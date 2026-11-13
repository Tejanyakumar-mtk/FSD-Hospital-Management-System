/**
 * Hospital Management System (HMS) - Validation & UI Utilities
 */

// Toggle password visibility
function togglePasswordVisibility(inputId, btnId) {
    var input = document.getElementById(inputId);
    var btn = document.getElementById(btnId);
    if (!input) return;
    if (input.type === "password") {
        input.type = "text";
        if (btn) btn.textContent = "Hide";
    } else {
        input.type = "password";
        if (btn) btn.textContent = "Show";
    }
}

// Validate registration form before submission
function validateRegistrationForm() {
    var form = document.forms["regForm"] || document.querySelector("form.needs-validation");
    if (!form) return true;

    var fullName = form["fullName"] ? form["fullName"].value.trim() : "";
    var dob = form["dob"] ? form["dob"].value.trim() : "";
    var gender = form["gender"] ? form["gender"].value : "";
    var phone = form["phone"] ? form["phone"].value.trim() : "";
    var email = form["email"] ? form["email"].value.trim() : "";
    var username = form["username"] ? form["username"].value.trim() : "";
    var password = form["password"] ? form["password"].value : "";
    var confirmPassword = form["confirmPassword"] ? form["confirmPassword"].value : "";

    if (!fullName) {
        alert("Please enter your full name.");
        return false;
    }
    if (!dob) {
        alert("Please select your date of birth.");
        return false;
    }
    if (!gender) {
        alert("Please select your gender.");
        return false;
    }
    // Phone validation: 10 digits
    var phonePattern = /^[0-9]{10}$/;
    if (!phonePattern.test(phone)) {
        alert("Please enter a valid 10-digit mobile number.");
        return false;
    }
    // Email validation
    var emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailPattern.test(email)) {
        alert("Please enter a valid email address.");
        return false;
    }
    if (username.length < 3) {
        alert("Username must be at least 3 characters long.");
        return false;
    }
    if (password.length < 6) {
        alert("Password must be at least 6 characters long.");
        return false;
    }
    if (password !== confirmPassword) {
        alert("Passwords do not match. Please re-enter.");
        return false;
    }
    return true;
}

// Validate login form
function validateLoginForm() {
    var form = document.forms["loginForm"] || document.querySelector("form.login-form");
    if (!form) return true;

    var username = form["username"] ? form["username"].value.trim() : "";
    var password = form["password"] ? form["password"].value : "";

    if (!username) {
        alert("Please enter your username.");
        return false;
    }
    if (!password) {
        alert("Please enter your password.");
        return false;
    }
    return true;
}
