package service;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.http.*;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Properties;

public class GeminiAI {
    private static final String PROPS_FILE = "config.properties";

    private static Properties loadProps() throws IOException {
        Properties p = new Properties();
        ClassLoader cl = Thread.currentThread().getContextClassLoader();
        try (InputStream in = cl.getResourceAsStream(PROPS_FILE)) {
            if (in == null) throw new IOException("Không tìm thấy " + PROPS_FILE + " trong classpath (WEB-INF/classes).");
            p.load(in);
        }
        return p;
    }

    private static String cfg(Properties p, String key, String def) {
        String v = p.getProperty(key);
        return (v == null || v.trim().isEmpty()) ? def : v.trim();
    }

    private static String jsonEscape(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\r", "\\r")
                .replace("\n", "\\n");
    }

    private static HttpClient http() {
        return HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();
    }

    private static String normalizeBaseUrl(String baseUrl) {
        if (baseUrl == null || baseUrl.isBlank()) baseUrl = "https://generativelanguage.googleapis.com";
        if (!baseUrl.startsWith("http://") && !baseUrl.startsWith("https://")) baseUrl = "https://" + baseUrl;
        if (baseUrl.endsWith("/")) baseUrl = baseUrl.substring(0, baseUrl.length() - 1);
        return baseUrl;
    }

    private static String normalizeModel(String model) {
        if (model == null || model.isBlank()) return "models/gemini-1.5-flash";
        model = model.trim();
        // API thường trả về tên có prefix "models/..."
        if (!model.startsWith("models/")) model = "models/" + model;
        return model;
    }

    public static String listModels() throws Exception {
        Properties p = loadProps();
        String baseUrl = normalizeBaseUrl(cfg(p, "ai.api.base_url", "https://generativelanguage.googleapis.com"));
        String apiKey = cfg(p, "ai.api.key", null);
        if (apiKey == null || apiKey.isBlank() || apiKey.startsWith("CHANGE_ME")) {
            throw new IllegalStateException("ai.api.key chưa cấu hình đúng trong config.properties");
        }

        String url = baseUrl + "/v1beta/models?key=" + apiKey;

        HttpRequest req = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(Duration.ofSeconds(30))
                .GET()
                .build();

        HttpResponse<String> res = http().send(req, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        if (res.statusCode() / 100 != 2) {
            throw new IOException("Gemini ListModels HTTP " + res.statusCode() + " at " + url + ": " + res.body());
        }
        return res.body();
    }

    public static String generateText(String prompt) throws Exception {
        Properties p = loadProps();
        String baseUrl = normalizeBaseUrl(cfg(p, "ai.api.base_url", "https://generativelanguage.googleapis.com"));
        String apiKey = cfg(p, "ai.api.key", null);
        String model = normalizeModel(cfg(p, "ai.gemini.model", "models/gemini-1.5-flash"));

        if (apiKey == null || apiKey.isBlank() || apiKey.startsWith("CHANGE_ME")) {
            throw new IllegalStateException("ai.api.key chưa cấu hình đúng trong config.properties");
        }

        // POST /v1beta/{model}:generateContent?key=...
        String url = baseUrl + "/v1beta/" + model + ":generateContent?key=" + apiKey;

        String body = "{"
                + "\"contents\":[{"
                +   "\"parts\":[{"
                +     "\"text\":\"" + jsonEscape(prompt) + "\""
                +   "}]"
                + "}],"
                + "\"generationConfig\":{"
                +   "\"temperature\":0.6,"
                +   "\"maxOutputTokens\":512"
                + "}"
                + "}";

        HttpRequest req = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(Duration.ofSeconds(30))
                .header("Content-Type", "application/json; charset=UTF-8")
                .POST(HttpRequest.BodyPublishers.ofString(body, StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> res = http().send(req, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        if (res.statusCode() / 100 != 2) {
            throw new IOException("Gemini generateContent HTTP " + res.statusCode() + " at " + url + ": " + res.body());
        }
        return res.body();
    }
}