export type AuthMethod = "phone" | "email";
export type AuthStep = "input" | "otp";

export interface SendOtpRequest {
  otp_type: AuthMethod;
  phone_number?: string | number;
  email?: string;
}

export interface VerifyOtpRequest {
  otp_type: AuthMethod;
  phone_number?: string | number;
  email?: string;
  otp_code: string;
  name?: string;
  // If your backend uses a session ID instead of just cookies
  otpSessionId?: string;
}