<%-- 
    Document   : index
    Created on : 24 thg 4, 2026, 23:43:33
    Author     : SonHuHong
--%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="database.Users"%>
<%@page import="service.PasswordUtil"%>

<%
    // 1. Kiểm tra bảo mật: Phải qua bước verify OTP mới được vào đây
    String resetEmail = (String) session.getAttribute("resetEmail");
    Boolean isOtpVerified = (Boolean) session.getAttribute("isOtpVerified");

    if (resetEmail == null || isOtpVerified == null || !isOtpVerified) {
        // Nếu chưa xác minh, đẩy về trang nhập email ban đầu
        response.sendRedirect("../");
        return;
    }

    String msg = "";
    String msgType = "";

    // 2. Xử lý đổi mật khẩu
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String newPass = request.getParameter("newPassword");
        String confirmPass = request.getParameter("confirmPassword");

        if (newPass == null || newPass.length() < 6) {
            msg = "Mật khẩu phải có ít nhất 6 ký tự.";
            msgType = "error";
        } else if (!newPass.equals(confirmPass)) {
            msg = "Mật khẩu xác nhận không khớp.";
            msgType = "error";
        } else {
            // Thực hiện mã hóa mật khẩu kèm Pepper
            String hashedPass = PasswordUtil.hashPassword(newPass);
            
            database.Users dao = new database.Users();
            boolean success = dao.updatePassword(resetEmail, hashedPass);

            if (success) {
                // Xóa các thông tin tạm thời trong session để kết thúc luồng
                session.removeAttribute("resetEmail");
                session.removeAttribute("maskedEmail");
                session.removeAttribute("isOtpVerified");
                
                // Gắn cờ thông báo thành công để trang login hiển thị
                session.setAttribute("flashMsg", "Đặt lại mật khẩu thành công! Vui lòng đăng nhập lại.");
                response.sendRedirect("../../login/");
                return;
            } else {
                msg = "Không thể cập nhật mật khẩu. Vui lòng thử lại sau.";
                msgType = "error";
            }
        }
    }
%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Thiết lập mật khẩu mới - Dosmé</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; background: #f8f9fa; margin: 0; }
        .card { background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 25px rgba(0,0,0,0.06); width: 100%; max-width: 380px; text-align: center; }
        h2 { margin-bottom: 10px; color: #111; }
        p { color: #666; font-size: 14px; margin-bottom: 25px; }
        .form-group { text-align: left; margin-bottom: 15px; }
        label { display: block; font-size: 13px; font-weight: 600; margin-bottom: 5px; color: #444; }
        input { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 8px; box-sizing: border-box; font-size: 15px; }
        button { width: 100%; padding: 14px; background: #000; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: 600; margin-top: 10px; }
        .error-msg { background: #fff5f5; color: #e03131; padding: 10px; border-radius: 8px; font-size: 13px; margin-bottom: 20px; border: 1px solid #ffc9c9; }
    </style>
</head>
<body>
    <div class="card">
        <h2>Mật khẩu mới</h2>
        <p>Vui lòng tạo mật khẩu mới cho tài khoản:<br><b><%= resetEmail %></b></p>

        <% if (!msg.isEmpty()) { %>
            <div class="error-msg"><%= msg %></div>
        <% } %>

        <form method="post">
            <div class="form-group">
                <label>Mật khẩu mới</label>
                <input type="password" name="newPassword" placeholder="Tối thiểu 6 ký tự" required autofocus>
            </div>
            <div class="form-group">
                <label>Xác nhận mật khẩu mới</label>
                <input type="password" name="confirmPassword" placeholder="Nhập lại mật khẩu" required>
            </div>
            <button type="submit">Cập nhật mật khẩu</button>
        </form>
    </div>
</body>
</html>