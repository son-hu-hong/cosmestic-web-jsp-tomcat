<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="database.Users"%>
<%@page import="service.PasswordUtil"%>

<%
    // 1. Kiểm tra đăng nhập [cite: 66]
    database.Users user = (database.Users) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect(request.getContextPath() + "/login/?redirect=" + request.getRequestURI());
        return;
    }

    String msg = "";
    String msgType = "";
    database.Users dao = new database.Users();

    // 2. Xử lý yêu cầu POST (Giữ nguyên logic xử lý của bạn) [cite: 69]
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");

        if ("update_gender_fast".equals(action)) {
            String newSexual = request.getParameter("userSexual");
            user.setUserSexual(newSexual);
            if (dao.updateUser(user)) {
                msg = "Đã cập nhật giới tính!";
                msgType = "success";
            }
        } else if ("update_info".equals(action)) {
            String currentPasswordInput = request.getParameter("currentPassword");
            String hashedInput = PasswordUtil.hashPassword(currentPasswordInput);
            
            if (!user.getPassword().equals(hashedInput)) {
                msg = "Mật khẩu hiện tại không chính xác!";
                msgType = "error";
            } else {
                // Lấy email mới từ form
                String newEmail = request.getParameter("email");
                boolean emailValid = true;

                // Kiểm tra nếu người dùng đổi sang email khác
                if (newEmail != null && !newEmail.equalsIgnoreCase(user.getUserEmail())) {
                    // Kiểm tra email mới đã tồn tại trong hệ thống chưa
                    if (dao.getUserByAny(newEmail) != null) {
                        msg = "Email này đã được sử dụng bởi tài khoản khác!";
                        msgType = "error";
                        emailValid = false;
                    } else {
                        user.setUserEmail(newEmail);
                    }
                }

                if (emailValid) {
                    user.setFullName(request.getParameter("fullName"));
                    user.setUserPhone(request.getParameter("phone"));
                    user.setUserAddress(request.getParameter("address"));
                    user.setUserSexual(request.getParameter("userSexual"));

                    String newPass = request.getParameter("newPassword");
                    if (newPass != null && !newPass.trim().isEmpty()) {
                        user.setPassword(PasswordUtil.hashPassword(newPass));
                    }

                    if (dao.updateUser(user)) {
                        msg = "Cập nhật thông tin thành công!";
                        msgType = "success";
                    } else {
                        msg = "Lỗi khi cập nhật dữ liệu.";
                        msgType = "error";
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
    <title>Thiết lập tài khoản - Dosmé</title>
    <style>
        /* CẤU HÌNH CHUNG [cite: 86] */
        :root {
            --primary-color: #000;
            --bg-color: #f8f9fa;
            --card-bg: #fff;
            --border-color: #eee;
            --text-main: #333;
            --text-muted: #666;
        }

        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: var(--bg-color); 
            margin: 0; 
            padding: 20px; 
            color: var(--text-main);
        }

        .container { 
            max-width: 900px; 
            margin: 0 auto; 
            background: var(--card-bg); 
            padding: 30px; 
            border-radius: 16px; 
            box-shadow: 0 10px 30px rgba(0,0,0,0.05); 
        }

        h2 { margin-top: 0; border-bottom: 2px solid var(--border-color); padding-bottom: 15px; margin-bottom: 30px; font-weight: 700; }

        /* BỐ CỤC RESPONSIVE (PC & MOBILE)  */
        .profile-layout { 
            display: flex; 
            flex-direction: row; /* Mặc định cho PC: 2 cột */
            gap: 50px; 
        }

        @media (max-width: 768px) {
            body { padding: 10px; }
            .container { padding: 20px; border-radius: 0; }
            .profile-layout { 
                flex-direction: column; /* Chuyển sang 1 cột trên Mobile */
                align-items: center; 
                gap: 30px;
            }
            .profile-sidebar { width: 100% !important; border-right: none !important; padding-right: 0 !important; }
        }

        /* CỘT TRÁI: AVATAR [cite: 101] */
        .profile-sidebar { 
            width: 250px; 
            flex-shrink: 0; 
            text-align: center; 
            padding-right: 20px;
        }

        .avatar-container {
            position: relative;
            width: 180px;
            height: 180px;
            margin: 0 auto;
            border-radius: 50%;
            overflow: hidden;
            border: 4px solid var(--card-bg);
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            cursor: pointer;
        }

        .avatar-preview { width: 100%; height: 100%; object-fit: cover; }

        /* Hiệu ứng Hover Đổi ảnh  */
        .avatar-overlay {
            position: absolute;
            top: 0; left: 0; width: 100%; height: 100%;
            background: rgba(0, 0, 0, 0.4);
            color: white;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            opacity: 0;
            transition: 0.3s;
            font-size: 14px;
        }

        .avatar-container:hover .avatar-overlay { opacity: 1; }

        /* CỘT PHẢI: FORM [cite: 89, 91] */
        .profile-content { flex-grow: 1; width: 100%; }

        .section { margin-bottom: 35px; }
        .section-title { font-weight: 700; margin-bottom: 20px; color: var(--primary-color); display: block; font-size: 18px; text-transform: uppercase; letter-spacing: 1px; }

        .form-group { margin-bottom: 20px; }
        label { display: block; font-size: 13px; color: var(--text-muted); margin-bottom: 8px; font-weight: 600; }
        
        input, select { 
            width: 100%; 
            padding: 12px 15px; 
            border: 1px solid #ddd; 
            border-radius: 8px; 
            box-sizing: border-box; 
            font-size: 15px;
            transition: all 0.3s;
        }

        input:focus, select:focus { border-color: var(--primary-color); box-shadow: 0 0 0 3px rgba(0,0,0,0.05); outline: none; }
        input:disabled { background: #f1f3f5; color: #adb5bd; cursor: not-allowed; }

        /* NÚT BẤM [cite: 95] */
        .btn-save { 
            background: var(--primary-color); 
            color: white; 
            padding: 15px; 
            border: none; 
            border-radius: 8px; 
            width: 100%; 
            font-weight: 700; 
            cursor: pointer; 
            font-size: 16px;
            transition: 0.3s;
        }
        .btn-save:hover { background: #333; transform: translateY(-2px); }

        /* THÔNG BÁO [cite: 98] */
        .msg { padding: 15px; border-radius: 8px; margin-bottom: 25px; font-size: 14px; font-weight: 500; text-align: center; }
        .msg-success { background: #ebfbee; color: #2b8a3e; border: 1px solid #d3f9d8; }
        .msg-error { background: #fff5f5; color: #c92a2a; border: 1px solid #ffe3e3; }
    </style>
</head>
<body>

<div class="container">
    <h2>Thiết lập tài khoản</h2>

    <% if (!msg.isEmpty()) { %>
        <div class="msg msg-<%= msgType %>"><%= msg %></div>
    <% } %>

    <form id="fastGenderForm" method="post" style="display:none;">
        <input type="hidden" name="action" value="update_gender_fast">
        <input type="hidden" name="userSexual" id="hiddenSexual">
    </form>

    <div class="profile-layout">
        <div class="profile-sidebar">
            <form action="<%= request.getContextPath() %>/upload-avatar" method="post" enctype="multipart/form-data">
                <label for="file-upload" class="avatar-container">
                    <img src="<%= request.getContextPath() %>/assets/images/avt/<%= user.getAvtUrl() %>" 
                         class="avatar-preview" 
                         onerror="this.src='<%= request.getContextPath() %>/assets/images/avt/default.png'">
                    <div class="avatar-overlay">
                        <span>Thay đổi ảnh</span>
                    </div>
                </label>
                <input id="file-upload" type="file" name="avatarFile" accept="image/*" style="display: none;" onchange="this.form.submit()">
            </form>
            <p style="margin-top: 15px; font-weight: 600; color: #888;">@<%= user.getUserName() %></p>
        </div>

        <div class="profile-content">
            <form method="post">
                <input type="hidden" name="action" value="update_info">
                
                <div class="section">
                    <span class="section-title">Thông tin cá nhân</span>
                    
                    <div class="form-group">
                        <label>Tên đăng nhập</label>
                        <input type="text" value="<%= user.getUserName() %>" disabled>
                    </div>

                    <div class="form-group">
                        <label>Họ và tên</label>
                        <input type="text" name="fullName" value="<%= (user.getFullName() != null ? user.getFullName() : "") %>" required>
                    </div>

                    <div class="form-group">
                        <label>Giới tính (Tự động lưu khi chọn)</label>
                        <select name="userSexual" onchange="document.getElementById('hiddenSexual').value = this.value; document.getElementById('fastGenderForm').submit();">
                            <option value="default" <%= "default".equals(user.getUserSexual()) ? "selected" : "" %>>Không muốn công khai</option>
                            <option value="male" <%= "male".equals(user.getUserSexual()) ? "selected" : "" %>>Nam</option>
                            <option value="female" <%= "female".equals(user.getUserSexual()) ? "selected" : "" %>>Nữ</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>Số điện thoại</label>
                        <input type="text" name="phone" value="<%= (user.getUserPhone() != null ? user.getUserPhone() : "") %>">
                    </div>
                    
                    <div class="form-group">
                        <label>Email liên lạc</label>
                        <input type="email" name="email" value="<%= user.getUserEmail() %>" required placeholder="example@domain.com">
                        <small style="color: #999; font-size: 11px;">Mã OTP xác thực sẽ được gửi về email này khi cần thiết.</small>
                    </div>

                    <div class="form-group">
                        <label>Địa chỉ</label>
                        <input type="text" name="address" value="<%= (user.getUserAddress() != null ? user.getUserAddress() : "") %>">
                    </div>
                </div>

                <div class="section">
                    <span class="section-title">Bảo mật</span>
                    <div class="form-group">
                        <label>Mật khẩu mới (Để trống nếu không đổi)</label>
                        <input type="password" name="newPassword" placeholder="••••••••">
                    </div>
                    
                    <div style="background: #fff9db; padding: 20px; border-radius: 12px; border: 1px solid #fab005;">
                        <label style="color: #856404;">Mật khẩu hiện tại (Để xác nhận lưu thay đổi)</label>
                        <input type="password" name="currentPassword" required placeholder="Nhập mật khẩu hiện tại của bạn">
                        <button type="submit" class="btn-save" style="margin-top: 15px;">Lưu tất cả thay đổi</button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <div style="text-align: center; margin-top: 30px;">
        <a href="../" style="color: #888; text-decoration: none; font-size: 14px;">← Quay lại hồ sơ cá nhân</a>
    </div>
</div>

</body>
</html>