import { Router, Request, Response } from "express";
import { db } from "@/shared/db";
import {
  transactions,
  transactionSourceSplits,
  type NewTransaction,
} from "./transactions.schema";
import { eq, and, desc } from "drizzle-orm";
import { authMiddleware } from "@/features/auth/auth.middleware";

interface TransactionBody {
  title: string;
  amount: number;
  date: string;
  type: "income" | "expense";
  category: string;
  description?: string;
  relatedPerson?: string;
  sources?: { sourceId: string; amount: number }[];
  isUrgent?: boolean;
  receiptPath?: string;
}

const router = Router();

router.use(authMiddleware);

router.get("/", async (req: Request, res: Response) => {
  try {
    const userId = req.userId!;
    const { startDate, endDate, type, category } = req.query;

    let query = db
      .select()
      .from(transactions)
      .where(eq(transactions.userId, userId))
      .orderBy(desc(transactions.date));

    let userTransactions = await query;

    if (startDate) {
      const start = new Date(startDate as string);
      userTransactions = userTransactions.filter((tx) => tx.date >= start);
    }

    if (endDate) {
      const end = new Date(endDate as string);
      userTransactions = userTransactions.filter((tx) => tx.date <= end);
    }

    if (type && (type === "income" || type === "expense")) {
      userTransactions = userTransactions.filter((tx) => tx.type === type);
    }

    if (category) {
      userTransactions = userTransactions.filter(
        (tx) => tx.category === category,
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

    res.json({
      success: true,
      data: transactionsWithSources,
    });
  } catch (error) {
    console.error("Get transactions error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to get transactions",
    });
  }
});

router.get("/:id", async (req: Request, res: Response) => {
  try {
    const userId = req.userId!;
    const transactionId = req.params.id;

    const foundTransactions = await db
      .select()
      .from(transactions)
      .where(
        and(
          eq(transactions.id, transactionId),
          eq(transactions.userId, userId),
        ),
      )
      .limit(1);

    if (foundTransactions.length === 0) {
      res.status(404).json({
        success: false,
        message: "Transaction not found",
      });
      return;
    }

    const splits = await db
      .select()
      .from(transactionSourceSplits)
      .where(eq(transactionSourceSplits.transactionId, transactionId));

    res.json({
      success: true,
      data: {
        ...foundTransactions[0],
        sources: splits,
      },
    });
  } catch (error) {
    console.error("Get transaction error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to get transaction",
    });
  }
});

router.post("/", async (req: Request, res: Response) => {
  try {
    const userId = req.userId!;
    const {
      title,
      amount,
      date,
      type,
      category,
      description,
      relatedPerson,
      sources: sourceSplits,
      isUrgent,
      receiptPath,
    } = req.body as TransactionBody;

    if (!title || amount === undefined || !date || !type || !category) {
      res.status(400).json({
        success: false,
        message: "Title, amount, date, type, and category are required",
      });
      return;
    }

    const validTypes = ["income", "expense"];
    if (!validTypes.includes(type)) {
      res.status(400).json({
        success: false,
        message: "Type must be: income or expense",
      });
      return;
    }

    const transactionDate = new Date(date);
    if (isNaN(transactionDate.getTime())) {
      res.status(400).json({
        success: false,
        message: "Invalid date format",
      });
      return;
    }

    if (typeof amount !== "number" || amount <= 0) {
      res.status(400).json({
        success: false,
        message: "Amount must be a positive number",
      });
      return;
    }

    if (sourceSplits && Array.isArray(sourceSplits)) {
      const totalSplits = sourceSplits.reduce(
        (sum: number, split) => sum + (split.amount || 0),
        0,
      );

      if (Math.abs(totalSplits - amount) > 0.01) {
        res.status(400).json({
          success: false,
          message: `Source splits total (${totalSplits}) must equal transaction amount (${amount})`,
        });
        return;
      }
    }

    const newTransaction = await db
      .insert(transactions)
      .values({
        userId: userId,
        title: title,
        amount: amount,
        date: transactionDate,
        type: type,
        category: category,
        description: description || null,
        relatedPerson: relatedPerson || null,
        isUrgent: isUrgent || false,
        receiptPath: receiptPath || null,
      })
      .returning();

    let createdSplits: (typeof transactionSourceSplits.$inferSelect)[] = [];
    if (
      sourceSplits &&
      Array.isArray(sourceSplits) &&
      sourceSplits.length > 0
    ) {
      for (const split of sourceSplits) {
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

    res.status(201).json({
      success: true,
      message: "Transaction created successfully",
      data: {
        ...newTransaction[0],
        sources: createdSplits,
      },
    });
  } catch (error) {
    console.error("Create transaction error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to create transaction",
    });
  }
});

router.put("/:id", async (req: Request, res: Response) => {
  try {
    const userId = req.userId!;
    const transactionId = req.params.id;
    const {
      title,
      amount,
      date,
      type,
      category,
      description,
      relatedPerson,
      sources: sourceSplits,
      isUrgent,
      receiptPath,
    } = req.body as Partial<TransactionBody>;

    const existingTransactions = await db
      .select()
      .from(transactions)
      .where(
        and(
          eq(transactions.id, transactionId),
          eq(transactions.userId, userId),
        ),
      )
      .limit(1);

    if (existingTransactions.length === 0) {
      res.status(404).json({
        success: false,
        message: "Transaction not found",
      });
      return;
    }

    if (type) {
      const validTypes = ["income", "expense"];
      if (!validTypes.includes(type)) {
        res.status(400).json({
          success: false,
          message: "Type must be: income or expense",
        });
        return;
      }
    }

    const updateData: Partial<NewTransaction> = {
      updatedAt: new Date(),
    };

    if (title !== undefined) updateData.title = title;
    if (amount !== undefined) updateData.amount = amount;
    if (date !== undefined) {
      const transactionDate = new Date(date);
      if (isNaN(transactionDate.getTime())) {
        res.status(400).json({
          success: false,
          message: "Invalid date format",
        });
        return;
      }
      updateData.date = transactionDate;
    }
    if (type !== undefined) updateData.type = type;
    if (category !== undefined) updateData.category = category;
    if (description !== undefined) updateData.description = description;
    if (relatedPerson !== undefined) updateData.relatedPerson = relatedPerson;
    if (isUrgent !== undefined) updateData.isUrgent = isUrgent;
    if (receiptPath !== undefined) updateData.receiptPath = receiptPath;

    // Validate split consistency if amount is updated but splits are not provided
    if (amount !== undefined && !sourceSplits) {
      // Check if we have existing splits
      const existingSplits = await db
        .select()
        .from(transactionSourceSplits)
        .where(eq(transactionSourceSplits.transactionId, transactionId));

      if (existingSplits.length > 0) {
        const totalExistingSplits = existingSplits.reduce(
          (sum, split) => sum + split.amount,
          0,
        );
        if (Math.abs(totalExistingSplits - amount) > 0.01) {
          res.status(400).json({
            success: false,
            message:
              "Cannot update amount without updating source splits to match. Existing splits total: " +
              totalExistingSplits,
          });
          return;
        }
      }
    }

    // Validate new splits if provided
    if (sourceSplits) {
      const targetAmount =
        amount !== undefined ? amount : existingTransactions[0].amount;
      const totalSplits = sourceSplits.reduce(
        (sum: number, split) => sum + (split.amount || 0),
        0,
      );

      if (Math.abs(totalSplits - targetAmount) > 0.01) {
        res.status(400).json({
          success: false,
          message: `Source splits total (${totalSplits}) must equal transaction amount (${targetAmount})`,
        });
        return;
      }
    }

    const updatedTransaction = await db
      .update(transactions)
      .set(updateData)
      .where(eq(transactions.id, transactionId))
      .returning();

    let splits: (typeof transactionSourceSplits.$inferSelect)[] = [];
    if (sourceSplits && Array.isArray(sourceSplits)) {
      await db
        .delete(transactionSourceSplits)
        .where(eq(transactionSourceSplits.transactionId, transactionId));

      for (const split of sourceSplits) {
        if (split.sourceId && split.amount > 0) {
          const newSplit = await db
            .insert(transactionSourceSplits)
            .values({
              transactionId: transactionId,
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
        .where(eq(transactionSourceSplits.transactionId, transactionId));
    }

    res.json({
      success: true,
      message: "Transaction updated successfully",
      data: {
        ...updatedTransaction[0],
        sources: splits,
      },
    });
  } catch (error) {
    console.error("Update transaction error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to update transaction",
    });
  }
});

router.delete("/:id", async (req: Request, res: Response) => {
  try {
    const userId = req.userId!;
    const transactionId = req.params.id;

    const existingTransactions = await db
      .select()
      .from(transactions)
      .where(
        and(
          eq(transactions.id, transactionId),
          eq(transactions.userId, userId),
        ),
      )
      .limit(1);

    if (existingTransactions.length === 0) {
      res.status(404).json({
        success: false,
        message: "Transaction not found",
      });
      return;
    }

    await db
      .delete(transactionSourceSplits)
      .where(eq(transactionSourceSplits.transactionId, transactionId));

    await db.delete(transactions).where(eq(transactions.id, transactionId));

    res.json({
      success: true,
      message: "Transaction deleted successfully",
    });
  } catch (error) {
    console.error("Delete transaction error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to delete transaction",
    });
  }
});

router.get("/stats/summary", async (req: Request, res: Response) => {
  try {
    const userId = req.userId!;
    const { startDate, endDate } = req.query;

    let userTransactions = await db
      .select()
      .from(transactions)
      .where(eq(transactions.userId, userId));

    if (startDate) {
      const start = new Date(startDate as string);
      userTransactions = userTransactions.filter((tx) => tx.date >= start);
    }

    if (endDate) {
      const end = new Date(endDate as string);
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

    const balance = totalIncome - totalExpense;

    res.json({
      success: true,
      data: {
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: balance,
        transactionCount: userTransactions.length,
      },
    });
  } catch (error) {
    console.error("Get stats error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to get statistics",
    });
  }
});

export default router;
