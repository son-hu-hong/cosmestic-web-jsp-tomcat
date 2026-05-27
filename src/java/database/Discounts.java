package database;

import java.io.Serializable;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class Discounts implements Serializable {
    private static final long serialVersionUID = 1L;

    // --- CÁC THUỘC TÍNH (FIELDS) KHỚP 100% VỚI DATABASE CHUẨN TMĐT ---
    private int discountId;
    private String discountCode;       // Mã giảm giá (Vd: DOSMEHE20)
    private String discountTitle;      // Tên hiển thị chương trình
    private String discountType;       // Kiểu: "percentage" (theo %) hoặc "fixed" (tiền mặt)
    private double discountValue;      // Giá trị giảm giá
    private double minOrderValue;      // Giá trị đơn hàng tối thiểu để áp dụng
    private double maxDiscountAmount;  // Số tiền giảm tối đa (Áp dụng cho giảm theo %)
    private String applyScope;         // Phạm vi áp dụng: "order" hoặc "product"
    private int usageLimit;            // Giới hạn tổng số lượt sử dụng
    private int usedCount;             // Số lượt đã dùng thực tế
    private Timestamp startTime;       // Thời gian bắt đầu hiệu lực
    private Timestamp endTime;         // Thời gian hết hạn
    private int status;                // Trạng thái (1: Hoạt động, 0: Khóa/Hết lượt)

    // --- CONSTRUCTORS ---
    public Discounts() {}

    // --- GETTERS & SETTERS ---
    public int getDiscountId() { return discountId; }
    public void setDiscountId(int discountId) { this.discountId = discountId; }
    public String getDiscountCode() { return discountCode; }
    public void setDiscountCode(String discountCode) { this.discountCode = discountCode; }
    public String getDiscountTitle() { return discountTitle; }
    public void setDiscountTitle(String discountTitle) { this.discountTitle = discountTitle; }
    public String getDiscountType() { return discountType; }
    public void setDiscountType(String discountType) { this.discountType = discountType; }
    public double getDiscountValue() { return discountValue; }
    public void setDiscountValue(double discountValue) { this.discountValue = discountValue; }
    public double getMinOrderValue() { return minOrderValue; }
    public void setMinOrderValue(double minOrderValue) { this.minOrderValue = minOrderValue; }
    public double getMaxDiscountAmount() { return maxDiscountAmount; }
    public void setMaxDiscountAmount(double maxDiscountAmount) { this.maxDiscountAmount = maxDiscountAmount; }
    public String getApplyScope() { return applyScope; }
    public void setApplyScope(String applyScope) { this.applyScope = applyScope; }
    public int getUsageLimit() { return usageLimit; }
    public void setUsageLimit(int usageLimit) { this.usageLimit = usageLimit; }
    public int getUsedCount() { return usedCount; }
    public void setUsedCount(int usedCount) { this.usedCount = usedCount; }
    public Timestamp getStartTime() { return startTime; }
    public void setStartTime(Timestamp startTime) { this.startTime = startTime; }
    public Timestamp getEndTime() { return endTime; }
    public void setEndTime(Timestamp endTime) { this.endTime = endTime; }
    public int getStatus() { return status; }
    public void setStatus(int status) { this.status = status; }


    // =========================================================================
    // --- CÁC PHƯƠNG THỨC DAO (CRUD & LOGIC XỬ LÝ MÃ GIẢM GIÁ) ---
    // =========================================================================

    // 1. CHỨC NĂNG: Thêm mới mã giảm giá
    public boolean insertDiscount(Discounts d) {
        String sql = "INSERT INTO discounts (discountCode, discountTitle, discountType, discountValue, " +
                     "minOrderValue, maxDiscountAmount, applyScope, usageLimit, startTime, endTime, status) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, d.getDiscountCode());
            ps.setString(2, d.getDiscountTitle());
            ps.setString(3, d.getDiscountType());
            ps.setDouble(4, d.getDiscountValue());
            ps.setDouble(5, d.getMinOrderValue());
            ps.setDouble(6, d.getMaxDiscountAmount());
            ps.setString(7, d.getApplyScope());
            ps.setInt(8, d.getUsageLimit());
            ps.setTimestamp(9, d.getStartTime());
            ps.setTimestamp(10, d.getEndTime());
            ps.setInt(11, d.getStatus());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 2. CHỨC NĂNG: Hiển thị toàn bộ danh sách mã giảm giá (Sắp xếp theo hạn dùng mới nhất)
    public List<Discounts> getAllDiscounts() {
        List<Discounts> list = new ArrayList<>();
        String sql = "SELECT * FROM discounts ORDER BY endTime DESC";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapResultSetToDiscount(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    // 3. CHỨC NĂNG: Lấy thông tin chi tiết một mã qua ID (Phục vụ trang sửa)
    public Discounts getDiscountById(int discountId) {
        String sql = "SELECT * FROM discounts WHERE discountId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, discountId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapResultSetToDiscount(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    // 4. CHỨC NĂNG: Cập nhật / Chỉnh sửa mã giảm giá
    public boolean updateDiscount(Discounts d) {
        String sql = "UPDATE discounts SET discountCode=?, discountTitle=?, discountType=?, discountValue=?, " +
                     "minOrderValue=?, maxDiscountAmount=?, applyScope=?, usageLimit=?, startTime=?, endTime=?, status=? " +
                     "WHERE discountId=?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, d.getDiscountCode());
            ps.setString(2, d.getDiscountTitle());
            ps.setString(3, d.getDiscountType());
            ps.setDouble(4, d.getDiscountValue());
            ps.setDouble(5, d.getMinOrderValue());
            ps.setDouble(6, d.getMaxDiscountAmount());
            ps.setString(7, d.getApplyScope());
            ps.setInt(8, d.getUsageLimit());
            ps.setTimestamp(9, d.getStartTime());
            ps.setTimestamp(10, d.getEndTime());
            ps.setInt(11, d.getStatus());
            ps.setInt(12, d.getDiscountId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 5. CHỨC NĂNG: Xóa mã giảm giá ra khỏi hệ thống
    public boolean deleteDiscount(int discountId) {
        String sql = "DELETE FROM discounts WHERE discountId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, discountId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 6. CHỨC NĂNG ĐẶC BIỆT: Kiểm tra tính hợp lệ và tính số tiền giảm giá thực tế
    /**
     * @param code Chuỗi mã người dùng nhập vào ô Voucher
     * @param totalOrderAmount Tổng tiền hóa đơn hiện tại trong giỏ hàng
     * @return Số tiền được giảm (Trả về 0.0 nếu mã không đúng, hết hạn, hết lượt, hoặc không đủ min đơn)
     */
    public double checkVoucherValidation(String code, double totalOrderAmount) {
        String sql = "SELECT * FROM discounts WHERE discountCode = ? AND status = 1";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, code);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Discounts d = mapResultSetToDiscount(rs);
                    Timestamp now = new Timestamp(System.currentTimeMillis());

                    // A. Kiểm tra thời gian hiệu lực
                    if (now.before(d.getStartTime()) || now.after(d.getEndTime())) {
                        return 0.0; 
                    }

                    // B. Kiểm tra số lượt còn lại của mã
                    if (d.getUsedCount() >= d.getUsageLimit()) {
                        return 0.0; 
                    }

                    // C. Kiểm tra điều kiện giá trị đơn hàng tối thiểu (Min đơn)
                    if (totalOrderAmount < d.getMinOrderValue()) {
                        return 0.0; 
                    }

                    // D. TÍNH TOÁN SỐ TIỀN GIẢM GIÁ THỰC TẾ
                    if ("fixed".equalsIgnoreCase(d.getDiscountType())) {
                        return d.getDiscountValue(); // Giảm thẳng tiền cố định (Vd: Giảm 30k)
                    } else if ("percentage".equalsIgnoreCase(d.getDiscountType())) {
                        double calculatedDiscount = totalOrderAmount * (d.getDiscountValue() / 100.0);
                        
                        // Nếu số tiền tính theo % vượt quá số tiền giảm tối đa cho phép (Trần giảm giá)
                        if (d.getMaxDiscountAmount() > 0 && calculatedDiscount > d.getMaxDiscountAmount()) {
                            return d.getMaxDiscountAmount(); // Ép về mức tối đa cho phép
                        }
                        return calculatedDiscount;
                    }
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0.0;
    }

    // 7. CHỨC NĂNG: Tự động cộng 1 vào usedCount khi đặt hàng thành công (Tự động khóa mã nếu chạm giới hạn)
    public boolean incrementUsedCount(int discountId) {
        String sql = "UPDATE discounts SET usedCount = usedCount + 1, " +
                     "status = CASE WHEN usedCount + 1 >= usageLimit THEN 0 ELSE status END " +
                     "WHERE discountId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, discountId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // --- HÀM PHỤ TRỢ MAPPING DỮ LIỆU ---
    private Discounts mapResultSetToDiscount(ResultSet rs) throws SQLException {
        Discounts d = new Discounts();
        d.setDiscountId(rs.getInt("discountId"));
        d.setDiscountCode(rs.getString("discountCode"));
        d.setDiscountTitle(rs.getString("discountTitle"));
        d.setDiscountType(rs.getString("discountType"));
        d.setDiscountValue(rs.getDouble("discountValue"));
        d.setMinOrderValue(rs.getDouble("minOrderValue"));
        d.setMaxDiscountAmount(rs.getDouble("maxDiscountAmount"));
        d.setApplyScope(rs.getString("applyScope"));
        d.setUsageLimit(rs.getInt("usageLimit"));
        d.setUsedCount(rs.getInt("usedCount"));
        d.setStartTime(rs.getTimestamp("startTime"));
        d.setEndTime(rs.getTimestamp("endTime"));
        d.setStatus(rs.getInt("status"));
        return d;
    }
}