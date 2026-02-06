import jwt from "jsonwebtoken";
import requireEnv from "@/shared/utils/requireEnv";
import { User } from "@/features/user/user.schema";

const ACCESS_SECRET = requireEnv("JWT_ACCESS_SECRET");
const REFRESH_SECRET = requireEnv("JWT_REFRESH_SECRET");

const ACCESS_EXPIRY = requireEnv("JWT_ACCESS_EXPIRY");
const REFRESH_EXPIRY = requireEnv("JWT_REFRESH_EXPIRY");

interface TokenPayload {
  userId: string;
  email: string;
}

export function generateAccessToken(user: User): string {
  const payload: TokenPayload = {
    userId: user.id,
    email: user.email,
  };

  return jwt.sign(payload, ACCESS_SECRET, {
    expiresIn: ACCESS_EXPIRY as jwt.SignOptions["expiresIn"],
  });
}

export function generateRefreshToken(user: User): string {
  const payload: TokenPayload = {
    userId: user.id,
    email: user.email,
  };

  return jwt.sign(payload, REFRESH_SECRET, {
    expiresIn: REFRESH_EXPIRY as jwt.SignOptions["expiresIn"],
  });
}

export function verifyAccessToken(token: string): TokenPayload | null {
  try {
    const decoded = jwt.verify(token, ACCESS_SECRET) as TokenPayload;
    return decoded;
  } catch (error) {
    return null;
  }
}

export function verifyRefreshToken(token: string): TokenPayload | null {
  try {
    const decoded = jwt.verify(token, REFRESH_SECRET) as TokenPayload;
    return decoded;
  } catch (error) {
    return null;
  }
}

export function getRefreshTokenExpiry(): Date {
  const expiryString = REFRESH_EXPIRY;
  const value = parseInt(expiryString);
  const unit = expiryString.replace(/\d/g, "");

  const now = new Date();

  switch (unit) {
    case "d":
      now.setDate(now.getDate() + value);
      break;
    case "h":
      now.setHours(now.getHours() + value);
      break;
    case "m":
      now.setMinutes(now.getMinutes() + value);
      break;
    default:
      now.setDate(now.getDate() + 7);
  }

  return now;
}
