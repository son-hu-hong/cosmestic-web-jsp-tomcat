package database;

import java.io.Serializable;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Lớp quản lý Danh mục sản phẩm (Categories)
 * Mô hình hợp nhất: Vừa là Model (POJO) vừa là DAO.
 */
public class Categories implements Serializable {
    private static final long serialVersionUID = 1L;

    // --- CÁC THUỘC TÍNH (FIELDS) KHỚP 100% SCHEMA ĐA CẤP ---
    private int categoryId;
    private String categoryName;
    private int parentId;      // ID danh mục cha (Nếu = 0 hoặc null trong DB thì là danh mục gốc)
    private int status;        // Trạng thái (1: Hoạt động hiển thị, 0: Khóa/Ẩn)
    
    // Các thuộc tính mở rộng phục vụ hiển thị giao diện nhanh (UI Helpers)
    private int productCount;   // Số lượng sản phẩm trực thuộc danh mục này
    private String parentName;  // Tên của danh mục cha (Hiển thị trong bảng Admin)

    // --- CONSTRUCTORS ---
    public Categories() {}

    // --- GETTERS & SETTERS ---
    public int getCategoryId() { return categoryId; }
    public void setCategoryId(int categoryId) { this.categoryId = categoryId; }

    public String getCategoryName() { return categoryName; }
    public void setCategoryName(String categoryName) { this.categoryName = categoryName; }

    public int getParentId() { return parentId; }
    public void setParentId(int parentId) { this.parentId = parentId; }

    public int getStatus() { return status; }
    public void setStatus(int status) { this.status = status; }

    public int getProductCount() { return productCount; }
    public void setProductCount(int productCount) { this.productCount = productCount; }

    public String getParentName() { return parentName; }
    public void setParentName(String parentName) { this.parentName = parentName; }


    // =========================================================================
    // --- CÁC PHƯƠNG THỨC THAO TÁC DATABASE (DAO FULL CHỨC NĂNG) ---
    // =========================================================================

    // 1. CHỨC NĂNG: Thêm mới danh mục (Hỗ trợ cả danh mục gốc lẫn danh mục con)
    public boolean insertCategory(Categories c) {
        String sql = "INSERT INTO categories (categoryName, parentId, status) VALUES (?, ?, ?)";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, c.getCategoryName());
            
            // Xử lý lưu parentId: Nếu không chọn cha (parentId = 0) -> lưu NULL vào database
            if (c.getParentId() <= 0) {
                ps.setNull(2, Types.INTEGER);
            } else {
                ps.setInt(2, c.getParentId());
            }
            
            ps.setInt(3, c.getStatus());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 2. CHỨC NĂNG: Cập nhật / Chỉnh sửa thông tin danh mục
    public boolean updateCategory(Categories c) {
        String sql = "UPDATE categories SET categoryName = ?, parentId = ?, status = ? WHERE categoryId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, c.getCategoryName());
            
            // Xử lý lưu parentId rỗng
            if (c.getParentId() <= 0) {
                ps.setNull(2, Types.INTEGER);
            } else {
                ps.setInt(2, c.getParentId());
            }
            
            ps.setInt(3, c.getStatus());
            ps.setInt(4, c.getCategoryId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 3. CHỨC NĂNG: Xóa danh mục
    public boolean deleteCategory(int id) {
        String sql = "DELETE FROM categories WHERE categoryId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 4. CHỨC NĂNG: Lấy toàn bộ danh sách danh mục (Phục vụ bảng quản trị của Admin)
    // Tự động tính số lượng sản phẩm của từng mục và tìm tên danh mục cha bằng subquery
    public List<Categories> getAllCategories() {
        List<Categories> list = new ArrayList<>();
        String sql = "SELECT c.*, " +
                     "(SELECT categoryName FROM categories WHERE categoryId = c.parentId) AS pName, " +
                     "(SELECT COUNT(*) FROM products WHERE categoryId = c.categoryId) AS pCount " +
                     "FROM categories c ORDER BY c.categoryId DESC";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapResultSetToCategory(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    // 5. CHỨC NĂNG: Lấy chi tiết một danh mục theo ID (Dùng khi bấm nút Sửa để đổ dữ liệu cũ ra Form)
    public Categories getCategoryById(int id) {
        String sql = "SELECT c.*, " +
                     "(SELECT categoryName FROM categories WHERE categoryId = c.parentId) AS pName, " +
                     "(SELECT COUNT(*) FROM products WHERE categoryId = c.categoryId) AS pCount " +
                     "FROM categories c WHERE c.categoryId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapResultSetToCategory(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    // 6. CHỨC NĂNG: Lấy danh sách danh mục GỐC / CHA (parentId IS NULL)
    // Thường dùng đổ vào thẻ select chọn "Danh mục gốc" khi thêm danh mục mới
    public List<Categories> getRootCategories() {
        List<Categories> list = new ArrayList<>();
        String sql = "SELECT c.*, NULL AS pName, 0 AS pCount FROM categories c WHERE c.parentId IS NULL AND c.status = 1";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapResultSetToCategory(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    // 7. CHỨC NĂNG: Lấy danh sách danh mục CON theo ID danh mục cha
    // Thường dùng cho cụm chức năng Left Menu (Hover menu chuột) ngoài trang chủ
    public List<Categories> getSubCategoriesByParentId(int parentId) {
        List<Categories> list = new ArrayList<>();
        String sql = "SELECT c.*, " +
                     "(SELECT categoryName FROM categories WHERE categoryId = ?) AS pName, " +
                     "(SELECT COUNT(*) FROM products WHERE categoryId = c.categoryId) AS pCount " +
                     "FROM categories c WHERE c.parentId = ? AND c.status = 1";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, parentId);
            ps.setInt(2, parentId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapResultSetToCategory(rs));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    // --- HÀM PHỤ TRỢ (HELPER METHOD) MAPPING DỮ LIỆU ---
    private Categories mapResultSetToCategory(ResultSet rs) throws SQLException {
        Categories c = new Categories();
        c.setCategoryId(rs.getInt("categoryId"));
        c.setCategoryName(rs.getString("categoryName"));
        c.setStatus(rs.getInt("status"));
        
        // Xử lý giá trị NULL của parentId một cách an toàn trong Java
        int pId = rs.getInt("parentId");
        if (rs.wasNull()) {
            c.setParentId(0); // Nếu trong DB là NULL thì chuyển về số 0 cho dễ check ở tầng View
        } else {
            c.setParentId(pId);
        }

        // Đọc dữ liệu từ các cột tính toán bổ sung (Subqueries)
        try {
            c.setParentName(rs.getString("pName"));
            c.setProductCount(rs.getInt("pCount"));
        } catch (SQLException ignored) {
            // Trường hợp một số hàm truy vấn không select hai cột này thì bỏ qua không báo lỗi
        }
        return c;
    }
}