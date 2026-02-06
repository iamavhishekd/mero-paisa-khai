import { Router, Request, Response } from "express";
import { categoriesService } from "./categories.service";
import { authMiddleware } from "@/features/auth/auth.middleware";

interface CategoryBody {
  name: string;
  type: "income" | "expense" | "both";
  icon: string;
  color: string;
  budget?: number;
}

const router = Router();

router.use(authMiddleware);

router.get("/", async (req: Request, res: Response) => {
  try {
    const userId = req.userId!;
    const userCategories = await categoriesService.getAll(userId);

    res.json({
      success: true,
      data: userCategories,
    });
  } catch (error) {
    console.error("Get categories error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to get categories",
    });
  }
});

router.get("/:id", async (req: Request, res: Response) => {
  try {
    const userId = req.userId!;
    const categoryId = req.params.id;
    const category = await categoriesService.getById(userId, categoryId);

    if (!category) {
      res.status(404).json({
        success: false,
        message: "Category not found",
      });
      return;
    }

    res.json({
      success: true,
      data: category,
    });
  } catch (error) {
    console.error("Get category error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to get category",
    });
  }
});

router.post("/", async (req: Request, res: Response) => {
  try {
    const userId = req.userId!;
    const body = req.body as CategoryBody;
    const { name, type, icon, color, budget } = body;

    if (!name || !type || !icon || !color) {
      res.status(400).json({
        success: false,
        message: "Name, type, icon, and color are required",
      });
      return;
    }

    const validTypes = ["income", "expense", "both"];
    if (!validTypes.includes(type)) {
      res.status(400).json({
        success: false,
        message: "Type must be: income, expense, or both",
      });
      return;
    }

    const newCategory = await categoriesService.create({
      userId,
      ...body,
    });

    res.status(201).json({
      success: true,
      message: "Category created successfully",
      data: newCategory,
    });
  } catch (error) {
    console.error("Create category error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to create category",
    });
  }
});

router.put("/:id", async (req: Request, res: Response) => {
  try {
    const userId = req.userId!;
    const categoryId = req.params.id;
    const body = req.body as Partial<CategoryBody>;
    const { type } = body;

    if (type) {
      const validTypes = ["income", "expense", "both"];
      if (!validTypes.includes(type)) {
        res.status(400).json({
          success: false,
          message: "Type must be: income, expense, or both",
        });
        return;
      }
    }

    const updatedCategory = await categoriesService.update({
      userId,
      id: categoryId,
      ...body,
    });

    res.json({
      success: true,
      message: "Category updated successfully",
      data: updatedCategory,
    });
  } catch (error: any) {
    if (error.message === "Category not found") {
      res.status(404).json({
        success: false,
        message: error.message,
      });
      return;
    }
    console.error("Update category error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to update category",
    });
  }
});

router.delete("/:id", async (req: Request, res: Response) => {
  try {
    const userId = req.userId!;
    const categoryId = req.params.id;

    await categoriesService.delete(userId, categoryId);

    res.json({
      success: true,
      message: "Category deleted successfully",
    });
  } catch (error: any) {
    if (error.message === "Category not found") {
      res.status(404).json({
        success: false,
        message: error.message,
      });
      return;
    }
    console.error("Delete category error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to delete category",
    });
  }
});

export default router;
