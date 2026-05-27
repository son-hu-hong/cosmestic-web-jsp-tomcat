package database;

import java.io.Serializable;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import service.PasswordUtil;

/**
 * Lớp hợp nhất: Vừa là Model (POJO) vừa là DAO.
 */
public class Users implements Serializable {

    // --- CÁC THUỘC TÍNH (FIELDS) ---
    private int userId;
    private String userName;
    private String fullName;
    private String userSexual; // 'default', 'male', 'female'
    private String userEmail;
    private String userPhone;
    private String userAddress;
    private String password;
    private int disable;
    private String avtUrl;
    private String role;
    private int userBalance; // Số dư tài khoản

    // --- CONSTRUCTORS ---
    public Users() {
        this.userSexual = "default";
        this.userBalance = 10000000; // Giá trị mặc định khi tạo mới object
    }

    public Users(int userId, String userName, String fullName, String userSexual, String userEmail, 
                 String userPhone, String userAddress, String password, int disable, String avtUrl, String role, int userBalance) {
        this.userId = userId;
        this.userName = userName;
        this.fullName = fullName;
        this.userSexual = userSexual;
        this.userEmail = userEmail;
        this.userPhone = userPhone;
        this.userAddress = userAddress;
        this.password = password;
        this.disable = disable;
        this.avtUrl = avtUrl;
        this.role = role;
        this.userBalance = userBalance;
    }

    // --- GETTERS & SETTERS ---
    // ... (Giữ nguyên các Getters/Setters cũ) ...
    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }
    public String getUserName() { return userName; }
    public void setUserName(String userName) { this.userName = userName; }
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public String getUserSexual() { return userSexual; }
    public void setUserSexual(String userSexual) { this.userSexual = userSexual; }
    public String getUserEmail() { return userEmail; }
    public void setUserEmail(String userEmail) { this.userEmail = userEmail; }
    public String getUserPhone() { return userPhone; }
    public void setUserPhone(String userPhone) { this.userPhone = userPhone; }
    public String getUserAddress() { return userAddress; }
    public void setUserAddress(String userAddress) { this.userAddress = userAddress; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public int getDisable() { return disable; }
    public void setDisable(int disable) { this.disable = disable; }
    public String getAvtUrl() { return avtUrl; }
    public void setAvtUrl(String avtUrl) { this.avtUrl = avtUrl; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
    public int getUserBalance() { return userBalance; }
    public void setUserBalance(int userBalance) { this.userBalance = userBalance; }

    // --- CÁC PHƯƠNG THỨC THAO TÁC DATABASE (DAO) ---

    // 1. Thêm người dùng mới (Dùng cho Đăng ký)
    public String insertUser(Users users) {
        // Cập nhật câu lệnh SQL
        String sql = "INSERT INTO users (userName, fullName, userSexual, userEmail, userPhone, userAddress, password, disable, avt_url, role, userBalance) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, users.getUserName());
            ps.setString(2, users.getFullName());
            ps.setString(3, users.getUserSexual() != null ? users.getUserSexual() : "default");
            ps.setString(4, users.getUserEmail());
            ps.setString(5, users.getUserPhone());
            ps.setString(6, users.getUserAddress());
            ps.setString(7, users.getPassword());
            ps.setInt(8, users.getDisable());
            ps.setString(9, users.getAvtUrl());
            ps.setString(10, users.getRole());
            ps.setInt(11, users.getUserBalance() > 0 ? users.getUserBalance() : 10000000); // Gắn số dư
            
            return ps.executeUpdate() > 0 ? "" : "Không có dòng nào được thêm vào cơ sở dữ liệu.";
        } catch (SQLException e) {
            e.printStackTrace();
            return "Lỗi SQL: " + e.getMessage();
        }
    }

    // 2. Kiểm tra đăng nhập
    public Users checkLogin(String userName, String plainPassword) {
        String hashedPassword = PasswordUtil.hashPassword(plainPassword);
        String sql = "SELECT * FROM users WHERE userName=? AND password=? AND disable=0";
        
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, userName);
            ps.setString(2, hashedPassword);
            
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapResultSetToUser(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    // 3. Lấy thông tin người dùng theo ID
    public Users getUserById(int userId) {
        String sql = "SELECT * FROM users WHERE userId=?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapResultSetToUser(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    // 4. Cập nhật thông tin người dùng
    public boolean updateUser(Users users) {
        // Cập nhật câu lệnh SQL
        String sql = "UPDATE users SET fullName=?, userSexual=?, userEmail=?, userPhone=?, userAddress=?, disable=?, avt_url=?, role=?, userBalance=? WHERE userId=?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, users.getFullName());
            ps.setString(2, users.getUserSexual() != null ? users.getUserSexual() : "default");
            ps.setString(3, users.getUserEmail());
            ps.setString(4, users.getUserPhone());
            ps.setString(5, users.getUserAddress());
            ps.setInt(6, users.getDisable());
            ps.setString(7, users.getAvtUrl());
            ps.setString(8, users.getRole());
            ps.setInt(9, users.getUserBalance()); // Cập nhật số dư
            ps.setInt(10, users.getUserId());
            
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 5. Lấy danh sách toàn bộ người dùng
    public List<Users> getAllUsers(String orderBy, boolean isAsc) {
        List<Users> list = new ArrayList<>();
        // Bổ sung userBalance vào whitelist sắp xếp
        String validColumn = orderBy.matches("^(userId|userName|fullName|userEmail|role|userBalance)$") ? orderBy : "userId";
        String direction = isAsc ? "ASC" : "DESC";
        
        String sql = "SELECT * FROM users ORDER BY " + validColumn + " " + direction;
        
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            
            while (rs.next()) {
                list.add(mapResultSetToUser(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<Users> getAllUsers() {
        return getAllUsers("userId", true);
    }

    // Hàm phụ trợ map dữ liệu
    private Users mapResultSetToUser(ResultSet rs) throws SQLException {
        Users u = new Users();
        u.setUserId(rs.getInt("userId"));
        u.setUserName(rs.getString("userName"));
        u.setFullName(rs.getString("fullName"));
        u.setUserSexual(rs.getString("userSexual")); 
        u.setUserEmail(rs.getString("userEmail"));
        u.setUserPhone(rs.getString("userPhone"));
        u.setUserAddress(rs.getString("userAddress"));
        u.setPassword(rs.getString("password"));
        u.setDisable(rs.getInt("disable"));
        u.setAvtUrl(rs.getString("avt_url"));
        u.setRole(rs.getString("role"));
        u.setUserBalance(rs.getInt("userBalance")); // Map dữ liệu số dư
        return u;
    }

    // Tìm kiếm người dùng bằng Username OR Email OR Số điện thoại
    public Users getUserByAny(String identifier) {
        String sql = "SELECT * FROM users WHERE userName=? OR userEmail=? OR userPhone=?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps =conn.prepareStatement(sql)) {

            ps.setString(1, identifier);
            ps.setString(2, identifier);
            ps.setString(3, identifier);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapResultSetToUser(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    // 6. Xóa người dùng
    public boolean deleteUser(int userId) {
        String sql = "DELETE FROM users WHERE userId=?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 7. Kiểm tra trùng lặp Username
    public boolean checkUserNameExists(String userName) {
        String sql = "SELECT userId FROM users WHERE userName=?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, userName);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 7.1 Cập nhật riêng tên đăng nhập
    public boolean updateUserName(int userId, String newUserName) {
        String sql = "UPDATE users SET userName=? WHERE userId=?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, newUserName);
            ps.setInt(2, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 8. Cập nhật mật khẩu mới bằng Email
    public boolean updatePassword(String email, String hashedSubPassword) {
        String sql = "UPDATE users SET password=? WHERE userEmail=?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, hashedSubPassword);
            ps.setString(2, email);

            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 9. Cập nhật riêng ảnh đại diện
    public boolean updateAvatar(int userId, String newAvtUrl) {
        String sql = "UPDATE users SET avt_url=? WHERE userId=?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, newAvtUrl);
            ps.setInt(2, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    // 10. (Tính năng thêm) Cập nhật số dư (Trừ tiền khi mua hàng hoặc cộng tiền)
    public boolean updateBalance(int userId, int newBalance) {
        String sql = "UPDATE users SET userBalance=? WHERE userId=?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, newBalance);
            ps.setInt(2, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    // 11. Cộng tiền (khi hoàn hàng, admin nạp tiền)
    public boolean addBalance(int userId, int amount) {
        if (amount <= 0) return false; // Không cộng số âm
        
        // Cộng trực tiếp vào CSDL
        String sql = "UPDATE users SET userBalance = userBalance + ? WHERE userId=?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, amount);
            ps.setInt(2, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 12. Trừ tiền (khi thanh toán đơn hàng)
    public boolean deductBalance(int userId, int amount) {
        if (amount <= 0) return false; 
        
        // Trừ trực tiếp và chỉ cho phép trừ nếu số dư hiện tại >= số tiền cần trừ
        String sql = "UPDATE users SET userBalance = userBalance - ? WHERE userId=? AND userBalance >= ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, amount);
            ps.setInt(2, userId);
            ps.setInt(3, amount); // Ràng buộc số dư không bị âm
            
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
}