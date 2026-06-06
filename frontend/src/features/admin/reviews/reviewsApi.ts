import { api } from "../../../services/api";

/* ── Review DTO from backend ── */
export interface ReviewDto {
    id: number;
    product: number;
    product_name?: string;
    user: number;
    user_name?: string;
    rating: number;
    title: string;
    comment: string;
    is_approved: boolean;
    created_at: string;
    updated_at: string;
}

export type ReviewsQuery = {
    q?: string;
    rating?: number;
    is_approved?: boolean;
    page?: number;
    limit?: number;
    offset?: number;
};

export const reviewsApi = {
    list: async (
        params?: ReviewsQuery
    ): Promise<{ results: ReviewDto[]; count: number }> => {
        const res = await api.get<{ results: ReviewDto[]; count: number }>(
            "/reviews/",
            { params }
        );
        return res.data;
    },

    details: async (id: number): Promise<ReviewDto> => {
        const res = await api.get<ReviewDto>(`/reviews/${id}/`);
        return res.data;
    },

    approve: async (id: number): Promise<ReviewDto> => {
        const res = await api.patch<ReviewDto>(`/reviews/${id}/`, {
            is_approved: true,
        });
        return res.data;
    },

    reject: async (id: number): Promise<ReviewDto> => {
        const res = await api.patch<ReviewDto>(`/reviews/${id}/`, {
            is_approved: false,
        });
        return res.data;
    },

    delete: async (id: number): Promise<void> => {
        await api.delete(`/reviews/${id}/`);
    },
};
