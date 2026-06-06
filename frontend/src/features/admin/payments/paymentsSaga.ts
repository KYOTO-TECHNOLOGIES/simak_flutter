import { call, put, select, takeLatest } from "redux-saga/effects";
import type { SagaIterator } from "redux-saga";
import { paymentsApi } from "./paymentsApi";
import { paymentsActions } from "./paymentsSlice";
import type { Payment, PaymentStatus, PaymentMethod } from "./paymentsSlice";
import type { PaymentDto } from "./paymentsApi";
import type { RootState } from "../../../app/store";

/* ── Normalize payment status ── */
function normalizePaymentStatus(raw?: string): PaymentStatus {
    if (!raw) return "Pending";
    const map: Record<string, PaymentStatus> = {
        paid: "Success",
        success: "Success",
        completed: "Success",
        failed: "Failed",
        pending: "Pending",
        refunded: "Refunded",
    };
    return map[raw.toLowerCase()] ?? "Pending";
}

function normalizePaymentMethod(raw?: string): PaymentMethod {
    if (!raw) return "N/A";
    const map: Record<string, PaymentMethod> = {
        upi: "UPI",
        card: "Card",
        credit_card: "Card",
        debit_card: "Card",
        netbanking: "NetBanking",
        net_banking: "NetBanking",
        nb: "NetBanking",
        wallet: "Wallet",
        cod: "COD",
        cash_on_delivery: "COD",
    };
    return map[raw.toLowerCase()] ?? "N/A";
}

/* ── Map DTO → Payment ── */
function mapPaymentDto(dto: PaymentDto): Payment {
    return {
        id: dto.id,
        paymentId: `PAY-${dto.id}`,
        orderNumber: dto.order_number ?? `ORD-${dto.id}`,
        customerId: dto.user,
        customerName: dto.user_name ?? `User #${dto.user}`,
        customerEmail: dto.user_email ?? "",
        customerPhone: dto.user_phone ?? "",
        amount: parseFloat(dto.total) || 0,
        paymentStatus: normalizePaymentStatus(dto.payment_status),
        paymentMethod: normalizePaymentMethod(dto.payment_method),
        orderStatus: dto.status ?? "",
        date: dto.created_at,
        updatedAt: dto.updated_at,
    };
}

function normalizePayments(payload: any): Payment[] {
    if (Array.isArray(payload?.results))
        return payload.results.map(mapPaymentDto);
    if (Array.isArray(payload)) return payload.map(mapPaymentDto);
    if (Array.isArray(payload?.data))
        return payload.data.map(mapPaymentDto);
    return [];
}

function* fetchPaymentsWorker(
    action: ReturnType<typeof paymentsActions.fetchPaymentsRequest>
): SagaIterator {
    try {
        const auth: any = yield select((state: RootState) => (state as any).auth);
        if (auth && auth.isAuthenticated === false) {
            yield put(paymentsActions.fetchPaymentsFailure("User not authenticated"));
            return;
        }

        const raw: any = yield call(paymentsApi.list, action.payload);
        const totalCount = raw?.count || 0;
        const items = normalizePayments(raw);
        const page = action.payload?.page || 1;

        yield put(
            paymentsActions.fetchPaymentsSuccess({
                items,
                totalCount,
                page,
            })
        );
    } catch (e: any) {
        console.error("Fetch Payments Error:", {
            status: e?.response?.status,
            data: e?.response?.data,
            message: e?.message,
        });

        const errMsg =
            e?.response?.data?.detail ||
            e?.response?.data?.message ||
            e?.message ||
            "Failed to fetch payments";

        yield put(paymentsActions.fetchPaymentsFailure(errMsg));
    }
}

export function* paymentsSaga(): SagaIterator {
    yield takeLatest(
        paymentsActions.fetchPaymentsRequest.type,
        fetchPaymentsWorker
    );
}
