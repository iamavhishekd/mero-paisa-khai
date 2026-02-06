import { defineConfig } from "drizzle-kit";
import * as dotenv from "dotenv";
import requireEnv from "./src/shared/utils/requireEnv";

dotenv.config();

export default defineConfig({
  schema: "./src/shared/db/schema.ts",
  out: "./drizzle",
  dialect: "postgresql",
  dbCredentials: {
    url: requireEnv("DATABASE_URL"),
  },
});
