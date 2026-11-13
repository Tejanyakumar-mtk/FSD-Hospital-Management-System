<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>About Us - CityHealth Hospital Management System</title>
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/public.css">
</head>
<body>

    <jsp:include page="includes/navbar.jsp" />

    <section class="hero" style="padding: 50px 0;">
        <div class="container">
            <span class="hero-badge">About Our Institution</span>
            <h1>Dedicated to Healing, Committed to Care</h1>
            <p style="max-width: 650px;">CityHealth Hospital has been providing cutting-edge clinical services, multi-specialty diagnostics, and compassionate patient care with uncompromising medical standards.</p>
        </div>
    </section>

    <div class="container" style="padding: 60px 20px;">
        <div class="grid grid-2" style="align-items: center; margin-bottom: 50px;">
            <div>
                <span class="section-tag">Our Vision &amp; Mission</span>
                <h2>Transforming Healthcare Through Innovation</h2>
                <p style="margin-bottom: 16px; color: var(--text-secondary);">
                    Founded with a vision to provide accessible, ethical, and high-quality healthcare, CityHealth operates as a full-service referral and tertiary care hospital. We integrate clinical expertise, compassionate nursing care, and modern healthcare management information systems.
                </p>
                <p style="color: var(--text-secondary);">
                    Our Hospital Management System (HMS) streamlines every step of patient care—from online appointments and electronic health records to laboratory investigations and billing transparency.
                </p>
            </div>
            <div class="card" style="background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%); padding: 36px;">
                <h3 style="color: var(--secondary); margin-bottom: 16px;">Key Highlights</h3>
                <ul style="line-height: 2.2; color: var(--text-primary); font-size: 14.5px;">
                    <li>&#10003; <strong>250+ Bedded</strong> Tertiary Multi-Specialty Facility</li>
                    <li>&#10003; <strong>NABH &amp; NABL</strong> Accredited Clinical Laboratories</li>
                    <li>&#10003; <strong>Round-the-clock</strong> Trauma Care &amp; Intensive Care Units (ICU)</li>
                    <li>&#10003; <strong>Full Digital EHR</strong> with instant prescription and billing records</li>
                    <li>&#10003; Over <strong>50,000+</strong> successfully treated patients</li>
                </ul>
            </div>
        </div>

        <div class="section-header" style="margin-top: 40px;">
            <span class="section-tag">Core Principles</span>
            <h2>Our Guiding Healthcare Values</h2>
        </div>

        <div class="grid grid-3">
            <div class="card">
                <div class="feature-icon" style="background: var(--primary-light); color: var(--primary);">&#9829;</div>
                <h3 style="text-align: center;">Patient-Centric Care</h3>
                <p style="text-align: center; color: var(--text-secondary); font-size: 14px;">Every decision, clinical pathway, and administrative process is designed to ensure patient comfort, dignity, and recovery.</p>
            </div>
            <div class="card">
                <div class="feature-icon" style="background: var(--success-light); color: var(--success);">&#9733;</div>
                <h3 style="text-align: center;">Clinical Integrity</h3>
                <p style="text-align: center; color: var(--text-secondary); font-size: 14px;">Unwavering adherence to evidence-based medical practices, transparent treatment plans, and zero unnecessary interventions.</p>
            </div>
            <div class="card">
                <div class="feature-icon" style="background: var(--warning-light); color: var(--warning);">&#9881;</div>
                <h3 style="text-align: center;">Continuous Modernization</h3>
                <p style="text-align: center; color: var(--text-secondary); font-size: 14px;">Investing in advanced medical equipment, digital records, and continuous professional training for all clinical staff.</p>
            </div>
        </div>
    </div>

    <jsp:include page="includes/footer.jsp" />

</body>
</html>
