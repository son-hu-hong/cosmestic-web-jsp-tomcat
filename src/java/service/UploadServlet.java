package service;

import database.Users;
import java.io.File;
import java.io.IOException;
import java.nio.file.Paths;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;

// ĐÂY LÀ DÒNG QUAN TRỌNG NHẤT: Bắt đường dẫn /upload-avatar từ giao diện
@WebServlet("/upload-avatar") 

// Cấu hình cho phép nhận file đính kèm
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2, // 2MB
    maxFileSize = 1024 * 1024 * 10,      // Giới hạn file tối đa 10MB
    maxRequestSize = 1024 * 1024 * 50    // 50MB
)
public class UploadServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Đường dẫn trả về mặc định
        String returnUrl = request.getContextPath() + "/UserProfile/config/";

        // 1. Kiểm tra session
        Users currentUser = (Users) request.getSession().getAttribute("user");
        if (currentUser == null) {
            response.sendRedirect(request.getContextPath() + "/login/");
            return;
        }

        try {
            // 2. Lấy dữ liệu file từ input có name="avatarFile"
            Part filePart = request.getPart("avatarFile"); 
            
            // Nếu người dùng không chọn file
            if (filePart == null || filePart.getSize() == 0) {
                response.sendRedirect(returnUrl + "?msg=error_file");
                return;
            }

            String fileName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
            if (fileName == null || fileName.isEmpty()) {
                response.sendRedirect(returnUrl + "?msg=error_file");
                return;
            }

            // 3. Lấy đuôi mở rộng của ảnh (.jpg, .png, .jpeg)
            String extension = "";
            int i = fileName.lastIndexOf('.');
            if (i > 0) {
                extension = fileName.substring(i);
            } else {
                extension = ".png"; 
            }

            // 4. Đổi tên file thành ID của người dùng (Ví dụ: 12.jpg)
            String newFileName = currentUser.getUserId() + extension;

            // 5. Tìm đường dẫn thực tế trên máy chủ để lưu ảnh
            String uploadPath = getServletContext().getRealPath("") + File.separator + "assets" + File.separator + "images" + File.separator + "avt";
            File uploadDir = new File(uploadPath);
            if (!uploadDir.exists()) {
                uploadDir.mkdirs(); // Tự động tạo thư mục nếu chưa có
            }

            // 6. Ghi file trực tiếp vào ổ cứng
            filePart.write(uploadPath + File.separator + newFileName);

            // 7. Lưu tên ảnh mới vào Database
            Users dao = new Users();
            if (dao.updateAvatar(currentUser.getUserId(), newFileName)) {
                // Thành công: Cập nhật lại session và quay về trang cá nhân
                currentUser.setAvtUrl(newFileName);
                request.getSession().setAttribute("user", currentUser);
                response.sendRedirect(returnUrl + "?msg=success");
            } else {
                response.sendRedirect(returnUrl + "?msg=db_error");
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(returnUrl + "?msg=upload_failed");
        }
    }
}