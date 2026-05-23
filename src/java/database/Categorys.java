package database;

import java.io.Serializable;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Lớp quản lý Danh mục sản phẩm (Categorys)
 */
public class Categorys implements Serializable {

    // --- CÁC THUỘC TÍNH (FIELDS) ---
    private int categoryId;
    private String categoryName;
    
    // Thuộc tính mở rộng: Số lượng sản phẩm thuộc danh mục này
    private int productCount; 

    // --- CONSTRUCTORS ---
    public Categorys() {}

    public Categorys(int categoryId, String categoryName, int productCount) {
        this.categoryId = categoryId;
        this.categoryName = categoryName;
        this.productCount = productCount;
    }

    // --- GETTERS & SETTERS ---
    public int getCategoryId() { return categoryId; }
    public void setCategoryId(int categoryId) { this.categoryId = categoryId; }

    public String getCategoryName() { return categoryName; }
    public void setCategoryName(String categoryName) { this.categoryName = categoryName; }

    public int getProductCount() { return productCount; }
    public void setProductCount(int productCount) { this.productCount = productCount; }

    // --- CÁC PHƯƠNG THỨC THAO TÁC DATABASE (DAO) ---

    // 1. Lấy danh sách danh mục KÈM SỐ LƯỢNG SẢN PHẨM
    public List<Categorys> getAllCategoriesWithCount() {
        List<Categorys> list = new ArrayList<>();
        // Sử dụng LEFT JOIN để đếm số sản phẩm trong bảng products thuộc category này
        String sql = "SELECT c.categoryId, c.categoryName, COUNT(p.productId) as productCount " +
                     "FROM categorys c " +
                     "LEFT JOIN products p ON c.categoryId = p.categoryId " +
                     "GROUP BY c.categoryId, c.categoryName " +
                     "ORDER BY c.categoryId ASC";
                     
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new Categorys(
                    rs.getInt("categoryId"),
                    rs.getString("categoryName"),
                    rs.getInt("productCount")
                ));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    // 2. Lấy thông tin danh mục theo ID
    public Categorys getCategoryById(int id) {
        String sql = "SELECT * FROM categorys WHERE categoryId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Categorys c = new Categorys();
                    c.setCategoryId(rs.getInt("categoryId"));
                    c.setCategoryName(rs.getString("categoryName"));
                    return c;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    // 3. Thêm danh mục mới
    public boolean insertCategory(Categorys c) {
        String sql = "INSERT INTO categorys (categoryName) VALUES (?)";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, c.getCategoryName());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 4. Cập nhật thông tin danh mục
    public boolean updateCategory(Categorys c) {
        String sql = "UPDATE categorys SET categoryName = ? WHERE categoryId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, c.getCategoryName());
            ps.setInt(2, c.getCategoryId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 5. Xóa danh mục
    public boolean deleteCategory(int id) {
        String sql = "DELETE FROM categorys WHERE categoryId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
}