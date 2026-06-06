import { createSlice, type PayloadAction } from "@reduxjs/toolkit";
import type {
  AuthMethod,
  AuthStep,
  SendOtpRequest,
  VerifyOtpRequest,
} from "../../types/types";

type User = any; // later you can replace with proper User interface

interface AuthState {
  otp_type: AuthMethod;
  step: AuthStep;
  isLoading: boolean;
  error: string | null;
  phone_number: number | null;
  email: string | null // The email or phone number

  // ✅ session-based auth additions
  user: User | null;
  isAuthenticated: boolean;
  checkingAuth: boolean; // optional: for app load /me check
}

const initialState: AuthState = {
  otp_type: "phone",
  step: "input",
  isLoading: false,
  error: null,
  phone_number: null,
  email: null,

  user: null,
  isAuthenticated: false,
  checkingAuth: true,
};

const authSlice = createSlice({
  name: "auth",
  initialState,
  reducers: {
    /* -------------------------
       UI -> Saga triggers
    -------------------------- */

    requestOtp: (state, action: PayloadAction<SendOtpRequest>) => {
      state.isLoading = true;
      state.error = null;
      state.phone_number = action.payload.phone_number ? Number(action.payload.phone_number) : null;
      state.email = action.payload.email ?? null;
    },

    verifyOtp: (state, _action: PayloadAction<VerifyOtpRequest>) => {
      state.isLoading = true;
      state.error = null;
    },

    /* -------------------------
       State updates from Sagas
    -------------------------- */

    setStep: (state, action: PayloadAction<AuthStep>) => {
      state.step = action.payload;
      state.isLoading = false;
    },

    setMethod: (state, action: PayloadAction<AuthMethod>) => {
      state.otp_type = action.payload;
      state.step = "input";
      state.phone_number = null;
      state.email = null;
      state.error = null;
      state.isLoading = false;
    },

    // ✅ called after verify success + /auth/me success
    setUser: (state, action: PayloadAction<User>) => {
      state.user = action.payload;
      state.isAuthenticated = true;
      state.isLoading = false;
      state.error = null;
    },

    // ✅ optional: app load session check
    checkAuth: (state) => {
      state.checkingAuth = true;
      state.error = null;
    },
    checkAuthDone: (state) => {
      state.checkingAuth = false;
    },
    setUnauthenticated: (state) => {
      state.user = null;
      state.isAuthenticated = false;
      state.isLoading = false;
      state.checkingAuth = false;
      state.step = "input";
      state.phone_number = null;
      state.email = null;
    },

    authError: (state, action: PayloadAction<string>) => {
      state.isLoading = false;
      state.checkingAuth = false;
      state.error = action.payload;
    },

    // ✅ Logout trigger (saga will handle API call + cleanup)
    logout: (state) => {
      state.user = null;
      state.isAuthenticated = false;
      state.isLoading = true;
      state.step = "input";
      state.phone_number = null;
      state.email = null;
    },

    resetAuth: () => initialState,
  },
});

export const {
  requestOtp,
  verifyOtp,
  setStep,
  setMethod,
  setUser,
  checkAuth,
  checkAuthDone,
  setUnauthenticated,
  authError,
  logout,
  resetAuth,
} = authSlice.actions;

export default authSlice.reducer;
