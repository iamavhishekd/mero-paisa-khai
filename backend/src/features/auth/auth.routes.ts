import { Router, Request, Response } from "express";
import { authService, RegisterData, LoginData } from "./auth.service";
import { authMiddleware } from "./auth.middleware";

interface RegisterBody extends RegisterData {}
interface LoginBody extends LoginData {}
interface RefreshBody {
  refreshToken: string;
}

const router = Router();

router.post("/register", async (req: Request, res: Response) => {
  try {
    const data = req.body as RegisterBody;
    const { email, password, name } = data;

    if (!email || !password || !name) {
      res.status(400).json({
        success: false,
        message: "Email, password, and name are required",
      });
      return;
    }

    const emailRegex =
      /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$/;

    if (!emailRegex.test(email)) {
      res.status(400).json({
        success: false,
        message: "Invalid email format",
      });
      return;
    }

    if (password.length < 6) {
      res.status(400).json({
        success: false,
        message: "Password must be at least 6 characters",
      });
      return;
    }

    const tokens = await authService.register(data);

    res.status(201).json({
      success: true,
      message: "User registered successfully",
      data: tokens,
    });
  } catch (error: any) {
    if (error.message === "User with this email already exists") {
      res.status(400).json({
        success: false,
        message: error.message,
      });
      return;
    }
    console.error("Register error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to register user",
    });
  }
});

router.post("/login", async (req: Request, res: Response) => {
  try {
    const data = req.body as LoginBody;
    const { email, password } = data;

    if (!email || !password) {
      res.status(400).json({
        success: false,
        message: "Email and password are required",
      });
      return;
    }

    const tokens = await authService.login(data);

    res.json({
      success: true,
      message: "Login successful",
      data: tokens,
    });
  } catch (error: any) {
    if (error.message === "Invalid email or password") {
      res.status(401).json({
        success: false,
        message: error.message,
      });
      return;
    }
    console.error("Login error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to login",
    });
  }
});

router.post("/refresh", async (req: Request, res: Response) => {
  try {
    const { refreshToken } = req.body as RefreshBody;

    if (!refreshToken) {
      res.status(400).json({
        success: false,
        message: "Refresh token is required",
      });
      return;
    }

    const tokens = await authService.refresh(refreshToken);

    res.json({
      success: true,
      message: "Token refreshed successfully",
      data: tokens,
    });
  } catch (error: any) {
    if (
      error.message === "Invalid or expired refresh token" ||
      error.message === "Refresh token not found" ||
      error.message === "Refresh token has expired" ||
      error.message === "User not found"
    ) {
      res.status(401).json({
        success: false,
        message: error.message,
      });
      return;
    }
    console.error("Refresh error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to refresh token",
    });
  }
});

router.post("/logout", authMiddleware, async (req: Request, res: Response) => {
  try {
    const { refreshToken } = req.body as RefreshBody;

    if (refreshToken) {
      await authService.logout(refreshToken);
    }

    res.json({
      success: true,
      message: "Logged out successfully",
    });
  } catch (error) {
    console.error("Logout error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to logout",
    });
  }
});

router.get("/me", authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = req.userId!;
    const user = await authService.getUser(userId);

    res.json({
      success: true,
      data: user,
    });
  } catch (error: any) {
    if (error.message === "User not found") {
      res.status(404).json({
        success: false,
        message: error.message,
      });
      return;
    }
    console.error("Get me error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to get user info",
    });
  }
});

export default router;
