import { db } from "@/shared/db";
import {
  transactions,
  transactionSourceSplits,
  type NewTransaction,
  type Transaction,
  type TransactionSourceSplit,
} from "./transactions.schema";
import { eq, and, desc } from "drizzle-orm";

export interface TransactionSourceSplitData {
  sourceId: string;
  amount: number;
}

export interface CreateTransactionData {
  userId: string;
  title: string;
  amount: number;
  date: string;
  type: "income" | "expense";
  category: string;
  description?: string;
  relatedPerson?: string;
  sources?: TransactionSourceSplitData[];
  isUrgent?: boolean;
  receiptPath?: string;
}

export interface UpdateTransactionData {
  userId: string;
  id: string;
  title?: string;
  amount?: number;
  date?: string;
  type?: "income" | "expense";
  category?: string;
  description?: string;
  relatedPerson?: string;
  sources?: TransactionSourceSplitData[];
  isUrgent?: boolean;
  receiptPath?: string;
}

export interface TransactionWithSplits extends Transaction {
  sources: TransactionSourceSplit[];
}

export interface TransactionStats {
  totalIncome: number;
  totalExpense: number;
  balance: number;
  transactionCount: number;
}

export class TransactionsService {
  async getAll(
    userId: string,
    filters?: {
      startDate?: string;
      endDate?: string;
      type?: string;
      category?: string;
    },
  ): Promise<TransactionWithSplits[]> {
    let query = db
      .select()
      .from(transactions)
      .where(eq(transactions.userId, userId))
      .orderBy(desc(transactions.date));

    let userTransactions = await query;

    if (filters?.startDate) {
      const start = new Date(filters.startDate);
      userTransactions = userTransactions.filter((tx) => tx.date >= start);
    }

    if (filters?.endDate) {
      const end = new Date(filters.endDate);
      userTransactions = userTransactions.filter((tx) => tx.date <= end);
    }

    if (
      filters?.type &&
      (filters.type === "income" || filters.type === "expense")
    ) {
      userTransactions = userTransactions.filter(
        (tx) => tx.type === filters.type,
      );
    }

    if (filters?.category) {
      userTransactions = userTransactions.filter(
        (tx) => tx.category === filters.category,
      );
    }

    const transactionsWithSources = await Promise.all(
      userTransactions.map(async (tx) => {
        const splits = await db
          .select()
          .from(transactionSourceSplits)
          .where(eq(transactionSourceSplits.transactionId, tx.id));

        return {
          ...tx,
          sources: splits,
        };
      }),
    );

    return transactionsWithSources;
  }

  async getById(
    userId: string,
    id: string,
  ): Promise<TransactionWithSplits | null> {
    const foundTransactions = await db
      .select()
      .from(transactions)
      .where(and(eq(transactions.id, id), eq(transactions.userId, userId)))
      .limit(1);

    if (foundTransactions.length === 0) {
      return null;
    }

    const splits = await db
      .select()
      .from(transactionSourceSplits)
      .where(eq(transactionSourceSplits.transactionId, id));

    return {
      ...foundTransactions[0],
      sources: splits,
    };
  }

  async create(data: CreateTransactionData): Promise<TransactionWithSplits> {
    const transactionDate = new Date(data.date);
    if (isNaN(transactionDate.getTime())) {
      throw new Error("Invalid date format");
    }

    if (typeof data.amount !== "number" || data.amount <= 0) {
      throw new Error("Amount must be a positive number");
    }

    if (data.sources && Array.isArray(data.sources)) {
      const totalSplits = data.sources.reduce(
        (sum: number, split) => sum + (split.amount || 0),
        0,
      );

      if (Math.abs(totalSplits - data.amount) > 0.01) {
        throw new Error(
          `Source splits total (${totalSplits}) must equal transaction amount (${data.amount})`,
        );
      }
    }

    const newTransaction = await db
      .insert(transactions)
      .values({
        userId: data.userId,
        title: data.title,
        amount: data.amount,
        date: transactionDate,
        type: data.type,
        category: data.category,
        description: data.description || null,
        relatedPerson: data.relatedPerson || null,
        isUrgent: data.isUrgent || false,
        receiptPath: data.receiptPath || null,
      })
      .returning();

    let createdSplits: TransactionSourceSplit[] = [];
    if (
      data.sources &&
      Array.isArray(data.sources) &&
      data.sources.length > 0
    ) {
      for (const split of data.sources) {
        if (split.sourceId && split.amount > 0) {
          const newSplit = await db
            .insert(transactionSourceSplits)
            .values({
              transactionId: newTransaction[0].id,
              sourceId: split.sourceId,
              amount: split.amount,
            })
            .returning();
          createdSplits.push(newSplit[0]);
        }
      }
    }

    return {
      ...newTransaction[0],
      sources: createdSplits,
    };
  }

  async update(data: UpdateTransactionData): Promise<TransactionWithSplits> {
    const existingTransaction = await this.getById(data.userId, data.id);

    if (!existingTransaction) {
      throw new Error("Transaction not found");
    }

    const updateData: Partial<NewTransaction> = {
      updatedAt: new Date(),
    };

    if (data.title !== undefined) updateData.title = data.title;
    if (data.amount !== undefined) updateData.amount = data.amount;
    if (data.date !== undefined) {
      const transactionDate = new Date(data.date);
      if (isNaN(transactionDate.getTime())) {
        throw new Error("Invalid date format");
      }
      updateData.date = transactionDate;
    }
    if (data.type !== undefined) updateData.type = data.type;
    if (data.category !== undefined) updateData.category = data.category;
    if (data.description !== undefined)
      updateData.description = data.description;
    if (data.relatedPerson !== undefined)
      updateData.relatedPerson = data.relatedPerson;
    if (data.isUrgent !== undefined) updateData.isUrgent = data.isUrgent;
    if (data.receiptPath !== undefined)
      updateData.receiptPath = data.receiptPath;

    // Validate split consistency if amount is updated but splits are not provided
    if (data.amount !== undefined && !data.sources) {
      const existingSplits = existingTransaction.sources;

      if (existingSplits.length > 0) {
        const totalExistingSplits = existingSplits.reduce(
          (sum, split) => sum + split.amount,
          0,
        );
        if (Math.abs(totalExistingSplits - data.amount) > 0.01) {
          throw new Error(
            "Cannot update amount without updating source splits to match. Existing splits total: " +
              totalExistingSplits,
          );
        }
      }
    }

    // Validate new splits if provided
    if (data.sources) {
      const targetAmount =
        data.amount !== undefined ? data.amount : existingTransaction.amount;
      const totalSplits = data.sources.reduce(
        (sum: number, split) => sum + (split.amount || 0),
        0,
      );

      if (Math.abs(totalSplits - targetAmount) > 0.01) {
        throw new Error(
          `Source splits total (${totalSplits}) must equal transaction amount (${targetAmount})`,
        );
      }
    }

    const updatedTransaction = await db
      .update(transactions)
      .set(updateData)
      .where(eq(transactions.id, data.id))
      .returning();

    let splits: TransactionSourceSplit[] = [];
    if (data.sources && Array.isArray(data.sources)) {
      await db
        .delete(transactionSourceSplits)
        .where(eq(transactionSourceSplits.transactionId, data.id));

      for (const split of data.sources) {
        if (split.sourceId && split.amount > 0) {
          const newSplit = await db
            .insert(transactionSourceSplits)
            .values({
              transactionId: data.id,
              sourceId: split.sourceId,
              amount: split.amount,
            })
            .returning();
          splits.push(newSplit[0]);
        }
      }
    } else {
      splits = await db
        .select()
        .from(transactionSourceSplits)
        .where(eq(transactionSourceSplits.transactionId, data.id));
    }

    return {
      ...updatedTransaction[0],
      sources: splits,
    };
  }

  async delete(userId: string, id: string): Promise<void> {
    const existingTransaction = await this.getById(userId, id);

    if (!existingTransaction) {
      throw new Error("Transaction not found");
    }

    await db
      .delete(transactionSourceSplits)
      .where(eq(transactionSourceSplits.transactionId, id));

    await db.delete(transactions).where(eq(transactions.id, id));
  }

  async getStats(
    userId: string,
    filters?: { startDate?: string; endDate?: string },
  ): Promise<TransactionStats> {
    let userTransactions = await db
      .select()
      .from(transactions)
      .where(eq(transactions.userId, userId));

    if (filters?.startDate) {
      const start = new Date(filters.startDate);
      userTransactions = userTransactions.filter((tx) => tx.date >= start);
    }

    if (filters?.endDate) {
      const end = new Date(filters.endDate);
      userTransactions = userTransactions.filter((tx) => tx.date <= end);
    }

    let totalIncome = 0;
    let totalExpense = 0;

    for (const tx of userTransactions) {
      if (tx.type === "income") {
        totalIncome += tx.amount;
      } else if (tx.type === "expense") {
        totalExpense += tx.amount;
      }
    }

    return {
      totalIncome,
      totalExpense,
      balance: totalIncome - totalExpense,
      transactionCount: userTransactions.length,
    };
  }
}

export const transactionsService = new TransactionsService();
