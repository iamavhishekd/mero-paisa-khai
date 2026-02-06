import express from "express";
import cors from "cors";
import * as dotenv from "dotenv";

import authRoutes from "@/features/auth/auth.routes";
import categoriesRoutes from "@/features/categories/categories.routes";
import sourcesRoutes from "@/features/sources/sources.routes";
import transactionsRoutes from "@/features/transactions/transactions.routes";
import requireEnv from "@/shared/utils/requireEnv";

dotenv.config();

const app = express();

app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE"],
    allowedHeaders: ["Content-Type", "Authorization"],
  }),
);

app.use(express.json());

app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "Paisa Khai API is running!",
    version: "1.0.0",
    endpoints: {
      auth: "/api/auth",
      categories: "/api/categories",
      sources: "/api/sources",
      transactions: "/api/transactions",
    },
  });
});

app.get("/health", (req, res) => {
  res.json({
    success: true,
    message: "Server is healthy",
    timestamp: new Date().toISOString(),
  });
});

app.use("/api/auth", authRoutes);

app.use("/api/categories", categoriesRoutes);

app.use("/api/sources", sourcesRoutes);

app.use("/api/transactions", transactionsRoutes);

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route not found: ${req.method} ${req.path}`,
  });
});

app.use(
  (
    err: Error,
    _: express.Request,
    res: express.Response,
    __: express.NextFunction,
  ) => {
    console.error("Unhandled error:", err);
    res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  },
);

const PORT = requireEnv("PORT");

app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});

export default app;
