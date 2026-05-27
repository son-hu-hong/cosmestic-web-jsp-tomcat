<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="database.Users" %>
<%
    // Tự động hóa lấy dữ liệu thành viên (User Autocomplete) để tối ưu UX
    // Đảm bảo "userSession" là tên attribute bạn đã lưu khi khách hàng đăng nhập
    Users userSession = (Users) session.getAttribute("userSession"); 
    String defaultName = userSession != null ? userSession.getFullName() : "";
    String defaultEmail = userSession != null ? userSession.getUserEmail() : "";
    String defaultPhone = userSession != null ? userSession.getUserPhone() : "";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Liên hệ - Dosmé Cosmetics</title>
    <style>
        /* Đồng bộ màu sắc thương hiệu Dosmé */
        :root {
            --primary-color: #A67C52;
        }
        body { font-family: 'Times New Roman', serif; margin: 0; padding: 0; background: #fafafa; }

        /* Cơ chế Layout Stability chống vỡ giao diện */
        .main-container {
            display: table;
            width: 100%;
            max-width: 1200px;
            margin: 20px auto;
            border-collapse: separate;
            border-spacing: 20px 0;
        }
        .content-row { display: table-row; }
        .left-menu-cell {
            display: table-cell;
            width: 25%;
            vertical-align: top;
        }
        .content-cell {
            display: table-cell;
            width: 75%;
            vertical-align: top;
            background: #fff;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 4px 10px rgba(0,0,0,0.05);
        }

        /* Styling cho Form Liên hệ */
        .contact-header { color: var(--primary-color); border-bottom: 2px solid var(--primary-color); padding-bottom: 10px; margin-top:0; text-transform: uppercase; }
        .contact-info { margin-bottom: 30px; padding: 15px; background: #fdfaf6; border-left: 4px solid var(--primary-color); }
        
        .form-group { margin-bottom: 15px; }
        .form-group label { display: block; font-weight: bold; margin-bottom: 5px; color: #333; }
        .form-group input, .form-group textarea {
            width: 100%; padding: 10px; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box; font-family: inherit; font-size: 15px;
        }
        .form-group input:focus, .form-group textarea:focus {
            border-color: var(--primary-color); outline: none; box-shadow: 0 0 5px rgba(166,124,82,0.3);
        }
        
        .btn-submit {
            background: var(--primary-color); color: white; padding: 12px 25px; border: none; border-radius: 4px;
            cursor: pointer; font-size: 16px; font-weight: bold; transition: background 0.3s; width: 100%;
        }
        .btn-submit:hover { background: #8e6842; }
        .error-msg { color: #d9534f; font-size: 13px; display: none; margin-top: 5px; font-style: italic; }
    </style>
</head>
<body>

    <jsp:include page="../assets/components/header.jsp" />

    <div class="main-container">
        <div class="content-row">
            
            <div class="left-menu-cell">
                <jsp:include page="../assets/components/left_menu.jsp" />
            </div>

            <div class="content-cell">
                <h2 class="contact-header">Thông tin liên hệ</h2>
                
                <div class="contact-info">
                    <p><strong>📍 Địa chỉ trụ sở:</strong> Số 1, Đại Cồ Việt, Hai Bà Trưng, Hà Nội</p>
                    <p><strong>📞 Hotline hỗ trợ:</strong> 1900 1234 (Miễn phí cước gọi)</p>
                    <p><strong>✉️ Email CSKH:</strong> support@dosme.vn</p>
                </div>

                <form id="contactForm" action="${pageContext.request.contextPath}/ContactServlet" method="POST" onsubmit="return validateContactForm()">
                    
                    <div class="form-group">
                        <label for="fullName">Họ và tên (*)</label>
                        <input type="text" id="fullName" name="fullName" value="<%= defaultName %>" placeholder="Nhập họ và tên của bạn...">
                        <span id="errName" class="error-msg">Vui lòng nhập họ tên!</span>
                    </div>

                    <div class="form-group">
                        <label for="email">Địa chỉ Email (*)</label>
                        <input type="text" id="email" name="email" value="<%= defaultEmail %>" placeholder="VD: nguyenvan@gmail.com">
                        <span id="errEmail" class="error-msg">Email không được để trống và phải đúng định dạng (có @)!</span>
                    </div>

                    <div class="form-group">
                        <label for="phone">Số điện thoại (*)</label>
                        <input type="text" id="phone" name="phone" value="<%= defaultPhone %>" placeholder="Nhập số điện thoại liên hệ...">
                        <span id="errPhone" class="error-msg">Số điện thoại không hợp lệ (Chỉ chứa số, từ 9-11 ký tự)!</span>
                    </div>

                    <div class="form-group">
                        <label for="title">Chủ đề liên hệ (*)</label>
                        <input type="text" id="title" name="title" placeholder="VD: Cần tư vấn sản phẩm chăm sóc da mụn">
                        <span id="errTitle" class="error-msg">Vui lòng nhập chủ đề bạn muốn liên hệ!</span>
                    </div>

                    <div class="form-group">
                        <label for="message">Nội dung chi tiết (*)</label>
                        <textarea id="message" name="message" rows="6" placeholder="Vui lòng mô tả chi tiết yêu cầu của bạn tại đây..."></textarea>
                        <span id="errMessage" class="error-msg">Nội dung liên hệ không được để trống!</span>
                    </div>

                    <button type="submit" class="btn-submit">GỬI YÊU CẦU CHO CHÚNG TÔI</button>
                </form>
            </div>
        </div>
    </div>

    <jsp:include page="../assets/components/footer.jsp" />

    <script>
        function validateContactForm() {
            let isValid = true;

            // Lấy dữ liệu từ thẻ input
            const name = document.getElementById("fullName").value.trim();
            const email = document.getElementById("email").value.trim();
            const phone = document.getElementById("phone").value.trim();
            const title = document.getElementById("title").value.trim();
            const message = document.getElementById("message").value.trim();

            // Ẩn toàn bộ thông báo lỗi cũ
            document.querySelectorAll('.error-msg').forEach(e => e.style.display = 'none');

            // 1. Kiểm tra Họ Tên
            if (name === "") {
                document.getElementById("errName").style.display = "block";
                isValid = false;
            }

            // 2. Kiểm tra Email (đúng định dạng)
            const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (email === "" || !emailPattern.test(email)) {
                document.getElementById("errEmail").style.display = "block";
                isValid = false;
            }

            // 3. Kiểm tra Số điện thoại (chỉ có số, 9-11 ký tự)
            const phonePattern = /^[0-9]{9,11}$/;
            if (phone === "" || !phonePattern.test(phone)) {
                document.getElementById("errPhone").style.display = "block";
                isValid = false;
            }

            // 4. Kiểm tra Chủ đề
            if (title === "") {
                document.getElementById("errTitle").style.display = "block";
                isValid = false;
            }

            // 5. Kiểm tra Nội dung
            if (message === "") {
                document.getElementById("errMessage").style.display = "block";
                isValid = false;
            }

            // Nếu isValid = false, JS sẽ tự động return false chặn form không gửi dữ liệu đi
            return isValid;
        }
    </script>
</body>
</html>