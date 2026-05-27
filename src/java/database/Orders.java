package database;

import java.io.Serializable;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class Orders implements Serializable {
    private static final long serialVersionUID = 1L;

    // --- THUỘC TÍNH BẢNG ORDERS ---
    private int orderId;
    private int userId;
    private String receiverName;
    private String receiverPhone;
    private String receiverAddress;
    private double totalAmount;
    private String paymentMethod;
    private String status;
    private Timestamp createdAt;

    // Danh sách chi tiết các sản phẩm nằm trong đơn hàng này (Dùng khi hiển thị)
    private List<OrderDetailItem> orderDetailsList = new ArrayList<>();

    // Constructor
    public Orders() {}

    // --- GETTERS & SETTERS ---
    public int getOrderId() { return orderId; }
    public void setOrderId(int orderId) { this.orderId = orderId; }
    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }
    public String getReceiverName() { return receiverName; }
    public void setReceiverName(String receiverName) { this.receiverName = receiverName; }
    public String getReceiverPhone() { return receiverPhone; }
    public void setReceiverPhone(String receiverPhone) { this.receiverPhone = receiverPhone; }
    public String getReceiverAddress() { return receiverAddress; }
    public void setReceiverAddress(String receiverAddress) { this.receiverAddress = receiverAddress; }
    public double getTotalAmount() { return totalAmount; }
    public void setTotalAmount(double totalAmount) { this.totalAmount = totalAmount; }
    public String getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }
    public List<OrderDetailItem> getOrderDetailsList() { return orderDetailsList; }
    public void setOrderDetailsList(List<OrderDetailItem> orderDetailsList) { this.orderDetailsList = orderDetailsList; }

    // =========================================================================
    // --- LỚP NỘI (INNER CLASS) ĐẠI DIỆN CHO CHI TIẾT ĐƠN HÀNG ---
    // =========================================================================
    public static class OrderDetailItem {
        private int orderDetailId;
        private int productId;
        private String productName; // Hỗ trợ hiển thị tên sản phẩm lên UI
        private int quantity;
        private double price;

        public OrderDetailItem() {}

        // Getters & Setters cho bảng con
        public int getOrderDetailId() { return orderDetailId; }
        public void setOrderDetailId(int orderDetailId) { this.orderDetailId = orderDetailId; }
        public int getProductId() { return productId; }
        public void setProductId(int productId) { this.productId = productId; }
        public String getProductName() { return productName; }
        public void setProductName(String productName) { this.productName = productName; }
        public int getQuantity() { return quantity; }
        public void setQuantity(int quantity) { this.quantity = quantity; }
        public double getPrice() { return price; }
        public void setPrice(double price) { this.price = price; }
    }

    // =========================================================================
    // --- PHƯƠNG THỨC DAO XỬ LÝ NGHIỆP VỤ (CRUD & TRANSACTION) ---
    // =========================================================================

    // 1. CHỨC NĂNG CỐT LÕI: Đặt hàng thành công bằng Ví Shop (Sử dụng Transaction an toàn)
    public boolean createOrder(Orders order) {
        Connection conn = null;
        PreparedStatement psCheckWallet = null;
        PreparedStatement psInsertOrder = null;
        PreparedStatement psGetCart = null;
        PreparedStatement psInsertDetail = null;
        PreparedStatement psUpdateProduct = null;
        PreparedStatement psDeductWallet = null;
        PreparedStatement psClearCart = null;
        ResultSet rs = null;

        try {
            conn = Connect.getConnection();
            conn.setAutoCommit(false); // BẮT ĐẦU CHUỖI TRANSACTION

            // BƯỚC A: Kiểm tra số dư Ví Shop (`userBalance`) của khách hàng có đủ thanh toán không
            String sqlCheckWallet = "SELECT userBalance FROM users WHERE userId = ?";
            psCheckWallet = conn.prepareStatement(sqlCheckWallet);
            psCheckWallet.setInt(1, order.getUserId());
            rs = psCheckWallet.executeQuery();
            if (rs.next()) {
                int walletBalance = rs.getInt("userBalance");
                if (walletBalance < order.getTotalAmount()) {
                    System.out.println("Lỗi: Số dư ví không đủ để thanh toán!");
                    conn.rollback(); // Hủy bỏ ngay lập tức
                    return false;
                }
            } else {
                conn.rollback();
                return false;
            }
            rs.close();

            // BƯỚC B: Tạo hóa đơn tổng quan vào bảng `orders` và lấy ID vừa sinh tự động
            String sqlInsertOrder = "INSERT INTO orders (userId, receiverName, receiverPhone, receiverAddress, totalAmount, paymentMethod, status) " +
                                    "VALUES (?, ?, ?, ?, ?, 'Ví Shop', 'Processing')";
            psInsertOrder = conn.prepareStatement(sqlInsertOrder, Statement.RETURN_GENERATED_KEYS);
            psInsertOrder.setInt(1, order.getUserId());
            psInsertOrder.setString(2, order.getReceiverName());
            psInsertOrder.setString(3, order.getReceiverPhone());
            psInsertOrder.setString(4, order.getReceiverAddress());
            psInsertOrder.setDouble(5, order.getTotalAmount());
            psInsertOrder.executeUpdate();

            // Lấy ID hóa đơn vừa sinh
            rs = psInsertOrder.getGeneratedKeys();
            int newOrderId = 0;
            if (rs.next()) {
                newOrderId = rs.getInt(1);
            }
            rs.close();

            // BƯỚC C: Lấy toàn bộ sản phẩm đang có trong giỏ hàng (`cart`) của user này ra để chuyển sang hóa đơn
            String sqlGetCart = "SELECT c.productId, c.quantity, p.productPrice, p.stockQuantity FROM cart c " +
                                "JOIN products p ON c.productId = p.productId WHERE c.userId = ?";
            psGetCart = conn.prepareStatement(sqlGetCart);
            psGetCart.setInt(1, order.getUserId());
            rs = psGetCart.executeQuery();

            String sqlInsertDetail = "INSERT INTO orderDetails (orderId, productId, quantity, price) VALUES (?, ?, ?, ?)";
            psInsertDetail = conn.prepareStatement(sqlInsertDetail);

            String sqlUpdateProduct = "UPDATE products SET stockQuantity = stockQuantity - ?, productSold = productSold + ? WHERE productId = ?";
            psUpdateProduct = conn.prepareStatement(sqlUpdateProduct);

            boolean hasItems = false;
            while (rs.next()) {
                hasItems = true;
                int prodId = rs.getInt("productId");
                int buyQty = rs.getInt("quantity");
                double currPrice = rs.getDouble("productPrice");
                int stockQty = rs.getInt("stockQuantity");

                // Kiểm tra hàng trong kho có đủ bán không
                if (stockQty < buyQty) {
                    System.out.println("Lỗi: Sản phẩm mã " + prodId + " đã hết hàng hoặc không đủ số lượng trong kho!");
                    conn.rollback(); // Quay lui hệ thống
                    return false;
                }

                // C.1 Thêm vào bảng chi tiết hóa đơn
                psInsertDetail.setInt(1, newOrderId);
                psInsertDetail.setInt(2, prodId);
                psInsertDetail.setInt(3, buyQty);
                psInsertDetail.setDouble(4, currPrice);
                psInsertDetail.addBatch();

                // C.2 Trừ kho và tăng biến đếm sản phẩm đã bán trong bảng products
                psUpdateProduct.setInt(1, buyQty);
                psUpdateProduct.setInt(2, buyQty);
                psUpdateProduct.setInt(3, prodId);
                psUpdateProduct.addBatch();
            }

            if (!hasItems) {
                conn.rollback(); // Giỏ hàng rỗng thì không tạo đơn
                return false;
            }

            // Thực thi lưu hàng loạt (Batch Execution) để tối ưu bộ nhớ
            psInsertDetail.executeBatch();
            psUpdateProduct.executeBatch();

            // BƯỚC D: Trừ tiền trực tiếp vào Ví Shop trong bảng `users`
            String sqlDeductWallet = "UPDATE users SET userBalance = userBalance - ? WHERE userId = ?";
            psDeductWallet = conn.prepareStatement(sqlDeductWallet);
            psDeductWallet.setDouble(1, order.getTotalAmount());
            psDeductWallet.setInt(2, order.getUserId());
            psDeductWallet.executeUpdate();

            // BƯỚC E: Xóa sạch giỏ hàng cũ sau khi đã thanh toán xong
            String sqlClearCart = "DELETE FROM cart WHERE userId = ?";
            psClearCart = conn.prepareStatement(sqlClearCart);
            psClearCart.setInt(1, order.getUserId());
            psClearCart.executeUpdate();

            // HOÀN THÀNH TOÀN BỘ CHUỖI GIAO DỊCH AN TOÀN
            conn.commit();
            return true;

        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
            }
            e.printStackTrace();
        } finally {
            // Đóng tất cả kết nối rỗng để giải phóng tài nguyên RAM hệ thống
            try {
                if (rs != null) rs.close();
                if (psCheckWallet != null) psCheckWallet.close();
                if (psInsertOrder != null) psInsertOrder.close();
                if (psGetCart != null) psGetCart.close();
                if (psInsertDetail != null) psInsertDetail.close();
                if (psUpdateProduct != null) psUpdateProduct.close();
                if (psDeductWallet != null) psDeductWallet.close();
                if (psClearCart != null) psClearCart.close();
                if (conn != null) { conn.setAutoCommit(true); conn.close(); }
            } catch (SQLException e) { e.printStackTrace(); }
        }
        return false;
    }

    // 2. CHỨC NĂNG: Lấy danh sách lịch sử mua hàng của một khách hàng cụ thể
    public List<Orders> getOrdersByUserId(int userId) {
        List<Orders> list = new ArrayList<>();
        String sql = "SELECT * FROM orders WHERE userId = ? ORDER BY orderId DESC";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapResultSetToOrder(rs));
                }
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    // 3. CHỨC NĂNG: Lấy toàn bộ đơn hàng của hệ thống (Dùng cho trang Dashboard quản trị Admin)
    public List<Orders> getAllOrders() {
        List<Orders> list = new ArrayList<>();
        String sql = "SELECT * FROM orders ORDER BY orderId DESC";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapResultSetToOrder(rs));
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    // 4. CHỨC NĂNG: Xem chi tiết một đơn hàng kèm album sản phẩm bên trong đơn đó
    public Orders getOrderWithDetails(int orderId) {
        Orders order = null;
        String sqlOrder = "SELECT * FROM orders WHERE orderId = ?";
        String sqlDetails = "SELECT d.*, p.productName FROM orderDetails d " +
                            "JOIN products p ON d.productId = p.productId WHERE d.orderId = ?";
        try (Connection conn = Connect.getConnection()) {
            // Lấy hóa đơn tổng quan
            try (PreparedStatement ps1 = conn.prepareStatement(sqlOrder)) {
                ps1.setInt(1, orderId);
                try (ResultSet rs1 = ps1.executeQuery()) {
                    if (rs1.next()) order = mapResultSetToOrder(rs1);
                }
            }
            // Lấy danh sách sản phẩm mua trong hóa đơn đó
            if (order != null) {
                try (PreparedStatement ps2 = conn.prepareStatement(sqlDetails)) {
                    ps2.setInt(1, orderId);
                    try (ResultSet rs2 = ps2.executeQuery()) {
                        while (rs2.next()) {
                            OrderDetailItem item = new OrderDetailItem();
                            item.setOrderDetailId(rs2.getInt("orderDetailId"));
                            item.setProductId(rs2.getInt("productId"));
                            item.setProductName(rs2.getString("productName"));
                            item.setQuantity(rs2.getInt("quantity"));
                            item.setPrice(rs2.getDouble("price"));
                            order.getOrderDetailsList().add(item);
                        }
                    }
                }
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return order;
    }

    // 5. CHỨC NĂNG: Thay đổi trạng thái đơn hàng (Admin duyệt đơn, chuyển hàng hoặc Khách bấm Hủy đơn)
    public boolean updateOrderStatus(int orderId, String newStatus) {
        String sql = "UPDATE orders SET status = ? WHERE orderId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, newStatus);
            ps.setInt(2, orderId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    // Helper map dữ liệu
    private Orders mapResultSetToOrder(ResultSet rs) throws SQLException {
        Orders order = new Orders();
        order.setOrderId(rs.getInt("orderId"));
        order.setUserId(rs.getInt("userId"));
        order.setReceiverName(rs.getString("receiverName"));
        order.setReceiverPhone(rs.getString("receiverPhone"));
        order.setReceiverAddress(rs.getString("receiverAddress"));
        order.setTotalAmount(rs.getDouble("totalAmount"));
        order.setPaymentMethod(rs.getString("paymentMethod"));
        order.setStatus(rs.getString("status"));
        order.setCreatedAt(rs.getTimestamp("createdAt"));
        return order;
    }
}