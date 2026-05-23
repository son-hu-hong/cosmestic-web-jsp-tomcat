package service;

import java.io.File;
import java.io.IOException;
import java.nio.file.*;
import java.util.Locale;
import java.util.Set;

import javax.servlet.ServletContext;
import javax.servlet.http.Part;

public class AvatarStorage {

    // Thư mục public trong webapp:
    // web/assets/images/avt
    public static final String AVT_DIR_WEB = "/assets/images/avt";
    public static final Set<String> ALLOWED_EXT = Set.of("png", "jpg", "jpeg", "webp", "gif");

    /** Trả về filesystem path tới thư mục avt trong thư mục deploy của Tomcat */
    public static Path getAvatarDirFs(ServletContext ctx) {
        String realPath = ctx.getRealPath(AVT_DIR_WEB);
        if (realPath == null) {
            // Trường hợp chạy từ WAR/hoặc container không cho realPath
            // Bạn sẽ cần cấu hình external folder. (Nếu gặp, báo mình để đổi phương án.)
            throw new IllegalStateException("getRealPath() trả về null. Không thể ghi file vào web folder khi deploy dạng WAR.");
        }
        return Paths.get(realPath);
    }

    /** Lấy extension từ filename (lowercase), null nếu không có */
    public static String getExt(String filename) {
        if (filename == null) return null;
        int dot = filename.lastIndexOf('.');
        if (dot < 0 || dot == filename.length() - 1) return null;
        return filename.substring(dot + 1).toLowerCase(Locale.ROOT);
    }

    /** Lấy filename gốc từ Part header */
    public static String getSubmittedFileName(Part part) {
        String cd = part.getHeader("content-disposition");
        if (cd == null) return null;
        for (String token : cd.split(";")) {
            token = token.trim();
            if (token.startsWith("filename=")) {
                String name = token.substring("filename=".length()).trim().replace("\"", "");
                return name.isEmpty() ? null : name;
            }
        }
        return null;
    }

    /** Xóa các file avatar cũ theo baseName (ví dụ "15" -> 15.png/15.jpg/...) */
    public static void deleteByBaseName(Path avatarDir, String baseName) throws IOException {
        for (String ext : ALLOWED_EXT) {
            Path p = avatarDir.resolve(baseName + "." + ext);
            Files.deleteIfExists(p);
        }
    }

    /**
     * Lưu avatar theo userId, đặt tên: {userId}.{ext}, và xóa các avatar cũ cùng baseName trước đó.
     * Return: baseName lưu DB (ở đây là userId dạng string).
     */
    public static String saveAvatar(ServletContext ctx, long userId, Part avatarPart) throws IOException {
        if (avatarPart == null || avatarPart.getSize() <= 0) {
            throw new IllegalArgumentException("avatarPart rỗng");
        }

        String submitted = getSubmittedFileName(avatarPart);
        String ext = getExt(submitted);
        if (ext == null || !ALLOWED_EXT.contains(ext)) {
            throw new IllegalArgumentException("File avatar không hợp lệ. Chỉ cho phép: " + ALLOWED_EXT);
        }

        Path avatarDir = getAvatarDirFs(ctx);
        Files.createDirectories(avatarDir);

        String baseName = String.valueOf(userId);
        // Xóa file cũ (userId.*)
        deleteByBaseName(avatarDir, baseName);

        Path target = avatarDir.resolve(baseName + "." + ext);
        try {
            // overwrite nếu có
            Files.copy(avatarPart.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);
        } finally {
            avatarPart.delete(); // dọn temp (Tomcat)
        }

        return baseName; // lưu vào users.avt_url
    }

    /**
     * Resolve ra URL web để hiển thị:
     * - avtBase = 'default' -> tìm default.png/jpg/... cái nào tồn tại
     * - avtBase = '15' -> tìm 15.png/jpg/... cái nào tồn tại
     * - nếu không có file nào -> fallback về default.* (nếu cũng không có thì trả rỗng)
     */
    public static String resolveAvatarUrl(ServletContext ctx, String avtBase) {
        if (avtBase == null || avtBase.isBlank()) avtBase = "default";

        String found = findFirstExisting(ctx, avtBase);
        if (found != null) return ctx.getContextPath() + AVT_DIR_WEB + "/" + found;

        // fallback về default
        found = findFirstExisting(ctx, "default");
        if (found != null) return ctx.getContextPath() + AVT_DIR_WEB + "/" + found;

        return ""; // hoặc trả về 1 ảnh placeholder CDN
    }

    private static String findFirstExisting(ServletContext ctx, String baseName) {
        String realBase = ctx.getRealPath(AVT_DIR_WEB);
        if (realBase == null) return null;
        File dir = new File(realBase);
        if (!dir.exists()) return null;

        for (String ext : ALLOWED_EXT) {
            File f = new File(dir, baseName + "." + ext);
            if (f.exists() && f.isFile()) {
                return baseName + "." + ext;
            }
        }
        return null;
    }
}