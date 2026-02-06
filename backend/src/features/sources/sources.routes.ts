import { Router, Request, Response } from "express";
import { sourcesService } from "./sources.service";
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
    const userSources = await sourcesService.getAll(userId);

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
    const source = await sourcesService.getById(userId, sourceId);

    if (!source) {
      res.status(404).json({
        success: false,
        message: "Source not found",
      });
      return;
    }

    res.json({
      success: true,
      data: source,
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
    const body = req.body as SourceBody;
    const { name, type, icon, color } = body;

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

    const newSource = await sourcesService.create({
      userId,
      ...body,
    });

    res.status(201).json({
      success: true,
      message: "Source created successfully",
      data: newSource,
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
    const body = req.body as Partial<SourceBody>;
    const { type } = body;

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

    const updatedSource = await sourcesService.update({
      userId,
      id: sourceId,
      ...body,
    });

    res.json({
      success: true,
      message: "Source updated successfully",
      data: updatedSource,
    });
  } catch (error: any) {
    if (error.message === "Source not found") {
      res.status(404).json({
        success: false,
        message: error.message,
      });
      return;
    }
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

    await sourcesService.delete(userId, sourceId);

    res.json({
      success: true,
      message: "Source deleted successfully",
    });
  } catch (error: any) {
    if (error.message === "Source not found") {
      res.status(404).json({
        success: false,
        message: error.message,
      });
      return;
    }
    console.error("Delete source error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to delete source",
    });
  }
});

export default router;
