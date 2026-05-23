package database;

import java.io.Serializable;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Lớp quản lý Thương hiệu (Brands) - Kết hợp Model và DAO
 */
public class Brands implements Serializable {

    // --- CÁC THUỘC TÍNH (FIELDS) ---
    private int brandId;
    private String brandName;
    private String brandDesc;
    private int totalProducts; // Thuộc tính bổ sung để chứa số lượng sản phẩm

    // --- CONSTRUCTORS ---
    public Brands() {}

    public Brands(int brandId, String brandName, String brandDesc, int totalProducts) {
        this.brandId = brandId;
        this.brandName = brandName;
        this.brandDesc = brandDesc;
        this.totalProducts = totalProducts;
    }

    // --- GETTERS & SETTERS ---
    public int getBrandId() { return brandId; }
    public void setBrandId(int brandId) { this.brandId = brandId; }
    public String getBrandName() { return brandName; }
    public void setBrandName(String brandName) { this.brandName = brandName; }
    public String getBrandDesc() { return brandDesc; }
    public void setBrandDesc(String brandDesc) { this.brandDesc = brandDesc; }
    public int getTotalProducts() { return totalProducts; }
    public void setTotalProducts(int totalProducts) { this.totalProducts = totalProducts; }

    // --- CÁC PHƯƠNG THỨC THAO TÁC DATABASE (DAO) ---

    // 1. Lấy danh sách thương hiệu KÈM THEO TỔNG SỐ SẢN PHẨM
    public List<Brands> getAllBrandsWithCount() {
        List<Brands> list = new ArrayList<>();
        // Sử dụng LEFT JOIN để đếm sản phẩm ngay cả khi thương hiệu chưa có SP nào
        String sql = "SELECT b.brandId, b.brandName, b.brandDesc, COUNT(p.productId) AS totalProducts " +
                     "FROM brands b " +
                     "LEFT JOIN products p ON b.brandId = p.brandId " +
                     "GROUP BY b.brandId, b.brandName, b.brandDesc " +
                     "ORDER BY b.brandName ASC";
        
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new Brands(
                    rs.getInt("brandId"),
                    rs.getString("brandName"),
                    rs.getString("brandDesc"),
                    rs.getInt("totalProducts")
                ));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public Brands getBrandById(int id) {
        String sql = "SELECT * FROM brands WHERE brandId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Brands b = new Brands();
                    b.setBrandId(rs.getInt("brandId"));
                    b.setBrandName(rs.getString("brandName"));
                    b.setBrandDesc(rs.getString("brandDesc"));
                    return b;
                }
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    public boolean insertBrand(Brands b) {
        String sql = "INSERT INTO brands (brandName, brandDesc) VALUES (?, ?)";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, b.getBrandName());
            ps.setString(2, b.getBrandDesc());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean updateBrand(Brands b) {
        String sql = "UPDATE brands SET brandName = ?, brandDesc = ? WHERE brandId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, b.getBrandName());
            ps.setString(2, b.getBrandDesc());
            ps.setInt(3, b.getBrandId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean deleteBrand(int id) {
        String sql = "DELETE FROM brands WHERE brandId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }
}