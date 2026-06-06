import { call, put, takeLatest } from "redux-saga/effects";
import { authApi } from "./authApi";
import { tokenManager } from "../../services/api";
import {
  requestOtp,
  verifyOtp,
  setStep,
  authError,
  setUser,
  checkAuth,
  checkAuthDone,
  setUnauthenticated,
  logout,
} from "./authSlice";

const getErrMsg = (err: any, fallback: string) =>
  err?.response?.data?.message ||
  err?.response?.data?.error ||
  err?.message ||
  fallback;

function* handleSendOtp(action: ReturnType<typeof requestOtp>) {
  try {
    // Build clean payload without undefined fields
    const payload: any = { otp_type: action.payload.otp_type };
    if (action.payload.phone_number) payload.phone_number = action.payload.phone_number;
    if (action.payload.email) payload.email = action.payload.email;

    yield call(authApi.sendOtp, payload);
    yield put(setStep("otp"));
  } catch (err: any) {
    yield put(authError(getErrMsg(err, "Failed to send OTP")));
  }
}

function* handleVerifyOtp(action: ReturnType<typeof verifyOtp>) {
  try {
    // Build clean payload without undefined fields
    const payload: any = { otp_type: action.payload.otp_type, otp_code: action.payload.otp_code };
    if (action.payload.phone_number) payload.phone_number = action.payload.phone_number;
    if (action.payload.email) payload.email = action.payload.email;

    // ✅ verifies OTP & server returns access token + sets session cookie
    const verifyRes: { data: any } = yield call(authApi.verifyOtp, payload);

    // ✅ Extract access token from response and store it
    const accessToken = verifyRes.data?.access || verifyRes.data?.accessToken || verifyRes.data?.token;
    if (accessToken) {
      tokenManager.set(accessToken);
    }

    // ✅ fetch user data (now with token attached via interceptor)
    const res: { data: any } = yield call(authApi.me);

    // Adjust based on your backend response shape:
    // - if res.data = { user: {...} } use res.data.user
    // - if res.data = {...user} use res.data
    const user = res.data?.user ?? res.data;

    // ✅ store in redux (UI/guard will redirect)
    yield put(setUser(user));
  } catch (err: any) {
    yield put(authError(getErrMsg(err, "Invalid OTP")));
  }
}

function* handleCheckAuth() {
  try {
    // ✅ Check if we even have a token locally before calling API
    // This prevents 401 -> Refresh -> 500 loop for guests
    const hasToken = tokenManager.get();
    if (!hasToken) {
      yield put(setUnauthenticated());
      yield put(checkAuthDone());
      return;
    }

    // ✅ Call /users/me to restore session on page load/refresh
    const res: { data: any } = yield call(authApi.me);
    const user = res.data?.user ?? res.data;
    yield put(setUser(user));
  } catch (err: any) {
    // No valid session, clear auth state
    yield put(setUnauthenticated());
  } finally {
    yield put(checkAuthDone());
  }
}

function* handleLogout() {
  try {
    // ✅ Call backend to clear the refresh cookie
    yield call(authApi.logout);
  } catch (_err) {
    // Even if the API fails, we still clear the local state
  } finally {
    // ✅ Clear in-memory access token
    tokenManager.clear();
    // ✅ Clear Redux auth state (keeps checkingAuth=false so routes render)
    yield put(setUnauthenticated());
  }
}

export function* authSaga() {
  yield takeLatest(requestOtp.type, handleSendOtp);
  yield takeLatest(verifyOtp.type, handleVerifyOtp);
  yield takeLatest(checkAuth.type, handleCheckAuth);
  yield takeLatest(logout.type, handleLogout);
}
