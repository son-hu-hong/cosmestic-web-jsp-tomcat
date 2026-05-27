<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="database.Users"%>
<%
    // 1. Lấy đối tượng user từ session (chuẩn theo form đăng nhập mới)
    database.Users user = (database.Users) session.getAttribute("user");

    // 2. Nếu không có user trong session -> chưa đăng nhập -> đẩy về login kèm redirect
    if (user == null) {
        String currentUrl = request.getRequestURI();
        response.sendRedirect(request.getContextPath() + "/login/?redirect=" + currentUrl);
        return;
    }

    // 3. Xử lý đường dẫn Avatar
    String contextPath = request.getContextPath();
    String avt = (user.getAvtUrl() == null || user.getAvtUrl().trim().isEmpty()) ? "default.png" : user.getAvtUrl().trim();
    String avatarUrl = contextPath + "/assets/images/avt/" + avt;

    // 4. Kiểm tra quyền Admin
    boolean isAdmin = "admin".equalsIgnoreCase(user.getRole());
    
    // 5. Xử lý hiển thị giới tính
    String genderDisplay = "Chưa thiết lập";
    String genderValue = user.getUserSexual(); // Giả định getter là getUserSexual()
    
    if ("male".equalsIgnoreCase(genderValue)) {
        genderDisplay = "Nam";
    } else if ("female".equalsIgnoreCase(genderValue)) {
        genderDisplay = "Nữ";
    } else if ("default".equalsIgnoreCase(genderValue)) {
        genderDisplay = "Không muốn công khai";
    }
    
    // 6. Định dạng hiển thị số dư (VNĐ)
    long balance = user.getUserBalance(); // Lấy giá trị userBalance bạn vừa thêm
    java.text.NumberFormat formatter = java.text.NumberFormat.getInstance(new java.util.Locale("vi", "VN"));
    String balanceDisplay = formatter.format(balance) + " VNĐ";
%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Hồ sơ người dùng - Dosmé</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 0; padding: 24px; background: #f4f7f6; }
        .wrap { max-width: 900px; margin: 0 auto; background: white; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.05); padding: 24px; }
        .card { border: 1px solid #eef0f2; border-radius: 12px; padding: 20px; background: #fff; }
        .row { display: flex; gap: 30px; align-items: flex-start; flex-wrap: wrap; }
        .avatar-section { text-align: center; }
        .avatar { width: 140px; height: 140px; border-radius: 50%; object-fit: cover; border: 3px solid #f0f0f0; }
        table { border-collapse: collapse; width: 100%; }
        th, td { padding: 12px 10px; border-bottom: 1px solid #f0f0f0; text-align: left; font-size: 15px; }
        th { width: 160px; color: #555; font-weight: 600; }
        .btns { margin-top: 25px; display: flex; gap: 12px; flex-wrap: wrap; }
        a.btn { display:inline-block; padding:10px 18px; border-radius:8px; border:1px solid #333; text-decoration:none; color:#333; background:#fff; font-weight: 500; transition: 0.2s; }
        a.btn:hover { background: #f8f9fa; }
        a.btn.primary { background:#111; color:#fff; border-color: #111; }
        a.btn.primary:hover { background: #333; }
        .admin-badge { display:inline-block; padding:4px 12px; border-radius:999px; background:#e03131; color:#fff; font-size:12px; font-weight: bold; }
        .status-badge { display:inline-block; padding:4px 12px; border-radius:999px; font-size:12px; font-weight: bold; }
        .status-active { background:#d3f9d8; color:#2b8a3e; }
        .status-locked { background:#ffe3e3; color:#c92a2a; }
        .note { color:#888; font-size:12px; margin-top:10px; }
        h2 { margin-top: 0; color: #222; border-bottom: 2px solid #f0f0f0; padding-bottom: 15px; margin-bottom: 20px; }
    </style>
</head>
<body>
<div class="wrap">
    <h2>Hồ sơ cá nhân</h2>

    <div class="card">
        <div class="row">
            <div class="avatar-section">
                <img class="avatar" src="<%= avatarUrl %>" alt="avatar"
                     onerror="this.src='<%= contextPath %>/assets/images/avt/default.png'">
                <div class="note">Tệp ảnh: <%= avt %></div>
            </div>

            <div style="flex:1; min-width: 320px;">
                <table>
                    <tr>
                        <th>Tên tài khoản</th>
                        <td><b><%= user.getUserName() %></b></td>
                    </tr>
                    <tr>
                        <th>Họ và tên</th>
                        <td><%= (user.getFullName() == null || user.getFullName().isEmpty() ? "<i>Chưa cập nhật</i>" : user.getFullName()) %></td>
                    </tr>
                    <tr>
                        <th>Giới tính</th>
                        <td><%= genderDisplay %></td>
                    </tr>
   
                    <tr>
                        <th>Email</th>
                        <td><%= user.getUserEmail() %></td>
                    </tr>
                    <tr>
                        <th>Số điện thoại</th>
                        <td><%= (user.getUserPhone() == null || user.getUserPhone().isEmpty() ? "<i>Chưa cập nhật</i>" : user.getUserPhone()) %></td>
                    </tr>
                    <tr>
                        <th>Địa chỉ</th>
                        <td><%= (user.getUserAddress() == null || user.getUserAddress().isEmpty() ? "<i>Chưa cập nhật</i>" : user.getUserAddress()) %></td></tr>
                    <tr>
                        <th>Trạng thái</th>
                        <td>
                            <% if (user.getDisable() == 1) { %>
                                <span class="status-badge status-locked">Đang bị khóa</span>
                            <% } else { %>
                                <span class="status-badge status-active">Hoạt động</span>
                            <% } %>
                        </td>
                    </tr>
                    <tr>
                        <th>Số dư tài khoản</th>
                        <td style="color: #2f9e44; font-weight: bold;"><%= balanceDisplay %></td>
                    </tr>

                    <% if (isAdmin) { %>
                    <tr>
                        <th>Phân quyền</th>
                        <td><span class="admin-badge">Quản trị viên (Admin)</span></td>
                    </tr>
                    <% } %>
                </table>

                <div class="btns">
                    <a class="btn primary" href="<%= contextPath %>/UserProfile/config/">Cập nhật thông tin</a>
                    <a class="btn" href="<%= contextPath %>/shop/">Về Trang chủ</a>
                    
                    <% if (isAdmin) { %>
                        <a class="btn" href="<%= contextPath %>/admin/" style="border-color: #e03131; color: #e03131;">Trang Quản Trị</a>
                    <% } %>
                </div>
            </div>
        </div>
    </div>
</div>
</body>
</html>