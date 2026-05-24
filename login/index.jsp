<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="database.Users"%>
<%@page import="service.PasswordUtil"%>
<%@page import="service.OTP"%>
<%@page import="service.MailSender"%>
<%@page import="java.time.Duration"%>

<%
    String error = "";
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String identifier = request.getParameter("identifier");
        String password = request.getParameter("password");

        database.Users dao = new database.Users();
        database.Users user = dao.getUserByAny(identifier);

        if (user != null) {
            String hashedInput = PasswordUtil.hashPassword(password);
            if (user.getPassword().equals(hashedInput)) {
                if (user.getDisable() == 1) {
                    error = "Tài khoản của bạn hiện đang bị khóa.";
                } else {
                    String currentIp = request.getRemoteAddr();
                    boolean isNewDevice = false; 

                    if (isNewDevice) {
                        try {
                            session.setAttribute("pendingUser", user);
                            OTP.CreateOtpResult otp = OTP.createOtp(user.getUserId(), user.getUserEmail(), OTP.TYPE_NEW_DEVICE_LOGIN, Duration.ofMinutes(5), currentIp);
                            MailSender.sendOtpEmail(user.getUserEmail(), otp.otpPlain, OTP.TYPE_NEW_DEVICE_LOGIN, 5);
                            response.sendRedirect("verify/");
                            return;
                        } catch (Exception e) {
                            error = "Lỗi gửi OTP: " + e.getMessage();
                        }
                    } else {
                        session.setAttribute("user", user);
                        response.sendRedirect("../shop/");
                        return;
                    }
                }
            } else {
                error = "Mật khẩu không chính xác.";
            }
        } else {
            error = "Tài khoản không tồn tại.";
        }
    }
%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Đăng Nhập - Dosmé</title>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600&family=Montserrat:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        :root {
            /* MÀU CHỦ ĐẠO LẤY TỪ NỀN LOGO */
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
            /* Thiết lập màu nền toàn trang trùng với màu logo */
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

        /* PHẦN BÊN TRÁI: LOGO */
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
            margin-top: 10px; /* Kéo slogan sát lên logo */
            letter-spacing: 3px;
            text-transform: uppercase;
        }

        /* PHẦN BÊN PHẢI: FORM */
        .form-section {
            flex: 1;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        .login-card {
            background: var(--white);
            width: 100%;
            max-width: 400px;
            padding: 50px 40px;
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
            font-size: 2rem;
            color: var(--text-black);
            margin-bottom: 30px;
            letter-spacing: 1px;
        }

        .form-group {
            margin-bottom: 20px;
        }

        label {
            display: block;
            margin-bottom: 8px;
            font-size: 13px;
            font-weight: 600;
            color: var(--text-black);
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        input {
            width: 100%;
            padding: 15px;
            border: 1px solid #f0f0f0;
            border-radius: 12px;
            box-sizing: border-box;
            background-color: #fafafa;
            font-size: 14px;
            transition: all 0.3s;
        }

        input:focus {
            outline: none;
            border-color: var(--logo-beige);
            background-color: var(--white);
            box-shadow: 0 0 0 4px rgba(229, 213, 193, 0.3);
        }

        .btn-login {
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

        .btn-login:hover {
            background: var(--deep-gold);
            color: var(--white);
            transform: translateY(-3px);
        }

        .error-msg {
            color: #d32f2f;
            background: #fff5f5;
            padding: 12px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 13px;
            text-align: center;
            border: 1px solid #ffeded;
        }

        .links {
            margin-top: 25px;
            text-align: center;
            font-size: 13px;
        }

        .links a {
            color: var(--text-muted);
            text-decoration: none;
            font-weight: 500;
            transition: 0.3s;
        }

        .links a:hover {
            color: var(--deep-gold);
        }

        /* RESPONSIVE */
        @media (max-width: 992px) {
            .main-wrapper { flex-direction: column; align-items: center; }
            .brand-section { padding: 20px; }
            .brand-section img { width: 150px; }
            .form-section { width: 100%; }
            .login-card { border-radius: 20px; padding: 40px 25px; }
        }
    </style>
</head>
<body>

    <div class="main-wrapper">
        <div class="brand-section">
            <img src="../assets/images/logo/logo.png" alt="Dosmé Logo">
            <p class="brand-slogan">Vẻ đẹp từ sự thuần khiết</p>
        </div>

        <div class="form-section">
            <div class="login-card">
                <h2>Đăng Nhập</h2>
                
                <% if (error != null && !error.isEmpty()) { %>
                    <div class="error-msg"><%= error %></div>
                <% } %>

                <form method="post">
                    <div class="form-group">
                        <label>Tài khoản</label>
                        <input type="text" name="identifier" required placeholder="Tên đăng nhập, Email hoặc Số điện thoại">
                    </div>
                    <div class="form-group">
                        <label>Mật khẩu</label>
                        <input type="password" name="password" required placeholder="••••••••">
                    </div>
                    <button type="submit" class="btn-login">Đăng nhập</button>
                </form>

                <div class="links">
                    <a href="../forgot/">Quên mật khẩu?</a>
                    <p>Chưa có tài khoản? <a href="../register" style="color: var(--deep-gold); font-weight: 600;">Đăng ký ngay</a></p>
                </div>
            </div>
        </div>
    </div>

</body>
</html>