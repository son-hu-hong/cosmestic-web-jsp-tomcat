<%-- 
    Document   : index
    Created on : 24 thg 4, 2026, 23:39:18
    Author     : SonHuHong
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="service.OTP"%>

<%
    // 1. Kiểm tra quyền truy cập: Phải có email reset trong session
    String realEmail = (String) session.getAttribute("resetEmail");
    String maskedEmail = (String) session.getAttribute("maskedEmail");

    if (realEmail == null) {
        // Nếu không có thông tin email, quay lại bước nhập identifier
        response.sendRedirect("../");
        return;
    }

    String msg = "";
    String msgType = "";

    // 2. Xử lý khi người dùng nhấn "Xác nhận"
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String otpInput = request.getParameter("otp");

        try {
            // Xác thực OTP (loại 3: Quên mật khẩu)
            // Hàm verifyOtp sẽ tự động xóa bản ghi trong DB nếu khớp
            boolean isOk = OTP.verifyOtp(realEmail, otpInput, OTP.TYPE_FORGOT_PASSWORD);

            if (isOk) {
                // Đánh dấu đã xác thực OTP thành công để cho phép vào trang reset
                session.setAttribute("isOtpVerified", true);
                
                // Chuyển hướng sang trang đặt lại mật khẩu mới
                response.sendRedirect("../reset/");
                return;
            } else {
                msg = "Mã xác thực không chính xác hoặc đã hết hạn.";
                msgType = "error";
            }
        } catch (Exception e) {
            msg = "Lỗi hệ thống: " + e.getMessage();
            msgType = "error";
        }
    }
%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Xác minh OTP - Dosmé</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; background: #f8f9fa; margin: 0; }
        .container { background: white; padding: 40px; border-radius: 12px; box-shadow: 0 10px 30px rgba(0,0,0,0.05); text-align: center; width: 100%; max-width: 400px; }
        h2 { color: #111; margin-bottom: 10px; }
        p { color: #666; font-size: 14px; line-height: 1.6; }
        .email-display { font-weight: 600; color: #000; background: #f1f3f5; padding: 5px 10px; border-radius: 4px; }
        input { width: 100%; padding: 15px; margin: 25px 0; border: 1px solid #ddd; border-radius: 8px; font-size: 24px; text-align: center; letter-spacing: 10px; box-sizing: border-box; }
        button { background: #000; color: white; border: none; padding: 15px; border-radius: 8px; cursor: pointer; width: 100%; font-size: 16px; font-weight: 600; transition: 0.3s; }
        button:hover { background: #333; }
        .error-msg { background: #fff5f5; color: #e03131; padding: 12px; border-radius: 8px; margin-bottom: 20px; font-size: 14px; border: 1px solid #ffc9c9; }
        .footer-links { margin-top: 25px; font-size: 13px; color: #888; }
        .footer-links a { color: #228be6; text-decoration: none; }
    </style>
</head>
<body>
    <div class="container">
        <h2>Xác minh mã OTP</h2>
        <p>Chúng tôi đã gửi mã xác minh 6 số tới địa chỉ email:</p>
        <p><span class="email-display"><%= maskedEmail %></span></p>
        
        <% if (!msg.isEmpty()) { %>
            <div class="error-msg"><%= msg %></div>
        <% } %>

        <form method="post">
            <input type="text" name="otp" placeholder="000000" required maxlength="6" autocomplete="off" autofocus>
            <button type="submit">Xác nhận mã</button>
        </form>

        <div class="footer-links">
            Chưa nhận được mã? <a href="../">Gửi lại yêu cầu</a> <br>
            <a href="../../login/" style="display:inline-block; margin-top:15px;">Quay lại đăng nhập</a>
        </div>
    </div>
</body>
</html>