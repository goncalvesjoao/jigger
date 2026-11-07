import react, { reactCompilerPreset } from "@vitejs/plugin-react";
import babel from "@rolldown/plugin-babel";
import { defineConfig } from "vitest/config";

// https://vite.dev/config/
export default defineConfig({
  server: {
    proxy: {
      "/api": {
        target: "http://localhost:3000",
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ""),
        configure: (proxy) => {
          proxy.on("proxyRes", (response) => {
            const location = response.headers.location;
            if (location?.startsWith("http://localhost:3000/"))
              response.headers.location =
                "/api" + location.slice("http://localhost:3000".length);
          });
          proxy.on("proxyReq", (proxyReq, req) => {
            // Preserve Rails origin checking behind the local same-origin dev proxy.
            // Never rewrite foreign origins: only this dev server's browser origin.
            if (req.headers.origin === `http://${req.headers.host}`)
              proxyReq.setHeader("origin", "http://localhost:3000");
          });
        },
      },
    },
  },
  test: {
    include: ["src/**/*.test.{ts,tsx}"],
    environment: "jsdom",
    setupFiles: ["./src/test/setup.ts"],
  },
  plugins: [react(), babel({ presets: [reactCompilerPreset()] })],
});
