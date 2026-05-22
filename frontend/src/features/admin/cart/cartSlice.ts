import { createSlice } from "@reduxjs/toolkit";
import type { PayloadAction } from "@reduxjs/toolkit";
import type { RootState } from "../../../app/store";
import type { CartsQuery } from "./cartApi";

type Status = "idle" | "loading" | "succeeded" | "failed";

export interface AdminCartItem {
    id: number;
    productId: number;
    productName: string;
    productImage: string | null;
    productPrice: number;
    discountPrice: number | null;
    finalPrice: number;
    sku: string;
    categoryName: string;
    quantity: number;
    subtotal: number;
}

export interface AdminCart {
    id: number;
    userId: number;
    items: AdminCartItem[];
    totalPrice: number;
    totalItems: number;
    createdAt: string;
    updatedAt: string;
}

interface AdminCartsState {
    items: AdminCart[];
    totalCount: number;
    currentPage: number;
    status: Status;
    error: string | null;
    selectedId: number | null;
    lastQuery: CartsQuery | null;
}

const initialState: AdminCartsState = {
    items: [],
    totalCount: 0,
    currentPage: 1,
    status: "idle",
    error: null,
    selectedId: null,
    lastQuery: null,
};

const adminCartsSlice = createSlice({
    name: "adminCarts",
    initialState,
    reducers: {
        fetchCartsRequest: (
            state,
            action: PayloadAction<CartsQuery | undefined>
        ) => {
            state.status = "loading";
            state.error = null;
            state.lastQuery = action.payload ?? null;
        },
        fetchCartsSuccess: (
            state,
            action: PayloadAction<{
                items: AdminCart[];
                totalCount: number;
                page: number;
            }>
        ) => {
            state.status = "succeeded";
            state.items = action.payload.items;
            state.totalCount = action.payload.totalCount;
            state.currentPage = action.payload.page;
        },
        fetchCartsFailure: (state, action: PayloadAction<string>) => {
            state.status = "failed";
            state.error = action.payload;
        },
        setSelectedCartId: (state, action: PayloadAction<number | null>) => {
            state.selectedId = action.payload;
        },
    },
});

export const adminCartsActions = adminCartsSlice.actions;
export default adminCartsSlice.reducer;

// Selectors
export const selectAdminCarts = (s: RootState) => s.adminCarts.items;
export const selectAdminCartsTotal = (s: RootState) => s.adminCarts.totalCount;
export const selectAdminCartsPage = (s: RootState) => s.adminCarts.currentPage;
export const selectAdminCartsStatus = (s: RootState) => s.adminCarts.status;
export const selectAdminCartsError = (s: RootState) => s.adminCarts.error;
export const selectSelectedCartId = (s: RootState) => s.adminCarts.selectedId;

/* ═══════════════════════════════════════════════════════
   USER-FACING CART SLICE
   (current user's own cart — add/remove/update/fetch)
   ═══════════════════════════════════════════════════════ */

export interface CartItem {
    id: number;         // product id
    cartItemId?: number; // backend cart item id
    name: string;
    price: number;
    discountPrice?: number;
    finalPrice: number;
    image: string | null;
    quantity: number;
    stock: number;
    sku?: string;
    category?: string;
}

interface CartState {
    items: CartItem[];
    isLoading: boolean;
    error: string | null;
    isOpen: boolean;
}

const cartInitialState: CartState = {
    items: [],
    isLoading: false,
    error: null,
    isOpen: false,
};

const cartSlice = createSlice({
    name: 'cart',
    initialState: cartInitialState,
    reducers: {
        toggleCart: (state) => {
            state.isOpen = !state.isOpen;
        },
        fetchCartRequest: (state) => {
            state.isLoading = true;
            state.error = null;
        },
        fetchCartSuccess: (state, action: PayloadAction<CartItem[]>) => {
            state.items = action.payload;
            state.isLoading = false;
            state.error = null;
        },
        fetchCartFailure: (state, action: PayloadAction<string>) => {
            state.isLoading = false;
            state.error = action.payload;
        },
        addToCart: (state, action: PayloadAction<CartItem>) => {
            const existing = state.items.find((i) => i.id === action.payload.id);
            if (existing) {
                if (existing.quantity < existing.stock) {
                    existing.quantity += 1;
                }
            } else {
                state.items.push({ ...action.payload, quantity: 1 });
            }
        },
        removeFromCart: (state, action: PayloadAction<number>) => {
            state.items = state.items.filter((i) => i.id !== action.payload);
        },
        updateQuantity: (state, action: PayloadAction<{ id: number; quantity: number }>) => {
            const item = state.items.find((i) => i.id === action.payload.id);
            if (item && action.payload.quantity > 0 && action.payload.quantity <= item.stock) {
                item.quantity = action.payload.quantity;
            }
        },
        clearCart: (state) => {
            state.items = [];
        },
    },
});

export const {
    toggleCart,
    fetchCartRequest,
    fetchCartSuccess,
    fetchCartFailure,
    addToCart,
    removeFromCart,
    updateQuantity,
    clearCart,
} = cartSlice.actions;

// User cart selectors
export const selectCartItems = (state: RootState) => state.cart.items;
export const selectCartTotal = (state: RootState) =>
    state.cart.items.reduce((total, item) => total + item.finalPrice * item.quantity, 0);
export const selectCartCount = (state: RootState) =>
    state.cart.items.reduce((count, item) => count + item.quantity, 0);
export const selectCartLoading = (state: RootState) => state.cart.isLoading;
export const selectCartError = (state: RootState) => state.cart.error;

export const cartReducer = cartSlice.reducer;
