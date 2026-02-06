import { defineConfig } from "drizzle-kit";
import * as dotenv from "dotenv";
import requireEnv from "./src/shared/utils/requireEnv";

dotenv.config();

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

const databaseUrl = requireEnv("DATABASE_URL");
const databaseCa = requireEnv("DATABASE_CA");

const ca = Buffer.from(databaseCa, "base64").toString("utf8");
export default defineConfig({
  schema: "./src/shared/db/schema.ts",
  out: "./drizzle",
  dialect: "postgresql",
  dbCredentials: {
    url: databaseUrl,
    ssl: {
      rejectUnauthorized: false,
      ca,
    },
  },
});
