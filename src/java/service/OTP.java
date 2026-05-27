package service;

import database.Connect;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.sql.*;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Date;
import java.util.Properties;

import javax.crypto.SecretKey;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;

public class OTP {

    // otpType: 1-Đăng ký, 2-Đăng nhập thiết bị lạ, 3-Quên mật khẩu,
    //          4-Đổi email, 5-Đổi mật khẩu
    public static final int TYPE_REGISTER = 1;
    public static final int TYPE_NEW_DEVICE_LOGIN = 2;
    public static final int TYPE_FORGOT_PASSWORD = 3;
    public static final int TYPE_CHANGE_EMAIL = 4;
    public static final int TYPE_CHANGE_PASSWORD = 5;

    // status: 0-Chưa sử dụng, 1-Đã sử dụng, 2-Đã hủy
    // (Phương án B: verify/cancel thành công sẽ DELETE record, nhưng vẫn giữ status để tương thích schema)
    public static final int STATUS_UNUSED = 0;
    public static final int STATUS_USED = 1;
    public static final int STATUS_CANCELED = 2;

    private static final SecureRandom RNG = new SecureRandom();
    private static final String PROPS_FILE = "config.properties";

    public static class CreateOtpResult {
        public final long otpId;
        public final String email;
        public final String otpPlain;     // để gửi email/SMS
        public final String otpJwtToken;  // lưu DB (otpCode)
        public final LocalDateTime expiresAt;

        public CreateOtpResult(long otpId, String email, String otpPlain, String otpJwtToken, LocalDateTime expiresAt) {
            this.otpId = otpId;
            this.email = email;
            this.otpPlain = otpPlain;
            this.otpJwtToken = otpJwtToken;
            this.expiresAt = expiresAt;
        }
    }

    private static Properties loadProps() throws IOException {
        Properties p = new Properties();
        ClassLoader cl = Thread.currentThread().getContextClassLoader();
        try (InputStream in = cl.getResourceAsStream(PROPS_FILE)) {
            if (in == null) {
                throw new IOException("Không tìm thấy " + PROPS_FILE
                        + " trong classpath. Hãy đảm bảo file nằm ở web/WEB-INF/classes/config.properties");
            }
            p.load(in);
        }
        return p;
    }

    private static SecretKey otpSecretKey() throws IOException {
        String secret = loadProps().getProperty("otp.jwt.secret");
        if (secret == null || secret.trim().isEmpty() || secret.startsWith("CHANGE_ME")) {
            throw new IOException("otp.jwt.secret chưa được cấu hình đúng trong config.properties");
        }
        // HS256 cần key đủ mạnh. Khuyến nghị secret >= 32 ký tự.
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    private static String generateNumericOtp(int length) {
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) sb.append(RNG.nextInt(10));
        return sb.toString();
    }

    /**
     * JWT payload không dùng claims JSON để tránh Jackson.
     * - sub = email
     * - jti = "otp:type"
     * - exp = expiresAt
     */
    private static String buildOtpJwtNoJackson(String email, String otpPlain, int otpType, LocalDateTime expiresAt) throws IOException {
        SecretKey key = otpSecretKey();
        Date exp = Timestamp.valueOf(expiresAt);

        String jti = otpPlain + ":" + otpType;

        return Jwts.builder()
                .setSubject(email)
                .setId(jti)
                .setExpiration(exp)
                .signWith(key, SignatureAlgorithm.HS256)
                .compact();
    }

    /**
     * Parse JWT và trích OTP từ jti (otp:type). Token sai signature/exp sẽ throw.
     */
    private static String extractOtpFromJwtJti(String jwtToken, int expectedType) throws IOException {
        SecretKey key = otpSecretKey();

        String jti = Jwts.parserBuilder()
                .setSigningKey(key)
                .build()
                .parseClaimsJws(jwtToken)
                .getBody()
                .getId();

        if (jti == null) return null;

        String[] parts = jti.split(":");
        if (parts.length != 2) return null;

        String otp = parts[0];
        int typeInToken;
        try {
            typeInToken = Integer.parseInt(parts[1]);
        } catch (NumberFormatException e) {
            return null;
        }

        if (typeInToken != expectedType) return null;
        return otp;
    }

    /**
     * Tạo OTP (6 số), tạo JWT token, LƯU JWT token vào otp_codes.otpCode.
     * Trả về OTP plain để gửi email/SMS.
     */
    public static CreateOtpResult createOtp(Integer userId, String email, int otpType, Duration ttl, String ipAddress) throws Exception {
        if (email == null || email.trim().isEmpty()) throw new IllegalArgumentException("email không hợp lệ");
        if (ttl == null || ttl.isNegative() || ttl.isZero()) ttl = Duration.ofMinutes(5);

        cleanupExpiredOtps();

        String otpPlain = generateNumericOtp(6);
        LocalDateTime expiresAt = LocalDateTime.now().plus(ttl);
        String jwtToken = buildOtpJwtNoJackson(email.trim(), otpPlain, otpType, expiresAt);

        String sql = "INSERT INTO otp_codes (userId, email, otpCode, otpType, status, createdAt, expiresAt, ipAddress) " +
                     "VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP, ?, ?)";

        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            if (userId == null) ps.setNull(1, Types.INTEGER);
            else ps.setInt(1, userId);

            ps.setString(2, email.trim());

            // Phương án B: otpCode lưu JWT token
            ps.setString(3, jwtToken);

            ps.setInt(4, otpType);
            ps.setInt(5, STATUS_UNUSED);
            ps.setTimestamp(6, Timestamp.valueOf(expiresAt));

            if (ipAddress == null || ipAddress.isEmpty()) ps.setNull(7, Types.VARCHAR);
            else ps.setString(7, ipAddress);

            ps.executeUpdate();

            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    long otpId = rs.getLong(1);
                    return new CreateOtpResult(otpId, email.trim(), otpPlain, jwtToken, expiresAt);
                }
            }
        }

        throw new SQLException("Không tạo được OTP (không lấy được otpId).");
    }

    /**
     * Verify OTP theo email + otpType.
     * - Lấy record mới nhất status=0, chưa hết hạn (DB)
     * - Parse JWT trong DB (signature + exp của JWT)
     * - So sánh OTP
     * - Thành công: DELETE record (đúng yêu cầu)
     */
    public static boolean verifyOtp(String email, String otpUserInput, int otpType) throws Exception {
        cleanupExpiredOtps();

        if (email == null || email.trim().isEmpty()) return false;
        if (otpUserInput == null || otpUserInput.trim().isEmpty()) return false;

        String selectSql =
                "SELECT otpId, otpCode " +
                "FROM otp_codes " +
                "WHERE email=? AND otpType=? AND status=? AND expiresAt > CURRENT_TIMESTAMP " +
                "ORDER BY createdAt DESC LIMIT 1";

        String deleteSql = "DELETE FROM otp_codes WHERE otpId=?";

        try (Connection conn = Connect.getConnection()) {
            conn.setAutoCommit(false);

            Long otpId = null;
            String jwtToken = null;

            try (PreparedStatement ps = conn.prepareStatement(selectSql)) {
                ps.setString(1, email.trim());
                ps.setInt(2, otpType);
                ps.setInt(3, STATUS_UNUSED);

                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        otpId = rs.getLong("otpId");
                        jwtToken = rs.getString("otpCode");
                    }
                }
            }

            if (otpId == null || jwtToken == null || jwtToken.trim().isEmpty()) {
                conn.rollback();
                return false;
            }

            String otpInToken;
            try {
                otpInToken = extractOtpFromJwtJti(jwtToken, otpType);
            } catch (Exception ex) {
                conn.rollback();
                return false;
            }

            if (otpInToken == null || !otpInToken.equals(otpUserInput.trim())) {
                conn.rollback();
                return false;
            }

            try (PreparedStatement ps = conn.prepareStatement(deleteSql)) {
                ps.setLong(1, otpId);
                int deleted = ps.executeUpdate();
                conn.commit();
                return deleted == 1;
            } catch (Exception e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    /**
     * Người dùng hủy xác minh -> XÓA record (đúng yêu cầu).
     */
    public static boolean cancelOtpById(long otpId) throws Exception {
        String sql = "DELETE FROM otp_codes WHERE otpId=?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, otpId);
            return ps.executeUpdate() == 1;
        }
    }

    public static boolean cancelLatestOtp(String email, int otpType) throws Exception {
        cleanupExpiredOtps();

        String selectSql =
                "SELECT otpId FROM otp_codes " +
                "WHERE email=? AND otpType=? AND status=? AND expiresAt > CURRENT_TIMESTAMP " +
                "ORDER BY createdAt DESC LIMIT 1";

        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(selectSql)) {

            ps.setString(1, email.trim());
            ps.setInt(2, otpType);
            ps.setInt(3, STATUS_UNUSED);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return false;
                long otpId = rs.getLong("otpId");
                return cancelOtpById(otpId);
            }
        }
    }

    /**
     * Xóa OTP hết hạn khỏi DB.
     */
    public static int cleanupExpiredOtps() throws Exception {
        String sql = "DELETE FROM otp_codes WHERE expiresAt <= CURRENT_TIMESTAMP";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            return ps.executeUpdate();
        }
    }
}