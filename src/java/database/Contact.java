package database;

import java.io.Serializable;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class Contact implements Serializable {
    private static final long serialVersionUID = 1L;

    // --- CÁC THUỘC TÍNH (FIELDS) KHỚP 100% SCHEMA ---
    private int contactId;
    private int userId;        // Lưu 0 nếu là khách vãng lai chưa đăng nhập
    private String fullName;
    private String email;
    private String phone;
    private String title;
    private String message;
    private int status;        // 0: Chưa đọc, 1: Đã đọc, 2: Đã phản hồi
    private Timestamp createdAt;

    // --- CONSTRUCTORS ---
    public Contact() {}

    // --- GETTERS & SETTERS ---
    public int getContactId() { return contactId; }
    public void setContactId(int contactId) { this.contactId = contactId; }
    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
    public int getStatus() { return status; }
    public void setStatus(int status) { this.status = status; }
    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }


    // =========================================================================
    // --- PHƯƠNG THỨC DAO THAO TÁC DATABASE (CRUD FULL CHỨC NĂNG) ---
    // =========================================================================

    // 1. CHỨC NĂNG: Gửi thông tin liên hệ (Lưu form liên hệ từ khách hàng vào CSDL)
    public boolean insertContact(Contact c) {
        String sql = "INSERT INTO contacts (userId, fullName, email, phone, title, message, status) VALUES (?, ?, ?, ?, ?, ?, 0)";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            // Nếu userId <= 0 (Khách vãng lai chưa đăng nhập tài khoản) -> lưu NULL vào DB
            if (c.getUserId() <= 0) {
                ps.setNull(1, Types.INTEGER);
            } else {
                ps.setInt(1, c.getUserId());
            }
            
            ps.setString(2, c.getFullName());
            ps.setString(3, c.getEmail());
            ps.setString(4, c.getPhone());
            ps.setString(5, c.getTitle());
            ps.setString(6, c.getMessage());
            
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 2. CHỨC NĂNG: Hiển thị danh sách toàn bộ ý kiến liên hệ (Dùng cho Admin quản trị hệ thống)
    public List<Contact> getAllContacts() {
        List<Contact> list = new ArrayList<>();
        String sql = "SELECT * FROM contacts ORDER BY status ASC, createdAt DESC"; // Ưu tiên tin chưa đọc lên đầu
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapResultSetToContact(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    // 3. CHỨC NĂNG: Xem chi tiết một thư liên hệ theo ID
    public Contact getContactById(int contactId) {
        String sql = "SELECT * FROM contacts WHERE contactId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, contactId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapResultSetToContact(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    // 4. CHỨC NĂNG: Cập nhật trạng thái xử lý thư liên hệ (Ví dụ: Đánh dấu đã đọc, Đã trả lời)
    public boolean updateContactStatus(int contactId, int newStatus) {
        String sql = "UPDATE contacts SET status = ? WHERE contactId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, newStatus);
            ps.setInt(2, contactId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 5. CHỨC NĂNG: Xóa thư liên hệ (Khi xử lý xong hoặc dọn rác)
    public boolean deleteContact(int contactId) {
        String sql = "DELETE FROM contacts WHERE contactId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, contactId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 6. CHỨC NĂNG THỐNG KÊ: Đếm số lượng phản hồi chưa xử lý (Hiển thị số thông báo Badge ở góc màn hình Admin)
    public int getNewContactCount() {
        String sql = "SELECT COUNT(*) FROM contacts WHERE status = 0";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    // --- HÀM PHỤ TRỢ (HELPER METHOD) MAPPING DỮ LIỆU ---
    private Contact mapResultSetToContact(ResultSet rs) throws SQLException {
        Contact c = new Contact();
        c.setContactId(rs.getInt("contactId"));
        
        int uId = rs.getInt("userId");
        if (rs.wasNull()) {
            c.setUserId(0); // Nếu rỗng lưu về số 0 để tầng View dễ xử lý logic
        } else {
            c.setUserId(uId);
        }
        
        c.setFullName(rs.getString("fullName"));
        c.setEmail(rs.getString("email"));
        c.setPhone(rs.getString("phone"));
        c.setTitle(rs.getString("title"));
        c.setMessage(rs.getString("message"));
        c.setStatus(rs.getInt("status"));
        c.setCreatedAt(rs.getTimestamp("createdAt"));
        return c;
    }
}