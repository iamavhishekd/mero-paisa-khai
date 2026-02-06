import { db } from "@/shared/db";
import { sources, type NewSource, type Source } from "./sources.schema";
import { eq, and } from "drizzle-orm";

export interface CreateSourceData {
  userId: string;
  name: string;
  type: "bank" | "wallet" | "cash";
  icon: string;
  color: string;
  initialBalance?: number;
}

export interface UpdateSourceData {
  userId: string;
  id: string;
  name?: string;
  type?: "bank" | "wallet" | "cash";
  icon?: string;
  color?: string;
  initialBalance?: number;
}

export class SourcesService {
  async getAll(userId: string): Promise<Source[]> {
    return await db
      .select()
      .from(sources)
      .where(eq(sources.userId, userId))
      .orderBy(sources.createdAt);
  }

  async getById(userId: string, id: string): Promise<Source | null> {
    const foundSources = await db
      .select()
      .from(sources)
      .where(and(eq(sources.id, id), eq(sources.userId, userId)))
      .limit(1);

    return foundSources.length > 0 ? foundSources[0] : null;
  }

  async create(data: CreateSourceData): Promise<Source> {
    const newSource = await db
      .insert(sources)
      .values({
        userId: data.userId,
        name: data.name,
        type: data.type,
        icon: data.icon,
        color: data.color,
        initialBalance: data.initialBalance || 0,
      })
      .returning();

    return newSource[0];
  }

  async update(data: UpdateSourceData): Promise<Source> {
    const existingSource = await this.getById(data.userId, data.id);

    if (!existingSource) {
      throw new Error("Source not found");
    }

    const updateData: Partial<NewSource> = {
      updatedAt: new Date(),
    };

    if (data.name !== undefined) updateData.name = data.name;
    if (data.type !== undefined) updateData.type = data.type;
    if (data.icon !== undefined) updateData.icon = data.icon;
    if (data.color !== undefined) updateData.color = data.color;
    if (data.initialBalance !== undefined)
      updateData.initialBalance = data.initialBalance;

    const updatedSource = await db
      .update(sources)
      .set(updateData)
      .where(eq(sources.id, data.id))
      .returning();

    return updatedSource[0];
  }

  async delete(userId: string, id: string): Promise<void> {
    const existingSource = await this.getById(userId, id);

    if (!existingSource) {
      throw new Error("Source not found");
    }

    await db.delete(sources).where(eq(sources.id, id));
  }
}

export const sourcesService = new SourcesService();
