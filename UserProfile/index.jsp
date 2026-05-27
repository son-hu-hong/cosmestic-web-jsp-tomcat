<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="database.Users"%>
<%@page import="service.OTP"%>
<%@page import="service.MailSender"%>
<%@page import="service.PasswordUtil"%>
<%@page import="java.time.Duration"%>
<%@page import="java.net.URLEncoder"%>
<%!
    private String esc(String value) {
        if (value == null) return "";
        return value
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }
%>
<%
    String contextPath = request.getContextPath();
    Users sessionUser = (Users) session.getAttribute("user");
    if (sessionUser == null) {
        String redirect = URLEncoder.encode(request.getRequestURI(), "UTF-8");
        response.sendRedirect(contextPath + "/login/?redirect=" + redirect);
        return;
    }

    Users dao = new Users();
    Users currentUser = dao.getUserById(sessionUser.getUserId());
    if (currentUser == null) {
        session.removeAttribute("user");
        response.sendRedirect(contextPath + "/login/");
        return;
    }

    String success = "";
    String error = "";
    String info = "";
    String uploadMsg = request.getParameter("msg");
    if ("success".equals(uploadMsg)) {
        success = "Cập nhật ảnh đại diện thành công.";
    } else if ("error_file".equals(uploadMsg)) {
        error = "Vui lòng chọn tệp ảnh hợp lệ.";
    } else if ("db_error".equals(uploadMsg) || "upload_failed".equals(uploadMsg)) {
        error = "Không thể cập nhật ảnh đại diện. Vui lòng thử lại.";
    }

    String userName = currentUser.getUserName() == null ? "" : currentUser.getUserName();
    String fullName = currentUser.getFullName() == null ? "" : currentUser.getFullName();
    String userEmail = currentUser.getUserEmail() == null ? "" : currentUser.getUserEmail();
    String userPhone = currentUser.getUserPhone() == null ? "" : currentUser.getUserPhone();
    String userAddress = currentUser.getUserAddress() == null ? "" : currentUser.getUserAddress();
    String userSexual = currentUser.getUserSexual() == null ? "default" : currentUser.getUserSexual();

    String emailOtp = "";
    String passwordOtp = "";
    String newPassword = "";
    String confirmNewPassword = "";
    String currentPassword = "";
    String newPasswordHash = "";

    String verifiedEmail = (String) session.getAttribute("profileVerifiedEmail");
    String verifiedPasswordHash = (String) session.getAttribute("profileVerifiedPasswordHash");

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String reqUserName = request.getParameter("userName");
        String reqFullName = request.getParameter("fullName");
        String reqUserEmail = request.getParameter("userEmail");
        String reqUserPhone = request.getParameter("userPhone");
        String reqUserAddress = request.getParameter("userAddress");
        String reqUserSexual = request.getParameter("userSexual");

        userName = reqUserName == null ? "" : reqUserName.trim();
        fullName = reqFullName == null ? "" : reqFullName.trim();
        userEmail = reqUserEmail == null ? "" : reqUserEmail.trim();
        userPhone = reqUserPhone == null ? "" : reqUserPhone.trim();
        userAddress = reqUserAddress == null ? "" : reqUserAddress.trim();
        userSexual = reqUserSexual == null ? "default" : reqUserSexual.trim();

        if (!"male".equals(userSexual) && !"female".equals(userSexual)) {
            userSexual = "default";
        }

        emailOtp = request.getParameter("emailOtp") == null ? "" : request.getParameter("emailOtp").trim();
        passwordOtp = request.getParameter("passwordOtp") == null ? "" : request.getParameter("passwordOtp").trim();
        newPassword = request.getParameter("newPassword") == null ? "" : request.getParameter("newPassword");
        confirmNewPassword = request.getParameter("confirmNewPassword") == null ? "" : request.getParameter("confirmNewPassword");
        currentPassword = request.getParameter("currentPassword") == null ? "" : request.getParameter("currentPassword");
        newPasswordHash = newPassword.isEmpty() ? "" : PasswordUtil.hashPassword(newPassword);

        String action = request.getParameter("action");

        try {
            if ("send_email_otp".equals(action)) {
                if (userEmail.isEmpty() || !userEmail.contains("@")) {
                    error = "Email mới không hợp lệ.";
                } else if (userEmail.equalsIgnoreCase(currentUser.getUserEmail())) {
                    error = "Email chưa thay đổi nên không cần OTP.";
                } else if (dao.checkEmailExists(userEmail, currentUser.getUserId())) {
                    error = "Email đã được sử dụng bởi tài khoản khác.";
                } else {
                    OTP.CreateOtpResult otpResult = OTP.createOtp(currentUser.getUserId(), userEmail, OTP.TYPE_CHANGE_EMAIL, Duration.ofMinutes(5), request.getRemoteAddr());
                    MailSender.sendOtpEmail(userEmail, otpResult.otpPlain, OTP.TYPE_CHANGE_EMAIL, 5);
                    session.removeAttribute("profileVerifiedEmail");
                    verifiedEmail = null;
                    info = "Đã gửi OTP xác minh đổi email đến " + userEmail;
                }
            } else if ("verify_email_otp".equals(action)) {
                if (userEmail.isEmpty() || userEmail.equalsIgnoreCase(currentUser.getUserEmail())) {
                    error = "Vui lòng nhập email mới trước khi xác minh OTP.";
                } else if (emailOtp.isEmpty()) {
                    error = "Vui lòng nhập OTP email.";
                } else if (OTP.verifyOtp(userEmail, emailOtp, OTP.TYPE_CHANGE_EMAIL)) {
                    session.setAttribute("profileVerifiedEmail", userEmail);
                    verifiedEmail = userEmail;
                    success = "Xác minh OTP đổi email thành công.";
                } else {
                    error = "OTP email không hợp lệ hoặc đã hết hạn.";
                }
            } else if ("send_password_otp".equals(action)) {
                if (newPassword.isEmpty()) {
                    error = "Vui lòng nhập mật khẩu mới.";
                } else if (!newPassword.equals(confirmNewPassword)) {
                    error = "Xác nhận mật khẩu mới không khớp.";
                } else {
                    OTP.CreateOtpResult otpResult = OTP.createOtp(currentUser.getUserId(), currentUser.getUserEmail(), OTP.TYPE_CHANGE_PASSWORD, Duration.ofMinutes(5), request.getRemoteAddr());
                    MailSender.sendOtpEmail(currentUser.getUserEmail(), otpResult.otpPlain, OTP.TYPE_CHANGE_PASSWORD, 5);
                    session.removeAttribute("profileVerifiedPasswordHash");
                    verifiedPasswordHash = null;
                    info = "Đã gửi OTP đổi mật khẩu tới email hiện tại của bạn.";
                }
            } else if ("verify_password_otp".equals(action)) {
                if (newPassword.isEmpty()) {
                    error = "Vui lòng nhập mật khẩu mới trước khi xác minh OTP.";
                } else if (!newPassword.equals(confirmNewPassword)) {
                    error = "Xác nhận mật khẩu mới không khớp.";
                } else if (passwordOtp.isEmpty()) {
                    error = "Vui lòng nhập OTP đổi mật khẩu.";
                } else if (OTP.verifyOtp(currentUser.getUserEmail(), passwordOtp, OTP.TYPE_CHANGE_PASSWORD)) {
                    verifiedPasswordHash = newPasswordHash;
                    session.setAttribute("profileVerifiedPasswordHash", verifiedPasswordHash);
                    success = "Xác minh OTP đổi mật khẩu thành công.";
                } else {
                    error = "OTP đổi mật khẩu không hợp lệ hoặc đã hết hạn.";
                }
            } else if ("save_profile".equals(action)) {
                boolean usernameChanged = !userName.equals((currentUser.getUserName() == null ? "" : currentUser.getUserName()));
                boolean emailChanged = !userEmail.equalsIgnoreCase((currentUser.getUserEmail() == null ? "" : currentUser.getUserEmail()));
                boolean passwordChanged = !newPassword.isEmpty();
                boolean sensitiveChanged = usernameChanged || emailChanged || passwordChanged;

                if (userName.isEmpty() || fullName.isEmpty() || userEmail.isEmpty()) {
                    error = "Tên đăng nhập, họ tên và email là bắt buộc.";
                } else if (dao.checkUserNameExists(userName, currentUser.getUserId())) {
                    error = "Tên đăng nhập đã tồn tại.";
                } else if (emailChanged && dao.checkEmailExists(userEmail, currentUser.getUserId())) {
                    error = "Email đã được sử dụng bởi tài khoản khác.";
                } else if (emailChanged && (verifiedEmail == null || !verifiedEmail.equalsIgnoreCase(userEmail))) {
                    error = "Vui lòng xác minh OTP cho email mới trước khi lưu.";
                } else if (passwordChanged && !newPassword.equals(confirmNewPassword)) {
                    error = "Xác nhận mật khẩu mới không khớp.";
                } else if (passwordChanged && (verifiedPasswordHash == null || !verifiedPasswordHash.equals(newPasswordHash))) {
                    error = "Vui lòng xác minh OTP đổi mật khẩu trước khi lưu.";
                } else if (sensitiveChanged && (currentPassword.isEmpty() || !PasswordUtil.hashPassword(currentPassword).equals(currentUser.getPassword()))) {
                    error = "Bạn cần nhập đúng mật khẩu hiện tại để xác nhận thay đổi nhạy cảm.";
                } else {
                    String hashedPasswordToSave = passwordChanged ? newPasswordHash : currentUser.getPassword();
                    boolean updated = dao.updateProfileAccount(currentUser.getUserId(), userName, fullName, userSexual, userEmail, userPhone, userAddress, hashedPasswordToSave);
                    if (updated) {
                        currentUser = dao.getUserById(currentUser.getUserId());
                        session.setAttribute("user", currentUser);
                        session.removeAttribute("profileVerifiedEmail");
                        session.removeAttribute("profileVerifiedPasswordHash");
                        verifiedEmail = null;
                        verifiedPasswordHash = null;
                        success = "Đã lưu thông tin tài khoản thành công.";
                        userName = currentUser.getUserName() == null ? "" : currentUser.getUserName();
                        fullName = currentUser.getFullName() == null ? "" : currentUser.getFullName();
                        userEmail = currentUser.getUserEmail() == null ? "" : currentUser.getUserEmail();
                        userPhone = currentUser.getUserPhone() == null ? "" : currentUser.getUserPhone();
                        userAddress = currentUser.getUserAddress() == null ? "" : currentUser.getUserAddress();
                        userSexual = currentUser.getUserSexual() == null ? "default" : currentUser.getUserSexual();
                        newPassword = "";
                        confirmNewPassword = "";
                        currentPassword = "";
                    } else {
                        error = "Không thể lưu thông tin. Vui lòng thử lại.";
                    }
                }
            }
        } catch (Exception ex) {
            error = "Lỗi hệ thống: " + ex.getMessage();
        }
    }

    String role = currentUser.getRole() == null ? "" : currentUser.getRole();
    boolean isAdmin = "admin".equalsIgnoreCase(role);
    String avatarFile = currentUser.getAvtUrl() == null || currentUser.getAvtUrl().trim().isEmpty() ? "default.png" : currentUser.getAvtUrl().trim();
    String avatarUrl = contextPath + "/assets/images/avt/" + avatarFile;
    String sexualLabel = "Chưa cập nhật";
    if ("male".equalsIgnoreCase(currentUser.getUserSexual())) {
        sexualLabel = "Nam";
    } else if ("female".equalsIgnoreCase(currentUser.getUserSexual())) {
        sexualLabel = "Nữ";
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
            --bg: #f7f7f9;
            --card: #fff;
            --text: #1f2937;
            --muted: #6b7280;
            --line: #e5e7eb;
            --primary: #111827;
            --accent: #b08d57;
            --danger: #c92a2a;
            --success: #2b8a3e;
            --info: #1864ab;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: 'Segoe UI', Arial, sans-serif;
            background: var(--bg);
            color: var(--text);
        }
        .topbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 14px 24px;
            background: #fff;
            border-bottom: 1px solid var(--line);
            position: sticky;
            top: 0;
            z-index: 10;
        }
        .topbar img { height: 42px; object-fit: contain; }
        .top-links { display: flex; gap: 12px; align-items: center; }
        .top-links a {
            text-decoration: none;
            color: var(--primary);
            background: #f3f4f6;
            border-radius: 10px;
            padding: 10px 14px;
            font-size: 14px;
            font-weight: 600;
        }
        .container {
            max-width: 1100px;
            margin: 24px auto;
            padding: 0 16px 24px;
            display: grid;
            gap: 16px;
            grid-template-columns: 330px 1fr;
        }
        .card {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 16px;
            box-shadow: 0 8px 25px rgba(0,0,0,0.04);
            padding: 20px;
        }
        .profile-top { text-align: center; }
        .avatar-wrap {
            width: 124px;
            height: 124px;
            border-radius: 50%;
            overflow: hidden;
            margin: 0 auto 12px;
            border: 3px solid #f3f4f6;
        }
        .avatar-wrap img { width: 100%; height: 100%; object-fit: cover; }
        .btn {
            border: none;
            border-radius: 10px;
            padding: 11px 14px;
            cursor: pointer;
            font-weight: 600;
        }
        .btn-dark { background: var(--primary); color: #fff; }
        .btn-soft { background: #eef2ff; color: #243b7a; }
        .btn-danger { background: #fff5f5; color: var(--danger); }
        .badge {
            display: inline-flex;
            align-items: center;
            border-radius: 999px;
            padding: 5px 10px;
            font-size: 12px;
            font-weight: 700;
            margin-left: 6px;
            background: #ede9fe;
            color: #5f3dc4;
        }
        .meta-list { margin-top: 14px; }
        .meta-row {
            display: flex;
            justify-content: space-between;
            gap: 12px;
            border-top: 1px dashed var(--line);
            padding: 10px 0;
            font-size: 14px;
        }
        .meta-row span:first-child { color: var(--muted); }
        .notice {
            border-radius: 10px;
            padding: 10px 12px;
            margin-bottom: 12px;
            font-size: 14px;
        }
        .notice.error { background: #fff5f5; color: var(--danger); border: 1px solid #ffe3e3; }
        .notice.success { background: #ebfbee; color: var(--success); border: 1px solid #d3f9d8; }
        .notice.info { background: #e7f5ff; color: var(--info); border: 1px solid #d0ebff; }
        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 14px;
        }
        .form-group { display: flex; flex-direction: column; gap: 6px; }
        .full { grid-column: 1 / -1; }
        label { font-size: 13px; color: var(--muted); font-weight: 600; }
        input, select, textarea {
            border: 1px solid var(--line);
            border-radius: 10px;
            padding: 10px 12px;
            font-size: 14px;
            background: #fff;
        }
        textarea { min-height: 84px; resize: vertical; }
        .otp-box {
            border: 1px dashed #c7d2fe;
            background: #f8faff;
            border-radius: 12px;
            padding: 10px;
            display: none;
            gap: 10px;
            margin-top: 8px;
        }
        .otp-box.active { display: grid; }
        .otp-actions { display: flex; gap: 8px; flex-wrap: wrap; }
        .actions {
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            margin-top: 16px;
            border-top: 1px solid var(--line);
            padding-top: 14px;
        }
        .modal {
            position: fixed;
            inset: 0;
            background: rgba(17, 24, 39, 0.45);
            display: none;
            align-items: center;
            justify-content: center;
            padding: 16px;
            z-index: 20;
        }
        .modal.show { display: flex; }
        .modal-card {
            width: 100%;
            max-width: 720px;
            background: #fff;
            border-radius: 14px;
            padding: 16px;
        }
        .preview-grid {
            display: grid;
            gap: 12px;
            grid-template-columns: 1fr 1fr;
            margin: 14px 0;
        }
        .preview-box {
            border: 1px solid var(--line);
            border-radius: 12px;
            min-height: 220px;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
            background: #f8fafc;
        }
        .preview-box img {
            max-width: 100%;
            max-height: 100%;
            transform-origin: center;
            transition: transform .2s ease;
        }
        .slider { width: 100%; }
        .modal-actions { display: flex; justify-content: flex-end; gap: 10px; }

        @media (max-width: 900px) {
            .container { grid-template-columns: 1fr; }
            .form-grid, .preview-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <header class="topbar">
        <a href="<%= contextPath %>/shop/"><img src="<%= contextPath %>/assets/images/logo/logo.png" alt="Dosmé"></a>
        <div class="top-links">
            <a href="<%= contextPath %>/shop/">Cửa hàng</a>
            <% if (isAdmin) { %>
                <a href="<%= contextPath %>/admin/" target="_blank" rel="noopener">Trang quản trị</a>
            <% } %>
        </div>
    </header>

    <main class="container">
        <section class="card profile-top">
            <div class="avatar-wrap"><img id="currentAvatar" src="<%= esc(avatarUrl) %>" alt="Avatar"></div>
            <h2 style="margin:8px 0 0;"><%= esc(fullName.isEmpty() ? userName : fullName) %>
                <% if (isAdmin) { %><span class="badge">ADMIN</span><% } %>
            </h2>
            <p style="margin:8px 0;color:var(--muted)">@<%= esc(userName) %></p>
            <button type="button" class="btn btn-soft" id="openAvatarModal">Chỉnh sửa ảnh đại diện</button>

            <div class="meta-list">
                <div class="meta-row"><span>Giới tính</span><span><%= sexualLabel %></span></div>
                <div class="meta-row"><span>Email</span><span><%= esc(currentUser.getUserEmail() == null ? "-" : currentUser.getUserEmail()) %></span></div>
                <div class="meta-row"><span>Điện thoại</span><span><%= esc(currentUser.getUserPhone() == null || currentUser.getUserPhone().trim().isEmpty() ? "-" : currentUser.getUserPhone()) %></span></div>
                <div class="meta-row"><span>Địa chỉ</span><span><%= esc(currentUser.getUserAddress() == null || currentUser.getUserAddress().trim().isEmpty() ? "-" : currentUser.getUserAddress()) %></span></div>
                <div class="meta-row"><span>Trạng thái</span><span><%= currentUser.getDisable() == 1 ? "Đã khóa" : "Hoạt động" %></span></div>
                <div class="meta-row"><span>Số dư</span><span><%= String.format("%,d", currentUser.getUserBalance()) %> VNĐ</span></div>
            </div>
        </section>

        <section class="card">
            <h2 style="margin-top:0;">Thông tin cá nhân</h2>

            <% if (!error.isEmpty()) { %><div class="notice error"><%= esc(error) %></div><% } %>
            <% if (!success.isEmpty()) { %><div class="notice success"><%= esc(success) %></div><% } %>
            <% if (!info.isEmpty()) { %><div class="notice info"><%= esc(info) %></div><% } %>

            <form id="profileForm" method="post">
                <input type="hidden" name="action" id="profileAction" value="save_profile">

                <div class="form-grid">
                    <div class="form-group">
                        <label for="userName">Tên đăng nhập</label>
                        <input type="text" id="userName" name="userName" value="<%= esc(userName) %>" required>
                    </div>
                    <div class="form-group">
                        <label for="fullName">Tên hiển thị</label>
                        <input type="text" id="fullName" name="fullName" value="<%= esc(fullName) %>" required>
                    </div>
                    <div class="form-group">
                        <label for="userPhone">Số điện thoại</label>
                        <input type="text" id="userPhone" name="userPhone" value="<%= esc(userPhone) %>">
                    </div>
                    <div class="form-group">
                        <label for="userSexual">Giới tính</label>
                        <select id="userSexual" name="userSexual">
                            <option value="default" <%= "default".equals(userSexual) ? "selected" : "" %>>Chưa cập nhật</option>
                            <option value="male" <%= "male".equals(userSexual) ? "selected" : "" %>>Nam</option>
                            <option value="female" <%= "female".equals(userSexual) ? "selected" : "" %>>Nữ</option>
                        </select>
                    </div>
                    <div class="form-group full">
                        <label for="userEmail">Email</label>
                        <input type="email" id="userEmail" name="userEmail" value="<%= esc(userEmail) %>" required data-original="<%= esc(currentUser.getUserEmail() == null ? "" : currentUser.getUserEmail()) %>">
                        <div id="emailOtpBox" class="otp-box">
                            <label for="emailOtp" style="margin:0;">OTP đổi email</label>
                            <input type="text" id="emailOtp" name="emailOtp" value="<%= esc(emailOtp) %>" placeholder="Nhập OTP 6 số" maxlength="6">
                            <div class="otp-actions">
                                <button type="submit" class="btn btn-soft" data-action="send_email_otp">Gửi OTP</button>
                                <button type="submit" class="btn btn-soft" data-action="verify_email_otp">Xác minh OTP email</button>
                            </div>
                            <div style="font-size:12px;color:var(--muted)">
                                <% if (verifiedEmail != null && verifiedEmail.equalsIgnoreCase(userEmail)) { %>
                                    Đã xác minh email mới.
                                <% } else { %>
                                    Đổi email bắt buộc phải gửi và xác minh OTP trước khi lưu.
                                <% } %>
                            </div>
                        </div>
                    </div>
                    <div class="form-group full">
                        <label for="userAddress">Địa chỉ</label>
                        <textarea id="userAddress" name="userAddress"><%= esc(userAddress) %></textarea>
                    </div>

                    <div class="form-group">
                        <label for="newPassword">Mật khẩu mới</label>
                        <input type="password" id="newPassword" name="newPassword" autocomplete="new-password" placeholder="Để trống nếu không đổi">
                    </div>
                    <div class="form-group" id="confirmPasswordGroup">
                        <label for="confirmNewPassword">Xác nhận mật khẩu mới</label>
                        <input type="password" id="confirmNewPassword" name="confirmNewPassword" autocomplete="new-password">
                    </div>

                    <div id="passwordOtpBox" class="otp-box full">
                        <label for="passwordOtp" style="margin:0;">OTP đổi mật khẩu</label>
                        <input type="text" id="passwordOtp" name="passwordOtp" value="<%= esc(passwordOtp) %>" placeholder="Nhập OTP 6 số" maxlength="6">
                        <div class="otp-actions">
                            <button type="submit" class="btn btn-soft" data-action="send_password_otp">Gửi OTP</button>
                            <button type="submit" class="btn btn-soft" data-action="verify_password_otp">Xác minh OTP mật khẩu</button>
                        </div>
                        <div style="font-size:12px;color:var(--muted)">
                            <% if (verifiedPasswordHash != null && !newPassword.isEmpty() && verifiedPasswordHash.equals(newPasswordHash)) { %>
                                OTP đổi mật khẩu đã được xác minh cho mật khẩu mới.
                            <% } else { %>
                                Đổi mật khẩu bắt buộc phải gửi và xác minh OTP trước khi lưu.
                            <% } %>
                        </div>
                    </div>

                    <div class="form-group full">
                        <label for="currentPassword">Mật khẩu hiện tại (bắt buộc khi đổi Username/Email/Mật khẩu)</label>
                        <input type="password" id="currentPassword" name="currentPassword" autocomplete="current-password" placeholder="Nhập khi thay đổi thông tin nhạy cảm">
                    </div>
                </div>

                <div class="actions">
                    <button type="button" class="btn btn-danger" id="cancelChanges">Hủy</button>
                    <button type="submit" class="btn btn-dark" data-action="save_profile">Lưu</button>
                </div>
            </form>
        </section>
    </main>

    <div id="avatarModal" class="modal" aria-hidden="true">
        <div class="modal-card">
            <h3 style="margin:0;">Cập nhật ảnh đại diện</h3>
            <p style="margin:8px 0 0;color:var(--muted)">Chọn ảnh mới, xem trước và căn chỉnh phóng to trước khi lưu.</p>

            <form id="avatarForm" method="post" action="<%= contextPath %>/upload-avatar" enctype="multipart/form-data">
                <input type="file" id="avatarFile" name="avatarFile" accept="image/*" style="display:none;">

                <div class="preview-grid">
                    <div class="preview-box"><img id="previewCurrent" src="<%= esc(avatarUrl) %>" alt="Ảnh hiện tại"></div>
                    <div class="preview-box"><img id="previewNew" src="<%= esc(avatarUrl) %>" alt="Ảnh mới"></div>
                </div>

                <label for="zoomRange">Thu phóng ảnh hiển thị</label>
                <input type="range" id="zoomRange" class="slider" min="1" max="2.2" step="0.1" value="1">

                <div class="modal-actions" style="margin-top:14px;">
                    <button type="button" class="btn btn-soft" id="chooseAvatarBtn">Đổi ảnh</button>
                    <button type="submit" class="btn btn-dark">Lưu</button>
                    <button type="button" class="btn btn-danger" id="cancelAvatarBtn">Hủy</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        (function () {
            const form = document.getElementById('profileForm');
            const actionInput = document.getElementById('profileAction');
            const emailInput = document.getElementById('userEmail');
            const newPasswordInput = document.getElementById('newPassword');
            const confirmNewPasswordInput = document.getElementById('confirmNewPassword');
            const confirmPasswordGroup = document.getElementById('confirmPasswordGroup');
            const emailOtpBox = document.getElementById('emailOtpBox');
            const passwordOtpBox = document.getElementById('passwordOtpBox');
            const cancelBtn = document.getElementById('cancelChanges');

            const tracked = form.querySelectorAll('input:not([type="hidden"]), select, textarea');
            const initialState = Array.from(tracked).map(el => el.name + ':' + el.value).join('|');
            let submitted = false;

            function isDirty() {
                const current = Array.from(tracked).map(el => el.name + ':' + el.value).join('|');
                return current !== initialState;
            }

            function toggleOtpBoxes() {
                const originalEmail = (emailInput.dataset.original || '').trim().toLowerCase();
                const nowEmail = (emailInput.value || '').trim().toLowerCase();
                emailOtpBox.classList.toggle('active', nowEmail !== '' && nowEmail !== originalEmail);

                const hasNewPassword = (newPasswordInput.value || '').trim().length > 0;
                const hasConfirm = (confirmNewPasswordInput.value || '').trim().length > 0;
                confirmPasswordGroup.style.display = (hasNewPassword || hasConfirm) ? 'flex' : 'none';
                passwordOtpBox.classList.toggle('active', hasNewPassword || hasConfirm);
            }

            form.addEventListener('submit', function (e) {
                const clicked = e.submitter;
                if (clicked && clicked.dataset && clicked.dataset.action) {
                    actionInput.value = clicked.dataset.action;
                }
                submitted = true;
            });

            window.addEventListener('beforeunload', function (e) {
                if (!submitted && isDirty()) {
                    e.preventDefault();
                    e.returnValue = '';
                }
            });

            cancelBtn.addEventListener('click', function () {
                if (!isDirty() || confirm('Bạn có thay đổi chưa lưu. Bạn có chắc muốn hủy?')) {
                    submitted = true;
                    window.location.reload();
                }
            });

            emailInput.addEventListener('input', toggleOtpBoxes);
            newPasswordInput.addEventListener('input', toggleOtpBoxes);
            confirmNewPasswordInput.addEventListener('input', toggleOtpBoxes);
            toggleOtpBoxes();
        })();

        (function () {
            const modal = document.getElementById('avatarModal');
            const openBtn = document.getElementById('openAvatarModal');
            const cancelBtn = document.getElementById('cancelAvatarBtn');
            const chooseBtn = document.getElementById('chooseAvatarBtn');
            const fileInput = document.getElementById('avatarFile');
            const previewNew = document.getElementById('previewNew');
            const previewCurrent = document.getElementById('previewCurrent');
            const zoomRange = document.getElementById('zoomRange');

            function applyZoom() {
                const scale = zoomRange.value;
                previewCurrent.style.transform = 'scale(' + scale + ')';
                previewNew.style.transform = 'scale(' + scale + ')';
            }

            openBtn.addEventListener('click', function () {
                modal.classList.add('show');
            });

            cancelBtn.addEventListener('click', function () {
                modal.classList.remove('show');
            });

            modal.addEventListener('click', function (e) {
                if (e.target === modal) {
                    modal.classList.remove('show');
                }
            });

            chooseBtn.addEventListener('click', function () {
                fileInput.click();
            });

            fileInput.addEventListener('change', function () {
                const file = this.files && this.files[0];
                if (!file) return;
                const objectUrl = URL.createObjectURL(file);
                previewNew.src = objectUrl;
            });

            zoomRange.addEventListener('input', applyZoom);
            applyZoom();
        })();
    </script>
</body>
</html>
