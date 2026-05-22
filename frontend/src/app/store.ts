import { configureStore } from "@reduxjs/toolkit";
import createSagaMiddleware from "redux-saga";
import catalogReducer from "../features/shop/catalog/catalogSlice";
import { cartReducer } from "../features/admin/cart/cartSlice";
import customersReducer from "../features/admin/customers/customersSlice";
import productsReducer from "../features/admin/products/productsSlice";
import reviewsReducer from "../features/admin/reviews/reviewsSlice";
import ordersReducer from "../features/admin/orders/ordersSlice";
import adminCartsReducer from "../features/admin/cart/cartSlice";
import paymentsReducer from "../features/admin/payments/paymentsSlice";
import settingsReducer from "../features/admin/settings/settingsSlice";
import authReducer from "../features/auth/authSlice";
import { rootSaga } from "../store/sagas/rootSaga";

const sagaMiddleware = createSagaMiddleware();

export const store = configureStore({
  reducer: {
    catalog: catalogReducer,
    cart: cartReducer,
    customers: customersReducer,
    products: productsReducer,
    reviews: reviewsReducer,
    orders: ordersReducer,
    adminCarts: adminCartsReducer,
    payments: paymentsReducer,
    settings: settingsReducer,
    auth: authReducer,
  },
  middleware: (getDefault) =>
    getDefault({ thunk: false, serializableCheck: false }).concat(sagaMiddleware),
});

sagaMiddleware.run(rootSaga);

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
