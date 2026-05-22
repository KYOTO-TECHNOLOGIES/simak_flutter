import { api } from "../../../services/api";

/* ── Product Image DTO ── */
export interface ProductImageDto {
  id: number;
  image: string;
  is_feature: boolean;
  created_at: string;
}

/* ── Product Video DTO ── */
export interface ProductVideoDto {
  id: number;
  video_file: string | null;
  video_url: string | null;
  title: string;
  created_at: string;
}

/* ── Product DTO returned by backend ── */
export interface ProductDto {
  id: number;
  name: string;
  slug: string;
  description: string;
  category: number;
  category_name: string;
  price: string;
  discount_price: string | null;
  final_price: string;
  stock: number;
  is_available: boolean;
  image: string | null;
  sku: string;
  expected_delivery_time: string | null;
  images: ProductImageDto[];
  videos: ProductVideoDto[];
  average_rating: number;
  total_reviews: number;
  created_at: string;
  updated_at: string;
}

export type ProductsQuery = {
  search?: string;
  category?: string;
  category_slug?: string;
  min_price?: number;
  max_price?: number;
  ordering?: "price" | "-price" | "created_at";
  page?: number;
  limit?: number;
  offset?: number;
  q?: string;
  status?: string;
};

export interface CategoryDto {
  id: number;
  name: string;
  slug: string;
  description: string;
  parent?: number | null;
  image?: string | null;
  is_active: boolean;
  product_count?: number;
}

export const productsApi = {
  list: async (
    params?: ProductsQuery
  ): Promise<{ results: ProductDto[]; count: number }> => {
    const res = await api.get<{ results: ProductDto[]; count: number }>(
      "/products/products/",
      { params }
    );
    return res.data;
  },

  details: async (id: number): Promise<ProductDto> => {
    const res = await api.get<ProductDto>(`/products/products/${id}/`);
    return res.data;
  },

  newArrivals: async (): Promise<ProductDto[]> => {
    const res = await api.get<ProductDto[]>("/products/products/new_arrivals/");
    return res.data;
  },

  related: async (id: number): Promise<ProductDto[]> => {
    const res = await api.get<ProductDto[]>(`/products/products/${id}/related/`);
    return res.data;
  },

  create: async (payload: Partial<ProductDto> | FormData): Promise<ProductDto> => {
    const isFormData = payload instanceof FormData;
    const res = await api.post<ProductDto>("/products/products/", payload, {
      ...(isFormData && { timeout: 60000 }),
    });
    return res.data;
  },

  update: async (
    id: number,
    payload: Partial<ProductDto> | FormData
  ): Promise<ProductDto> => {
    const res = await api.patch<ProductDto>(`/products/products/${id}/`, payload);
    return res.data;
  },

  delete: async (id: number): Promise<void> => {
    await api.delete(`/products/products/${id}/`);
  },

  /* ── Categories ── */
  listCategories: async (): Promise<CategoryDto[]> => {
    const res = await api.get<CategoryDto[]>("/products/categories/");
    return res.data;
  },

  createCategory: async (payload: Partial<CategoryDto>): Promise<CategoryDto> => {
    const res = await api.post<CategoryDto>("/products/categories/", payload);
    return res.data;
  },
};
