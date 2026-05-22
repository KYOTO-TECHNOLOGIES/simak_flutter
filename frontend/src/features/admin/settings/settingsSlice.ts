import { createSlice } from "@reduxjs/toolkit";
import type { PayloadAction } from "@reduxjs/toolkit";
import type { RootState } from "../../../app/store";

type Status = "idle" | "loading" | "saving" | "succeeded" | "failed";

export type SettingSection =
    | "profile"
    | "hours"
    | "service"
    | "payments"
    | "delivery"
    | "tax"
    | "orders"
    | "returns"
    | "notifications"
    | "users"
    | "security"
    | "seo";

export interface DeliverySlot {
    id: number;
    name: string;
    startTime: string;
    endTime: string;
    cutoffTime: string;
    capacity: number;
    isActive: boolean;
}

export interface ServiceArea {
    id: number;
    pincode: string;
    zone: string;
    deliveryFee: string;
    minOrder: string;
    codAvailable: boolean;
}

export interface StoreProfile {
    storeName: string;
    storeEmail: string;
    storePhone: string;
    storeAddress: string;
    storeLogo: string;
    currency: string;
    timezone: string;
}

export interface SettingsState {
    status: Status;
    error: string | null;
    activeSection: SettingSection;
    isDirty: boolean;

    // Data
    storeProfile: StoreProfile;
    operationalDays: string[];
    deliverySlots: DeliverySlot[];
    serviceAreas: ServiceArea[];
    paymentGatewayConnected: boolean;
    codMin: string;
    codMax: string;
    returnWindowHours: number;
    photoProofRequired: boolean;
    returnsEnabled: boolean;
}

const initialState: SettingsState = {
    status: "idle",
    error: null,
    activeSection: "hours",
    isDirty: false,

    storeProfile: {
        storeName: "FreshCatch Seafood",
        storeEmail: "admin@freshcatch.in",
        storePhone: "+91 98200 XXXXX",
        storeAddress: "Mumbai, Maharashtra",
        storeLogo: "",
        currency: "AED",
        timezone: "Asia/Kolkata",
    },
    operationalDays: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
    deliverySlots: [
        { id: 1, name: "Early Morning", startTime: "06:00 AM", endTime: "09:00 AM", cutoffTime: "09:00 PM (Previous Day)", capacity: 40, isActive: true },
        { id: 2, name: "Lunch Rush", startTime: "11:00 AM", endTime: "01:00 PM", cutoffTime: "08:00 AM", capacity: 25, isActive: true },
        { id: 3, name: "Evening", startTime: "05:00 PM", endTime: "08:00 PM", cutoffTime: "02:00 PM", capacity: 50, isActive: true },
    ],
    serviceAreas: [
        { id: 1, pincode: "560001", zone: "Central BLR", deliveryFee: "AED 49", minOrder: "AED 499", codAvailable: true },
        { id: 2, pincode: "560067", zone: "Whitefield", deliveryFee: "AED 99", minOrder: "AED 999", codAvailable: false },
    ],
    paymentGatewayConnected: true,
    codMin: "300",
    codMax: "5000",
    returnWindowHours: 4,
    photoProofRequired: true,
    returnsEnabled: true,
};

const settingsSlice = createSlice({
    name: "settings",
    initialState,
    reducers: {
        /* ── Navigation ── */
        setActiveSection: (state, action: PayloadAction<SettingSection>) => {
            state.activeSection = action.payload;
        },

        /* ── Fetch ── */
        fetchSettingsRequest: (state) => {
            state.status = "loading";
            state.error = null;
        },
        fetchSettingsSuccess: (state, action: PayloadAction<Partial<SettingsState>>) => {
            state.status = "succeeded";
            Object.assign(state, action.payload);
            state.isDirty = false;
        },
        fetchSettingsFailure: (state, action: PayloadAction<string>) => {
            state.status = "failed";
            state.error = action.payload;
        },

        /* ── Save ── */
        saveSettingsRequest: (state) => {
            state.status = "saving";
            state.error = null;
        },
        saveSettingsSuccess: (state) => {
            state.status = "succeeded";
            state.isDirty = false;
        },
        saveSettingsFailure: (state, action: PayloadAction<string>) => {
            state.status = "failed";
            state.error = action.payload;
        },

        /* ── Field Updates ── */
        updateStoreProfile: (state, action: PayloadAction<Partial<StoreProfile>>) => {
            Object.assign(state.storeProfile, action.payload);
            state.isDirty = true;
        },
        setOperationalDays: (state, action: PayloadAction<string[]>) => {
            state.operationalDays = action.payload;
            state.isDirty = true;
        },
        toggleOperationalDay: (state, action: PayloadAction<string>) => {
            const day = action.payload;
            if (state.operationalDays.includes(day)) {
                state.operationalDays = state.operationalDays.filter((d) => d !== day);
            } else {
                state.operationalDays.push(day);
            }
            state.isDirty = true;
        },
        updateDeliverySlot: (state, action: PayloadAction<DeliverySlot>) => {
            const idx = state.deliverySlots.findIndex((s) => s.id === action.payload.id);
            if (idx >= 0) state.deliverySlots[idx] = action.payload;
            state.isDirty = true;
        },
        addDeliverySlot: (state, action: PayloadAction<DeliverySlot>) => {
            state.deliverySlots.push(action.payload);
            state.isDirty = true;
        },
        removeDeliverySlot: (state, action: PayloadAction<number>) => {
            state.deliverySlots = state.deliverySlots.filter((s) => s.id !== action.payload);
            state.isDirty = true;
        },
        updateServiceArea: (state, action: PayloadAction<ServiceArea>) => {
            const idx = state.serviceAreas.findIndex((a) => a.id === action.payload.id);
            if (idx >= 0) state.serviceAreas[idx] = action.payload;
            state.isDirty = true;
        },
        setCodThresholds: (state, action: PayloadAction<{ min: string; max: string }>) => {
            state.codMin = action.payload.min;
            state.codMax = action.payload.max;
            state.isDirty = true;
        },
        setReturnsConfig: (state, action: PayloadAction<{ enabled?: boolean; windowHours?: number; photoProof?: boolean }>) => {
            if (action.payload.enabled !== undefined) state.returnsEnabled = action.payload.enabled;
            if (action.payload.windowHours !== undefined) state.returnWindowHours = action.payload.windowHours;
            if (action.payload.photoProof !== undefined) state.photoProofRequired = action.payload.photoProof;
            state.isDirty = true;
        },

        /* ── Discard ── */
        discardChanges: () => initialState,
    },
});

export const settingsActions = settingsSlice.actions;
export default settingsSlice.reducer;

// Selectors
export const selectSettingsStatus = (s: RootState) => s.settings.status;
export const selectSettingsError = (s: RootState) => s.settings.error;
export const selectActiveSection = (s: RootState) => s.settings.activeSection;
export const selectIsDirty = (s: RootState) => s.settings.isDirty;
export const selectStoreProfile = (s: RootState) => s.settings.storeProfile;
export const selectOperationalDays = (s: RootState) => s.settings.operationalDays;
export const selectDeliverySlots = (s: RootState) => s.settings.deliverySlots;
export const selectServiceAreas = (s: RootState) => s.settings.serviceAreas;
export const selectPaymentGatewayConnected = (s: RootState) => s.settings.paymentGatewayConnected;
export const selectCodThresholds = (s: RootState) => ({ min: s.settings.codMin, max: s.settings.codMax });
export const selectReturnsConfig = (s: RootState) => ({
    enabled: s.settings.returnsEnabled,
    windowHours: s.settings.returnWindowHours,
    photoProof: s.settings.photoProofRequired,
});
