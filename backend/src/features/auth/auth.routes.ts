import { Router, Request, Response } from "express";
import bcrypt from "bcryptjs";
import { db } from "@/shared/db";
import { refreshTokens } from "./auth.schema";
import { eq } from "drizzle-orm";
import {
  generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken,
  getRefreshTokenExpiry,
} from "./auth.utils";
import { authMiddleware } from "./auth.middleware";
import { User, users } from "../user/user.schema";

interface RegisterBody {
  email: string;
  password: string;
  name: string;
}

interface LoginBody {
  email: string;
  password: string;
}

interface RefreshBody {
  refreshToken: string;
}

type SafeUser = Omit<User, "password">;

const router = Router();

router.post("/register", async (req: Request, res: Response) => {
  try {
    const { email, password, name } = req.body as RegisterBody;

    if (!email || !password || !name) {
      res.status(400).json({
        success: false,
        message: "Email, password, and name are required",
      });
      return;
    }

    const emailRegex =
      /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$/;
    // REGEX FROM https://github.com/peiffer-innovations/form_validation/blob/main/lib/src/validators/email_validator.dart

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

    const existingUser = await db
      .select()
      .from(users)
      .where(eq(users.email, email.toLowerCase()))
      .limit(1);

    if (existingUser.length > 0) {
      res.status(400).json({
        success: false,
        message: "User with this email already exists",
      });
      return;
    }

    const hashedPassword: string = await bcrypt.hash(password, 10);

    const newUser = await db
      .insert(users)
      .values({
        email: email.toLowerCase(),
        password: hashedPassword,
        name: name,
      })
      .returning();

    const accessToken = generateAccessToken(newUser[0]);
    const refreshToken = generateRefreshToken(newUser[0]);

    await db.insert(refreshTokens).values({
      userId: newUser[0].id,
      token: refreshToken,
      expiresAt: getRefreshTokenExpiry(),
    });

    res.status(201).json({
      success: true,
      message: "User registered successfully",
      data: {
        accessToken: accessToken,
        refreshToken: refreshToken,
      },
    });
  } catch (error) {
    console.error("Register error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to register user",
    });
  }
});

router.post("/login", async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body as LoginBody;

    if (!email || !password) {
      res.status(400).json({
        success: false,
        message: "Email and password are required",
      });
      return;
    }

    const foundUsers = await db
      .select()
      .from(users)
      .where(eq(users.email, email.toLowerCase()))
      .limit(1);

    if (foundUsers.length === 0) {
      res.status(401).json({
        success: false,
        message: "Invalid email or password",
      });
      return;
    }

    const user = foundUsers[0];

    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      res.status(401).json({
        success: false,
        message: "Invalid email or password",
      });
      return;
    }

    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);

    await db.insert(refreshTokens).values({
      userId: user.id,
      token: refreshToken,
      expiresAt: getRefreshTokenExpiry(),
    });

    res.json({
      success: true,
      message: "Login successful",
      data: {
        accessToken: accessToken,
        refreshToken: refreshToken,
      },
    });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to login",
    });
  }
});

router.post("/refresh", async (req: Request, res: Response) => {
  try {
    const { refreshToken: token } = req.body as RefreshBody;

    if (!token) {
      res.status(400).json({
        success: false,
        message: "Refresh token is required",
      });
      return;
    }

    const payload = verifyRefreshToken(token);

    if (!payload) {
      res.status(401).json({
        success: false,
        message: "Invalid or expired refresh token",
      });
      return;
    }

    const storedTokens = await db
      .select()
      .from(refreshTokens)
      .where(eq(refreshTokens.token, token))
      .limit(1);

    if (storedTokens.length === 0) {
      res.status(401).json({
        success: false,
        message: "Refresh token not found",
      });
      return;
    }

    const storedToken = storedTokens[0];

    if (new Date() > storedToken.expiresAt) {
      await db
        .delete(refreshTokens)
        .where(eq(refreshTokens.id, storedToken.id));

      res.status(401).json({
        success: false,
        message: "Refresh token has expired",
      });
      return;
    }

    const foundUsers = await db
      .select()
      .from(users)
      .where(eq(users.id, payload.userId))
      .limit(1);

    if (foundUsers.length === 0) {
      res.status(401).json({
        success: false,
        message: "User not found",
      });
      return;
    }

    const user = foundUsers[0];

    const newAccessToken = generateAccessToken(user);
    const newRefreshToken = generateRefreshToken(user);

    await db.delete(refreshTokens).where(eq(refreshTokens.id, storedToken.id));

    await db.insert(refreshTokens).values({
      userId: user.id,
      token: newRefreshToken,
      expiresAt: getRefreshTokenExpiry(),
    });

    res.json({
      success: true,
      message: "Token refreshed successfully",
      data: {
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      },
    });
  } catch (error) {
    console.error("Refresh error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to refresh token",
    });
  }
});

router.post("/logout", authMiddleware, async (req: Request, res: Response) => {
  try {
    const { refreshToken: token } = req.body as RefreshBody;

    if (token) {
      await db.delete(refreshTokens).where(eq(refreshTokens.token, token));
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

    const foundUsers = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (foundUsers.length === 0) {
      res.status(404).json({
        success: false,
        message: "User not found",
      });
      return;
    }

    const user = foundUsers[0];

    const safeUser: SafeUser = {
      id: user.id,
      email: user.email,
      name: user.name,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };

    res.json({
      success: true,
      data: safeUser,
    });
  } catch (error) {
    console.error("Get me error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to get user info",
    });
  }
});

export default router;
