// Database Connection Setup
// This file creates the connection to PostgreSQL

import { drizzle } from "drizzle-orm/node-postgres";
import pg from "pg";
import * as schema from "./schema";
import * as dotenv from "dotenv";
import requireEnv from "@/shared/utils/requireEnv";

dotenv.config();

// Get database URL from environment variables
const connectionString = requireEnv("DATABASE_URL");

// Get database CA from environment variables
const databaseCa = process.env.DATABASE_CA;
const ca = databaseCa
  ? Buffer.from(databaseCa, "base64").toString("utf8")
  : undefined;

// Create a PostgreSQL connection pool
// A pool reuses connections instead of creating new ones each time
const pool = new pg.Pool({
  connectionString: connectionString,
  ssl: {
    rejectUnauthorized: false,
    ca,
  },
});

// Create the drizzle database instance
// This is what we use throughout the app to query the database
export const db = drizzle(pool, { schema });

// Export the pool in case we need direct access
export { pool };
