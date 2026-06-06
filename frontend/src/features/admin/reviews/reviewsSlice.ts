import { createSlice } from "@reduxjs/toolkit";
import type { PayloadAction } from "@reduxjs/toolkit";
import type { RootState } from "../../../app/store";
import type { ReviewsQuery } from "./reviewsApi";

type Status = "idle" | "loading" | "succeeded" | "failed";

export type ReviewStatus = "Approved" | "Pending" | "Rejected";

export interface Review {
    id: number;
    productId: number;
    productName: string;
    userId: number;
    userName: string;
    rating: number;
    title: string;
    comment: string;
    status: ReviewStatus;
    createdAt: string;
    updatedAt: string;
}

interface ReviewsState {
    items: Review[];
    totalCount: number;
    currentPage: number;
    status: Status;
    error: string | null;
    selectedId: number | null;
    lastQuery: ReviewsQuery | null;
}

const initialState: ReviewsState = {
    items: [],
    totalCount: 0,
    currentPage: 1,
    status: "idle",
    error: null,
    selectedId: null,
    lastQuery: null,
};

const reviewsSlice = createSlice({
    name: "reviews",
    initialState,
    reducers: {
        fetchReviewsRequest: (
            state,
            action: PayloadAction<ReviewsQuery | undefined>
        ) => {
            state.status = "loading";
            state.error = null;
            state.lastQuery = action.payload ?? null;
        },
        fetchReviewsSuccess: (
            state,
            action: PayloadAction<{
                items: Review[];
                totalCount: number;
                page: number;
            }>
        ) => {
            state.status = "succeeded";
            state.items = action.payload.items;
            state.totalCount = action.payload.totalCount;
            state.currentPage = action.payload.page;
        },
        fetchReviewsFailure: (state, action: PayloadAction<string>) => {
            state.status = "failed";
            state.error = action.payload;
        },
        setSelectedReviewId: (state, action: PayloadAction<number | null>) => {
            state.selectedId = action.payload;
        },
    },
});

export const reviewsActions = reviewsSlice.actions;
export default reviewsSlice.reducer;

// Selectors
export const selectReviews = (s: RootState) => s.reviews.items;
export const selectReviewsTotal = (s: RootState) => s.reviews.totalCount;
export const selectReviewsPage = (s: RootState) => s.reviews.currentPage;
export const selectReviewsStatus = (s: RootState) => s.reviews.status;
export const selectReviewsError = (s: RootState) => s.reviews.error;
export const selectSelectedReviewId = (s: RootState) => s.reviews.selectedId;
