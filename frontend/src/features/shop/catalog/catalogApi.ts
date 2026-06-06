import { api } from "../../../services/api";

export const catalogApi = {
  listProducts: (params?: { q?: string; category?: string }) =>
    api.get("/products", { params }).then((r) => r.data),

  productDetails: (id: string) =>
    api.get(`/products/${id}`).then((r) => r.data),
};
