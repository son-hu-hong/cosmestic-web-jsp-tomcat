<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="database.Users"%>
<%@page import="service.OTP"%>
<%@page import="service.MailSender"%>
<%@page import="java.time.Duration"%>

<%
    // Tự động bỏ qua nếu người dùng đang đăng nhập
    if (session.getAttribute("user") != null) {
        response.sendRedirect(request.getContextPath() + "/home/");
        return;
    }

    String error = "";
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String identifier = request.getParameter("identifier");
        
        database.Users dao = new database.Users();
        // Sử dụng hàm getUserByAny đã viết trước đó (hỗ trợ Username, Email, Phone)
        database.Users user = dao.getUserByAny(identifier);

        if (user != null) {
            try {
                String realEmail = user.getUserEmail();
                
                // Thuật toán ẩn email: Giữ lại tối đa 2 ký tự đầu của phần tên
                String maskedEmail = realEmail;
                if (realEmail != null && realEmail.contains("@")) {
                    String[] parts = realEmail.split("@");
                    String name = parts[0];
                    String domain = parts[1];
                    
                    if (name.length() <= 2) {
                        maskedEmail = name.substring(0, 1) + "***@" + domain;
                    } else {
                        maskedEmail = name.substring(0, 2) + "***@" + domain;
                    }
                }

                // Lưu email thật (để backend xử lý) và email ảo (để frontend hiển thị) vào Session
                session.setAttribute("resetEmail", realEmail);
                session.setAttribute("maskedEmail", maskedEmail);
                
                // Tạo OTP loại 3 (Quên mật khẩu), thời hạn 10 phút
                OTP.CreateOtpResult otp = OTP.createOtp(user.getUserId(), realEmail, OTP.TYPE_FORGOT_PASSWORD, Duration.ofMinutes(10), request.getRemoteAddr());
                
                // Gửi mail
                MailSender.sendOtpEmail(realEmail, otp.otpPlain, OTP.TYPE_FORGOT_PASSWORD, 10);
                
                // Điều hướng sang trang nhập mã OTP (sử dụng đường dẫn thư mục sạch)
                response.sendRedirect("verify/");
                return;
            } catch (Exception e) {
                error = "Lỗi hệ thống: " + e.getMessage();
            }
        } else {
            error = "Không tìm thấy tài khoản nào khớp với thông tin bạn cung cấp.";
        }
    }
%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Khôi phục mật khẩu - Dosmé</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; background: #f8f9fa; margin: 0; }
        .card { background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 25px rgba(0,0,0,0.06); width: 100%; max-width: 380px; text-align: center; }
        h2 { margin-bottom: 15px; color: #111; }
        p { color: #666; font-size: 14px; line-height: 1.5; margin-bottom: 25px; }
        input { width: 100%; padding: 14px; margin-bottom: 20px; border: 1px solid #ddd; border-radius: 8px; box-sizing: border-box; font-size: 15px; }
        button { width: 100%; padding: 14px; background: #000; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: 600; font-size: 15px; transition: 0.3s; }
        button:hover { background: #333; }
        .error { color: #e03131; background: #ffe3e3; padding: 12px; border-radius: 8px; font-size: 14px; margin-bottom: 20px; text-align: left; }
        .back-link { display: inline-block; margin-top: 25px; color: #666; text-decoration: none; font-size: 14px; font-weight: 500; }
        .back-link:hover { color: #111; }
    </style>
</head>
<body>
    <div class="card">
        <h2>Khôi phục mật khẩu</h2>
        <p>Vui lòng nhập Email, Username hoặc Số điện thoại của bạn. Chúng tôi sẽ gửi mã OTP để thiết lập lại mật khẩu.</p>
        
        <% if (!error.isEmpty()) { %>
            <div class="error"><%= error %></div>
        <% } %>

        <form method="post">
            <input type="text" name="identifier" placeholder="Nhập tài khoản của bạn" required autocomplete="off">
            <button type="submit">Tìm tài khoản</button>
        </form>
        
        <a href="../login/" class="back-link">← Quay lại trang đăng nhập</a>
    </div>
</body>
</html>