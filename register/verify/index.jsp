<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="service.OTP"%>
<%@page import="service.PasswordUtil"%>
<%@page import="database.Users"%>

<%
    database.Users tempUser = (database.Users) session.getAttribute("tempUser");
    if (tempUser == null) {
        response.sendRedirect("../");
        return;
    }

    String msg = "";
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String otpInput = request.getParameter("otp");
        
        try {
            // Xác thực OTP (Hàm verifyOtp sẽ tự động xóa record nếu thành công)
            boolean isOk = OTP.verifyOtp(tempUser.getUserEmail(), otpInput, OTP.TYPE_REGISTER);
            
            if (isOk) {
                // Lưu người dùng chính thức vào Database
                database.Users dao = new database.Users();
                
                // CẬP NHẬT: Nhận chuỗi String trả về từ hàm insertUser
                String insertResult = dao.insertUser(tempUser);
                
                // Nếu chuỗi trả về rỗng (isEmpty) nghĩa là lệnh INSERT thành công
                if (insertResult != null && insertResult.isEmpty()) {
                    session.removeAttribute("tempUser"); // Xóa dữ liệu tạm
                    msg = "success";
                } else {
                    // Nếu thất bại, in trực tiếp câu lỗi của MySQL ra màn hình
                    msg = "Lỗi Database: " + insertResult;
                }
            } else {
                msg = "Mã OTP không đúng hoặc đã hết hạn.";
            }
        } catch (Exception e) {
            msg = "Lỗi: " + e.getMessage();
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Xác thực OTP - Dosmé</title>
    <style>
        body { font-family: sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; background: #f0f2f5; }
        .box { background: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); text-align: center; width: 350px; }
        input { width: 100%; padding: 12px; margin: 20px 0; border: 1px solid #ccc; border-radius: 4px; font-size: 20px; text-align: center; letter-spacing: 5px; }
        button { background: #007bff; color: white; border: none; padding: 12px 20px; border-radius: 4px; cursor: pointer; width: 100%; }
        .msg { margin-top: 15px; font-weight: bold; }
        .error { color: red; }
        .success { color: green; }
    </style>
</head>
<body>
    <div class="box">
        <% if ("success".equals(msg)) { %>
            <h2 class="success">Đăng ký thành công!</h2>
            <p>Tài khoản của bạn đã được kích hoạt.</p>
            <a href="../../login/">Đến trang đăng nhập</a>
        <% } else { %>
            <h2>Xác thực Email</h2>
            <p>Mã OTP đã được gửi đến: <br><strong><%= tempUser.getUserEmail() %></strong></p>
            
            <% if (!msg.isEmpty()) { %>
                <div class="msg error"><%= msg %></div>
            <% } %>

            <form method="post">
                <input type="text" name="otp" placeholder="000000" required maxlength="6">
                <button type="submit">Xác nhận</button>
            </form>
            <p style="font-size: 12px; color: #666; margin-top: 20px;">Vui lòng kiểm tra cả hòm thư Spam nếu không thấy mã.</p>
        <% } %>
    </div>
</body>
</html>