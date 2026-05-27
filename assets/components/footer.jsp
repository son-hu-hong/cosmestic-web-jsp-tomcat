<%@page contentType="text/html" pageEncoding="UTF-8"%>
<% String ctx = request.getContextPath(); %>

<style>
    .footer-wrapper { 
        background-color: #fbfbfb; 
        border-top: 4px solid var(--brand-primary); 
        padding: 20px 0 40px 0; 
        font-family: 'Segoe UI', sans-serif; 
        color: #555; 
    }
    .footer-container {
        max-width: 1200px; 
        margin: 0 auto; 
        display: flex; 
        justify-content: center;
    }
    .footer-col h4 {
        text-align: center;
        font-size: 22px; 
        color: #333; 
        text-transform: uppercase; 
        margin-bottom: 20px; 
        font-weight: bold; 
    }
    
    .member-table {
        font-size: 22px; 
        list-style: none; 
        padding: 0; margin: 0;
    }
    
        
    .member-table tbody { 
        margin-bottom: 12px; 
    }
 
    .member-table td:last-child {
        text-align: right;
        padding-left: 20px;
    }

    
    

    /* ================= RESPONSIVE FOOTER ================= */
    @media (max-width: 768px) {
        .footer-container { grid-template-columns: 1fr 1fr; gap: 20px; }
        .footer-col:nth-child(3), .footer-col:nth-child(4) { margin-top: 20px; }
        .footer-wrapper { padding-bottom: 70px; } /* Tránh bị Bottom Nav đè lên ở bản Mobile */
    }
    @media (max-width: 480px) {
        .footer-container { grid-template-columns: 1fr; text-align: center; }
    }
</style>

<footer class="footer-wrapper">
    <div class="footer-container">
        <div class="footer-col">
            <h4>DANH SÁCH THÀNH VIÊN</h4>
            <table class="member-table">
                <tbody>
                    <tr>
                        <td>Nguyễn Hồng Sơn</td>
                        <td>21/02/2005</td>
                    </tr>
                    <tr>
                        <td>Đặng Thị Nhi</td>
                        <td>21/5/2005</td>
                    </tr>
                    <tr>
                        <td>Nguyễn Thị Hồng Minh</td>
                        <td>08/12/2002</td>
                    </tr>
                    
                </tbody>
            </table>
        </div>
        
    </div>
</footer>