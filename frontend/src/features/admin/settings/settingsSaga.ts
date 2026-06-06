import { call, put, select, takeLatest } from "redux-saga/effects";
import type { SagaIterator } from "redux-saga";
import { settingsApi } from "./settingsApi";
import { settingsActions } from "./settingsSlice";
import type { RootState } from "../../../app/store";

/*
 * Settings Saga
 *
 * Handles fetching and saving settings.
 * Currently the backend has no /settings/ endpoint, so the API
 * layer gracefully returns defaults. When the backend is ready,
 * the saga will transparently work.
 */

function* fetchSettingsWorker(): SagaIterator {
    try {
        const raw: any = yield call(settingsApi.fetch);

        if (raw) {
            // Map DTO → slice state (when backend is ready)
            yield put(
                settingsActions.fetchSettingsSuccess({
                    storeProfile: raw.store_profile
                        ? {
                            storeName: raw.store_profile.store_name ?? "",
                            storeEmail: raw.store_profile.store_email ?? "",
                            storePhone: raw.store_profile.store_phone ?? "",
                            storeAddress: raw.store_profile.store_address ?? "",
                            storeLogo: raw.store_profile.store_logo ?? "",
                            currency: raw.store_profile.currency ?? "AED",
                            timezone: raw.store_profile.timezone ?? "Asia/Kolkata",
                        }
                        : undefined,
                    operationalDays: raw.operational_days,
                    returnsEnabled: raw.returns_enabled,
                    returnWindowHours: raw.return_window_hours,
                    photoProofRequired: raw.photo_proof_required,
                    codMin: raw.cod_min,
                    codMax: raw.cod_max,
                    paymentGatewayConnected: raw.payment_gateway_connected,
                })
            );
        } else {
            // No backend — keep default state
            yield put(settingsActions.fetchSettingsSuccess({}));
        }
    } catch (e: any) {
        console.error("Settings fetch error:", e?.message);
        yield put(
            settingsActions.fetchSettingsFailure(e?.message || "Failed to fetch settings")
        );
    }
}

function* saveSettingsWorker(): SagaIterator {
    try {
        const state: RootState = yield select();
        const settings = state.settings;

        yield call(settingsApi.save, {
            store_profile: {
                store_name: settings.storeProfile.storeName,
                store_email: settings.storeProfile.storeEmail,
                store_phone: settings.storeProfile.storePhone,
                store_address: settings.storeProfile.storeAddress,
                store_logo: settings.storeProfile.storeLogo,
                currency: settings.storeProfile.currency,
                timezone: settings.storeProfile.timezone,
            },
            operational_days: settings.operationalDays,
            returns_enabled: settings.returnsEnabled,
            return_window_hours: settings.returnWindowHours,
            photo_proof_required: settings.photoProofRequired,
            cod_min: settings.codMin,
            cod_max: settings.codMax,
            payment_gateway_connected: settings.paymentGatewayConnected,
        });

        yield put(settingsActions.saveSettingsSuccess());
    } catch (e: any) {
        console.error("Settings save error:", e?.message);
        yield put(
            settingsActions.saveSettingsFailure(e?.message || "Failed to save settings")
        );
    }
}

export function* settingsSaga(): SagaIterator {
    yield takeLatest(
        settingsActions.fetchSettingsRequest.type,
        fetchSettingsWorker
    );
    yield takeLatest(
        settingsActions.saveSettingsRequest.type,
        saveSettingsWorker
    );
}
