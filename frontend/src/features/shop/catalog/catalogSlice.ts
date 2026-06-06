import { createSlice } from "@reduxjs/toolkit";
import type { PayloadAction } from "@reduxjs/toolkit";
import type { RootState } from "../../../app/store";

// 1) Product Type
export interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  category: string;
  image: string;
  stock: number;
  rating: number;
}

// 2) State Shape
export type SortBy = "price-low" | "price-high" | "rating";

export interface CatalogState {
  products: Product[];
  filteredProducts: Product[];
  categories: string[];
  status: "idle" | "loading" | "succeeded" | "failed";
  error: string | null;
  filters: {
    category: string;
    search: string;
    sortBy: SortBy;
  };
}

const initialState: CatalogState = {
  products: [],
  filteredProducts: [],
  categories: [],
  status: "idle",
  error: null,
  filters: {
    category: "All",
    search: "",
    sortBy: "price-low",
  },
};

// ✅ Helper: apply filters (pure function)
const applyFilters = (products: Product[], filters: CatalogState["filters"]) => {
  let temp = products;

  if (filters.category !== "All") {
    temp = temp.filter((p) => p.category === filters.category);
  }

  if (filters.search.trim()) {
    const q = filters.search.trim().toLowerCase();
    temp = temp.filter((p) => p.name.toLowerCase().includes(q));
  }

  // ✅ Sorting on a copy to avoid mutating "temp" references
  const sorted = [...temp];

  switch (filters.sortBy) {
    case "price-low":
      sorted.sort((a, b) => a.price - b.price);
      break;
    case "price-high":
      sorted.sort((a, b) => b.price - a.price);
      break;
    case "rating":
      sorted.sort((a, b) => b.rating - a.rating);
      break;
  }

  return sorted;
};

const buildCategories = (products: Product[]) => {
  const set = new Set<string>();
  for (const p of products) set.add(p.category);
  return ["All", ...Array.from(set)];
};

export const catalogSlice = createSlice({
  name: "catalog",
  initialState,
  reducers: {
    // ✅ Saga triggers
    fetchProductsRequest: (state) => {
      state.status = "loading";
      state.error = null;
    },

    fetchProductsSuccess: (state, action: PayloadAction<Product[]>) => {
      state.status = "succeeded";
      state.products = action.payload;
      state.categories = buildCategories(action.payload);

      // ✅ IMPORTANT: apply existing filters after fetch
      state.filteredProducts = applyFilters(action.payload, state.filters);
    },

    fetchProductsFailure: (state, action: PayloadAction<string>) => {
      state.status = "failed";
      state.error = action.payload || "Something went wrong";
    },

    // ✅ Filters
    setCategoryFilter: (state, action: PayloadAction<string>) => {
      state.filters.category = action.payload;
      state.filteredProducts = applyFilters(state.products, state.filters);
    },

    setSearchFilter: (state, action: PayloadAction<string>) => {
      state.filters.search = action.payload;
      state.filteredProducts = applyFilters(state.products, state.filters);
    },

    setSortBy: (state, action: PayloadAction<SortBy>) => {
      state.filters.sortBy = action.payload;
      state.filteredProducts = applyFilters(state.products, state.filters);
    },

    // optional: reset filters (handy for UI)
    resetFilters: (state) => {
      state.filters = { category: "All", search: "", sortBy: "price-low" };
      state.filteredProducts = applyFilters(state.products, state.filters);
    },
  },
});

export const {
  fetchProductsRequest,
  fetchProductsSuccess,
  fetchProductsFailure,
  setCategoryFilter,
  setSearchFilter,
  setSortBy,
  resetFilters,
} = catalogSlice.actions;

// ✅ Selectors
export const selectAllProducts = (state: RootState) => state.catalog.filteredProducts;
export const selectCatalogStatus = (state: RootState) => state.catalog.status;
export const selectCatalogError = (state: RootState) => state.catalog.error;
export const selectCategories = (state: RootState) => state.catalog.categories;
export const selectFilters = (state: RootState) => state.catalog.filters;

export default catalogSlice.reducer;
