import bcrypt from "bcryptjs";
import { db } from "@/shared/db";
import { refreshTokens } from "./auth.schema";
import { User, users } from "../user/user.schema";
import { eq } from "drizzle-orm";
import {
  generateAccessToken,
  generateRefreshToken,
  getRefreshTokenExpiry,
  verifyRefreshToken,
} from "./auth.utils";

export interface RegisterData {
  email: string;
  password: string;
  name: string;
}

export interface LoginData {
  email: string;
  password: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

export class AuthService {
  async register(data: RegisterData): Promise<AuthTokens> {
    const { email, password, name } = data;

    const existingUser = await db
      .select()
      .from(users)
      .where(eq(users.email, email.toLowerCase()))
      .limit(1);

    if (existingUser.length > 0) {
      throw new Error("User with this email already exists");
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = await db
      .insert(users)
      .values({
        email: email.toLowerCase(),
        password: hashedPassword,
        name: name,
      })
      .returning();

    const tokens = this.generateTokens(newUser[0]);
    await this.storeRefreshToken(newUser[0].id, tokens.refreshToken);

    return tokens;
  }

  async login(data: LoginData): Promise<AuthTokens> {
    const { email, password } = data;

    const foundUsers = await db
      .select()
      .from(users)
      .where(eq(users.email, email.toLowerCase()))
      .limit(1);

    if (foundUsers.length === 0) {
      throw new Error("Invalid email or password");
    }

    const user = foundUsers[0];
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      throw new Error("Invalid email or password");
    }

    const tokens = this.generateTokens(user);
    await this.storeRefreshToken(user.id, tokens.refreshToken);

    return tokens;
  }

  async refresh(token: string): Promise<AuthTokens> {
    const payload = verifyRefreshToken(token);

    if (!payload) {
      throw new Error("Invalid or expired refresh token");
    }

    const storedTokens = await db
      .select()
      .from(refreshTokens)
      .where(eq(refreshTokens.token, token))
      .limit(1);

    if (storedTokens.length === 0) {
      throw new Error("Refresh token not found");
    }

    const storedToken = storedTokens[0];

    if (new Date() > storedToken.expiresAt) {
      await db
        .delete(refreshTokens)
        .where(eq(refreshTokens.id, storedToken.id));
      throw new Error("Refresh token has expired");
    }

    const foundUsers = await db
      .select()
      .from(users)
      .where(eq(users.id, payload.userId))
      .limit(1);

    if (foundUsers.length === 0) {
      throw new Error("User not found");
    }

    const user = foundUsers[0];

    // Invalidate old token
    await db.delete(refreshTokens).where(eq(refreshTokens.id, storedToken.id));

    // Generate new tokens
    const tokens = this.generateTokens(user);
    await this.storeRefreshToken(user.id, tokens.refreshToken);

    return tokens;
  }

  async logout(token: string): Promise<void> {
    await db.delete(refreshTokens).where(eq(refreshTokens.token, token));
  }

  async getUser(userId: string): Promise<Omit<User, "password">> {
    const foundUsers = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (foundUsers.length === 0) {
      throw new Error("User not found");
    }

    const user = foundUsers[0];
    const { password, ...safeUser } = user;
    return safeUser;
  }

  private generateTokens(user: User): AuthTokens {
    return {
      accessToken: generateAccessToken(user),
      refreshToken: generateRefreshToken(user),
    };
  }

  private async storeRefreshToken(
    userId: string,
    token: string,
  ): Promise<void> {
    await db.insert(refreshTokens).values({
      userId,
      token,
      expiresAt: getRefreshTokenExpiry(),
    });
  }
}

export const authService = new AuthService();
