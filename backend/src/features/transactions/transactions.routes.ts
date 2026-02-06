import { Router, Request, Response } from "express";
import {
  transactionsService,
  CreateTransactionData,
  UpdateTransactionData,
} from "./transactions.service";
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

    const transactions = await transactionsService.getAll(userId, {
      startDate: startDate as string,
      endDate: endDate as string,
      type: type as string,
      category: category as string,
    });

    res.json({
      success: true,
      data: transactions,
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
    const transaction = await transactionsService.getById(
      userId,
      transactionId,
    );

    if (!transaction) {
      res.status(404).json({
        success: false,
        message: "Transaction not found",
      });
      return;
    }

    res.json({
      success: true,
      data: transaction,
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
    const body = req.body as TransactionBody;
    const { title, amount, date, type, category } = body;

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

    const newTransaction = await transactionsService.create({
      userId,
      ...body,
    });

    res.status(201).json({
      success: true,
      message: "Transaction created successfully",
      data: newTransaction,
    });
  } catch (error: any) {
    if (
      error.message === "Invalid date format" ||
      error.message === "Amount must be a positive number" ||
      error.message.startsWith("Source splits total")
    ) {
      res.status(400).json({
        success: false,
        message: error.message,
      });
      return;
    }
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
    const body = req.body as Partial<TransactionBody>;
    const { type } = body;

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

    const updatedTransaction = await transactionsService.update({
      userId,
      id: transactionId,
      ...body,
    });

    res.json({
      success: true,
      message: "Transaction updated successfully",
      data: updatedTransaction,
    });
  } catch (error: any) {
    if (error.message === "Transaction not found") {
      res.status(404).json({
        success: false,
        message: error.message,
      });
      return;
    }
    if (
      error.message === "Invalid date format" ||
      error.message.startsWith("Cannot update amount") ||
      error.message.startsWith("Source splits total")
    ) {
      res.status(400).json({
        success: false,
        message: error.message,
      });
      return;
    }
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

    await transactionsService.delete(userId, transactionId);

    res.json({
      success: true,
      message: "Transaction deleted successfully",
    });
  } catch (error: any) {
    if (error.message === "Transaction not found") {
      res.status(404).json({
        success: false,
        message: error.message,
      });
      return;
    }
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

    const stats = await transactionsService.getStats(userId, {
      startDate: startDate as string,
      endDate: endDate as string,
    });

    res.json({
      success: true,
      data: stats,
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
