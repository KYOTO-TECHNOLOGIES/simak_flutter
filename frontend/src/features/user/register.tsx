import React, { useEffect, useMemo, useRef, useState } from "react";
import {
  Shield,
  ArrowRight,
  Loader2,
  Check,
  Phone,
  Mail,
  RefreshCcw,
  User,
  ChevronDown,
} from "lucide-react";
import { useDispatch, useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";

import type { AuthMethod } from "../../types/types";
import { requestOtp, verifyOtp, setMethod, setStep } from "../auth/authSlice"; // adjust path if needed

// If you have RootState type, replace `any` with RootState
const RegisterWithOtp: React.FC = () => {
  const dispatch = useDispatch();
  const navigate = useNavigate();

  const { otp_type, step, isLoading, error, value, isAuthenticated, user } = useSelector(
    (s: any) => s.auth
  );

  const [localValue, setLocalValue] = useState(value || "");
  const [otp, setOtp] = useState("");
  const [agreeTerms, setAgreeTerms] = useState(false);
  const [name, setName] = useState("");
  const [nameTouched, setNameTouched] = useState(false);
  const [countryCode, setCountryCode] = useState("+91");
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  const countries = [
    { code: "+91", flag: "🇮🇳", name: "India" },
    { code: "+971", flag: "🇦🇪", name: "UAE" },
    { code: "+86", flag: "🇨🇳", name: "China" },
  ];

  const selectedCountry = countries.find((c) => c.code === countryCode) || countries[0];

  // Close dropdown on outside click
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setDropdownOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  // Keep input synced with store value (when saga stores it)
  useEffect(() => {
    setLocalValue(value || "");
  }, [value]);

  // Redirect after successful verify — role-based navigation
  useEffect(() => {
    if (!isAuthenticated || !user) return;

    const isAdmin = user.role === "admin" || user.is_admin === true;
    navigate(isAdmin ? "/admin/dashboard" : "/", { replace: true });
  }, [isAuthenticated, user, navigate]);

  const isPhoneValid = useMemo(() => {
    const digits = localValue.replace(/\D/g, "");
    return digits.length >= 10;
  }, [localValue]);

  const isEmailValid = useMemo(() => {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(localValue.trim());
  }, [localValue]);

  const isNameValid = useMemo(() => {
    const trimmed = name.trim();
    return trimmed.length >= 2 && /^[a-zA-Z\s]+$/.test(trimmed);
  }, [name]);

  const canSendOtp =
    !isLoading &&
    agreeTerms &&
    isNameValid &&
    (otp_type === "phone" ? isPhoneValid : isEmailValid);

  const canVerifyOtp = !isLoading && otp.trim().length === 6;

  const onChangeMethod = (m: AuthMethod) => {
    setOtp("");
    setAgreeTerms(false);
    setLocalValue("");
    setName("");
    setNameTouched(false);
    setCountryCode("+91");
    dispatch(setMethod(m));
  };

  const onSendOtp = (e: React.FormEvent) => {
    e.preventDefault();
    if (!canSendOtp) return;

    const phoneWithCode = otp_type === "phone" ? `${countryCode}${localValue.trim().replace(/^0+/, '')}` : undefined;
    dispatch(
      requestOtp({
        otp_type: otp_type,
        phone_number: phoneWithCode,
        email: otp_type === "email" ? localValue.trim() : undefined,
      })
    );
  };

  const onVerifyOtp = (e: React.FormEvent) => {
    e.preventDefault();
    if (!canVerifyOtp) return;

    dispatch(
      verifyOtp({
        otp_type: otp_type,
        phone_number: otp_type === "phone" ? (value || localValue.trim()) : undefined,
        email: otp_type === "email" ? (value || localValue.trim()) : undefined,
        otp_code: otp.trim(),
        name: name.trim(),
      })
    );
  };

  const onChangeNumberOrEmail = () => {
    setOtp("");
    dispatch(setStep("input"));
  };

  const onResend = () => {
    if (isLoading) return;
    // resend uses the same requestOtp
    dispatch(
      requestOtp({
        otp_type: otp_type,
        phone_number: otp_type === "phone" ? (value || localValue.trim()) : undefined,
        email: otp_type === "email" ? (value || localValue.trim()) : undefined,
      })
    );
  };

  return (
    <div className="min-h-screen bg-white text-black antialiased flex items-center justify-center px-5 py-10">
      <div className="w-full max-w-105">
        {/* Brand line */}
        <div className="flex items-center gap-2 text-[11px] font-semibold tracking-[0.22em] uppercase text-gray-500">
          <Shield size={16} strokeWidth={2.6} className="text-rose-600" />
          Protocol
        </div>

        {/* Card */}
        <div className="mt-4 rounded-2xl border border-gray-100 shadow-[0_10px_30px_rgba(0,0,0,0.06)] bg-white">
          <div className="px-6 pt-7 pb-6">
            <h1 className="text-[26px] leading-tight font-semibold tracking-tight">
              Create account
            </h1>
            <p className="mt-2 text-sm text-gray-500">
              Register using OTP. No password needed.
            </p>

            {/* Tabs */}
            <div className="mt-6 grid grid-cols-2 gap-2 rounded-2xl bg-gray-50 p-1">
              <button
                type="button"
                onClick={() => onChangeMethod("phone")}
                className={`h-10 rounded-xl text-[11px] font-semibold uppercase tracking-[0.18em] transition ${otp_type === "phone" ? "bg-white shadow-sm text-rose-600" : "text-gray-500 hover:text-rose-600"
                  }`}
              >
                <span className="inline-flex items-center gap-2 justify-center">
                  <Phone size={14} /> Phone
                </span>
              </button>

              <button
                type="button"
                onClick={() => onChangeMethod("email")}
                className={`h-10 rounded-xl text-[11px] font-semibold uppercase tracking-[0.18em] transition ${otp_type === "email" ? "bg-white shadow-sm text-rose-600" : "text-gray-500 hover:text-rose-600"
                  }`}
              >
                <span className="inline-flex items-center gap-2 justify-center">
                  <Mail size={14} /> Email
                </span>
              </button>
            </div>

            {/* Step: Input */}
            {step === "input" && (
              <form onSubmit={onSendOtp} className="mt-6 space-y-5">
                <Field label="Full Name">
                  <div className="relative">
                    <User size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                    <input
                      type="text"
                      required
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      onBlur={() => setNameTouched(true)}
                      placeholder="John Doe"
                      className={`w-full h-11 rounded-xl border bg-white pl-9 pr-3 text-sm outline-none transition
                                 focus:border-rose-600 focus:ring-4 focus:ring-rose-500/10 placeholder:text-gray-300
                                 ${nameTouched && !isNameValid ? "border-red-400" : "border-gray-200"}`}
                    />
                  </div>
                  {nameTouched && !isNameValid && (
                    <p className="text-[11px] text-red-500 mt-1">
                      {name.trim().length < 2
                        ? "Name must be at least 2 characters."
                        : "Name can only contain letters and spaces."}
                    </p>
                  )}
                </Field>

                <Field label={otp_type === "phone" ? "Phone number" : "Email"}>
                  {otp_type === "phone" ? (
                    <div className="flex gap-2">
                      {/* Flag Dropdown */}
                      <div className="relative" ref={dropdownRef}>
                        <button
                          type="button"
                          onClick={() => setDropdownOpen(!dropdownOpen)}
                          className="h-11 rounded-xl border border-gray-200 bg-white px-3 text-sm outline-none transition
                                     focus:border-rose-600 focus:ring-4 focus:ring-rose-500/10 cursor-pointer
                                     flex items-center gap-2 hover:bg-gray-50"
                        >
                          <span className="text-xl leading-none">{selectedCountry.flag}</span>
                          <span className="text-sm font-medium text-gray-700">{selectedCountry.code}</span>
                          <ChevronDown size={14} className={`text-gray-400 transition-transform ${dropdownOpen ? "rotate-180" : ""}`} />
                        </button>

                        {dropdownOpen && (
                          <div className="absolute top-full left-0 mt-1 w-48 bg-white border border-gray-200 rounded-xl shadow-lg z-50 overflow-hidden">
                            {countries.map((c) => (
                              <button
                                key={c.code}
                                type="button"
                                onClick={() => {
                                  setCountryCode(c.code);
                                  setDropdownOpen(false);
                                }}
                                className={`w-full flex items-center gap-3 px-3 py-2.5 text-sm hover:bg-rose-50 transition-colors
                                           ${c.code === countryCode ? "bg-rose-50 text-rose-600" : "text-gray-700"}`}
                              >
                                <span className="text-xl leading-none">{c.flag}</span>
                                <span className="font-medium">{c.name}</span>
                                <span className="ml-auto text-gray-400 text-xs">{c.code}</span>
                              </button>
                            ))}
                          </div>
                        )}
                      </div>

                      <input
                        type="tel"
                        required
                        value={localValue}
                        onChange={(e) => setLocalValue(e.target.value.replace(/[^\d]/g, ''))}
                        placeholder="XXXXX XXXXX"
                        className="flex-1 h-11 rounded-xl border border-gray-200 bg-white px-3 text-sm outline-none transition
                                   focus:border-rose-600 focus:ring-4 focus:ring-rose-500/10 placeholder:text-gray-300"
                      />
                    </div>
                  ) : (
                    <input
                      type="email"
                      required
                      value={localValue}
                      onChange={(e) => setLocalValue(e.target.value)}
                      placeholder="name@domain.com"
                      className="w-full h-11 rounded-xl border border-gray-200 bg-white px-3 text-sm outline-none transition
                                 focus:border-rose-600 focus:ring-4 focus:ring-rose-500/10 placeholder:text-gray-300"
                    />
                  )}
                </Field>

                {/* Terms */}
                <label className="flex items-start gap-3 pt-1 cursor-pointer select-none">
                  <span className="relative mt-0.5 h-4 w-4 rounded-md border border-gray-300 flex items-center justify-center">
                    <input
                      type="checkbox"
                      className="peer absolute inset-0 opacity-0 cursor-pointer"
                      checked={agreeTerms}
                      onChange={(e) => setAgreeTerms(e.target.checked)}
                    />
                    <Check
                      size={12}
                      strokeWidth={3}
                      className="opacity-0 peer-checked:opacity-100 transition-opacity"
                    />
                  </span>
                  <span className="text-xs text-gray-500 leading-relaxed">
                    I agree to the <span className="text-rose-600">Terms</span> and{" "}
                    <span className="text-rose-600">Privacy Policy</span>.
                  </span>
                </label>

                {error && (
                  <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl p-3">
                    {error}
                  </p>
                )}

                <button
                  type="submit"
                  disabled={!canSendOtp}
                  className="w-full h-11 rounded-xl bg-rose-600 text-white text-[11px] font-semibold uppercase tracking-[0.22em]
                             flex items-center justify-center gap-2 transition
                             hover:bg-rose-700 disabled:opacity-30 disabled:cursor-not-allowed text-white shadow-lg shadow-rose-500/20"
                >
                  {isLoading ? (
                    <Loader2 size={16} className="animate-spin" />
                  ) : (
                    <>
                      Send OTP <ArrowRight size={14} />
                    </>
                  )}
                </button>
              </form>
            )}

            {/* Step: OTP */}
            {step === "otp" && (
              <form onSubmit={onVerifyOtp} className="mt-6 space-y-5">
                <div className="rounded-xl border border-gray-200 bg-gray-50 p-3">
                  <p className="text-xs text-gray-500">
                    OTP sent to{" "}
                    <span className="text-rose-600 font-semibold">
                      {value || localValue}
                    </span>
                  </p>

                  <button
                    type="button"
                    onClick={onChangeNumberOrEmail}
                    className="mt-2 inline-flex items-center gap-2 text-[11px] font-semibold uppercase tracking-[0.18em] text-gray-700 hover:text-rose-600"
                  >
                    <RefreshCcw size={14} /> Change
                  </button>
                </div>

                <Field label="OTP (6 digits)">
                  <input
                    inputMode="numeric"
                    pattern="\d*"
                    maxLength={6}
                    value={otp}
                    onChange={(e) => setOtp(e.target.value.replace(/\D/g, ""))}
                    placeholder="••••••"
                    className="w-full h-11 rounded-xl border border-gray-200 bg-white px-3 text-sm tracking-[0.35em] text-center outline-none transition
                               focus:border-rose-600 focus:ring-4 focus:ring-rose-500/10 placeholder:text-gray-300"
                  />
                </Field>

                {error && (
                  <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl p-3">
                    {error}
                  </p>
                )}

                <button
                  type="submit"
                  disabled={!canVerifyOtp}
                  className="w-full h-11 rounded-xl bg-rose-600 text-white text-[11px] font-semibold uppercase tracking-[0.22em]
                             flex items-center justify-center gap-2 transition
                             hover:bg-rose-700 disabled:opacity-30 disabled:cursor-not-allowed shadow-lg shadow-rose-500/20"
                >
                  {isLoading ? (
                    <Loader2 size={16} className="animate-spin" />
                  ) : (
                    <>
                      Verify & Continue <ArrowRight size={14} />
                    </>
                  )}
                </button>

                <button
                  type="button"
                  onClick={onResend}
                  disabled={isLoading}
                  className="w-full h-11 rounded-xl border border-gray-200 text-[11px] font-semibold uppercase tracking-[0.18em]
                             hover:border-rose-600 hover:text-rose-600 transition disabled:opacity-40"
                >
                  Resend OTP
                </button>
              </form>
            )}

            {/* Divider + Social (UI only for now) */}
            <div className="mt-7">
              <div className="flex items-center gap-3 text-gray-200">
                <div className="h-px flex-1 bg-current" />
                <span className="text-[10px] font-semibold uppercase tracking-[0.22em] text-gray-400">
                  or
                </span>
                <div className="h-px flex-1 bg-current" />
              </div>

              <div className="mt-4 grid grid-cols-2 gap-3">
                <button
                  type="button"
                  className="h-11 rounded-xl border border-gray-200 text-[11px] font-semibold uppercase tracking-[0.18em]
                             hover:border-rose-600 hover:text-rose-600 transition"
                >
                  Google
                </button>
                <button
                  type="button"
                  className="h-11 rounded-xl border border-gray-200 text-[11px] font-semibold uppercase tracking-[0.18em]
                             hover:border-rose-600 hover:text-rose-600 transition"
                >
                  Apple
                </button>
              </div>
            </div>
          </div>

          {/* Footer */}
          <div className="px-6 pb-6">
            <p className="text-center text-xs text-gray-500">
              Already a member?{" "}
              <button
                type="button"
                onClick={() => navigate("/login")}
                className="text-rose-600 font-semibold underline underline-offset-4"
              >
                Sign in
              </button>
            </p>
          </div>
        </div>

        <p className="mt-4 text-center text-[11px] text-gray-400">
          OTP-first onboarding. Faster conversion.
        </p>
      </div>
    </div>
  );
};

export default RegisterWithOtp;

/* --- Small field wrapper --- */
function Field({
  label,
  children,
  right,
  hint,
}: {
  label: string;
  children: React.ReactNode;
  right?: React.ReactNode;
  hint?: React.ReactNode;
}) {
  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <span className="text-[11px] font-semibold tracking-[0.18em] uppercase text-gray-500">
          {label}
        </span>
        {right}
      </div>
      {children}
      {hint ? <div>{hint}</div> : null}
    </div>
  );
}
