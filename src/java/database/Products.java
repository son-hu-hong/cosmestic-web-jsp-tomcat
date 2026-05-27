package database;

import java.io.Serializable;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class Products implements Serializable {
    private static final long serialVersionUID = 1L;

    // --- CÁC THUỘC TÍNH (FIELDS) THEO ĐÚNG SCHEMA CỦA BẠN ---
    private int productId;
    private String productName;
    private String sku;
    private int stockQuantity;
    private double productPrice;
    private double productOldPrice;
    private int categoryId;
    private int brandId;
    private String volume;
    private String skinType;
    private String description;
    private String ingredients;
    private int productSold;
    private int isNew;
    private int isBestSeller;
    private int status;

    // Thuộc tính bổ sung để hỗ trợ hiển thị ảnh đại diện chính kèm theo sản phẩm
    private String mainImageUrl;

    // --- CONSTRUCTORS ---
    public Products() {}

    // --- GETTERS & SETTERS ---
    public int getProductId() { return productId; }
    public void setProductId(int productId) { this.productId = productId; }
    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }
    public String getSku() { return sku; }
    public void setSku(String sku) { this.sku = sku; }
    public int getStockQuantity() { return stockQuantity; }
    public void setStockQuantity(int stockQuantity) { this.stockQuantity = stockQuantity; }
    public double getProductPrice() { return productPrice; }
    public void setProductPrice(double productPrice) { this.productPrice = productPrice; }
    public double getProductOldPrice() { return productOldPrice; }
    public void setProductOldPrice(double productOldPrice) { this.productOldPrice = productOldPrice; }
    public int getCategoryId() { return categoryId; }
    public void setCategoryId(int categoryId) { this.categoryId = categoryId; }
    public int getBrandId() { return brandId; }
    public void setBrandId(int brandId) { this.brandId = brandId; }
    public String getVolume() { return volume; }
    public void setVolume(String volume) { this.volume = volume; }
    public String getSkinType() { return skinType; }
    public void setSkinType(String skinType) { this.skinType = skinType; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getIngredients() { return ingredients; }
    public void setIngredients(String ingredients) { this.ingredients = ingredients; }
    public int getProductSold() { return productSold; }
    public void setProductSold(int productSold) { this.productSold = productSold; }
    public int getIsNew() { return isNew; }
    public void setIsNew(int isNew) { this.isNew = isNew; }
    public int getIsBestSeller() { return isBestSeller; }
    public void setIsBestSeller(int isBestSeller) { this.isBestSeller = isBestSeller; }
    public int getStatus() { return status; }
    public void setStatus(int status) { this.status = status; }
    public String getMainImageUrl() { return mainImageUrl; }
    public void setMainImageUrl(String mainImageUrl) { this.mainImageUrl = mainImageUrl; }

    // =========================================================================
    // --- CHỨC NĂNG NGHIỆP VỤ BẢNG PRODUCTS (THÊM, SỬA, XÓA, HIỂN THỊ, TÌM KIẾM) ---
    // =========================================================================

    // 1. CHỨC NĂNG: Thêm mới sản phẩm
    public boolean insertProduct(Products p) {
        String sql = "INSERT INTO products (productName, sku, stockQuantity, productPrice, productOldPrice, " +
                     "categoryId, brandId, volume, skinType, description, ingredients, productSold, isNew, isBestSeller, status) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, p.getProductName());
            ps.setString(2, p.getSku());
            ps.setInt(3, p.getStockQuantity());
            ps.setDouble(4, p.getProductPrice());
            ps.setDouble(5, p.getProductOldPrice());
            ps.setInt(6, p.getCategoryId());
            ps.setInt(7, p.getBrandId());
            ps.setString(8, p.getVolume());
            ps.setString(9, p.getSkinType());
            ps.setString(10, p.getDescription());
            ps.setString(11, p.getIngredients());
            ps.setInt(12, p.getProductSold());
            ps.setInt(13, p.getIsNew());
            ps.setInt(14, p.getIsBestSeller());
            ps.setInt(15, p.getStatus());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 2. CHỨC NĂNG: Chỉnh sửa thông tin sản phẩm
    public boolean updateProduct(Products p) {
        String sql = "UPDATE products SET productName=?, sku=?, stockQuantity=?, productPrice=?, productOldPrice=?, " +
                     "categoryId=?, brandId=?, volume=?, skinType=?, description=?, ingredients=?, productSold=?, " +
                     "isNew=?, isBestSeller=?, status=? WHERE productId=?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, p.getProductName());
            ps.setString(2, p.getSku());
            ps.setInt(3, p.getStockQuantity());
            ps.setDouble(4, p.getProductPrice());
            ps.setDouble(5, p.getProductOldPrice());
            ps.setInt(6, p.getCategoryId());
            ps.setInt(7, p.getBrandId());
            ps.setString(8, p.getVolume());
            ps.setString(9, p.getSkinType());
            ps.setString(10, p.getDescription());
            ps.setString(11, p.getIngredients());
            ps.setInt(12, p.getProductSold());
            ps.setInt(13, p.getIsNew());
            ps.setInt(14, p.getIsBestSeller());
            ps.setInt(15, p.getStatus());
            ps.setInt(16, p.getProductId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 3. CHỨC NĂNG: Xóa sản phẩm (Ràng buộc CASCADE tự động dọn sạch bảng productImages liên quan)
    public boolean deleteProduct(int productId) {
        String sql = "DELETE FROM products WHERE productId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, productId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 4. CHỨC NĂNG: Lấy danh sách toàn bộ sản phẩm (Kèm ảnh chính đại diện)
    public List<Products> getAllProducts() {
        List<Products> list = new ArrayList<>();
        String sql = "SELECT p.*, (SELECT imageUrl FROM productImages WHERE productId = p.productId AND isMain = 1 LIMIT 1) AS mainImage " +
                     "FROM products p ORDER BY p.productId DESC";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapResultSetToProduct(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    // 5. CHỨC NĂNG: Tìm kiếm linh hoạt nâng cao (Theo tên, khoảng giá, danh mục, hãng, thẻ lọc)
    public List<Products> searchProducts(String txtSearch, Integer catId, Integer bId, Double minPrice, Double maxPrice, Integer isNewFlag, Integer isBestFlag) {
        List<Products> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
            "SELECT p.*, (SELECT imageUrl FROM productImages WHERE productId = p.productId AND isMain = 1 LIMIT 1) AS mainImage " +
            "FROM products p WHERE 1=1"
        );

        if (txtSearch != null && !txtSearch.trim().isEmpty()) sql.append(" AND p.productName LIKE ?");
        if (catId != null && catId > 0) sql.append(" AND p.categoryId = ?");
        if (bId != null && bId > 0) sql.append(" AND p.brandId = ?");
        if (minPrice != null) sql.append(" AND p.productPrice >= ?");
        if (maxPrice != null) sql.append(" AND p.productPrice <= ?");
        if (isNewFlag != null) sql.append(" AND p.isNew = ?");
        if (isBestFlag != null) sql.append(" AND p.isBestSeller = ?");
        
        sql.append(" AND p.status = 1 ORDER BY p.productId DESC");

        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int index = 1;
            if (txtSearch != null && !txtSearch.trim().isEmpty()) ps.setString(index++, "%" + txtSearch + "%");
            if (catId != null && catId > 0) ps.setInt(index++, catId);
            if (bId != null && bId > 0) ps.setInt(index++, bId);
            if (minPrice != null) ps.setDouble(index++, minPrice);
            if (maxPrice != null) ps.setDouble(index++, maxPrice);
            if (isNewFlag != null) ps.setInt(index++, isNewFlag);
            if (isBestFlag != null) ps.setInt(index++, isBestFlag);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapResultSetToProduct(rs));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    // =========================================================================
    // --- CHỨC NĂNG NGHIỆP VỤ BẢNG PRODUCTIMAGES (QUẢN LÝ ALBUM ẢNH) ---
    // =========================================================================

    // 6. CHỨC NĂNG: Thêm ảnh vào album (Hỗ trợ xử lý cờ Checkbox ảnh chính)
    public boolean addProductImage(int productId, String imageUrl, int isMain) {
        Connection conn = null;
        try {
            conn = Connect.getConnection();
            conn.setAutoCommit(false); // Bật Transaction xử lý đồng bộ an toàn

            if (isMain == 1) {
                // Nếu ảnh này được chọn làm ảnh chính, hạ cấp toàn bộ ảnh cũ của sản phẩm này về ảnh phụ (isMain = 0)
                String resetSql = "UPDATE productImages SET isMain = 0 WHERE productId = ?";
                try (PreparedStatement psReset = conn.prepareStatement(resetSql)) {
                    psReset.setInt(1, productId);
                    psReset.executeUpdate();
                }
            }

            // Chèn ảnh mới vào album
            String insertSql = "INSERT INTO productImages (productId, imageUrl, isMain) VALUES (?, ?, ?)";
            try (PreparedStatement psInsert = conn.prepareStatement(insertSql)) {
                psInsert.setInt(1, productId);
                psInsert.setString(2, imageUrl);
                psInsert.setInt(3, isMain);
                psInsert.executeUpdate();
            }

            conn.commit();
            return true;
        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
            }
            e.printStackTrace();
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); } catch (SQLException e) { e.printStackTrace(); }
            }
        }
        return false;
    }

    // 7. CHỨC NĂNG: Xóa một ảnh cụ thể ra khỏi album
    public boolean deleteProductImage(int imageId) {
        String sql = "DELETE FROM productImages WHERE imageId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, imageId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 8. CHỨC NĂNG: Cập nhật sửa đổi đường dẫn ảnh (Chỉnh sửa hình ảnh)
    public boolean updateProductImageUrl(int imageId, String newImageUrl) {
        String sql = "UPDATE productImages SET imageUrl = ? WHERE imageId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, newImageUrl);
            ps.setInt(2, imageId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    // 9. CHỨC NĂNG: Đặt hình ảnh chính (Tác vụ khi bấm Checkbox trên Giao diện Admin)
    public boolean setMainImage(int productId, int imageId) {
        Connection conn = null;
        try {
            conn = Connect.getConnection();
            conn.setAutoCommit(false); // Bật tính năng giao dịch an toàn (Transaction)

            // Bước A: Hạ cấp mọi ảnh thuộc sản phẩm này về ảnh phụ (isMain = 0)
            String demoteSql = "UPDATE productImages SET isMain = 0 WHERE productId = ?";
            try (PreparedStatement ps1 = conn.prepareStatement(demoteSql)) {
                ps1.setInt(1, productId);
                ps1.executeUpdate();
            }

            // Bước B: Kích hoạt ảnh được chỉ định lên làm ảnh chính (isMain = 1)
            String promoteSql = "UPDATE productImages SET isMain = 1 WHERE imageId = ?";
            try (PreparedStatement ps2 = conn.prepareStatement(promoteSql)) {
                ps2.setInt(1, imageId);
                ps2.executeUpdate();
            }

            conn.commit(); // Hoàn tất thực thi lưu thông tin xuống database
            return true;
        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
            }
            e.printStackTrace();
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); } catch (SQLException e) { e.printStackTrace(); }
            }
        }
        return false;
    }

    // 10. CHỨC NĂNG: Lấy album ảnh phụ của một sản phẩm (Thường dùng cho trang chi tiết)
    public List<String> getProductImagesAlbum(int productId) {
        List<String> images = new ArrayList<>();
        String sql = "SELECT imageUrl FROM productImages WHERE productId = ? ORDER BY isMain DESC, imageId ASC";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, productId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    images.add(rs.getString("imageUrl"));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return images;
    }

    // --- HÀM PHỤ TRỢ (HELPER METHOD) MAPPING DỮ LIỆU ---
    private Products mapResultSetToProduct(ResultSet rs) throws SQLException {
        Products p = new Products();
        p.setProductId(rs.getInt("productId"));
        p.setProductName(rs.getString("productName"));
        p.setSku(rs.getString("sku"));
        p.setStockQuantity(rs.getInt("stockQuantity"));
        p.setProductPrice(rs.getDouble("productPrice"));
        p.setProductOldPrice(rs.getDouble("productOldPrice"));
        p.setCategoryId(rs.getInt("categoryId"));
        p.setBrandId(rs.getInt("brandId"));
        p.setVolume(rs.getString("volume"));
        p.setSkinType(rs.getString("skinType"));
        p.setDescription(rs.getString("description"));
        p.setIngredients(rs.getString("ingredients"));
        p.setProductSold(rs.getInt("productSold"));
        p.setIsNew(rs.getInt("isNew"));
        p.setIsBestSeller(rs.getInt("isBestSeller"));
        p.setStatus(rs.getInt("status"));
        
        // Nhận dữ liệu ảnh chính (nếu câu lệnh SELECT có chứa cột alias này)
        try {
            p.setMainImageUrl(rs.getString("mainImage"));
        } catch (SQLException ignored) {
            // Trường hợp câu lệnh truy vấn không join lấy ảnh thì bỏ qua
        }
        return p;
    }
}