import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import App from "./App";

const root = document.getElementById("root")!;
// Ensure root container fills the viewport
root.style.width = '100vw';
root.style.height = '100vh';

createRoot(root).render(
  <StrictMode>
    <App />
  </StrictMode>
);
