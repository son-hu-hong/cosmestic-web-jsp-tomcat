package service;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Properties;

public class PasswordUtil {

    private static final String PROPS_FILE = "config.properties";

    /**
     * Tải pepper từ file cấu hình.
     */
    private static String getPepper() {
        Properties p = new Properties();
        ClassLoader cl = Thread.currentThread().getContextClassLoader();
        try (InputStream in = cl.getResourceAsStream(PROPS_FILE)) {
            if (in != null) {
                p.load(in);
                return p.getProperty("password.pepper", "");
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return "";
    }

    /**
     * Mã hóa mật khẩu bằng SHA-256 kết hợp với Pepper.
     */
    public static String hashPassword(String password) {
        String pepper = getPepper();
        String combined = password + pepper;

        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] encodedHash = digest.digest(combined.getBytes(StandardCharsets.UTF_8));

            // Chuyển đổi mảng byte sang chuỗi Hexadecimal
            StringBuilder hexString = new StringBuilder();
            for (byte b : encodedHash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("Lỗi thuật toán mã hóa: " + e.getMessage());
        }
    }
}