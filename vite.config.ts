import path from "node:path";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

const BACKEND_ORIGIN = "http://127.0.0.1:4180";

// https://vite.dev/config/
export default defineConfig({
	plugins: [react(), tailwindcss()],
	resolve: {
		alias: {
			"@": path.resolve(import.meta.dirname, "./src"),
		},
	},
	server: {
		host: true,
		port: 5173,
		proxy: {
			"/api": {
				target: BACKEND_ORIGIN,
				changeOrigin: true,
				headers: {
					origin: BACKEND_ORIGIN,
				},
			},
		},
	},
});
