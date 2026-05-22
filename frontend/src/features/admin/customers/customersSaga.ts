import { call, put, select, takeEvery, takeLatest } from "redux-saga/effects";
import type { SagaIterator } from "redux-saga";
import { customersApi } from "./customersApi";
import { customersActions } from "./customersSlice";
import type { Customer, UserDto } from "./customersApi";
import type { RootState } from "../../../app/store";
import { setUser } from "../../auth/authSlice";

function mapUserDtoToCustomer(dto: UserDto): Customer {
  const firstName = dto.first_name || "";
  const lastName = dto.last_name || "";
  let name = `${firstName} ${lastName}`.trim();
  if (!name) name = dto.full_name || dto.phone_number || "Unknown";

  return {
    id: String(dto.id),
    name,
    email: dto.email || "",
    phone: dto.phone_number || "",
    role: dto.role,
    status: dto.is_active ? "Active" : "Blocked",
    isEmailVerified: dto.is_email_verified,
    isPhoneVerified: dto.is_phone_verified,
    googleLinked: !!dto.google_id,
    profilePicture: dto.profile?.profile_picture ?? null,
    dateOfBirth: dto.profile?.date_of_birth ?? null,
    gender: dto.profile?.gender ?? null,
    preferredLanguage: dto.profile?.preferred_language ?? "en",
    newsletterSubscribed: dto.profile?.newsletter_subscribed ?? false,
    notificationEnabled: dto.profile?.notification_enabled ?? false,
    lastLoginAt: dto.last_login_at,
    createdAt: dto.created_at,
    updatedAt: dto.updated_at,
    deletedAt: dto.deleted_at,
  };
}

/** Normalize any API shape -> Customer[] */
function normalizeCustomers(payload: any): Customer[] {
  if (Array.isArray(payload?.results)) {
    return payload.results.map(mapUserDtoToCustomer);
  }
  if (Array.isArray(payload)) return payload.map((item: any) => mapUserDtoToCustomer(item));
  if (Array.isArray(payload?.data)) return payload.data.map((item: any) => mapUserDtoToCustomer(item));
  return [];
}

function* fetchCustomersWorker(
  action: ReturnType<typeof customersActions.fetchCustomersRequest>
): SagaIterator {
  try {
    const auth: any = yield select((state: RootState) => (state as any).auth);

    if (auth && auth.isAuthenticated === false) {
      yield put(customersActions.fetchCustomersFailure("User not authenticated"));
      return;
    }

    const raw: any = yield call(customersApi.list, action.payload);
    const totalCount = raw?.count || 0;
    const items = normalizeCustomers(raw);
    const page = action.payload?.page || 1;

    yield put(
      customersActions.fetchCustomersSuccess({
        items,
        totalCount,
        page,
      })
    );
  } catch (e: any) {
    console.error("Fetch Customers Error:", {
      status: e?.response?.status,
      data: e?.response?.data,
      message: e?.message,
    });

    const errMsg =
      e?.response?.data?.detail ||
      e?.response?.data?.message ||
      e?.message ||
      "Failed to fetch customers";

    yield put(customersActions.fetchCustomersFailure(errMsg));
  }
}

function* retryCustomersOnAuth(): SagaIterator {
  const lastQuery: any = yield select(
    (state: RootState) => (state as any).customers?.lastQuery
  );

  yield put(customersActions.fetchCustomersRequest(lastQuery ?? undefined));
}

export function* customersSaga(): SagaIterator {
  yield takeLatest(customersActions.fetchCustomersRequest.type, fetchCustomersWorker);
  yield takeEvery(setUser.type, retryCustomersOnAuth);
}
