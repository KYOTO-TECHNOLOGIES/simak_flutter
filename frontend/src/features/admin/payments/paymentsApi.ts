import { api } from "../../../services/api";

/* ── Payment DTO ── 
 * There is no dedicated /payments/ endpoint on the backend.
 * Payment data is derived from orders. We query /orders/ and
 * extract payment-related fields. If a dedicated payments
 * endpoint is added in the future, update the URLs here.
 */

export interface PaymentDto {
    id: number;
    order_number: string;
    user: number;
    user_name?: string;
    user_email?: string;
    user_phone?: string;
    payment_status: string;
    payment_method: string;
    total: string;
    status: string; // order status
    created_at: string;
    updated_at: string;
}

export type PaymentsQuery = {
    q?: string;
    payment_status?: string;
    payment_method?: string;
    page?: number;
    limit?: number;
    offset?: number;
};

export const paymentsApi = {
    /**
     * List payments (backed by /orders/ endpoint).
     * Each order contains payment_status, payment_method, total.
     */
    list: async (
        params?: PaymentsQuery
    ): Promise<{ results: PaymentDto[]; count: number }> => {
        const res = await api.get<{ results: PaymentDto[]; count: number }>(
            "/orders/",
            { params }
        );
        return res.data;
    },

    details: async (id: number): Promise<PaymentDto> => {
        const res = await api.get<PaymentDto>(`/orders/${id}/`);
        return res.data;
    },
};
