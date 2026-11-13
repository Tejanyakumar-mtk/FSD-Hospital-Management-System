package com.hospital.util;

import java.security.SecureRandom;
import java.util.UUID;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

/**
 * Security and sanitization utility for XSS prevention, CSRF verification, and session authentication checks.
 */
public class SecurityUtil {

    public static final String CSRF_SESSION_ATTR = "HMS_CSRF_TOKEN";
    public static final String USER_SESSION_ATTR = "LOGGED_IN_USER";

    /**
     * Escapes HTML special characters to prevent Cross-Site Scripting (XSS).
     */
    public static String escapeHtml(String input) {
        if (input == null) return "";
        StringBuilder sb = new StringBuilder(input.length());
        for (char c : input.toCharArray()) {
            switch (c) {
                case '<': sb.append("&lt;"); break;
                case '>': sb.append("&gt;"); break;
                case '&': sb.append("&amp;"); break;
                case '"': sb.append("&quot;"); break;
                case '\'': sb.append("&#x27;"); break;
                case '/': sb.append("&#x2F;"); break;
                default: sb.append(c);
            }
        }
        return sb.toString();
    }

    /**
     * Sanitizes input string by trimming whitespace. Returns empty string if null.
     */
    public static String sanitize(String input) {
        return (input == null) ? "" : input.trim();
    }

    /**
     * Generates or retrieves an existing CSRF token for the session.
     */
    public static String getCsrfToken(HttpSession session) {
        if (session == null) return "";
        String token = (String) session.getAttribute(CSRF_SESSION_ATTR);
        if (token == null) {
            token = UUID.randomUUID().toString();
            session.setAttribute(CSRF_SESSION_ATTR, token);
        }
        return token;
    }

    /**
     * Validates whether the CSRF token submitted in the request matches the session token.
     */
    public static boolean verifyCsrfToken(HttpServletRequest request) {
        if (request == null) return false;
        HttpSession session = request.getSession(false);
        if (session == null) return false;
        String sessionToken = (String) session.getAttribute(CSRF_SESSION_ATTR);
        String requestToken = request.getParameter("csrfToken");
        return sessionToken != null && sessionToken.equals(requestToken);
    }

    /**
     * Checks if a user is logged in.
     */
    public static boolean isLoggedIn(HttpSession session) {
        return session != null && session.getAttribute("userId") != null;
    }

    /**
     * Checks if the logged-in user has one of the allowed roles.
     */
    public static boolean hasRole(HttpSession session, String... allowedRoles) {
        if (!isLoggedIn(session) || allowedRoles == null) return false;
        String userRole = (String) session.getAttribute("userRole");
        if (userRole == null) return false;
        for (String role : allowedRoles) {
            if (userRole.equalsIgnoreCase(role)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Parses an integer safely, returning a default value on error.
     */
    public static int parseInt(String val, int defaultValue) {
        if (val == null) return defaultValue;
        try {
            return Integer.parseInt(val.trim());
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }

    /**
     * Parses a double safely, returning a default value on error.
     */
    public static double parseDouble(String val, double defaultValue) {
        if (val == null) return defaultValue;
        try {
            return Double.parseDouble(val.trim());
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }
}
