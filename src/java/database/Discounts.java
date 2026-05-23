package database;

import java.io.Serializable;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class Discounts implements Serializable {
    private int discountId;
    private String discountName;
    private Date discountStart;
    private Date discountEnd;
    private int discountValue;

    public Discounts() {}

    // Getters và Setters
    public int getDiscountId() { return discountId; }
    public void setDiscountId(int discountId) { this.discountId = discountId; }
    public String getDiscountName() { return discountName; }
    public void setDiscountName(String discountName) { this.discountName = discountName; }
    public Date getDiscountStart() { return discountStart; }
    public void setDiscountStart(Date discountStart) { this.discountStart = discountStart; }
    public Date getDiscountEnd() { return discountEnd; }
    public void setDiscountEnd(Date discountEnd) { this.discountEnd = discountEnd; }
    public int getDiscountValue() { return discountValue; }
    public void setDiscountValue(int discountValue) { this.discountValue = discountValue; }

    // --- CÁC PHƯƠNG THỨC DAO ---

    public List<Discounts> getAllDiscounts() {
        List<Discounts> list = new ArrayList<>();
        String sql = "SELECT * FROM discounts ORDER BY discountEnd DESC";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Discounts d = new Discounts();
                d.setDiscountId(rs.getInt("discountId"));
                d.setDiscountName(rs.getString("discountName"));
                d.setDiscountStart(rs.getDate("discountStart"));
                d.setDiscountEnd(rs.getDate("discountEnd"));
                d.setDiscountValue(rs.getInt("discountValue"));
                list.add(d);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public boolean insertDiscount(Discounts d) {
        String sql = "INSERT INTO discounts (discountName, discountStart, discountEnd, discountValue) VALUES (?, ?, ?, ?)";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, d.getDiscountName());
            ps.setDate(2, d.getDiscountStart());
            ps.setDate(3, d.getDiscountEnd());
            ps.setInt(4, d.getDiscountValue());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean deleteDiscount(int id) {
        String sql = "DELETE FROM discounts WHERE discountId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    // Kiểm tra mã còn hạn hay không
    public boolean isValid(int id) {
        String sql = "SELECT 1 FROM discounts WHERE discountId = ? AND CURRENT_DATE BETWEEN discountStart AND discountEnd";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) { return rs.next(); }
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }
}