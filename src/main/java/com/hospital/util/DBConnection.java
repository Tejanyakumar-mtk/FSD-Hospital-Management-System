package com.hospital.util;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/**
 * Database connection manager for Oracle Database using JDBC.
 * Reads properties from db.properties if available on classpath, or defaults to Oracle XE configuration.
 */
public class DBConnection {

    private static String dbUrl = "jdbc:oracle:thin:@localhost:1521:xe";
    private static String dbUser = "hospital_db";
    private static String dbPassword = "hospital123";
    private static String dbDriver = "oracle.jdbc.driver.OracleDriver";

    static {
        try {
            Properties props = new Properties();
            try (InputStream in = DBConnection.class.getClassLoader().getResourceAsStream("db.properties")) {
                if (in != null) {
                    props.load(in);
                    if (props.getProperty("db.url") != null) dbUrl = props.getProperty("db.url");
                    if (props.getProperty("db.user") != null) dbUser = props.getProperty("db.user");
                    if (props.getProperty("db.password") != null) dbPassword = props.getProperty("db.password");
                    if (props.getProperty("db.driver") != null) dbDriver = props.getProperty("db.driver");
                }
            }
            Class.forName(dbDriver);
        } catch (Exception e) {
            System.err.println("[DBConnection] Initialization error or driver load: " + e.getMessage());
        }
    }

    /**
     * Obtains a new database connection.
     */
    public static Connection getConnection() throws SQLException {
        try {
            Class.forName(dbDriver);
        } catch (ClassNotFoundException e) {
            throw new SQLException("Oracle JDBC Driver not found: " + dbDriver, e);
        }
        return DriverManager.getConnection(dbUrl, dbUser, dbPassword);
    }

    /**
     * Safely closes one or more JDBC/AutoCloseable resources without throwing checked exceptions.
     */
    public static void close(AutoCloseable... resources) {
        if (resources == null) return;
        for (AutoCloseable res : resources) {
            if (res != null) {
                try {
                    res.close();
                } catch (Exception ignored) {
                }
            }
        }
    }

    public static String getDbUrl() {
        return dbUrl;
    }

    public static String getDbUser() {
        return dbUser;
    }
}
