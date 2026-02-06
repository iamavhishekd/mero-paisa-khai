import { Router, Request, Response } from "express";
import { db } from "@/shared/db";
import { sources, type NewSource } from "./sources.schema";
import { eq, and } from "drizzle-orm";
import { authMiddleware } from "@/features/auth/auth.middleware";

interface SourceBody {
  name: string;
  type: "bank" | "wallet" | "cash";
  icon: string;
  color: string;
  initialBalance?: number;
}

const router = Router();

router.use(authMiddleware);

router.get("/", async (req: Request, res: Response) => {
  try {
    const userId = req.userId!;

    const userSources = await db
      .select()
      .from(sources)
      .where(eq(sources.userId, userId))
      .orderBy(sources.createdAt);

    res.json({
      success: true,
      data: userSources,
    });
  } catch (error) {
    console.error("Get sources error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to get sources",
    });
  }
});

router.get("/:id", async (req: Request, res: Response) => {
  try {
    const userId = req.userId!;
    const sourceId = req.params.id;

    const foundSources = await db
      .select()
      .from(sources)
      .where(and(eq(sources.id, sourceId), eq(sources.userId, userId)))
      .limit(1);

    if (foundSources.length === 0) {
      res.status(404).json({
        success: false,
        message: "Source not found",
      });
      return;
    }

    res.json({
      success: true,
      data: foundSources[0],
    });
  } catch (error) {
    console.error("Get source error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to get source",
    });
  }
});

router.post("/", async (req: Request, res: Response) => {
  try {
    const userId = req.userId!;
    const { name, type, icon, color, initialBalance } = req.body as SourceBody;

    if (!name || !type || !icon || !color) {
      res.status(400).json({
        success: false,
        message: "Name, type, icon, and color are required",
      });
      return;
    }

    const validTypes = ["bank", "wallet", "cash"];
    if (!validTypes.includes(type)) {
      res.status(400).json({
        success: false,
        message: "Type must be: bank, wallet, or cash",
      });
      return;
    }

    const newSource = await db
      .insert(sources)
      .values({
        userId: userId,
        name: name,
        type: type,
        icon: icon,
        color: color,
        initialBalance: initialBalance || 0,
      })
      .returning();

    res.status(201).json({
      success: true,
      message: "Source created successfully",
      data: newSource[0],
    });
  } catch (error) {
    console.error("Create source error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to create source",
    });
  }
});

router.put("/:id", async (req: Request, res: Response) => {
  try {
    const userId = req.userId!;
    const sourceId = req.params.id;
    const { name, type, icon, color, initialBalance } =
      req.body as Partial<SourceBody>;

    const existingSources = await db
      .select()
      .from(sources)
      .where(and(eq(sources.id, sourceId), eq(sources.userId, userId)))
      .limit(1);

    if (existingSources.length === 0) {
      res.status(404).json({
        success: false,
        message: "Source not found",
      });
      return;
    }

    if (type) {
      const validTypes = ["bank", "wallet", "cash"];
      if (!validTypes.includes(type)) {
        res.status(400).json({
          success: false,
          message: "Type must be: bank, wallet, or cash",
        });
        return;
      }
    }

    const updateData: Partial<NewSource> = {
      updatedAt: new Date(),
    };

    if (name !== undefined) updateData.name = name;
    if (type !== undefined) updateData.type = type;
    if (icon !== undefined) updateData.icon = icon;
    if (color !== undefined) updateData.color = color;
    if (initialBalance !== undefined)
      updateData.initialBalance = initialBalance;

    const updatedSource = await db
      .update(sources)
      .set(updateData)
      .where(eq(sources.id, sourceId))
      .returning();

    res.json({
      success: true,
      message: "Source updated successfully",
      data: updatedSource[0],
    });
  } catch (error) {
    console.error("Update source error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to update source",
    });
  }
});

router.delete("/:id", async (req: Request, res: Response) => {
  try {
    const userId = req.userId!;
    const sourceId = req.params.id;

    const existingSources = await db
      .select()
      .from(sources)
      .where(and(eq(sources.id, sourceId), eq(sources.userId, userId)))
      .limit(1);

    if (existingSources.length === 0) {
      res.status(404).json({
        success: false,
        message: "Source not found",
      });
      return;
    }

    await db.delete(sources).where(eq(sources.id, sourceId));

    res.json({
      success: true,
      message: "Source deleted successfully",
    });
  } catch (error) {
    console.error("Delete source error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to delete source",
    });
  }
});

export default router;
