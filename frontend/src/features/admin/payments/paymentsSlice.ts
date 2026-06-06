import { createSlice } from "@reduxjs/toolkit";
import type { PayloadAction } from "@reduxjs/toolkit";
import type { RootState } from "../../../app/store";
import type { PaymentsQuery } from "./paymentsApi";

type Status = "idle" | "loading" | "succeeded" | "failed";

export type PaymentStatus = "Success" | "Failed" | "Pending" | "Refunded";
export type PaymentMethod = "UPI" | "Card" | "NetBanking" | "Wallet" | "COD" | "N/A";

export interface Payment {
    id: number;
    paymentId: string; // display ID like "PAY-1234"
    orderNumber: string;
    customerId: number;
    customerName: string;
    customerEmail: string;
    customerPhone: string;
    amount: number;
    paymentStatus: PaymentStatus;
    paymentMethod: PaymentMethod;
    orderStatus: string;
    date: string;
    updatedAt: string;
}

interface PaymentsState {
    items: Payment[];
    totalCount: number;
    currentPage: number;
    status: Status;
    error: string | null;
    selectedId: number | null;
    lastQuery: PaymentsQuery | null;
}

const initialState: PaymentsState = {
    items: [],
    totalCount: 0,
    currentPage: 1,
    status: "idle",
    error: null,
    selectedId: null,
    lastQuery: null,
};

const paymentsSlice = createSlice({
    name: "payments",
    initialState,
    reducers: {
        fetchPaymentsRequest: (
            state,
            action: PayloadAction<PaymentsQuery | undefined>
        ) => {
            state.status = "loading";
            state.error = null;
            state.lastQuery = action.payload ?? null;
        },
        fetchPaymentsSuccess: (
            state,
            action: PayloadAction<{
                items: Payment[];
                totalCount: number;
                page: number;
            }>
        ) => {
            state.status = "succeeded";
            state.items = action.payload.items;
            state.totalCount = action.payload.totalCount;
            state.currentPage = action.payload.page;
        },
        fetchPaymentsFailure: (state, action: PayloadAction<string>) => {
            state.status = "failed";
            state.error = action.payload;
        },
        setSelectedPaymentId: (state, action: PayloadAction<number | null>) => {
            state.selectedId = action.payload;
        },
    },
});

export const paymentsActions = paymentsSlice.actions;
export default paymentsSlice.reducer;

// Selectors
export const selectPayments = (s: RootState) => s.payments.items;
export const selectPaymentsTotal = (s: RootState) => s.payments.totalCount;
export const selectPaymentsPage = (s: RootState) => s.payments.currentPage;
export const selectPaymentsStatus = (s: RootState) => s.payments.status;
export const selectPaymentsError = (s: RootState) => s.payments.error;
export const selectSelectedPaymentId = (s: RootState) => s.payments.selectedId;
