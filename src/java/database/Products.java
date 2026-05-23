package database;

import java.io.Serializable;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import service.GeminiAI;

public class Products implements Serializable {

    // --- THUỘC TÍNH (FIELDS) theo schema  ---
    private int productId;
    private String productName;
    private int productAmount;
    private int productPrice;
    private int productOldPrice;
    private int categoryId;
    private int brandId;
    private int productStyle;
    private int productColor;
    private String productDesc;
    private String productPro;
    private int productSold;
    private int imageId;

    // --- CONSTRUCTORS ---
    public Products() {}

    // --- GETTERS & SETTERS ---
    public int getProductId() { return productId; }
    public void setProductId(int productId) { this.productId = productId; }
    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }
    public int getProductPrice() { return productPrice; }
    public void setProductPrice(int productPrice) { this.productPrice = productPrice; }
    public int getCategoryId() { return categoryId; }
    public void setCategoryId(int categoryId) { this.categoryId = categoryId; }
    public int getBrandId() { return brandId; }
    public void setBrandId(int brandId) { this.brandId = brandId; }
    public String getProductDesc() { return productDesc; }
    public void setProductDesc(String productDesc) { this.productDesc = productDesc; }
    public int getImageId() { return imageId; }
    public void setImageId(int imageId) { this.imageId = imageId; }

    public int getProductAmount() {
        return productAmount;
    }

    public void setProductAmount(int productAmount) {
        this.productAmount = productAmount;
    }

    public int getProductOldPrice() {
        return productOldPrice;
    }

    public void setProductOldPrice(int productOldPrice) {
        this.productOldPrice = productOldPrice;
    }

    public int getProductStyle() {
        return productStyle;
    }

    public void setProductStyle(int productStyle) {
        this.productStyle = productStyle;
    }

    public int getProductColor() {
        return productColor;
    }

    public void setProductColor(int productColor) {
        this.productColor = productColor;
    }

    public String getProductPro() {
        return productPro;
    }

    public void setProductPro(String productPro) {
        this.productPro = productPro;
    }

    public int getProductSold() {
        return productSold;
    }

    public void setProductSold(int productSold) {
        this.productSold = productSold;
    }
    
    // (Các getters/setters khác viết tương tự...)

    // --- PHƯƠNG THỨC DAO ---

    // 1. Thêm sản phẩm mới 
// 1. Thêm sản phẩm mới đầy đủ các trường
    public boolean insertProduct(Products p) {
        String sql = "INSERT INTO products (productName, productAmount, productPrice, productOldPrice, " +
                     "categoryId, brandId, productStyle, productColor, productDesc, productPro, imageId) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, p.getProductName());
            ps.setInt(2, p.getProductAmount());
            ps.setInt(3, p.getProductPrice());
            ps.setInt(4, p.getProductOldPrice());
            ps.setInt(5, p.getCategoryId());
            ps.setInt(6, p.getBrandId());
            ps.setInt(7, p.getProductStyle());
            ps.setInt(8, p.getProductColor());
            ps.setString(9, p.getProductDesc());
            ps.setString(10, p.getProductPro());
            ps.setInt(11, p.getImageId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    // 2. Hàm ánh xạ kết quả (Cần thiết để hiển thị khi nhấn "Sửa")
    private Products mapResultSetToProduct(ResultSet rs) throws SQLException {
        Products p = new Products();
        p.setProductId(rs.getInt("productId"));
        p.setProductName(rs.getString("productName"));
        p.setProductAmount(rs.getInt("productAmount")); // Bổ sung số lượng 
        p.setProductPrice(rs.getInt("productPrice"));
        p.setProductOldPrice(rs.getInt("productOldPrice"));
        p.setCategoryId(rs.getInt("categoryId"));
        p.setBrandId(rs.getInt("brandId"));
        p.setProductStyle(rs.getInt("productStyle")); // Bổ sung kích thước 
        p.setProductColor(rs.getInt("productColor")); // Bổ sung màu sắc 
        p.setProductDesc(rs.getString("productDesc"));
        p.setProductPro(rs.getString("productPro")); // Bổ sung thuộc tính 
        p.setImageId(rs.getInt("imageId"));
        return p;
    }

    // 2. Xóa sản phẩm
    public boolean deleteProduct(int id) {
        String sql = "DELETE FROM products WHERE productId = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    // 3. Tìm kiếm và Lọc nâng cao (Giá, Hãng, Sắp xếp)
    public List<Products> getFilteredProducts(String keyword, Integer catId, Integer bId, Integer minPrice, Integer maxPrice, String sortBy, boolean isAsc) {
        List<Products> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder("SELECT * FROM products WHERE 1=1 ");
        
        if (keyword != null && !keyword.isEmpty()) sql.append(" AND productName LIKE ? ");
        if (catId != null) sql.append(" AND categoryId = ? ");
        if (bId != null) sql.append(" AND brandId = ? ");
        if (minPrice != null) sql.append(" AND productPrice >= ? ");
        if (maxPrice != null) sql.append(" AND productPrice <= ? ");
        
        String order = isAsc ? "ASC" : "DESC";
        if (sortBy != null && sortBy.matches("^(productPrice|productName|productSold)$")) {
            sql.append(" ORDER BY ").append(sortBy).append(" ").append(order);
        }

        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int idx = 1;
            if (keyword != null && !keyword.isEmpty()) ps.setString(idx++, "%" + keyword + "%");
            if (catId != null) ps.setInt(idx++, catId);
            if (bId != null) ps.setInt(idx++, bId);
            if (minPrice != null) ps.setInt(idx++, minPrice);
            if (maxPrice != null) ps.setInt(idx++, maxPrice);

            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapResultSetToProduct(rs));
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    // 4. Tìm sản phẩm tương đương bằng Hình ảnh (A.I)
    public List<Products> searchByImageAI(String imageAnalysisResult) throws Exception {
        // Gửi mô tả hình ảnh từ AI tới database để tìm sản phẩm có mô tả tương đồng
        String prompt = "Dựa trên kết quả phân tích hình ảnh: '" + imageAnalysisResult + "', hãy liệt kê các từ khóa chính về loại mỹ phẩm, màu sắc và công dụng.";
        String keywords = GeminiAI.generateText(prompt); 
        
        // Tìm kiếm các sản phẩm có mô tả chứa từ khóa AI gợi ý
        return getFilteredProducts(keywords, null, null, null, null, "productSold", false);
    }

    // 5. Thêm nhanh từ dữ liệu Excel (Dùng giả lập danh sách từ file Excel)
    public int importFromExcel(List<String[]> excelData) {
        int count = 0;
        for (String[] row : excelData) {
            // Cột: Tên SP, Loại (tên), Thương hiệu (tên), Giá, Mô tả, Đường dẫn ảnh
            Products p = new Products();
            p.setProductName(row[0]);
            p.setProductPrice(Integer.parseInt(row[3]));
            p.setProductDesc(row[4]);
            
            // Logic tìm ID từ tên (Cần viết thêm hàm findIdByName cho Category/Brand)
            p.setCategoryId(findCategoryIdByName(row[1])); 
            p.setBrandId(findBrandIdByName(row[2]));
            
            if (insertProduct(p)) count++;
        }
        return count;
    }

    // Hàm phụ trợ tìm ID danh mục theo tên [cite: 5]
    private int findCategoryIdByName(String name) {
        String sql = "SELECT categoryId FROM categorys WHERE categoryName = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, name);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 1; // Mặc định nếu không tìm thấy
    }

    private int findBrandIdByName(String name) {
        String sql = "SELECT brandId FROM brands WHERE brandName = ?";
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, name);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 1;
    }
}