import {
  pgTable,
  uuid,
  varchar,
  text,
  timestamp,
  doublePrecision,
  boolean,
} from "drizzle-orm/pg-core";
import { transactionTypeEnum } from "@/features/categories/categories.schema";
import { sources } from "@/features/sources/sources.schema";
import { users } from "../user/user.schema";

export const transactions = pgTable("transactions", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }),
  title: varchar("title", { length: 255 }).notNull(),
  amount: doublePrecision("amount").notNull(),
  date: timestamp("date").notNull(),
  type: transactionTypeEnum("type").notNull(),
  category: varchar("category", { length: 255 }).notNull(),
  description: text("description"),
  relatedPerson: varchar("related_person", { length: 255 }),
  isUrgent: boolean("is_urgent").default(false),
  receiptPath: text("receipt_path"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});

export const transactionSourceSplits = pgTable("transaction_source_splits", {
  id: uuid("id").primaryKey().defaultRandom(),
  transactionId: uuid("transaction_id")
    .notNull()
    .references(() => transactions.id, { onDelete: "cascade" }),
  sourceId: uuid("source_id")
    .notNull()
    .references(() => sources.id, { onDelete: "cascade" }),
  amount: doublePrecision("amount").notNull(),
});

export type Transaction = typeof transactions.$inferSelect;
export type NewTransaction = typeof transactions.$inferInsert;

export type TransactionSourceSplit =
  typeof transactionSourceSplits.$inferSelect;
export type NewTransactionSourceSplit =
  typeof transactionSourceSplits.$inferInsert;
