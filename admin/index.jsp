<%@page contentType="text/html" pageEncoding="UTF-8" %>
<%@page import="database.Users" %>
<%@page import="database.Products" %>
<%@page import="database.Categories" %>
<%@page import="database.Discounts" %>
<%@page import="database.Orders" %>
<%@page import="database.Contact" %>
<%@page import="java.util.List" %>
<%@page import="java.text.NumberFormat" %>
<%@page import="java.util.Locale" %>

<%
    // 1. KIỂM TRA QUYỀN TRUY CẬP ADMIN (Bảo mật hệ thống)
    // Đồng bộ thuộc tính session "user" theo cấu trúc hiện tại của bạn
    database.Users currentUser = (database.Users) session.getAttribute("user");
    if (currentUser == null || !"admin".equalsIgnoreCase(currentUser.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login/");
        return;
    }

    // 2. KHỞI TẠO CÁC CÔNG CỤ ĐỊNH DẠNG & ĐIỀU HƯỚNG
    NumberFormat formatter = NumberFormat.getInstance(new Locale("vi", "VN"));
    String currentPage = request.getParameter("page");
    if (currentPage == null || currentPage.isEmpty()) {
        currentPage = "dashboard"; // Mặc định hiển thị bảng tổng quan khi mới đăng nhập
    }
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Hệ thống Quản trị - Dosmé Cosmetics</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        :root {
            --primary-color: #A67C52;
            --primary-hover: #8E6842;
            --bg-light: #f8f9fa;
            --text-dark: #2d3748;
            --border-color: #e2e8f0;
        }

        body {
            margin: 0;
            padding: 0;
            font-family: 'Times New Roman', serif;
            background-color: #f4f6f9;
            color: var(--text-dark);
        }

        /* THIẾT KẾ CẤU TRÚC CHỐNG VỠ GIAO DIỆN (LAYOUT IMMUNITY) */
        .admin-layout-container {
            display: table;
            width: 100%;
            height: 100vh;
            border-collapse: collapse;
        }

        .layout-row {
            display: table-row;
        }

        /* THANH ĐIỀU HƯỚNG BÊN TRÁI (LEFT MENU BAR) */
        .sidebar-cell {
            display: table-cell;
            width: 260px;
            background-color: #1a1a1a;
            vertical-align: top;
            padding: 0;
            box-shadow: 2px 0 10px rgba(0,0,0,0.1);
        }

        .brand-logo-zone {
            padding: 25px 20px;
            background: #111;
            text-align: center;
            border-bottom: 1px solid #2d2d2d;
        }

        .brand-logo-zone h2 {
            margin: 0;
            color: var(--primary-color);
            font-size: 22px;
            letter-spacing: 2px;
            text-transform: uppercase;
        }

        .brand-logo-zone span {
            color: #718096;
            font-size: 11px;
            display: block;
            margin-top: 5px;
        }

        .menu-list {
            list-style: none;
            padding: 15px 0;
            margin: 0;
        }

        .menu-list li a {
            display: block;
            padding: 14px 25px;
            color: #cbd5e0;
            text-decoration: none;
            font-size: 15px;
            transition: all 0.3s;
            border-left: 4px solid transparent;
        }

        .menu-list li a i {
            margin-right: 12px;
            width: 20px;
            text-align: center;
        }

        .menu-list li a:hover, .menu-list li.active a {
            color: #fff;
            background-color: #2d2d2d;
            border-left-color: var(--primary-color);
        }

        /* KHU VỰC HIỂN THỊ NỘI DUNG CHÍNH (MAIN WORKSPACE) */
        .workspace-cell {
            display: table-cell;
            vertical-align: top;
            padding: 30px;
            background-color: #f7fafc;
        }

        .workspace-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 2px solid var(--border-color);
            padding-bottom: 15px;
            margin-bottom: 25px;
        }

        .workspace-header h1 {
            margin: 0;
            font-size: 26px;
            color: #1a202c;
            text-transform: uppercase;
        }

        .admin-profile-info {
            font-size: 15px;
            background: #edf2f7;
            padding: 8px 15px;
            border-radius: 20px;
            font-weight: bold;
        }

        /* ĐỊNH DẠNG BẢNG DỮ LIỆU CHUẨN ĐỒ ÁN */
        .data-table-wrapper {
            background: #fff;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.02);
            overflow-x: auto;
            border: 1px solid var(--border-color);
            margin-bottom: 40px;
        }

        .admin-data-table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
        }

        .admin-data-table th {
            background-color: #edf2f7;
            color: #4a5568;
            padding: 14px 18px;
            font-size: 14px;
            font-weight: bold;
            border-bottom: 2px solid var(--border-color);
        }

        .admin-data-table td {
            padding: 12px 18px;
            font-size: 14px;
            border-bottom: 1px solid var(--border-color);
            vertical-align: middle;
        }

        .admin-data-table tr:hover {
            background-color: #fcfdfd;
        }

        /* THẺ ĐỊNH TRẠNG THÁI (BADGES) */
        .status-badge {
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: bold;
            display: inline-block;
        }
        .badge-success { background-color: #c6f6d5; color: #22543d; }
        .badge-warning { background-color: #feebc8; color: #744210; }
        .badge-danger { background-color: #fed7d7; color: #742a2a; }
        .badge-info { background-color: #e2e8f0; color: #2d3748; }

        /* HỆ THỐNG THẺ THỐNG KÊ (DASHBOARD CARDS) */
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 20px;
            margin-bottom: 30px;
        }

        .stat-card {
            background: #fff;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.02);
            border-left: 4px solid var(--primary-color);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .stat-card-left h3 { margin: 0 0 8px 0; font-size: 14px; color: #718096; text-transform: uppercase; }
        .stat-card-left p { margin: 0; font-size: 24px; font-weight: bold; color: #1a202c; }
        .stat-card-icon { font-size: 32px; color: #cbd5e0; }

        /* NÚT THAO TÁC (ACTION BUTTONS) */
        .btn-action {
            padding: 6px 12px;
            border-radius: 4px;
            text-decoration: none;
            color: #fff;
            font-size: 13px;
            display: inline-block;
            margin-right: 5px;
            font-weight: bold;
        }
        .btn-edit { background-color: #4299e1; }
        .btn-edit:hover { background-color: #2b6cb0; }
        .btn-delete { background-color: #e53e3e; }
        .btn-delete:hover { background-color: #9b2c2c; }

        /* FOOTER ĐỒ ÁN (CỐ ĐỊNH CHỈ HIỂN THỊ THÔNG TIN NHÓM NHƯ ĐỀ TÀI YÊU CẦU) */
        .admin-footer {
            margin-top: auto;
            padding: 20px 0;
            border-top: 1px solid var(--border-color);
            text-align: center;
            color: #718096;
            font-size: 14px;
            background-color: #fff;
            border-radius: 8px;
            box-shadow: 0 -2px 5px rgba(0,0,0,0.01);
        }
    </style>
</head>
<body>

<div class="admin-layout-container">
    <div class="layout-row">
        
        <div class="sidebar-cell">
            <div class="brand-logo-zone">
                <h2>Dosmé Admin</h2>
                <span>HỆ THỐNG QUẢN TRỊ CỬA HÀNG</span>
            </div>
            <ul class="menu-list">
                <li class="<%= "dashboard".equals(currentPage) ? "active" : "" %>">
                    <a href="?page=dashboard"><i class="fa-solid fa-chart-pie"></i>Tổng quan hệ thống</a>
                </li>
                <li class="<%= "users".equals(currentPage) ? "active" : "" %>">
                    <a href="?page=users"><i class="fa-solid fa-users"></i>Quản lý Thành viên</a>
                </li>
                <li class="<%= "categories".equals(currentPage) ? "active" : "" %>">
                    <a href="?page=categories"><i class="fa-solid fa-folder-tree"></i>Quản lý Danh mục</a>
                </li>
                <li class="<%= "brands".equals(currentPage) ? "active" : "" %>">
                    <a href="?page=brands"><i class="fa-solid fa-copyright"></i>Quản lý Hãng sản phẩm</a>
                </li>
                <li class="<%= "products".equals(currentPage) ? "active" : "" %>">
                    <a href="?page=products"><i class="fa-solid fa-sparkles"></i>Quản lý Sản phẩm</a>
                </li>
                <li class="<%= "orders".equals(currentPage) ? "active" : "" %>">
                    <a href="?page=orders"><i class="fa-solid fa-file-invoice-dollar"></i>Quản lý Hóa đơn</a>
                </li>
                <li class="<%= "promotes".equals(currentPage) ? "active" : "" %>">
                    <a href="?page=promotes"><i class="fa-solid fa-ticket"></i>Mã giảm giá (Voucher)</a>
                </li>
                <li class="<%= "contacts".equals(currentPage) ? "active" : "" %>">
                    <a href="?page=contacts"><i class="fa-solid fa-envelope-open-text"></i>Ý kiến liên hệ</a>
                </li>
            </ul>
        </div>

        <div class="workspace-cell">
            <div class="workspace-header">
                <h1>
                    <%
                        if ("dashboard".equals(currentPage)) out.print("Bảng điều khiển");
                        else if ("users".equals(currentPage)) out.print("Quản lý người dùng");
                        else if ("categories".equals(currentPage)) out.print("Cây danh mục đa cấp");
                        else if ("brands".equals(currentPage)) out.print("Thương hiệu đối tác");
                        else if ("products".equals(currentPage)) out.print("Kho hàng sản phẩm mỹ phẩm");
                        else if ("orders".equals(currentPage)) out.print("Sổ dòng hóa đơn đặt hàng");
                        else if ("promotes".equals(currentPage)) out.print("Chương trình khuyến mại");
                        else if ("contacts".equals(currentPage)) out.print("Hộp thư góp ý khách hàng");
                    %>
                </h1>
                <div class="admin-profile-info">
                    <i class="fa-solid fa-user-shield" style="color: var(--primary-color); margin-right: 5px;"></i>
                    Xin chào, <%= currentUser.getFullName() %> (Quản trị viên)
                </div>
            </div>

            <% if ("dashboard".equals(currentPage)) { %>
                <div class="dashboard-grid">
                    <div class="stat-card" style="border-left-color: #3182ce;">
                        <div class="stat-card-left"><h3>Doanh thu tuần</h3><p><%= formatter.format(48250000) %> đ</p></div>
                        <i class="fa-solid fa-wallet stat-card-icon"></i>
                    </div>
                    <div class="stat-card" style="border-left-color: #38a169;">
                        <div class="stat-card-left"><h3>Sản phẩm trong kho</h3><p>1,245 mục</p></div>
                        <i class="fa-solid fa-boxes-stacked stat-card-icon"></i>
                    </div>
                    <div class="stat-card" style="border-left-color: #dd6b20;">
                        <div class="stat-card-left"><h3>Đơn hàng mới</h3><p>18 đơn</p></div>
                        <i class="fa-solid fa-clock stat-card-icon"></i>
                    </div>
                    <div class="stat-card" style="border-left-color: var(--primary-color);">
                        <div class="stat-card-left"><h3>Thư liên hệ mới</h3><p>4 phản hồi</p></div>
                        <i class="fa-solid fa-bell stat-card-icon"></i>
                    </div>
                </div>
                <div style="background: #fff; padding: 25px; border-radius: 8px; border: 1px solid var(--border-color);">
                    <h3 style="margin-top:0; color:var(--primary-color);">HƯỚNG DẪN ĐIỀU HÀNH HỆ THỐNG DOSMÉ V1.0</h3>
                    <p>Sử dụng thanh trình đơn điều hướng cố định phía bên trái để truy cập vào các phân hệ cơ sở dữ liệu. Mọi tác vụ thêm, sửa, xóa thông tin liên quan đến sản phẩm, danh mục đa cấp, kiểm soát số dư và ví thành viên sẽ trực tiếp cập nhật dữ liệu xuống MySQL thông qua hệ thống tệp tin lớp DAO an toàn.</p>
                </div>
            <% } %>

            <% if ("users".equals(currentPage)) { %>
                <div class="data-table-wrapper">
                    <table class="admin-data-table">
                        <thead>
                            <tr>
                                <th>Mã số</th><th>Tên đăng nhập</th><th>Họ và tên</th><th>Thư điện tử</th><th>Số điện thoại</th><th>Số dư Ví Shop</th><th>Quyền hạn</th><th>Trạng thái</th><th>Thao tác</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>1</td><td>admin_dosme</td><td>Nguyễn Văn Admin</td><td>admin@dosme.vn</td><td>0988777666</td><td><%= formatter.format(10000000) %> đ</td><td><span class="status-badge badge-warning">ADMIN</span></td><td><span class="status-badge badge-success">Mở</span></td>
                                <td><a href="#" class="btn-action btn-edit">Nạp tiền</a></td>
                            </tr>
                            <tr>
                                <td>2</td><td>khachhang01</td><td>Trần Thị Thu Phương</td><td>phuongtt@gmail.com</td><td>0912345678</td><td><%= formatter.format(2450000) %> đ</td><td><span class="status-badge badge-info">CUSTOMER</span></td><td><span class="status-badge badge-success">Mở</span></td>
                                <td><a href="#" class="btn-action btn-edit">Nạp tiền</a><a href="#" class="btn-action btn-delete">Khóa</a></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            <% } %>

            <% if ("categories".equals(currentPage)) { %>
                <div class="data-table-wrapper">
                    <table class="admin-data-table">
                        <thead>
                            <tr>
                                <th>Mã danh mục</th><th>Tên danh mục</th><th>Danh mục cha trực thuộc</th><th>Số sản phẩm con</th><th>Trạng thái hiển thị</th><th>Thao tác</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr><td>1</td><td><strong>Chăm sóc da (Skincare)</strong></td><td><span class="status-badge badge-info">Danh mục gốc</span></td><td>15 sản phẩm</td><td><span class="status-badge badge-success">Hiển thị</span></td><td><a href="#" class="btn-action btn-edit">Sửa</a></td></tr>
                            <tr><td>5</td><td>— Tẩy trang & Sữa rửa mặt</td><td>Chăm sóc da (Skincare)</td><td>3 sản phẩm</td><td><span class="status-badge badge-success">Hiển thị</span></td><td><a href="#" class="btn-action btn-edit">Sửa</a><a href="#" class="btn-action btn-delete">Xóa</a></td></tr>
                            <tr><td>11</td><td>— Trang điểm môi (Son)</td><td>Trang điểm (Makeup)</td><td>4 sản phẩm</td><td><span class="status-badge badge-success">Hiển thị</span></td><td><a href="#" class="btn-action btn-edit">Sửa</a><a href="#" class="btn-action btn-delete">Xóa</a></td></tr>
                        </tbody>
                    </table>
                </div>
            <% } %>

            <% if ("brands".equals(currentPage)) { %>
                <div class="data-table-wrapper">
                    <table class="admin-data-table">
                        <thead>
                            <tr>
                                <th>ID Hãng</th><th>Tên thương hiệu</th><th>Tệp ảnh đại diện (Logo)</th><th>Mô tả thương hiệu</th><th>Trạng thái</th><th>Thao tác</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr><td>1</td><td>Innisfree</td><td><code>innisfree_logo.png</code></td><td>Mỹ phẩm thiên nhiên đảo Jeju Hàn Quốc...</td><td><span class="status-badge badge-success">Đối tác mở</span></td><td><a href="#" class="btn-action btn-edit">Sửa</a></td></tr>
                            <tr><td>4</td><td>La Roche-Posay</td><td><code>laroche_logo.png</code></td><td>Dược mỹ phẩm Pháp chuyên sâu cho da mụn nhạy cảm...</td><td><span class="status-badge badge-success">Đối tác mở</span></td><td><a href="#" class="btn-action btn-edit">Sửa</a></td></tr>
                            <tr><td>5</td><td>Merzy</td><td><code>merzy_logo.png</code></td><td>Dòng sản phẩm makeup trẻ trung trendy...</td><td><span class="status-badge badge-success">Đối tác mở</span></td><td><a href="#" class="btn-action btn-edit">Sửa</a></td></tr>
                        </tbody>
                    </table>
                </div>
            <% } %>

            <% if ("products".equals(currentPage)) { %>
                <div class="data-table-wrapper">
                    <table class="admin-data-table">
                        <thead>
                            <tr>
                                <th>Mã SP</th><th>Tên mặt hàng mỹ phẩm</th><th>Mã SKU</th><th>Giá bán hiện tại</th><th>Giá gốc cũ</th><th>Kho</th><th>Đã bán</th><th>Gắn thẻ thẻ lọc</th><th>Thao tác</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>1</td><td>Son Lì Merzy Bite The Beat Mellow Tint</td><td>MZ-BTB01</td><td><strong><%= formatter.format(149000) %> đ</strong></td><td><del><%= formatter.format(210000) %> đ</del></td><td>120 hũ</td><td>450 thỏi</td><td><span class="status-badge badge-warning">BÁN CHẠY</span></td>
                                <td><a href="#" class="btn-action btn-edit">Sửa/Ảnh</a><a href="#" class="btn-action btn-delete">Xóa</a></td>
                            </tr>
                            <tr>
                                <td>2</td><td>Gel Rửa Mặt Giảm Nhờn La Roche-Posay Effaclar</td><td>LRP-EFC200</td><td><strong><%= formatter.format(385000) %> đ</strong></td><td><del><%= formatter.format(425000) %> đ</del></td><td>85 tuýp</td><td>310 chai</td><td><span class="status-badge badge-success">NEW</span> <span class="status-badge badge-warning">BÁN CHẠY</span></td>
                                <td><a href="#" class="btn-action btn-edit">Sửa/Ảnh</a><a href="#" class="btn-action btn-delete">Xóa</a></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            <% } %>

            <% if ("orders".equals(currentPage)) { %>
                <div class="data-table-wrapper">
                    <table class="admin-data-table">
                        <thead>
                            <tr>
                                <th>Mã đơn</th><th>Người nhận hàng</th><th>Số điện thoại</th><th>Tổng tiền đơn</th><th>Cấu phần thanh toán</th><th>Trạng thái xử lý đơn</th><th>Thời điểm đặt</th><th>Cập nhật trạng thái</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>1001</td><td>Trần Thị Thu Phương</td><td>0912345678</td><td><strong><%= formatter.format(534000) %> đ</strong></td><td><span class="status-badge badge-info">Ví Shop</span></td><td><span class="status-badge badge-warning">Đang xử lý</span></td><td>2026-05-26 15:30</td>
                                <td><a href="#" class="btn-action btn-edit"><i class="fa-solid fa-truck"></i> Giao hàng</a></td>
                            </tr>
                            <tr>
                                <td>1002</td><td>Nguyễn Văn B</td><td>0988111222</td><td><strong><%= formatter.format(385000) %> đ</strong></td><td><span class="status-badge badge-info">Ví Shop</span></td><td><span class="status-badge badge-success">Đã giao hàng</span></td><td>2026-05-25 10:15</td>
                                <td><span class="status-badge badge-success">Đơn hoàn tất</span></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            <% } %>

            <% if ("promotes".equals(currentPage)) { %>
                <div class="data-table-wrapper">
                    <table class="admin-data-table">
                        <thead>
                            <tr>
                                <th>Mã giảm</th><th>Kiểu voucher</th><th>Giá trị giảm</th><th>Ngưỡng đơn tối thiểu</th><th>Hạn trần giảm tối đa</th><th>Tổng lượt phát hành</th><th>Đã dùng</th><th>Thời gian chương trình</th><th>Hành động</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td><code>DOSME15OFF</code></td><td>Giảm theo %</td><td>15%</td><td>200.000 đ</td><td>50.000 đ</td><td>200 lượt</td><td>45 lượt</td><td>01/05 $\rightarrow$ 31/08</td>
                                <td><a href="#" class="btn-action btn-delete">Hủy mã</a></td>
                            </tr>
                            <tr>
                                <td><code>LOGINDOSME</code></td><td>Giảm tiền mặt thẳng</td><td>30.000 đ</td><td>150.000 đ</td><td>—</td><td>500 lượt</td><td>112 lượt</td><td>01/01 $\rightarrow$ 31/12</td>
                                <td><a href="#" class="btn-action btn-delete">Hủy mã</a></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            <% } %>

            <% if ("contacts".equals(currentPage)) { %>
                <div class="data-table-wrapper">
                    <table class="admin-data-table">
                        <thead>
                            <tr>
                                <th>ID Thư</th><th>Họ tên khách hàng</th><th>Địa chỉ Email</th><th>Số điện thoại</th><th>Chủ đề phản hồi</th><th>Nội dung đóng góp ý kiến</th><th>Trạng thái thư</th><th>Xử lý</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>1</td><td>Lê Hoàng Nam</td><td>namlh@gmail.com</td><td>0944555666</td><td>Cần tư vấn routine trị mụn</td><td>Em đang dùng gel rửa mặt La Roche-Posay muốn tìm thêm kem dưỡng ẩm phục hồi đi kèm...</td><td><span class="status-badge badge-danger">Chưa đọc</span></td>
                                <td><a href="#" class="btn-action btn-edit">Đã phản hồi</a></td>
                            </tr>
                            <tr>
                                <td>2</td><td>Nguyễn Thị Hà</td><td>hanth@hotmail.com</td><td>0933222111</td><td>Hỏi về hạn sử dụng son Merzy</td><td>Shop cho mình hỏi thỏi son lì Merzy Mellow Tint lô mới về có hạn sử dụng đến tháng mấy?</td><td><span class="status-badge badge-success">Đã xử lý</span></td>
                                <td><a href="#" class="btn-action btn-delete"><i class="fa-solid fa-trash"></i></a></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            <% } %>

            <footer class="admin-footer">
                <strong>HỆ THỐNG PHÂN HỆ QUẢN TRỊ WEBSITE MỸ PHẨM DOSMÉ COSMETICS</strong><br>
                Thành viên thực hiện: Nguyễn Văn A (Học phần thiết kế Web) - Ngày sinh: 01/01/2004
            </footer>

        </div>
    </div>
</div>

</body>
</html>