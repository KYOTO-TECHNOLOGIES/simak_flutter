import { call, put, select, takeLatest, takeEvery, take } from "redux-saga/effects";
import type { SagaIterator } from "redux-saga";
import { cartsApi } from "./cartApi";
import { adminCartsActions } from "./cartSlice";
import {
    addToCart,
    removeFromCart,
    updateQuantity,
    clearCart,
    fetchCartRequest,
    fetchCartSuccess,
    fetchCartFailure,
    type CartItem,
} from "./cartSlice";
import type { AdminCart, AdminCartItem } from "./cartSlice";
import type { CartDto, CartItemDto } from "./cartApi";
import type { RootState } from "../../../app/store";
import { setUser, setUnauthenticated } from "../../auth/authSlice";

function mapCartItemDto(dto: CartItemDto): AdminCartItem {
    const pd = dto.product_details;
    // Get the best image: feature image first, then main image
    const featureImage = pd?.images?.find((img) => img.is_feature);
    const imageUrl = featureImage?.image ?? pd?.image ?? null;

    return {
        id: dto.id,
        productId: dto.product,
        productName: pd?.name ?? `Product #${dto.product}`,
        productImage: imageUrl,
        productPrice: parseFloat(pd?.price ?? "0") || 0,
        discountPrice: pd?.discount_price ? parseFloat(pd.discount_price) || null : null,
        finalPrice: parseFloat(pd?.final_price ?? pd?.price ?? "0") || 0,
        sku: pd?.sku ?? "",
        categoryName: pd?.category_name ?? "",
        quantity: dto.quantity,
        subtotal: parseFloat(dto.subtotal ?? "0") || 0,
    };
}

/* ── Map backend DTO → UI AdminCart ── */
function mapCartDtoToCart(dto: CartDto): AdminCart {
    const items = Array.isArray(dto.items)
        ? dto.items.map(mapCartItemDto)
        : [];

    return {
        id: dto.id,
        userId: dto.user,
        items,
        totalPrice: parseFloat(dto.total_price ?? "0") || 0,
        totalItems: dto.total_items ?? items.length,
        createdAt: dto.created_at,
        updatedAt: dto.updated_at,
    };
}

/** Normalize any API shape → AdminCart[] */
function normalizeCarts(payload: any): AdminCart[] {
    if (Array.isArray(payload?.results))
        return payload.results.map(mapCartDtoToCart);
    if (Array.isArray(payload)) return payload.map(mapCartDtoToCart);
    if (Array.isArray(payload?.data))
        return payload.data.map(mapCartDtoToCart);
    return [];
}

function* fetchCartsWorker(
    action: ReturnType<typeof adminCartsActions.fetchCartsRequest>
): SagaIterator {
    try {
        const auth: any = yield select((state: RootState) => (state as any).auth);
        if (auth && auth.isAuthenticated === false) {
            yield put(adminCartsActions.fetchCartsFailure("User not authenticated"));
            return;
        }

        const raw: any = yield call(cartsApi.list, action.payload);
        const totalCount = raw?.count || 0;
        const items = normalizeCarts(raw);
        const page = action.payload?.page || 1;

        yield put(
            adminCartsActions.fetchCartsSuccess({
                items,
                totalCount,
                page,
            })
        );
    } catch (e: any) {
        console.error("Fetch Carts Error:", {
            status: e?.response?.status,
            data: e?.response?.data,
            message: e?.message,
        });

        const errMsg =
            e?.response?.data?.detail ||
            e?.response?.data?.message ||
            e?.message ||
            "Failed to fetch carts";

        yield put(adminCartsActions.fetchCartsFailure(errMsg));
    }
}

export function* adminCartsSaga(): SagaIterator {
    yield takeLatest(
        adminCartsActions.fetchCartsRequest.type,
        fetchCartsWorker
    );
}

/* ═══════════════════════════════════════════════════════
   USER-FACING CART SAGA
   (fetch current user's cart, sync mutations to backend)
   ═══════════════════════════════════════════════════════ */

/* ── Map backend cart item DTO → user CartItem ── */
function mapApiItemToCartItem(dto: CartItemDto): CartItem {
    const pd = dto.product_details;
    const featureImg = pd?.images?.find((img) => img.is_feature);
    const image = featureImg?.image ?? pd?.image ?? null;
    const price = parseFloat(pd?.price ?? "0") || 0;
    const discountPrice = pd?.discount_price ? parseFloat(pd.discount_price) || undefined : undefined;
    const finalPrice = parseFloat(pd?.final_price ?? pd?.price ?? "0") || price;

    return {
        id: pd?.id ?? dto.product,
        cartItemId: dto.id,
        name: pd?.name ?? `Product #${dto.product}`,
        price,
        discountPrice,
        finalPrice,
        image,
        quantity: dto.quantity,
        stock: pd?.stock ?? 999,
        sku: pd?.sku ?? "",
        category: pd?.category_name ?? "",
    };
}

/* ── Fetch user's own cart from API ── */
function* fetchUserCartWorker(): SagaIterator {
    try {
        // Wait for auth check to finish if still in progress
        const isStillChecking: boolean = yield select(
            (state: RootState) => state.auth.checkingAuth
        );
        if (isStillChecking) {
            yield take([setUser.type, setUnauthenticated.type]);
        }

        const isAuthenticated: boolean = yield select(
            (state: RootState) => state.auth.isAuthenticated
        );
        if (!isAuthenticated) {
            yield put(fetchCartSuccess([]));
            return;
        }

        const data: Awaited<ReturnType<typeof cartsApi.fetchCart>> = yield call(
            cartsApi.fetchCart
        );
        const items: CartItem[] = Array.isArray(data?.items)
            ? data.items.map(mapApiItemToCartItem)
            : [];
        yield put(fetchCartSuccess(items));
    } catch (e: any) {
        const msg =
            e?.response?.data?.detail ||
            e?.response?.data?.message ||
            e?.message ||
            "Failed to load cart";
        yield put(fetchCartFailure(msg));
    }
}

/* ── Load cart when user logs in or session is restored ── */
function* onAuthSuccess(): SagaIterator {
    yield put(fetchCartRequest());
}

/* ── Clear cart on logout ── */
function* onLogout(): SagaIterator {
    yield put(clearCart());
}

/* ── Add an item to cart ── */
function* addToCartWorker(action: ReturnType<typeof addToCart>): SagaIterator {
    try {
        const isAuthenticated: boolean = yield select(
            (state: RootState) => state.auth.isAuthenticated
        );
        if (!isAuthenticated) return;

        yield call(cartsApi.addItem, action.payload.id, action.payload.quantity);
        // Refresh cart to ensure total price and item details are correct
        yield put(fetchCartRequest());
    } catch (e: any) {
        console.error("[Cart Add] Error:", e);
    }
}

/* ── Remove an item from cart ── */
function* removeFromCartWorker(action: ReturnType<typeof removeFromCart>): SagaIterator {
    try {
        const isAuthenticated: boolean = yield select(
            (state: RootState) => state.auth.isAuthenticated
        );
        if (!isAuthenticated) return;

        yield call(cartsApi.removeItem, action.payload);
        yield put(fetchCartRequest());
    } catch (e: any) {
        console.error("[Cart Remove] Error:", e);
    }
}

/* ── Update cart item quantity ── */
function* updateQuantityWorker(action: ReturnType<typeof updateQuantity>): SagaIterator {
    try {
        const isAuthenticated: boolean = yield select(
            (state: RootState) => state.auth.isAuthenticated
        );
        if (!isAuthenticated) return;

        yield call(cartsApi.updateQuantity, action.payload.id, action.payload.quantity);
        yield put(fetchCartRequest());
    } catch (e: any) {
        console.error("[Cart Update] Error:", e);
    }
}

/* ── Clear cart ── */
function* clearCartWorker(): SagaIterator {
    try {
        const isAuthenticated: boolean = yield select(
            (state: RootState) => state.auth.isAuthenticated
        );
        if (!isAuthenticated) return;

        yield call(cartsApi.clearCart);
        yield put(fetchCartSuccess([]));
    } catch (e: any) {
        console.error("[Cart Clear] Error:", e);
    }
}

export function* userCartSaga(): SagaIterator {
    // Fetch cart when auth is confirmed
    yield takeEvery(setUser.type, onAuthSuccess);

    // Fetch cart on explicit request
    yield takeLatest(fetchCartRequest.type, fetchUserCartWorker);

    // Clear cart on logout
    yield takeLatest(setUnauthenticated.type, onLogout);

    // Map individual actions to workers
    yield takeEvery(addToCart.type, addToCartWorker);
    yield takeEvery(removeFromCart.type, removeFromCartWorker);
    yield takeEvery(updateQuantity.type, updateQuantityWorker);
    yield takeEvery(clearCart.type, clearCartWorker);
}
