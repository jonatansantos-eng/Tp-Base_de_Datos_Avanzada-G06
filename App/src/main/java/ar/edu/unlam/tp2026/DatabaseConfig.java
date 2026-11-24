package ar.edu.unlam.tp2026;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public final class DatabaseConfig {
    private static final String DEFAULT_URL =
        "jdbc:sqlserver://localhost:1433;databaseName=TP2026;encrypt=true;trustServerCertificate=true;loginTimeout=10";

    private DatabaseConfig() {}

    public static Connection open() throws SQLException {
        String url = env("TP2026_DB_URL", DEFAULT_URL);
        String user = env("TP2026_APP_USER", "app_tp");
        String password = System.getenv("TP2026_APP_PASSWORD");
        if (password == null || password.isBlank()) {
            throw new SQLException("Falta la variable de entorno TP2026_APP_PASSWORD.");
        }
        Properties props = new Properties();
        props.setProperty("user", user);
        props.setProperty("password", password);
        props.setProperty("applicationName", "TP2026 Club ABM");
        return DriverManager.getConnection(url, props);
    }

    private static String env(String name, String fallback) {
        String value = System.getenv(name);
        return value == null || value.isBlank() ? fallback : value;
    }
}
