package service;

import database.Connect;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ChatbotService {

    // 1. Lấy danh sách sản phẩm để AI có "kiến thức" về cửa hàng
    private static String getProductContext() {
        StringBuilder context = new StringBuilder("Danh sách mỹ phẩm hiện có tại Dosmé: \n");
        String sql = "SELECT p.productName, p.productPrice, c.categoryName FROM products p " +
                     "JOIN categorys c ON p.categoryId = c.categoryId LIMIT 10";
        
        try (Connection conn = Connect.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                context.append(String.format("- %s (%s): Giá %d VNĐ\n", 
                    rs.getString("productName"), 
                    rs.getString("categoryName"),
                    rs.getInt("productPrice")));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return context.toString();
    }

    // 2. Hàm xử lý câu hỏi của khách hàng
    public static String askBeautyAssistant(String userQuestion) throws Exception {
        String productInfo = getProductContext();
        
        // Tạo prompt chuyên sâu về làm đẹp
        String finalPrompt = "Bạn là chuyên gia tư vấn làm đẹp của 'Dosmé Beauty'. " +
            "Hãy trả lời thân thiện, chuyên nghiệp. " +
            "Dựa trên dữ liệu sản phẩm sau: \n" + productInfo + 
            "\nCâu hỏi khách hàng: " + userQuestion;

        // Gọi đến dịch vụ GeminiAI đã có 
        return GeminiAI.generateText(finalPrompt);
    }
}