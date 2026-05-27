<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="database.Users"%>
<%@page import="service.PasswordUtil"%>
<%@page import="service.OTP"%>
<%@page import="service.MailSender"%>
<%@page import="java.time.Duration"%>
<%@page import="java.util.regex.Pattern"%>
<%
    Users user = (Users) session.getAttribute("user");
    if (user == null) {
        String currentUrl = request.getRequestURI();
        response.sendRedirect(request.getContextPath() + "/login/?redirect=" + currentUrl);
        return;
    }

    String contextPath = request.getContextPath();
    Users dao = new Users();

    String msg = "";
    String msgType = "";
    boolean showEmailOtp = false;
    boolean showPasswordOtp = false;

    String formUserName = user.getUserName() == null ? "" : user.getUserName().trim();
    String formFullName = user.getFullName() == null ? "" : user.getFullName();
    String formPhone = user.getUserPhone() == null ? "" : user.getUserPhone();
    String formEmail = user.getUserEmail() == null ? "" : user.getUserEmail().trim();
    String newPassword = "";
    String confirmPassword = "";
    String currentPassword = "";
    String otpEmail = "";
    String otpPassword = "";

    String avatarFile = (user.getAvtUrl() == null || user.getAvtUrl().trim().isEmpty()) ? "default.png" : user.getAvtUrl().trim();
    String avatarUrl = contextPath + "/assets/images/avt/" + avatarFile;

    String roleRaw = user.getRole() == null ? "" : user.getRole().trim();
    boolean hasRole = !roleRaw.isEmpty();
    boolean isAdmin = "admin".equalsIgnoreCase(roleRaw);

    String uploadMsg = request.getParameter("msg");
    if (uploadMsg != null) {
        if ("success".equals(uploadMsg)) {
            msg = "Cập nhật ảnh đại diện thành công!";
            msgType = "success";
        } else if ("error_file".equals(uploadMsg)) {
            msg = "Vui lòng chọn file ảnh hợp lệ.";
            msgType = "error";
        } else if ("db_error".equals(uploadMsg)) {
            msg = "Không thể lưu ảnh vào cơ sở dữ liệu.";
            msgType = "error";
        } else if ("upload_failed".equals(uploadMsg)) {
            msg = "Tải ảnh lên thất bại.";
            msgType = "error";
        }
    }

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            action = "save_profile";
        }

        formUserName = request.getParameter("userName") == null ? "" : request.getParameter("userName").trim();
        formFullName = request.getParameter("fullName") == null ? "" : request.getParameter("fullName").trim();
        formPhone = request.getParameter("phone") == null ? "" : request.getParameter("phone").trim();
        formEmail = request.getParameter("email") == null ? "" : request.getParameter("email").trim();
        newPassword = request.getParameter("newPassword") == null ? "" : request.getParameter("newPassword");
        confirmPassword = request.getParameter("confirmPassword") == null ? "" : request.getParameter("confirmPassword");
        currentPassword = request.getParameter("currentPassword") == null ? "" : request.getParameter("currentPassword");
        otpEmail = request.getParameter("otpEmail") == null ? "" : request.getParameter("otpEmail").trim();
        otpPassword = request.getParameter("otpPassword") == null ? "" : request.getParameter("otpPassword").trim();

        boolean userNameChanged = !formUserName.equals(user.getUserName());
        boolean fullNameChanged = !formFullName.equals(user.getFullName() == null ? "" : user.getFullName());
        boolean phoneChanged = !formPhone.equals(user.getUserPhone() == null ? "" : user.getUserPhone());
        boolean emailChanged = !formEmail.equalsIgnoreCase(user.getUserEmail() == null ? "" : user.getUserEmail());
        boolean passwordChanged = !newPassword.trim().isEmpty();

        if ("request_otp_email_change".equals(action)) {
            showEmailOtp = true;
            if (!emailChanged) {
                msg = "Bạn chưa thay đổi email.";
                msgType = "error";
            } else {
                Users existed = dao.getUserByAny(formEmail);
                if (existed != null && existed.getUserId() != user.getUserId()) {
                    msg = "Email mới đã được sử dụng bởi tài khoản khác.";
                    msgType = "error";
                } else {
                    try {
                        OTP.CreateOtpResult otp = OTP.createOtp(user.getUserId(), user.getUserEmail(), OTP.TYPE_PROFILE_CHANGE_EMAIL, Duration.ofMinutes(10), request.getRemoteAddr());
                        MailSender.sendOtpEmail(user.getUserEmail(), otp.otpPlain, OTP.TYPE_PROFILE_CHANGE_EMAIL, 10);
                        msg = "Đã gửi OTP tới email hiện tại của bạn.";
                        msgType = "success";
                    } catch (Exception e) {
                        msg = "Không thể gửi OTP: " + e.getMessage();
                        msgType = "error";
                    }
                }
            }
        } else if ("request_otp_password_change".equals(action)) {
            showPasswordOtp = true;
            if (!passwordChanged) {
                msg = "Vui lòng nhập mật khẩu mới trước khi yêu cầu OTP.";
                msgType = "error";
            } else if (newPassword.length() < 6) {
                msg = "Mật khẩu mới phải có ít nhất 6 ký tự.";
                msgType = "error";
            } else if (!newPassword.equals(confirmPassword)) {
                msg = "Mật khẩu xác nhận không khớp.";
                msgType = "error";
            } else {
                try {
                    OTP.CreateOtpResult otp = OTP.createOtp(user.getUserId(), user.getUserEmail(), OTP.TYPE_PROFILE_CHANGE_PASSWORD, Duration.ofMinutes(10), request.getRemoteAddr());
                    MailSender.sendOtpEmail(user.getUserEmail(), otp.otpPlain, OTP.TYPE_PROFILE_CHANGE_PASSWORD, 10);
                    msg = "Đã gửi OTP đổi mật khẩu tới email hiện tại của bạn.";
                    msgType = "success";
                } catch (Exception e) {
                    msg = "Không thể gửi OTP: " + e.getMessage();
                    msgType = "error";
                }
            }
        } else if ("save_profile".equals(action)) {
            boolean hasAnyChange = userNameChanged || fullNameChanged || phoneChanged || emailChanged || passwordChanged;
            showEmailOtp = emailChanged || !otpEmail.isEmpty();
            showPasswordOtp = passwordChanged || !otpPassword.isEmpty();

            if (!hasAnyChange) {
                msg = "Không có thay đổi nào để lưu.";
                msgType = "error";
            } else if (currentPassword.isEmpty() || !user.getPassword().equals(PasswordUtil.hashPassword(currentPassword))) {
                msg = "Mật khẩu hiện tại không chính xác.";
                msgType = "error";
            } else {
                boolean valid = true;

                if (formUserName.isEmpty() || !Pattern.matches("^[A-Za-z][A-Za-z0-9_.-]{2,14}$", formUserName)) {
                    msg = "Username không hợp lệ (3-15 ký tự, bắt đầu bằng chữ, chỉ gồm chữ/số/_/./-).";
                    msgType = "error";
                    valid = false;
                }

                if (valid && userNameChanged && dao.checkUserNameExists(formUserName)) {
                    msg = "Username đã tồn tại.";
                    msgType = "error";
                    valid = false;
                }

                if (valid && (formEmail == null || formEmail.isEmpty())) {
                    msg = "Email không được để trống.";
                    msgType = "error";
                    valid = false;
                }

                if (valid && emailChanged) {
                    Users existed = dao.getUserByAny(formEmail);
                    if (existed != null && existed.getUserId() != user.getUserId()) {
                        msg = "Email mới đã được sử dụng bởi tài khoản khác.";
                        msgType = "error";
                        valid = false;
                    } else if (otpEmail.isEmpty()) {
                        msg = "Vui lòng nhập OTP xác thực đổi email.";
                        msgType = "error";
                        valid = false;
                    } else {
                        try {
                            if (!OTP.verifyOtp(user.getUserEmail(), otpEmail, OTP.TYPE_PROFILE_CHANGE_EMAIL)) {
                                msg = "OTP đổi email không hợp lệ hoặc đã hết hạn.";
                                msgType = "error";
                                valid = false;
                            }
                        } catch (Exception e) {
                            msg = "Lỗi xác thực OTP email: " + e.getMessage();
                            msgType = "error";
                            valid = false;
                        }
                    }
                }

                if (valid && passwordChanged) {
                    if (newPassword.length() < 6) {
                        msg = "Mật khẩu mới phải có ít nhất 6 ký tự.";
                        msgType = "error";
                        valid = false;
                    } else if (!newPassword.equals(confirmPassword)) {
                        msg = "Mật khẩu xác nhận không khớp.";
                        msgType = "error";
                        valid = false;
                    } else if (otpPassword.isEmpty()) {
                        msg = "Vui lòng nhập OTP xác thực đổi mật khẩu.";
                        msgType = "error";
                        valid = false;
                    } else {
                        try {
                            if (!OTP.verifyOtp(user.getUserEmail(), otpPassword, OTP.TYPE_PROFILE_CHANGE_PASSWORD)) {
                                msg = "OTP đổi mật khẩu không hợp lệ hoặc đã hết hạn.";
                                msgType = "error";
                                valid = false;
                            }
                        } catch (Exception e) {
                            msg = "Lỗi xác thực OTP mật khẩu: " + e.getMessage();
                            msgType = "error";
                            valid = false;
                        }
                    }
                }

                if (valid) {
                    boolean ok = true;
                    if (userNameChanged) {
                        ok = dao.updateUserName(user.getUserId(), formUserName);
                        if (ok) {
                            user.setUserName(formUserName);
                        } else {
                            msg = "Không thể cập nhật username.";
                            msgType = "error";
                        }
                    }

                    if (ok) {
                        user.setFullName(formFullName);
                        user.setUserPhone(formPhone);
                        user.setUserEmail(formEmail);
                        ok = dao.updateUser(user);
                        if (!ok) {
                            msg = "Không thể cập nhật thông tin hồ sơ.";
                            msgType = "error";
                        }
                    }

                    if (ok && passwordChanged) {
                        String hashedPass = PasswordUtil.hashPassword(newPassword);
                        ok = dao.updatePassword(user.getUserEmail(), hashedPass);
                        if (ok) {
                            user.setPassword(hashedPass);
                        } else {
                            msg = "Không thể cập nhật mật khẩu mới.";
                            msgType = "error";
                        }
                    }

                    if (ok) {
                        session.setAttribute("user", user);
                        msg = "Lưu thay đổi thành công!";
                        msgType = "success";
                        newPassword = "";
                        confirmPassword = "";
                        currentPassword = "";
                        otpEmail = "";
                        otpPassword = "";
                        showEmailOtp = false;
                        showPasswordOtp = false;
                    }
                }
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hồ sơ người dùng - Dosmé</title>
    <style>
        :root {
            --bg: #f6f7fb;
            --card: #ffffff;
            --text: #1f2430;
            --muted: #6b7280;
            --primary: #111111;
            --primary-soft: #f1f2f4;
            --border: #e5e7eb;
            --danger: #dc2626;
            --success: #15803d;
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            font-family: 'Segoe UI', Tahoma, Arial, sans-serif;
            background: var(--bg);
            color: var(--text);
            padding: 18px;
        }

        .page {
            max-width: 1080px;
            margin: 0 auto;
        }

        .topbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: var(--card);
            border: 1px solid var(--border);
            border-radius: 14px;
            padding: 14px 18px;
            margin-bottom: 18px;
        }

        .brand {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            text-decoration: none;
            color: var(--text);
            font-weight: 700;
            font-size: 18px;
        }

        .brand img {
            width: 40px;
            height: 40px;
            object-fit: contain;
        }

        .top-links {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .top-link {
            text-decoration: none;
            color: var(--text);
            border: 1px solid var(--border);
            border-radius: 999px;
            padding: 9px 14px;
            font-size: 14px;
            font-weight: 600;
            background: #fff;
        }

        .top-link.admin {
            border-color: #fecaca;
            color: #b91c1c;
            background: #fff5f5;
        }

        .msg {
            border-radius: 10px;
            padding: 12px 14px;
            margin-bottom: 16px;
            font-size: 14px;
            border: 1px solid transparent;
        }

        .msg-success {
            color: var(--success);
            background: #f0fdf4;
            border-color: #bbf7d0;
        }

        .msg-error {
            color: var(--danger);
            background: #fef2f2;
            border-color: #fecaca;
        }

        .layout {
            display: grid;
            grid-template-columns: 320px 1fr;
            gap: 18px;
        }

        .card {
            background: var(--card);
            border: 1px solid var(--border);
            border-radius: 14px;
            padding: 18px;
        }

        .card h2 {
            margin: 0 0 14px;
            font-size: 18px;
        }

        .avatar-frame {
            width: 190px;
            height: 190px;
            margin: 0 auto 14px;
            border-radius: 50%;
            border: 3px solid var(--primary-soft);
            background: #f8fafc;
            overflow: hidden;
            position: relative;
        }

        .avatar-edit-img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            transform-origin: center center;
            transition: transform 0.15s ease;
        }

        .avatar-name {
            text-align: center;
            font-weight: 700;
            margin-bottom: 6px;
        }

        .avatar-file {
            text-align: center;
            color: var(--muted);
            font-size: 12px;
            margin-bottom: 14px;
        }

        .role-wrap {
            text-align: center;
            margin-bottom: 14px;
        }

        .role-badge {
            display: inline-flex;
            padding: 5px 10px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 700;
            background: #eef2ff;
            color: #3730a3;
            text-transform: uppercase;
        }

        .role-badge.admin {
            background: #fee2e2;
            color: #b91c1c;
        }

        .control-group {
            margin-bottom: 12px;
        }

        .control-group label {
            display: block;
            font-size: 13px;
            color: var(--muted);
            margin-bottom: 6px;
            font-weight: 600;
        }

        .control-group input[type="range"] {
            width: 100%;
        }

        .btn-row {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
        }

        button, .button {
            border: 1px solid var(--border);
            background: #fff;
            color: var(--text);
            padding: 9px 12px;
            border-radius: 9px;
            font-weight: 600;
            cursor: pointer;
            font-size: 13px;
            text-decoration: none;
        }

        button.primary {
            background: var(--primary);
            color: #fff;
            border-color: var(--primary);
        }

        button.danger {
            border-color: #fecaca;
            color: #b91c1c;
            background: #fff5f5;
        }

        .section { margin-bottom: 16px; }

        .section h3 {
            margin: 0 0 12px;
            font-size: 16px;
        }

        .grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
        }

        .field {
            margin-bottom: 12px;
        }

        .field.full { grid-column: 1 / -1; }

        .field label {
            display: block;
            font-size: 13px;
            margin-bottom: 5px;
            color: var(--muted);
            font-weight: 600;
        }

        .field input {
            width: 100%;
            border: 1px solid var(--border);
            border-radius: 9px;
            padding: 10px 12px;
            font-size: 14px;
        }

        .hint {
            color: var(--muted);
            font-size: 12px;
            margin-top: 4px;
        }

        .otp-box {
            border: 1px dashed #cbd5e1;
            border-radius: 10px;
            padding: 10px;
            margin-top: 10px;
            background: #f8fafc;
            display: none;
        }

        .otp-box.show {
            display: block;
        }

        .confirm-box {
            border: 1px solid #fde68a;
            background: #fffbeb;
            border-radius: 10px;
            padding: 12px;
            margin-top: 10px;
        }

        .actions {
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            margin-top: 14px;
            flex-wrap: wrap;
        }

        @media (max-width: 767px) {
            body { padding: 10px; }
            .topbar {
                padding: 12px;
                flex-direction: column;
                align-items: flex-start;
                gap: 10px;
            }
            .layout {
                grid-template-columns: 1fr;
            }
            .grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
<div class="page">
    <header class="topbar">
        <a class="brand" href="<%= contextPath %>/shop/">
            <img src="<%= contextPath %>/assets/images/logo/logo.png" alt="Dosmé" onerror="this.style.display='none'">
            <span>Dosmé</span>
        </a>
        <div class="top-links">
            <a class="top-link" href="<%= contextPath %>/shop/">Trang chủ</a>
            <% if (isAdmin) { %>
                <a class="top-link admin" href="<%= contextPath %>/admin/" target="_blank" rel="noopener">Trang quản trị</a>
            <% } %>
        </div>
    </header>

    <% if (msg != null && !msg.isEmpty()) { %>
        <div class="msg msg-<%= msgType %>"><%= msg %></div>
    <% } %>

    <div class="layout">
        <aside class="card">
            <h2>Ảnh đại diện</h2>
            <form id="avatarForm" method="post" action="<%= contextPath %>/upload-avatar" enctype="multipart/form-data">
                <div class="avatar-frame">
                    <img id="avatarEditImage" class="avatar-edit-img" src="<%= avatarUrl %>" alt="Avatar" onerror="this.src='<%= contextPath %>/assets/images/avt/default.png'">
                </div>
                <div class="avatar-name">@<%= user.getUserName() %></div>
                <div class="avatar-file">Tệp hiện tại: <%= avatarFile %></div>

                <% if (hasRole) { %>
                    <div class="role-wrap">
                        <span class="role-badge <%= isAdmin ? "admin" : "" %>"><%= isAdmin ? "Admin" : roleRaw %></span>
                    </div>
                <% } %>

                <input type="file" id="avatarFile" name="avatarFile" accept="image/*" style="display:none;">

                <div class="control-group">
                    <label for="avatarZoom">Phóng to ảnh</label>
                    <input type="range" id="avatarZoom" min="1" max="2.5" value="1" step="0.05">
                </div>
                <div class="control-group">
                    <label for="avatarMoveX">Dịch trái/phải</label>
                    <input type="range" id="avatarMoveX" min="-40" max="40" value="0" step="1">
                </div>
                <div class="control-group">
                    <label for="avatarMoveY">Dịch trên/dưới</label>
                    <input type="range" id="avatarMoveY" min="-40" max="40" value="0" step="1">
                </div>

                <div class="btn-row">
                    <button type="button" id="changeAvatarBtn">Đổi ảnh</button>
                    <button type="submit" class="primary" id="saveAvatarBtn" disabled>Lưu</button>
                    <button type="button" class="danger" id="cancelAvatarBtn">Hủy</button>
                </div>
            </form>
        </aside>

        <section class="card">
            <h2>Thông tin cá nhân</h2>
            <form id="profileForm" method="post">
                <div class="section">
                    <h3>Thông tin cơ bản</h3>
                    <div class="grid">
                        <div class="field">
                            <label for="userName">Username</label>
                            <input id="userName" name="userName" type="text" value="<%= formUserName %>" minlength="3" maxlength="15" pattern="^[A-Za-z][A-Za-z0-9_.-]{2,14}$" required>
                            <div class="hint">3-15 ký tự, bắt đầu bằng chữ, cho phép: chữ/số/_/./-</div>
                        </div>
                        <div class="field">
                            <label for="fullName">Tên hiển thị</label>
                            <input id="fullName" name="fullName" type="text" value="<%= formFullName %>">
                        </div>
                        <div class="field">
                            <label for="phone">Số điện thoại</label>
                            <input id="phone" name="phone" type="text" value="<%= formPhone %>">
                        </div>
                        <div class="field">
                            <label for="email">Email</label>
                            <input id="email" name="email" type="email" value="<%= formEmail %>" required>
                            <div class="hint">Nếu đổi email, OTP sẽ gửi đến email cũ hiện tại.</div>
                            <div id="emailOtpBox" class="otp-box <%= showEmailOtp ? "show" : "" %>">
                                <div class="field full" style="margin-bottom:8px;">
                                    <label for="otpEmail">OTP đổi email</label>
                                    <input id="otpEmail" name="otpEmail" type="text" value="<%= otpEmail %>" maxlength="6" placeholder="Nhập OTP 6 số">
                                </div>
                                <button type="submit" name="action" value="request_otp_email_change">Gửi OTP về email cũ</button>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="section">
                    <h3>Đổi mật khẩu</h3>
                    <div class="grid">
                        <div class="field">
                            <label for="newPassword">Mật khẩu mới</label>
                            <input id="newPassword" name="newPassword" type="password" value="<%= newPassword %>" minlength="6" placeholder="Tối thiểu 6 ký tự">
                        </div>
                        <div class="field" id="confirmPasswordField" style="display:<%= newPassword.trim().isEmpty() ? "none" : "block" %>">
                            <label for="confirmPassword">Xác nhận mật khẩu mới</label>
                            <input id="confirmPassword" name="confirmPassword" type="password" value="<%= confirmPassword %>">
                        </div>
                    </div>

                    <div id="passwordOtpBox" class="otp-box <%= showPasswordOtp ? "show" : "" %>">
                        <div class="field full" style="margin-bottom:8px;">
                            <label for="otpPassword">OTP đổi mật khẩu</label>
                            <input id="otpPassword" name="otpPassword" type="text" value="<%= otpPassword %>" maxlength="6" placeholder="Nhập OTP 6 số">
                        </div>
                        <button type="submit" name="action" value="request_otp_password_change">Gửi OTP về email cũ</button>
                    </div>
                </div>

                <div class="confirm-box">
                    <div class="field" style="margin: 0;">
                        <label for="currentPassword">Mật khẩu hiện tại (bắt buộc khi lưu thay đổi)</label>
                        <input id="currentPassword" name="currentPassword" type="password" value="<%= currentPassword %>" placeholder="Nhập mật khẩu hiện tại">
                    </div>
                </div>

                <div class="actions">
                    <button type="button" class="danger" id="cancelProfileBtn">Hủy</button>
                    <button type="submit" class="primary" name="action" value="save_profile">Lưu</button>
                </div>
            </form>
        </section>
    </div>
</div>

<script>
(function () {
    const profileForm = document.getElementById('profileForm');
    const avatarForm = document.getElementById('avatarForm');

    const userNameInput = document.getElementById('userName');
    const fullNameInput = document.getElementById('fullName');
    const phoneInput = document.getElementById('phone');
    const emailInput = document.getElementById('email');
    const newPasswordInput = document.getElementById('newPassword');
    const confirmPasswordInput = document.getElementById('confirmPassword');
    const currentPasswordInput = document.getElementById('currentPassword');
    const otpEmailInput = document.getElementById('otpEmail');
    const otpPasswordInput = document.getElementById('otpPassword');

    const emailOtpBox = document.getElementById('emailOtpBox');
    const passwordOtpBox = document.getElementById('passwordOtpBox');
    const confirmPasswordField = document.getElementById('confirmPasswordField');

    const initialProfile = {
        userName: userNameInput.value,
        fullName: fullNameInput.value,
        phone: phoneInput.value,
        email: emailInput.value,
        newPassword: '',
        confirmPassword: '',
        currentPassword: '',
        otpEmail: otpEmailInput ? otpEmailInput.value : '',
        otpPassword: otpPasswordInput ? otpPasswordInput.value : ''
    };

    const initialAvatarSrc = document.getElementById('avatarEditImage').src;
    const avatarFileInput = document.getElementById('avatarFile');
    const saveAvatarBtn = document.getElementById('saveAvatarBtn');
    const changeAvatarBtn = document.getElementById('changeAvatarBtn');
    const cancelAvatarBtn = document.getElementById('cancelAvatarBtn');
    const avatarPreview = document.getElementById('avatarEditImage');
    const avatarZoom = document.getElementById('avatarZoom');
    const avatarMoveX = document.getElementById('avatarMoveX');
    const avatarMoveY = document.getElementById('avatarMoveY');

    function hasProfileChange() {
        return userNameInput.value !== initialProfile.userName
            || fullNameInput.value !== initialProfile.fullName
            || phoneInput.value !== initialProfile.phone
            || emailInput.value !== initialProfile.email
            || newPasswordInput.value.trim() !== ''
            || confirmPasswordInput.value.trim() !== ''
            || currentPasswordInput.value.trim() !== ''
            || (otpEmailInput && otpEmailInput.value.trim() !== initialProfile.otpEmail)
            || (otpPasswordInput && otpPasswordInput.value.trim() !== initialProfile.otpPassword);
    }

    function hasAvatarChange() {
        return avatarFileInput.files.length > 0
            || avatarZoom.value !== '1'
            || avatarMoveX.value !== '0'
            || avatarMoveY.value !== '0';
    }

    function updateAvatarTransform() {
        const zoom = parseFloat(avatarZoom.value);
        const moveX = parseFloat(avatarMoveX.value);
        const moveY = parseFloat(avatarMoveY.value);
        avatarPreview.style.transform = 'translate(' + moveX + 'px, ' + moveY + 'px) scale(' + zoom + ')';
    }

    function updateOtpVisibility() {
        const emailChanged = emailInput.value.trim().toLowerCase() !== initialProfile.email.trim().toLowerCase();
        const hasPassword = newPasswordInput.value.trim() !== '';

        confirmPasswordField.style.display = hasPassword ? 'block' : 'none';

        if (emailChanged || (otpEmailInput && otpEmailInput.value.trim() !== '')) {
            emailOtpBox.classList.add('show');
        } else {
            emailOtpBox.classList.remove('show');
        }

        if (hasPassword || (otpPasswordInput && otpPasswordInput.value.trim() !== '')) {
            passwordOtpBox.classList.add('show');
        } else {
            passwordOtpBox.classList.remove('show');
        }
    }

    [emailInput, newPasswordInput, confirmPasswordInput].forEach(function (el) {
        el.addEventListener('input', updateOtpVisibility);
    });

    [avatarZoom, avatarMoveX, avatarMoveY].forEach(function (el) {
        el.addEventListener('input', updateAvatarTransform);
    });

    changeAvatarBtn.addEventListener('click', function () {
        avatarFileInput.click();
    });

    avatarFileInput.addEventListener('change', function () {
        if (avatarFileInput.files.length === 0) {
            saveAvatarBtn.disabled = true;
            return;
        }

        const file = avatarFileInput.files[0];
        const reader = new FileReader();
        reader.onload = function (e) {
            avatarPreview.src = e.target.result;
            saveAvatarBtn.disabled = false;
            avatarZoom.value = '1';
            avatarMoveX.value = '0';
            avatarMoveY.value = '0';
            updateAvatarTransform();
        };
        reader.readAsDataURL(file);
    });

    cancelAvatarBtn.addEventListener('click', function () {
        if (!hasAvatarChange()) {
            return;
        }
        if (!window.confirm('Bạn có thay đổi ảnh chưa lưu. Hủy thay đổi này?')) {
            return;
        }

        avatarFileInput.value = '';
        avatarPreview.src = initialAvatarSrc;
        avatarZoom.value = '1';
        avatarMoveX.value = '0';
        avatarMoveY.value = '0';
        updateAvatarTransform();
        saveAvatarBtn.disabled = true;
    });

    document.getElementById('cancelProfileBtn').addEventListener('click', function () {
        if (!hasProfileChange()) {
            return;
        }
        if (!window.confirm('Bạn có thay đổi chưa lưu. Hủy và khôi phục dữ liệu ban đầu?')) {
            return;
        }

        profileForm.reset();
        userNameInput.value = initialProfile.userName;
        fullNameInput.value = initialProfile.fullName;
        phoneInput.value = initialProfile.phone;
        emailInput.value = initialProfile.email;
        newPasswordInput.value = '';
        confirmPasswordInput.value = '';
        currentPasswordInput.value = '';
        if (otpEmailInput) otpEmailInput.value = '';
        if (otpPasswordInput) otpPasswordInput.value = '';
        updateOtpVisibility();
    });

    window.addEventListener('beforeunload', function (event) {
        if (!hasProfileChange() && !hasAvatarChange()) {
            return;
        }
        event.preventDefault();
        event.returnValue = '';
    });

    avatarForm.addEventListener('submit', function (event) {
        if (!hasAvatarChange()) {
            event.preventDefault();
            return;
        }
        if (!window.confirm('Lưu ảnh đại diện mới?')) {
            event.preventDefault();
        }
    });

    updateOtpVisibility();
    updateAvatarTransform();
})();
</script>
</body>
</html>
