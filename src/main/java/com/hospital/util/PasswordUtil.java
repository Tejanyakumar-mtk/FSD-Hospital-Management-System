package com.hospital.util;

import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.KeySpec;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

/**
 * Utility class for secure password hashing and verification using PBKDF2 with HMAC SHA-256.
 * Salt is stored alongside the hash to prevent rainbow table attacks.
 */
public class PasswordUtil {

    private static final String ALGORITHM = "PBKDF2WithHmacSHA256";
    private static final int ITERATION_COUNT = 65536;
    private static final int KEY_LENGTH = 256; // bits
    private static final int SALT_LENGTH = 16;  // bytes

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    /**
     * Generates a cryptographically secure random salt in hexadecimal format.
     */
    public static String generateSalt() {
        byte[] salt = new byte[SALT_LENGTH];
        SECURE_RANDOM.nextBytes(salt);
        return bytesToHex(salt);
    }

    /**
     * Hashes the given plain-text password using the provided salt and PBKDF2WithHmacSHA256.
     */
    public static String hashPassword(String password, String saltHex) {
        if (password == null || saltHex == null) {
            throw new IllegalArgumentException("Password and salt must not be null");
        }
        try {
            byte[] salt = hexToBytes(saltHex);
            KeySpec spec = new PBEKeySpec(password.toCharArray(), salt, ITERATION_COUNT, KEY_LENGTH);
            SecretKeyFactory factory = SecretKeyFactory.getInstance(ALGORITHM);
            byte[] hash = factory.generateSecret(spec).getEncoded();
            return bytesToHex(hash);
        } catch (NoSuchAlgorithmException | InvalidKeySpecException e) {
            throw new RuntimeException("Error hashing password", e);
        }
    }

    /**
     * Verifies whether the provided plain-text password matches the stored hash given the salt.
     */
    public static boolean verifyPassword(String password, String saltHex, String storedHash) {
        if (password == null || saltHex == null || storedHash == null) {
            return false;
        }
        String calculatedHash = hashPassword(password, saltHex);
        return slowEquals(calculatedHash, storedHash);
    }

    /**
     * Constant-time comparison to protect against timing attacks.
     */
    private static boolean slowEquals(String a, String b) {
        if (a == null || b == null || a.length() != b.length()) {
            return false;
        }
        int diff = 0;
        for (int i = 0; i < a.length(); i++) {
            diff |= a.charAt(i) ^ b.charAt(i);
        }
        return diff == 0;
    }

    private static String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }

    private static byte[] hexToBytes(String hex) {
        int len = hex.length();
        byte[] data = new byte[len / 2];
        for (int i = 0; i < len; i += 2) {
            data[i / 2] = (byte) ((Character.digit(hex.charAt(i), 16) << 4)
                    + Character.digit(hex.charAt(i + 1), 16));
        }
        return data;
    }
}
