import { api } from "../../services/api"
import type { SendOtpRequest, VerifyOtpRequest } from "../../types/types";

export const authApi = {
  sendOtp: (data: SendOtpRequest) =>
    api.post("/auth/otp/request/", data),

  verifyOtp: (data: VerifyOtpRequest) =>
    api.post("/auth/otp/login/", data),

  me: () => api.get("/users/me/"),

  logout: () => api.post("/auth/logout/"),
};