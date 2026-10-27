/**
 * @module client/main
 * @layer Entry Point
 * @purpose Mounts the ReLo B2C React 19 application root inside StrictMode.
 */

import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { App } from "@/client/App";
import "@/client/styles/index.css";

const rootElement = document.getElementById("root");
if (!rootElement) {
	throw new Error("Failed to find #root mount element in index.html");
}

createRoot(rootElement).render(
	<StrictMode>
		<App />
	</StrictMode>,
);
