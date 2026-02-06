import { Router, Request, Response } from "express";
import { db } from "@/shared/db";
import { categories, type NewCategory } from "./categories.schema";
import { eq, and } from "drizzle-orm";
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

    const userCategories = await db
      .select()
      .from(categories)
      .where(eq(categories.userId, userId))
      .orderBy(categories.createdAt);

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

    const foundCategories = await db
      .select()
      .from(categories)
      .where(and(eq(categories.id, categoryId), eq(categories.userId, userId)))
      .limit(1);

    if (foundCategories.length === 0) {
      res.status(404).json({
        success: false,
        message: "Category not found",
      });
      return;
    }

    res.json({
      success: true,
      data: foundCategories[0],
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
    const { name, type, icon, color, budget } = req.body as CategoryBody;

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

    const newCategory = await db
      .insert(categories)
      .values({
        userId: userId,
        name: name,
        type: type,
        icon: icon,
        color: color,
        budget: budget || null,
      })
      .returning();

    res.status(201).json({
      success: true,
      message: "Category created successfully",
      data: newCategory[0],
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
    const { name, type, icon, color, budget } =
      req.body as Partial<CategoryBody>;

    const existingCategories = await db
      .select()
      .from(categories)
      .where(and(eq(categories.id, categoryId), eq(categories.userId, userId)))
      .limit(1);

    if (existingCategories.length === 0) {
      res.status(404).json({
        success: false,
        message: "Category not found",
      });
      return;
    }

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

    const updateData: Partial<NewCategory> = {
      updatedAt: new Date(),
    };

    if (name !== undefined) updateData.name = name;
    if (type !== undefined) updateData.type = type;
    if (icon !== undefined) updateData.icon = icon;
    if (color !== undefined) updateData.color = color;
    if (budget !== undefined) updateData.budget = budget;

    const updatedCategory = await db
      .update(categories)
      .set(updateData)
      .where(eq(categories.id, categoryId))
      .returning();

    res.json({
      success: true,
      message: "Category updated successfully",
      data: updatedCategory[0],
    });
  } catch (error) {
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

    const existingCategories = await db
      .select()
      .from(categories)
      .where(and(eq(categories.id, categoryId), eq(categories.userId, userId)))
      .limit(1);

    if (existingCategories.length === 0) {
      res.status(404).json({
        success: false,
        message: "Category not found",
      });
      return;
    }

    await db.delete(categories).where(eq(categories.id, categoryId));

    res.json({
      success: true,
      message: "Category deleted successfully",
    });
  } catch (error) {
    console.error("Delete category error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to delete category",
    });
  }
});

export default router;
