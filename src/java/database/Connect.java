package database;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public class Connect {
    private static final String PROPS_FILE = "config.properties";
    private static Properties props;

    private static synchronized Properties loadProps() throws IOException {
        if (props != null) return props;

        Properties p = new Properties();
        ClassLoader cl = Thread.currentThread().getContextClassLoader();

        try (InputStream in = cl.getResourceAsStream(PROPS_FILE)) {
            if (in == null) {
                throw new IOException("Không tìm thấy " + PROPS_FILE
                        + " trong classpath. Hãy đảm bảo file nằm ở web/WEB-INF/classes/config.properties");
            }
            p.load(in);
        }

        props = p;
        return props;
    }

    public static Connection getConnection() throws SQLException {
        try {
            Properties p = loadProps();

            String driver = p.getProperty("db.driver");
            String url = p.getProperty("db.url");
            String user = p.getProperty("db.user");
            String pass = p.getProperty("db.pass");

            if (driver == null || url == null || user == null || pass == null) {
                throw new SQLException("Thiếu cấu hình DB trong config.properties (db.driver/db.url/db.user/db.pass)");
            }

            // Load driver (MySQL Connector/J 8+)
            Class.forName(driver);

            return DriverManager.getConnection(url, user, pass);
        } catch (IOException e) {
            throw new SQLException("Không đọc được config.properties: " + e.getMessage(), e);
        } catch (ClassNotFoundException e) {
            throw new SQLException("Không tìm thấy JDBC driver: " + e.getMessage(), e);
        }
    }
}