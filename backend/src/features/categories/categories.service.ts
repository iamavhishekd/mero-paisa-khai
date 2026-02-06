import { db } from "@/shared/db";
import {
  categories,
  type NewCategory,
  type Category,
} from "./categories.schema";
import { eq, and } from "drizzle-orm";

export interface CreateCategoryData {
  userId: string;
  name: string;
  type: "income" | "expense" | "both";
  icon: string;
  color: string;
  budget?: number;
}

export interface UpdateCategoryData {
  userId: string;
  id: string;
  name?: string;
  type?: "income" | "expense" | "both";
  icon?: string;
  color?: string;
  budget?: number;
}

export class CategoriesService {
  async getAll(userId: string): Promise<Category[]> {
    return await db
      .select()
      .from(categories)
      .where(eq(categories.userId, userId))
      .orderBy(categories.createdAt);
  }

  async getById(userId: string, id: string): Promise<Category | null> {
    const foundCategories = await db
      .select()
      .from(categories)
      .where(and(eq(categories.id, id), eq(categories.userId, userId)))
      .limit(1);

    return foundCategories.length > 0 ? foundCategories[0] : null;
  }

  async create(data: CreateCategoryData): Promise<Category> {
    const newCategory = await db
      .insert(categories)
      .values({
        userId: data.userId,
        name: data.name,
        type: data.type,
        icon: data.icon,
        color: data.color,
        budget: data.budget || null,
      })
      .returning();

    return newCategory[0];
  }

  async update(data: UpdateCategoryData): Promise<Category> {
    const existingCategory = await this.getById(data.userId, data.id);

    if (!existingCategory) {
      throw new Error("Category not found");
    }

    const updateData: Partial<NewCategory> = {
      updatedAt: new Date(),
    };

    if (data.name !== undefined) updateData.name = data.name;
    if (data.type !== undefined) updateData.type = data.type;
    if (data.icon !== undefined) updateData.icon = data.icon;
    if (data.color !== undefined) updateData.color = data.color;
    if (data.budget !== undefined) updateData.budget = data.budget;

    const updatedCategory = await db
      .update(categories)
      .set(updateData)
      .where(eq(categories.id, data.id))
      .returning();

    return updatedCategory[0];
  }

  async delete(userId: string, id: string): Promise<void> {
    const existingCategory = await this.getById(userId, id);

    if (!existingCategory) {
      throw new Error("Category not found");
    }

    await db.delete(categories).where(eq(categories.id, id));
  }
}

export const categoriesService = new CategoriesService();
