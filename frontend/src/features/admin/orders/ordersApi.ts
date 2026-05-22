import { api } from "../../../services/api";

/* ── Order Item DTO ── */
export interface OrderItemDto {
    id: number;
    product: number;
    product_name: string;
    quantity: number;
    price: string;
    subtotal: string;
}

/* ── Shipping Address DTO ── */
export interface ShippingAddressDto {
    id: string;
    label: string;
    address_type: string;
    is_default: boolean;
    full_name: string;
    phone_number: string;
    building_name: string | null;
    flat_villa_number: string | null;
    street_address: string;
    area: string;
    city: string;
    emirate: string;
    postal_code: string | null;
    country: string;
    latitude: string | null;
    longitude: string | null;
}

/* ── Payment DTO ── */
export interface PaymentDto {
    transaction_id: string;
    amount: string;
    status: string;
    payment_method: string;
    receipt: {
        receipt_number: string;
        generated_at: string;
    } | null;
    created_at: string;
}

/* ── Status History DTO ── */
export interface StatusHistoryDto {
    status: string;
    notes: string;
    created_at: string;
}

/* ── Order DTO from backend ── */
export interface OrderDto {
    id: number;
    status: string;
    shipping_address: string;
    shipping_address_details: ShippingAddressDto;
    total_amount: string;
    preferred_delivery_date: string | null;
    preferred_delivery_slot: string | null;
    delivery_notes: string | null;
    items: OrderItemDto[];
    status_history: StatusHistoryDto[];
    payment: PaymentDto | null;
    created_at: string;
    updated_at: string;
}

export type OrdersQuery = {
    q?: string;
    status?: string;
    payment_status?: string;
    page?: number;
    limit?: number;
    offset?: number;
};

export const ordersApi = {
    list: async (
        params?: OrdersQuery
    ): Promise<{ results: OrderDto[]; count: number }> => {
        const res = await api.get<{ results: OrderDto[]; count: number }>(
            "/orders/",
            { params }
        );
        return res.data;
    },

    details: async (id: number): Promise<OrderDto> => {
        const res = await api.get<OrderDto>(`/orders/${id}/`);
        return res.data;
    },

    updateStatus: async (
        id: number,
        status: string
    ): Promise<OrderDto> => {
        const res = await api.patch<OrderDto>(`/orders/${id}/`, { status });
        return res.data;
    },

    delete: async (id: number): Promise<void> => {
        await api.delete(`/orders/${id}/`);
    },

    create: async (data: any): Promise<OrderDto> => {
        const res = await api.post<OrderDto>("/orders/", data);
        return res.data;
    },
};
