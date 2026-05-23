package service;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Properties;

import jakarta.mail.Authenticator;
import jakarta.mail.Message;
import jakarta.mail.MessagingException;
import jakarta.mail.PasswordAuthentication;
import jakarta.mail.Session;
import jakarta.mail.Transport;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;

public class MailSender {

    private static final String PROPS_FILE = "config.properties";

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

    private static Session buildMailSession(Properties cfg) {
        final String host = cfg.getProperty("email.host");
        final String port = cfg.getProperty("email.port");
        final String user = cfg.getProperty("email.user");
        final String pass = cfg.getProperty("email.pass");

        Properties props = new Properties();
        props.put("mail.smtp.host", host);
        props.put("mail.smtp.port", port);

        // TLS (STARTTLS) for 587
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");

        // (optional) timeouts
        props.put("mail.smtp.connectiontimeout", "10000");
        props.put("mail.smtp.timeout", "10000");
        props.put("mail.smtp.writetimeout", "10000");

        return Session.getInstance(props, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(user, pass);
            }
        });
    }

    public static void sendOtpEmail(String toEmail, String otpCode, int otpType, int ttlMinutes) throws IOException, MessagingException {
        if (toEmail == null || toEmail.trim().isEmpty()) {
            throw new IllegalArgumentException("toEmail không hợp lệ");
        }
        if (otpCode == null || otpCode.trim().isEmpty()) {
            throw new IllegalArgumentException("otpCode không hợp lệ");
        }

        Properties cfg = loadProps();
        String from = cfg.getProperty("email.user");
        Session session = buildMailSession(cfg);

        String subject = buildSubject(otpType);
        String html = buildOtpHtml(otpCode.trim(), otpType, ttlMinutes);

        MimeMessage msg = new MimeMessage(session);
        msg.setFrom(new InternetAddress(from, "Dosmé Beauty Verify", StandardCharsets.UTF_8.name()));
        msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail.trim(), false));
        msg.setSubject(subject, StandardCharsets.UTF_8.name());
        msg.setContent(html, "text/html; charset=UTF-8");

        Transport.send(msg);
    }

    private static String buildSubject(int otpType) {
        switch (otpType) {
            case OTP.TYPE_REGISTER:
                return "DOSME - Mã OTP xác minh đăng ký";
            case OTP.TYPE_NEW_DEVICE_LOGIN:
                return "DOSME - Mã OTP đăng nhập thiết bị lạ";
            case OTP.TYPE_FORGOT_PASSWORD:
                return "DOSME - Mã OTP đặt lại mật khẩu";
            default:
                return "DOSME - Mã OTP xác minh";
        }
    }

    private static String buildOtpHtml(String otpCode, int otpType, int ttlMinutes) {
        String purpose;
        switch (otpType) {
            case OTP.TYPE_REGISTER:
                purpose = "xác minh đăng ký";
                break;
            case OTP.TYPE_NEW_DEVICE_LOGIN:
                purpose = "xác minh đăng nhập thiết bị lạ";
                break;
            case OTP.TYPE_FORGOT_PASSWORD:
                purpose = "xác minh đặt lại mật khẩu";
                break;
            default:
                purpose = "xác minh";
        }

        return ""
            + "<div style='font-family:Arial,sans-serif;line-height:1.5'>"
            + "  <h2>Dosmé Beauty</h2>"
            + "  <p>Bạn vừa yêu cầu <b>" + purpose + "</b>.</p>"
            + "  <p>Mã OTP của bạn là:</p>"
            + "  <div style='font-size:28px;font-weight:700;letter-spacing:4px;"
            + "              padding:12px 16px;border:1px solid #ddd;display:inline-block'>"
            +       otpCode
            + "  </div>"
            + "  <p>Mã có hiệu lực trong <b>" + ttlMinutes + " phút</b>.</p>"
            + "  <p>Nếu bạn không yêu cầu, vui lòng bỏ qua email này.</p>"
            + "</div>";
    }
}