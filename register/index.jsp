<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="database.Users"%>
<%@page import="service.OTP"%>
<%@page import="service.MailSender"%>
<%@page import="java.time.Duration"%>
<%@page import="service.PasswordUtil"%>

<%
    String error = "";
    // Logic xử lý POST Đăng ký
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String fullName = request.getParameter("fullName");
        String userName = request.getParameter("userName");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String address = request.getParameter("address");
        String password = request.getParameter("password");
        String confirmPassword = request.getParameter("confirmPassword");

        if (!password.equals(confirmPassword)) {
            error = "Mật khẩu xác nhận không khớp!";
        } else {
            try {
                database.Users tempUser = new database.Users();
                tempUser.setFullName(fullName);
                tempUser.setUserName(userName);
                tempUser.setUserEmail(email);
                tempUser.setUserPhone(phone);
                tempUser.setUserAddress(address);
                tempUser.setPassword(PasswordUtil.hashPassword(password));

                session.setAttribute("pendingUser", tempUser);
                
                // Gửi OTP (Ví dụ thời hạn 5 phút)
                OTP.CreateOtpResult otpResult = OTP.createOtp(0, email, OTP.TYPE_REGISTER, Duration.ofMinutes(5), "");
                MailSender.sendOtpEmail(email, otpResult.otpPlain, OTP.TYPE_REGISTER, 5);
                
                response.sendRedirect("verify/");
                return;
            } catch (Exception e) {
                error = "Có lỗi xảy ra: " + e.getMessage();
            }
        }
    }
%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Đăng Ký Thành Viên - Dosmé</title>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600&family=Montserrat:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --logo-beige: #FFEDD8; 
            --dark-beige: #d4c1aa;
            --text-black: #1a1a1a;
            --text-muted: #5e5e5e;
            --deep-gold: #b08d57;
            --white: #ffffff;
        }

        body {
            margin: 0;
            padding: 0;
            font-family: 'Montserrat', sans-serif;
            background-color: var(--logo-beige);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        .main-wrapper {
            display: flex;
            width: 100%;
            max-width: 1100px;
            min-height: 600px;
            background: transparent;
            margin: 20px;
        }

        .brand-section {
            flex: 1.2;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            text-align: center;
        }

        .brand-section img {
            max-width: 100%;
            height: auto;
            width: 450px;
            background: transparent; 
            border: none;
            display: block;
        }

        .brand-slogan {
            font-family: 'Playfair Display', serif;
            font-size: 1.2rem;
            color: var(--deep-gold);
            margin-top: 10px;
            letter-spacing: 3px;
            text-transform: uppercase;
        }

        .form-section {
            flex: 1;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        .reg-card {
            background: var(--white);
            width: 100%;
            max-width: 450px; /* Tăng nhẹ để chứa form đăng ký */
            padding: 40px;
            border-radius: 30px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.08);
            animation: slideIn 0.8s ease;
        }

        @keyframes slideIn {
            from { opacity: 0; transform: translateX(30px); }
            to { opacity: 1; transform: translateX(0); }
        }

        h2 {
            font-family: 'Playfair Display', serif;
            text-align: center;
            font-size: 1.8rem;
            color: var(--text-black);
            margin-bottom: 25px;
            letter-spacing: 1px;
        }

        /* Chia cột nhẹ cho form đăng ký để gọn hơn */
        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
        }

        .full-width { grid-column: span 2; }

        .form-group { margin-bottom: 15px; }

        label {
            display: block;
            margin-bottom: 6px;
            font-size: 11px;
            font-weight: 600;
            color: var(--text-black);
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        input {
            width: 100%;
            padding: 12px 15px;
            border: 1px solid #f0f0f0;
            border-radius: 12px;
            box-sizing: border-box;
            background-color: #fafafa;
            font-size: 13px;
            transition: all 0.3s;
        }

        input:focus {
            outline: none;
            border-color: var(--logo-beige);
            background-color: var(--white);
            box-shadow: 0 0 0 4px rgba(229, 213, 193, 0.3);
        }

        .btn-reg {
            width: 100%;
            padding: 16px;
            background: var(--text-black);
            color: var(--logo-beige);
            border: none;
            border-radius: 12px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 2px;
            transition: 0.3s;
            margin-top: 10px;
        }

        .btn-reg:hover {
            background: var(--deep-gold);
            color: var(--white);
            transform: translateY(-3px);
        }

        .error-msg {
            color: #d32f2f;
            background: #fff5f5;
            padding: 10px;
            border-radius: 8px;
            margin-bottom: 15px;
            font-size: 12px;
            text-align: center;
            border: 1px solid #ffeded;
        }

        .links {
            margin-top: 20px;
            text-align: center;
            font-size: 13px;
        }

        .links a {
            color: var(--text-muted);
            text-decoration: none;
            font-weight: 600;
            transition: 0.3s;
        }

        .links a:hover { color: var(--deep-gold); }

        @media (max-width: 992px) {
            .main-wrapper { flex-direction: column; align-items: center; margin-top: 50px; }
            .brand-section { padding: 20px; }
            .brand-section img { width: 180px; }
            .form-section { width: 100%; padding-bottom: 50px; }
            .reg-card { border-radius: 20px; padding: 30px 20px; width: 90%; }
            .form-grid { grid-template-columns: 1fr; }
            .full-width { grid-column: span 1; }
        }
    </style>
</head>
<body>
    <div class="main-wrapper">
        <div class="brand-section">
            <img src="../assets/images/logo/logo.png" alt="Dosmé Logo">
            <p class="brand-slogan">Đánh thức vẻ đẹp tiềm ẩn</p>
        </div>

        <div class="form-section">
            <div class="reg-card">
                <h2>Tạo Tài Khoản</h2>
                
                <% if (error != null && !error.isEmpty()) { %>
                    <div class="error"><%= error %></div>
                <% } %>

                <form method="post">
                    <div class="form-grid">
                        <div class="form-group full-width">
                            <label>Họ và tên</label>
                            <input type="text" name="fullName" required placeholder="Dosmé Beauty">
                        </div>
                        <div class="form-group">
                            <label>Tên đăng nhập</label>
                            <input type="text" name="userName" required placeholder="dosmebeauty">
                        </div>
                        <div class="form-group">
                            <label>Số điện thoại(Tùy chọn)</label>
                            <input type="text" name="phone" placeholder="035xxxxxxx">
                        </div>
                        <div class="form-group full-width">
                            <label>Email</label>
                            <input type="email" name="email" required placeholder="dosme.beauty@gmail.com">
                        </div>
                        <div class="form-group full-width">
                            <label>Địa chỉ (Tùy chọn)</label>
                            <input type="text" name="address" placeholder="Số nhà, tên đường, xã...">
                        </div>
                        <div class="form-group">
                            <label>Mật khẩu</label>
                            <input type="password" name="password" required placeholder="••••••••">
                        </div>
                        <div class="form-group">
                            <label>Xác nhận</label>
                            <input type="password" name="confirmPassword" required placeholder="••••••••">
                        </div>
                    </div>
                    <button type="submit" class="btn-reg">Đăng ký ngay</button>
                </form>

                <div class="links">
                    <span>Đã có tài khoản?</span>
                    <a href="../login/">Đăng nhập</a>
                </div>
            </div>
        </div>
    </div>
</body>
</html>