import { api } from "../../../services/api";

/*
 * Settings API
 *
 * There is no dedicated /settings/ endpoint on the backend yet.
 * This file provides a placeholder for future backend integration.
 * Currently settings are managed locally in Redux state.
 * When a backend endpoint is added, update the URLs here.
 */

export interface StoreProfileDto {
    id?: number;
    store_name: string;
    store_email: string;
    store_phone: string;
    store_address: string;
    store_logo?: string;
    currency: string;
    timezone: string;
}

export interface DeliverySlotDto {
    id?: number;
    name: string;
    start_time: string;
    end_time: string;
    cutoff_time: string;
    capacity: number;
    is_active: boolean;
}

export interface ServiceAreaDto {
    id?: number;
    pincode: string;
    zone: string;
    delivery_fee: string;
    min_order: string;
    cod_available: boolean;
}

export interface SettingsPayload {
    store_profile?: StoreProfileDto;
    delivery_slots?: DeliverySlotDto[];
    service_areas?: ServiceAreaDto[];
    operational_days?: string[];
    payment_gateway_connected?: boolean;
    cod_min?: string;
    cod_max?: string;
    return_window_hours?: number;
    photo_proof_required?: boolean;
    returns_enabled?: boolean;
}

export const settingsApi = {
    /** Fetch all settings (placeholder - returns null until backend exists) */
    fetch: async (): Promise<SettingsPayload | null> => {
        try {
            const res = await api.get<SettingsPayload>("/settings/");
            return res.data;
        } catch {
            // No backend endpoint yet — return null
            return null;
        }
    },

    /** Save settings (placeholder) */
    save: async (payload: SettingsPayload): Promise<SettingsPayload> => {
        try {
            const res = await api.put<SettingsPayload>("/settings/", payload);
            return res.data;
        } catch {
            // Simulate save success for local-only state
            return payload;
        }
    },
};
