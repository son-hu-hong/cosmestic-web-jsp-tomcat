<%@page contentType="text/html" pageEncoding="UTF-8" %>
<%@page import="database.Users" %>
<%@page import="database.Categories" %>
<%@page import="java.util.List" %>
<%@page import="java.text.NumberFormat" %>
<%@page import="java.util.Locale" %>
<%
    // 1. ĐỒNG BỘ CẤU TRÚC ĐỌC SESSION TÀI KHOẢN VÀ CONTEXT PATH
    database.Users currentUser = (database.Users) session.getAttribute("user");
    String context = request.getContextPath();

    // Khởi tạo định dạng tiền tệ Việt Nam cho số dư tài khoản ví người dùng
    NumberFormat formatter = NumberFormat.getInstance(new Locale("vi", "VN"));

    // Khởi tạo đối tượng DAO danh mục để nạp cây menu động đa cấp từ MySQL
    database.Categories categoryDAO = new database.Categories();
    List<database.Categories> rootCategories = categoryDAO.getRootCategories();
%>

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<style>
    :root {
        --brand-primary: #A67C52; /* Sắc màu vàng đồng quý phái thương hiệu Dosmé */
        --brand-hover: #8e6a45;
        --brand-light: #fef8f4;
        --text-dark: #333;
        --text-gray: #757575;
        --border-color: #e2e8f0;
    }

    body { margin: 0; font-family: 'Times New Roman', serif; color: var(--text-dark); }
    a { text-decoration: none; color: inherit; transition: 0.2s; }

    /* ======================================================== */
    /* CẤU TRÚC HEADER PC TOÀN DIỆN (MAIN BAR VÀ BOTTOM BAR)    */
    /* ======================================================== */
    .header-pc {
        background-color: var(--brand-light);
        border-bottom: 1px solid var(--border-color);
        padding: 0 40px;
    }

    /* 1. MAIN BAR TRUNG TÂM PHÍA TRÊN */
    .header-main-bar {
        display: flex;
        justify-content: space-between;
        align-items: center;
        max-width: 1300px;
        margin: 0 auto;
        padding: 12px 0;
        border-bottom: 1px dashed rgba(166, 124, 82, 0.15);
    }

    /* Căn chỉnh vùng chứa tệp ảnh Logo Shop cố định theo yêu cầu */
    .brand-logo-smn a {
        display: flex;
        align-items: center;
        gap: 12px;
        font-size: 26px;
        font-weight: bold;
        color: var(--brand-primary);
        letter-spacing: 2px;
        text-transform: uppercase;
    }

    /* Định dạng kích thước chuẩn 75px cho tệp ảnh xóa phông */
    .shop-main-logo-img {
        width: 75px;
        height: 75px;
        object-fit: contain;
        background: transparent; /* Đảm bảo hiển thị tốt ảnh xóa phông (PNG trong suốt) */
    }

    /* Thanh tìm kiếm thu hẹp vừa vặn, bo tròn tinh tế */
    .search-wrapper-box {
        position: relative;
        width: 1000px;
    }

    .search-inner-form {
        display: flex;
        align-items: center;
        background: #fff;
        border: 2px solid var(--brand-primary);
        border-radius: 20px;
        padding: 4px 14px;
        margin: 0;
    }

    .search-inner-form input {
        border: none;
        outline: none;
        width: 100%;
        font-size: 14px;
        padding: 4px;
        font-family: inherit;
    }

    .search-inner-form button {
        background: none;
        border: none;
        color: var(--brand-primary);
        cursor: pointer;
        font-size: 16px;
    }

    /* Khối chức năng giỏ hàng & tài khoản bên phải */
    .right-actions-group {
        display: flex;
        align-items: center;
        gap: 25px;
    }

    /* Giỏ hàng nhỏ gọn hiển thị đồng trục */
    .cart-indicator {
        font-size: 22px;
        color: var(--brand-primary);
        position: relative;
        display: flex;
        align-items: center;
    }
    
    .cart-counter-badge {
        position: absolute;
        top: -8px;
        right: -10px;
        background: red;
        color: #fff;
        font-size: 11px;
        padding: 2px 5px;
        border-radius: 50%;
        font-weight: bold;
    }

    /* Cấu phần Tài khoản người dùng kết hợp Avatar Dropdown */
    .user-profile-dropdown {
        position: relative;
        display: inline-block;
    }

    .user-avatar-trigger {
        cursor: pointer;
        display: flex;
        align-items: center;
    }

    .user-avatar-img {
        width: 42px;
        height: 42px;
        border-radius: 50%;
        border: 2px solid var(--brand-primary);
        object-fit: cover;
        background-color: #fff;
    }

    .user-icon-fallback {
        font-size: 24px;
        color: var(--brand-primary);
        background: #fff;
        padding: 6px;
        border-radius: 50%;
        border: 2px solid var(--brand-primary);
    }

    /* Hộp nội dung ẩn thả xuống khi rê chuột vào ảnh đại diện */
    .profile-dropdown-content {
        position: absolute;
        top: 100%;
        right: 0;
        background-color: #ffffff;
        min-width: 245px;
        box-shadow: 0px 8px 16px rgba(0, 0, 0, 0.1);
        border-radius: 6px;
        padding: 12px 0;
        display: none;
        z-index: 1001;
        border: 1px solid var(--border-color);
    }

    .dropdown-user-info {
        padding: 8px 20px 12px 20px;
        border-bottom: 1px solid var(--border-color);
        margin-bottom: 8px;
    }

    .dropdown-user-info .user-name {
        font-weight: bold;
        font-size: 16px;
        color: #1a202c;
        display: block;
        word-break: break-all;
    }

    .dropdown-user-info .user-balance {
        font-size: 13px;
        color: var(--brand-primary);
        display: block;
        margin-top: 4px;
        font-weight: bold;
    }

    .profile-dropdown-content a {
        color: var(--text-dark);
        padding: 10px 20px;
        text-decoration: none;
        display: block;
        font-size: 15px;
    }

    .profile-dropdown-content a i {
        margin-right: 10px;
        width: 18px;
        text-align: center;
        color: var(--brand-primary);
    }

    .profile-dropdown-content a:hover {
        background-color: var(--brand-light);
        color: var(--brand-primary);
    }

    /* Ép tab mới cho cổng Admin điều hành hệ thống */
    .admin-portal-link {
        font-weight: bold;
        background-color: var(--brand-light);
        color: var(--brand-primary) !important;
    }

    .user-profile-dropdown:hover .profile-dropdown-content {
        display: block;
    }


    /* 2. BOTTOM BAR: THANH MENU ĐIỀU HƯỚNG ĐƯỢC CĂN CHỈNH RA CHÍNH GIỮA TUYỆT ĐỐI */
    .header-bottom-navigation {
        display: flex;
        justify-content: center; 
        padding: 4px 0;
        position: relative;
    }

    .main-nav-menu {
        display: flex;
        list-style: none;
        padding: 0;
        margin: 0;
        align-items: center;
    }

    .main-nav-menu > li {
        position: relative;
    }

    .main-nav-menu > li > a {
        display: block;
        padding: 12px 24px;
        font-size: 15px;
        font-weight: bold;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }

    .main-nav-menu > li:hover > a {
        color: var(--brand-primary);
    }

    /* KHUNG DROPDOWN CON CHI TIẾT (TRÍCH XUẤT TỰ ĐỘNG TỪ DATABASE THEO PHÂN CẤP) */
    .dropdown-categories-list {
        position: absolute;
        top: 100%;
        left: 0;
        background: #fff;
        list-style: none;
        padding: 10px 0;
        margin: 0;
        min-width: 260px;
        box-shadow: 0 8px 20px rgba(0,0,0,0.08);
        border-radius: 4px;
        display: none;
        z-index: 999;
        border: 1px solid var(--border-color);
    }

    .dropdown-categories-list li a {
        display: block;
        padding: 11px 22px;
        font-size: 14.5px;
        text-transform: none; /* Giữ kiểu chữ thường tự nhiên danh mục */
        font-weight: normal;
        color: #4a5568;
    }

    .dropdown-categories-list li a:hover {
        background-color: var(--brand-light);
        color: var(--brand-primary);
        padding-left: 26px; /* Hiệu ứng đẩy nhẹ chữ khi hover mượt mà */
    }

    /* Kích hoạt cơ chế hiển thị menu con khi hover chuột vào danh mục gốc tương ứng */
    .main-nav-menu > li:hover .dropdown-categories-list {
        display: block;
    }


    /* ======================================================== */
    /* CẤU TRÚC MOBILE BAR & BOTTOM BAR (BẢO LƯU NGUYÊN VẸN)    */
    /* ======================================================== */
    .header-mobile {
        display: none;
    }
    .bottom-nav-mobile {
        display: none;
    }

    @media (max-width: 768px) {
        .header-pc { display: none; }
        .header-mobile {
            display: flex; justify-content: space-between; align-items: center;
            background-color: var(--brand-light); padding: 10px 20px; border-bottom: 1px solid var(--border-color);
        }
        .mob-search-box {
            display: flex; align-items: center; background: #fff; border: 1px solid var(--brand-primary);
            border-radius: 15px; padding: 4px 10px; flex-grow: 1; margin-right: 15px;
        }
        .mob-search-box input { border: none; outline: none; width: 100%; margin-left: 5px; font-size: 14px; }
        .mob-search-box i { color: var(--brand-primary); }
        
        .bottom-nav-mobile {
            display: flex; justify-content: space-around; position: fixed; bottom: 0; left: 0; width: 100%;
            background: #fff; border-top: 1px solid var(--border-color); padding: 8px 0; z-index: 999;
        }
        .nav-item { display: flex; flex-direction: column; align-items: center; font-size: 11px; color: var(--text-gray); }
        .nav-item i { font-size: 18px; margin-bottom: 2px; }
        .nav-item.active { color: var(--brand-primary); }
    }
</style>

<header class="header-pc">
    
    <div class="header-main-bar">
        <div class="brand-logo-smn">
            <a href="<%= context %>/shop"><img src="<%= context %>/assets/images/logo/logo.png" alt="Dosmé SMN" class="shop-main-logo-img"></a>
        </div>

        <div class="search-wrapper-box">
            <form action="<%= context %>/search" method="GET" class="search-inner-form">
                <input type="text" name="keyword" placeholder="Tìm kiếm mỹ phẩm..." autocomplete="off">
                <button type="submit"><i class="fa-solid fa-magnifying-glass"></i></button>
            </form>
        </div>

        <div class="right-actions-group">
            <a href="<%= context %>/cart/" class="cart-indicator">
                <i class="fa-solid fa-cart-shopping"></i>
                <span class="cart-counter-badge">0</span>
            </a>

            <div class="user-profile-dropdown">
                <div class="user-avatar-trigger">
                    <% if (currentUser != null && currentUser.getAvtUrl() != null && !currentUser.getAvtUrl().isEmpty()) { %>
                        <img src="<%= context %>/assets/images/avt/<%= currentUser.getAvtUrl() %>" alt="Avatar" class="user-avatar-img">
                    <% } else { %>
                        <i class="fa-regular fa-circle-user user-icon-fallback"></i>
                    <% } %>
                </div>
                
                <div class="profile-dropdown-content">
                    <% if (currentUser != null) { %>
                        <div class="dropdown-user-info">
                            <span class="user-name"><%= currentUser.getFullName() %></span>
                            <span class="user-balance">Ví Shop: <%= formatter.format(currentUser.getUserBalance()) %> đ</span>
                        </div>
                        
                        <a href="<%= context %>/UserProfile/"><i class="fa-solid fa-id-card"></i> Thông tin cá nhân</a>
                        <a href="<%= context %>/cart/"><i class="fa-solid fa-basket-shopping"></i> Giỏ hàng của tôi</a>
                        
                        <% if ("admin".equalsIgnoreCase(currentUser.getRole())) { %>
                            <a href="<%= context %>/admin/" target="_blank" class="admin-portal-link">
                                <i class="fa-solid fa-user-shield"></i> Cổng quản trị Admin
                            </a>
                        <% } %>
                        
                        <a href="<%= context %>/login?action=logout" style="border-top: 1px solid var(--border-color); margin-top: 5px;">
                            <i class="fa-solid fa-power-off" style="color: #e53e3e;"></i> Đăng xuất
                        </a>
                    <% } else { %>
                        <a href="<%= context %>/login/"><i class="fa-solid fa-right-to-bracket"></i> Đăng nhập</a>
                        <a href="<%= context %>/register/"><i class="fa-solid fa-user-plus"></i> Đăng ký tài khoản</a>
                    <% } %>
                </div>
            </div>
        </div>
    </div>

    <nav class="header-bottom-navigation">
        <ul class="main-nav-menu">
            <li><a href="<%= context %>/"><i class="fa-solid fa-house"></i> Trang chủ</a></li>
            
            <% 
                for (database.Categories rootCat : rootCategories) { 
                    // Nhặt danh sách danh mục con trực thuộc mã ID của danh mục cha này
                    List<database.Categories> subCategories = categoryDAO.getSubCategoriesByParentId(rootCat.getCategoryId());
            %>
                <li>
                    <a href="<%= context %>/category?id=<%= rootCat.getCategoryId() %>">
                        <%= rootCat.getCategoryName() %> 
                        <% if(!subCategories.isEmpty()) { %>
                            <i class="fa-solid fa-chevron-down" style="font-size: 11px; margin-left: 3px;"></i>
                        <% } %>
                    </a>
                    
                    <% if(!subCategories.isEmpty()) { %>
                        <ul class="dropdown-categories-list">
                            <% for (database.Categories subCat : subCategories) { %>
                                <li>
                                    <a href="<%= context %>/category?id=<%= subCat.getCategoryId() %>">
                                        <i class="fa-solid fa-angle-right" style="font-size: 12px; margin-right: 6px; color: var(--brand-primary);"></i>
                                        <%= subCat.getCategoryName() %>
                                    </a>
                                </li>
                            <% } %>
                        </ul>
                    <% } %>
                </li>
            <% } %>
            
            <li><a href="<%= context %>/cart/">Giỏ hàng</a></li>
            <li><a href="<%= context %>/contact/">Liên hệ góp ý</a></li>
        </ul>
    </nav>

</header>

<header class="header-mobile">
    <div class="mob-search-box">
        <i class="fa-solid fa-magnifying-glass"></i>
        <form action="<%= context %>/search" method="GET" style="flex-grow: 1; display: flex;">
            <input type="text" name="keyword" placeholder="Tìm kiếm mỹ phẩm...">
        </form>
    </div>
    <a href="<%= context %>/cart/" class="cart-wrapper" style="margin:0; padding:0;">
        <i class="fa-solid fa-cart-shopping" style="color: var(--brand-primary);"></i>
        <span class="cart-badge" style="top: -8px; right: -8px;">0</span>
    </a>
</header>

<nav class="bottom-nav-mobile">
    <a href="<%= context %>/shop" class="nav-item active">
        <i class="fa-solid fa-house"></i>
        <span>Trang chủ</span>
    </a>
    <a href="<%= context %>/category/" class="nav-item">
        <i class="fa-solid fa-border-all"></i>
        <span>Danh mục</span>
    </a>
    <a href="<%= context %>/notifications/" class="nav-item">
        <i class="fa-regular fa-bell"></i>
        <span>Thông báo</span>
    </a>
    <a href="<%= context %>/UserProfile/" class="nav-item">
        <i class="fa-regular fa-user"></i>
        <span>Tôi</span>
    </a>
</nav>