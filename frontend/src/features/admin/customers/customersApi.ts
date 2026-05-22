import { api } from "../../../services/api";

/* ── User DTO from backend ── */
export interface UserDto {
  id: number;
  first_name: string;
  last_name: string;
  full_name: string;
  email: string | null;
  phone_number: string | null;
  role: "user" | "admin";
  is_active: boolean;
  is_email_verified: boolean;
  is_phone_verified: boolean;
  google_id: string | null;
  profile: {
    id: number;
    profile_picture: string | null;
    date_of_birth: string | null;
    gender: string | null;
    preferred_language: string;
    newsletter_subscribed: boolean;
    notification_enabled: boolean;
    created_at: string;
    updated_at: string;
  } | null;
  addresses: any[];
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
  last_login_at: string | null;
}

/* ── Frontend Customer type ── */
export interface Customer {
  id: string;
  name: string;
  email: string;
  phone: string;
  role: "user" | "admin";
  status: "Active" | "Blocked";
  isEmailVerified: boolean;
  isPhoneVerified: boolean;
  googleLinked: boolean;
  profilePicture: string | null;
  dateOfBirth: string | null;
  gender: string | null;
  preferredLanguage: string;
  newsletterSubscribed: boolean;
  notificationEnabled: boolean;
  lastLoginAt: string | null;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
}

export type CustomersQuery = {
  q?: string;
  status?: string;
  role?: string;
  page?: number;
  limit?: number;
  offset?: number;
};

export const customersApi = {
  list: async (params?: CustomersQuery): Promise<{ results: UserDto[]; count: number }> => {
    const res = await api.get<{ results: UserDto[]; count: number }>("/users/", { params });
    return res.data;
  },

  details: async (id: string): Promise<UserDto> => {
    const res = await api.get<UserDto>(`/users/${id}/`);
    return res.data;
  },
};
