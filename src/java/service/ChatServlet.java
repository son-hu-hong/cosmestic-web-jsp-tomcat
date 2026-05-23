package service;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

@WebServlet("/api/chatbot")
public class ChatServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json; charset=UTF-8");

        String userMsg = request.getParameter("message");
        try {
            // Gọi ChatbotService
            String aiResponse = ChatbotService.askBeautyAssistant(userMsg);
            
            // Trả về JSON (Bạn có thể dùng thư viện GSON hoặc chuỗi thuần)
            response.getWriter().write("{\"reply\": \"" + aiResponse + "\"}");
        } catch (Exception e) {
            response.setStatus(500);
            response.getWriter().write("{\"error\": \"Lỗi kết nối AI\"}");
        }
    }
}