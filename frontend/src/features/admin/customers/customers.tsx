import React, {
  useCallback,
  useDeferredValue,
  useEffect,
  useMemo,
  useRef,
  useState,
  memo,
} from "react";
import { useDispatch, useSelector } from "react-redux";
import {
  Search,
  Filter,
  X,
  Phone,
  Mail,
  RotateCcw,
  ChevronRight,
  ChevronLeft,
  Download,
  ListFilter,
  Columns3,
  Shield,
  ShieldCheck,
  Globe,
  Bell,
  Calendar,
  User,
  CheckCircle2,
  XCircle,
  Eye,
} from "lucide-react";

import {
  customersActions,
  selectCustomers,
  selectCustomersStatus,
  selectCustomersError,
  selectSelectedCustomerId,
  selectCustomersTotal,
} from "./customersSlice";
import type { Customer } from "./customersApi";

/* --- Column visibility --- */
type ColumnKey =
  | "index"
  | "customer"
  | "status"
  | "role"
  | "verified"
  | "phone"
  | "googleLinked"
  | "language"
  | "newsletter"
  | "lastLogin"
  | "joined"
  | "actions";

interface ColumnDef {
  key: ColumnKey;
  label: string;
  icon?: React.ReactNode;
  defaultVisible: boolean;
  alwaysVisible?: boolean;
}

const COLUMNS: ColumnDef[] = [
  { key: "index", label: "#", defaultVisible: true, alwaysVisible: true },
  { key: "customer", label: "Customer", defaultVisible: true },
  { key: "status", label: "Status", defaultVisible: true },
  { key: "role", label: "Role", icon: <Shield size={12} />, defaultVisible: true },
  {
    key: "verified",
    label: "Verified",
    icon: <ShieldCheck size={12} />,
    defaultVisible: true,
  },
  { key: "phone", label: "Phone", icon: <Phone size={12} />, defaultVisible: false },
  { key: "googleLinked", label: "Google", icon: <Globe size={12} />, defaultVisible: false },
  { key: "language", label: "Language", icon: <Globe size={12} />, defaultVisible: false },
  { key: "newsletter", label: "Newsletter", icon: <Bell size={12} />, defaultVisible: false },
  { key: "lastLogin", label: "Last Login", icon: <Calendar size={12} />, defaultVisible: false },
  { key: "joined", label: "Joined", icon: <Calendar size={12} />, defaultVisible: true },
  { key: "actions", label: "Actions", defaultVisible: true, alwaysVisible: true },
];

type StatusFilter = "All" | "Active" | "Blocked";
type RoleFilter = "All" | "user" | "admin";

// Simple debounce hook
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value);
  useEffect(() => {
    const handler = window.setTimeout(() => setDebouncedValue(value), delay);
    return () => window.clearTimeout(handler);
  }, [value, delay]);
  return debouncedValue;
}

/* ─────────────────────────────
   Memo Sub-components
───────────────────────────── */

const QuickStat = memo(function QuickStat({
  label,
  value,
  sub,
  icon,
  onClick,
  active = false,
}: {
  label: string;
  value: string;
  sub: string;
  icon?: React.ReactNode;
  onClick?: () => void;
  active?: boolean;
}) {
  return (
    <div
      onClick={onClick}
      className={`p-5 bg-white border rounded-2xl shadow-sm transition-all ${onClick ? "cursor-pointer hover:shadow-md" : ""
        } ${active ? "border-black ring-1 ring-black/5" : "border-[#EEEEEE] hover:border-[#D4D4D8]"}`}
    >
      <div className="flex items-center justify-between">
        <p className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest">{label}</p>
        {icon}
      </div>
      <h3 className="text-2xl font-bold mt-1 tracking-tight">{value}</h3>
      <p className="text-[11px] text-emerald-600 font-medium mt-1">{sub}</p>
    </div>
  );
});

const InfoField = memo(function InfoField({
  label,
  value,
  icon,
  children,
}: {
  label: string;
  value?: string;
  icon?: React.ReactNode;
  children?: React.ReactNode;
}) {
  return (
    <div className="space-y-1.5">
      <div className="flex items-center gap-1.5">
        {icon && <span className="text-[#A1A1AA]">{icon}</span>}
        <p className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest">{label}</p>
      </div>
      {children || <p className="text-sm font-bold">{value}</p>}
    </div>
  );
});

const CustomerRow = memo(function CustomerRow({
  customer,
  index,
  page,
  limit,
  isVisible,
  onView,
  joinedLabel,
  lastLoginLabel,
}: {
  customer: Customer;
  index: number;
  page: number;
  limit: number;
  isVisible: (k: ColumnKey) => boolean;
  onView: (e: React.MouseEvent<HTMLButtonElement>) => void;
  joinedLabel: string;
  lastLoginLabel: string;
}) {
  return (
    <tr className="group hover:bg-[#FBFBFA] transition-colors">
      {isVisible("index") && (
        <td className="px-5 py-4 text-xs font-mono text-[#A1A1AA] text-center">
          {(page - 1) * limit + index + 1}
        </td>
      )}

      {isVisible("customer") && (
        <td className="px-5 py-4">
          <div className="flex items-center gap-3">
            {customer.profilePicture ? (
              <img
                src={customer.profilePicture}
                alt={customer.name}
                className="w-9 h-9 rounded-xl object-cover border border-[#EEEEEE]"
                loading="lazy"
              />
            ) : (
              <div className="w-9 h-9 rounded-xl bg-slate-100 flex items-center justify-center text-xs font-bold border border-[#EEEEEE]">
                {customer.name?.charAt(0) ?? "?"}
              </div>
            )}
            <div>
              <p className="text-xs font-bold">{customer.name}</p>
              <p className="text-[10px] text-[#A1A1AA]">{customer.email || "—"}</p>
            </div>
          </div>
        </td>
      )}

      {isVisible("status") && (
        <td className="px-5 py-4">
          <span
            className={`text-[10px] font-bold px-2.5 py-1 rounded-full uppercase border ${customer.status === "Active"
              ? "bg-emerald-50 text-emerald-600 border-emerald-100"
              : "bg-rose-50 text-rose-600 border-rose-100"
              }`}
          >
            {customer.status}
          </span>
        </td>
      )}

      {isVisible("role") && (
        <td className="px-5 py-4">
          <span
            className={`text-[10px] font-bold px-2.5 py-1 rounded-full uppercase border ${customer.role === "admin"
              ? "bg-blue-50 text-blue-600 border-blue-100"
              : "bg-gray-50 text-gray-600 border-gray-200"
              }`}
          >
            {customer.role}
          </span>
        </td>
      )}

      {isVisible("verified") && (
        <td className="px-5 py-4">
          <div className="flex items-center gap-2">
            <span
              title="Email"
              className={`text-[9px] font-bold px-1.5 py-0.5 rounded ${customer.isEmailVerified ? "bg-emerald-50 text-emerald-600" : "bg-gray-50 text-[#A1A1AA]"
                }`}
            >
              ✉ {customer.isEmailVerified ? "✓" : "✗"}
            </span>
            <span
              title="Phone"
              className={`text-[9px] font-bold px-1.5 py-0.5 rounded ${customer.isPhoneVerified ? "bg-emerald-50 text-emerald-600" : "bg-gray-50 text-[#A1A1AA]"
                }`}
            >
              ☎ {customer.isPhoneVerified ? "✓" : "✗"}
            </span>
          </div>
        </td>
      )}

      {isVisible("phone") && (
        <td className="px-5 py-4">
          <span className="text-xs font-medium text-[#52525B]">{customer.phone || "—"}</span>
        </td>
      )}

      {isVisible("googleLinked") && (
        <td className="px-5 py-4">
          {customer.googleLinked ? (
            <span className="text-[9px] font-bold px-2 py-1 rounded-full bg-blue-50 text-blue-600 border border-blue-100">
              Linked
            </span>
          ) : (
            <span className="text-[10px] text-[#A1A1AA]">—</span>
          )}
        </td>
      )}

      {isVisible("language") && (
        <td className="px-5 py-4">
          <span className="text-xs font-medium text-[#52525B] uppercase">
            {customer.preferredLanguage}
          </span>
        </td>
      )}

      {isVisible("newsletter") && (
        <td className="px-5 py-4">
          {customer.newsletterSubscribed ? (
            <CheckCircle2 size={14} className="text-emerald-500" />
          ) : (
            <XCircle size={14} className="text-[#D4D4D8]" />
          )}
        </td>
      )}

      {isVisible("lastLogin") && (
        <td className="px-5 py-4">
          <span className="text-xs text-[#52525B] font-medium">{lastLoginLabel}</span>
        </td>
      )}

      {isVisible("joined") && (
        <td className="px-5 py-4">
          <span className="text-xs text-[#52525B] font-medium">{joinedLabel}</span>
        </td>
      )}

      {isVisible("actions") && (
        <td className="px-5 py-4 text-right">
          <div className="flex items-center justify-end gap-2">
            <button
              data-id={customer.id}
              onClick={onView}
              className="p-2 hover:bg-black hover:text-white rounded-lg transition-colors text-[#A1A1AA]"
              title="View Details"
            >
              <Eye size={16} />
            </button>
          </div>
        </td>
      )}
    </tr>
  );
});

const CustomerDetailPanel = memo(function CustomerDetailPanel({
  customer,
  onClose,
}: {
  customer: Customer;
  onClose: () => void;
}) {
  return (
    <>
      <div
        className="fixed inset-0 bg-black/40 backdrop-blur-[2px] z-50 transition-opacity"
        onClick={onClose}
      />
      <div className="fixed inset-y-0 right-0 w-full max-w-xl bg-white z-[60] shadow-2xl flex flex-col animate-in slide-in-from-right duration-300">
        {/* Header */}
        <div className="p-6 border-b border-[#EEEEEE] flex justify-between items-center bg-white sticky top-0">
          <div className="flex items-center gap-3">
            {customer.profilePicture ? (
              <img
                src={customer.profilePicture}
                alt={customer.name}
                className="w-12 h-12 rounded-xl object-cover border border-[#EEEEEE]"
                loading="lazy"
              />
            ) : (
              <div className="p-2.5 bg-gray-900 text-white rounded-xl">
                <User size={18} />
              </div>
            )}
            <div>
              <h2 className="text-lg font-black flex items-center gap-2">
                {customer.name}
                <span
                  className={`text-[9px] font-bold px-2 py-0.5 rounded-full uppercase ${customer.role === "admin" ? "bg-blue-50 text-blue-600" : "bg-gray-50 text-gray-500"
                    }`}
                >
                  {customer.role}
                </span>
              </h2>
              <span className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest">
                User Details · ID: {customer.id}
              </span>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 border border-[#EEEEEE] rounded-lg hover:bg-gray-50 transition-colors"
          >
            <X size={18} />
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {/* Status Banner */}
          <div className="bg-[#FAFAFA] p-4 rounded-xl border border-[#EEEEEE] flex justify-between items-center">
            <div>
              <p className="text-[10px] font-bold text-[#A1A1AA] uppercase">Account Status</p>
              <div className="mt-1">
                <span
                  className={`inline-flex items-center gap-1.5 text-[10px] font-bold px-2.5 py-1 rounded-full uppercase border ${customer.status === "Active"
                    ? "bg-emerald-50 text-emerald-600 border-emerald-100"
                    : "bg-rose-50 text-rose-600 border-rose-100"
                    }`}
                >
                  <span
                    className={`w-1.5 h-1.5 rounded-full ${customer.status === "Active" ? "bg-emerald-500" : "bg-rose-500"
                      }`}
                  />
                  {customer.status}
                </span>
              </div>
            </div>
            {customer.deletedAt && (
              <span className="text-[10px] font-bold text-rose-500 bg-rose-50 border border-rose-100 px-2.5 py-1 rounded-full">
                DELETED
              </span>
            )}
          </div>

          {/* Contact Info */}
          <div className="grid grid-cols-2 gap-5">
            <InfoField label="Email" value={customer.email || "—"} icon={<Mail size={12} />} />
            <InfoField label="Phone" value={customer.phone || "—"} icon={<Phone size={12} />} />
            <InfoField label="Email Verified" icon={<ShieldCheck size={12} />}>
              <span
                className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${customer.isEmailVerified ? "bg-emerald-50 text-emerald-600" : "bg-gray-100 text-[#A1A1AA]"
                  }`}
              >
                {customer.isEmailVerified ? "Verified ✓" : "Unverified ✗"}
              </span>
            </InfoField>
            <InfoField label="Phone Verified" icon={<ShieldCheck size={12} />}>
              <span
                className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${customer.isPhoneVerified ? "bg-emerald-50 text-emerald-600" : "bg-gray-100 text-[#A1A1AA]"
                  }`}
              >
                {customer.isPhoneVerified ? "Verified ✓" : "Unverified ✗"}
              </span>
            </InfoField>
          </div>

          {/* Profile Info */}
          <div>
            <h4 className="text-[10px] font-bold uppercase tracking-widest text-[#A1A1AA] border-b border-[#EEEEEE] pb-2 mb-4">
              Profile Details
            </h4>
            <div className="grid grid-cols-2 gap-5">
              <InfoField
                label="Date of Birth"
                value={
                  customer.dateOfBirth
                    ? new Date(customer.dateOfBirth).toLocaleDateString("en-IN", {
                      day: "2-digit",
                      month: "long",
                      year: "numeric",
                    })
                    : "—"
                }
              />
              <InfoField label="Gender" value={customer.gender || "—"} />
              <InfoField label="Language" value={customer.preferredLanguage.toUpperCase()} />
              <InfoField label="Google Linked">
                <span
                  className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${customer.googleLinked ? "bg-blue-50 text-blue-600" : "bg-gray-100 text-[#A1A1AA]"
                    }`}
                >
                  {customer.googleLinked ? "Linked ✓" : "Not Linked"}
                </span>
              </InfoField>
            </div>
          </div>

          {/* Preferences */}
          <div>
            <h4 className="text-[10px] font-bold uppercase tracking-widest text-[#A1A1AA] border-b border-[#EEEEEE] pb-2 mb-4">
              Preferences
            </h4>
            <div className="grid grid-cols-2 gap-5">
              <InfoField label="Newsletter">
                <span
                  className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${customer.newsletterSubscribed ? "bg-emerald-50 text-emerald-600" : "bg-gray-100 text-[#A1A1AA]"
                    }`}
                >
                  {customer.newsletterSubscribed ? "Subscribed" : "Not Subscribed"}
                </span>
              </InfoField>
              <InfoField label="Notifications">
                <span
                  className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${customer.notificationEnabled ? "bg-emerald-50 text-emerald-600" : "bg-gray-100 text-[#A1A1AA]"
                    }`}
                >
                  {customer.notificationEnabled ? "Enabled" : "Disabled"}
                </span>
              </InfoField>
            </div>
          </div>

          {/* Timestamps */}
          <div>
            <h4 className="text-[10px] font-bold uppercase tracking-widest text-[#A1A1AA] border-b border-[#EEEEEE] pb-2 mb-4">
              Activity
            </h4>
            <div className="grid grid-cols-2 gap-5">
              <InfoField
                label="Last Login"
                value={
                  customer.lastLoginAt
                    ? new Date(customer.lastLoginAt).toLocaleString("en-IN", {
                      day: "2-digit",
                      month: "short",
                      year: "numeric",
                      hour: "2-digit",
                      minute: "2-digit",
                    })
                    : "Never"
                }
              />
              <InfoField
                label="Joined"
                value={new Date(customer.createdAt).toLocaleDateString("en-IN", {
                  day: "2-digit",
                  month: "long",
                  year: "numeric",
                })}
              />
              <InfoField
                label="Last Updated"
                value={new Date(customer.updatedAt).toLocaleDateString("en-IN", {
                  day: "2-digit",
                  month: "long",
                  year: "numeric",
                })}
              />
              {customer.deletedAt && (
                <InfoField
                  label="Deleted At"
                  value={new Date(customer.deletedAt).toLocaleDateString("en-IN", {
                    day: "2-digit",
                    month: "long",
                    year: "numeric",
                  })}
                />
              )}
            </div>
          </div>
        </div>
      </div>
    </>
  );
});

/* --- MAIN COMPONENT --- */
const CustomerManagement: React.FC = () => {
  const dispatch = useDispatch();

  const customers = useSelector(selectCustomers);
  const totalCount = useSelector(selectCustomersTotal);
  const status = useSelector(selectCustomersStatus);
  const error = useSelector(selectCustomersError);
  const selectedCustomerId = useSelector(selectSelectedCustomerId);

  // Filter states
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState<StatusFilter>("All");
  const [roleFilter, setRoleFilter] = useState<RoleFilter>("All");
  const [verifiedFilter, setVerifiedFilter] = useState("");
  const [phoneFilter, setPhoneFilter] = useState("");
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(5);

  // smoother typing
  const deferredSearchTerm = useDeferredValue(searchTerm);
  const debouncedSearch = useDebounce(deferredSearchTerm, 500);

  // Column visibility
  const [visibleColumns, setVisibleColumns] = useState<Record<ColumnKey, boolean>>(() => {
    const init = {} as Record<ColumnKey, boolean>;
    COLUMNS.forEach((c) => (init[c.key] = c.defaultVisible));
    return init;
  });

  const [isColumnsOpen, setIsColumnsOpen] = useState(false);
  const columnsRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (columnsRef.current && !columnsRef.current.contains(e.target as Node)) {
        setIsColumnsOpen(false);
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const toggleColumn = useCallback((key: ColumnKey) => {
    const col = COLUMNS.find((c) => c.key === key);
    if (col?.alwaysVisible) return;
    setVisibleColumns((prev) => ({ ...prev, [key]: !prev[key] }));
  }, []);

  const isVisible = useCallback((key: ColumnKey) => !!visibleColumns[key], [visibleColumns]);

  // Fetch when params change
  useEffect(() => {
    const offset = (page - 1) * limit;
    dispatch(
      customersActions.fetchCustomersRequest({
        q: debouncedSearch || undefined,
        status: statusFilter === "All" ? undefined : statusFilter,
        role: roleFilter === "All" ? undefined : roleFilter,
        page,
        limit,
        offset,
      })
    );
  }, [dispatch, debouncedSearch, statusFilter, roleFilter, page, limit]);

  const handleReset = useCallback(() => {
    setSearchTerm("");
    setStatusFilter("All");
    setRoleFilter("All");
    setVerifiedFilter("");
    setPhoneFilter("");
    setPage(1);
  }, []);

  // Client-side filtering + stats in ONE memo (big win)
  const { filteredCustomers, stats } = useMemo(() => {
    let result = customers;

    // Redundant now that it is server-side triggered via fetch useEffect
    // if (roleFilter !== "All") result = result.filter((c) => c.role === roleFilter);

    if (verifiedFilter === "email") result = result.filter((c) => c.isEmailVerified);
    else if (verifiedFilter === "phone") result = result.filter((c) => c.isPhoneVerified);
    else if (verifiedFilter === "both") result = result.filter((c) => c.isEmailVerified && c.isPhoneVerified);
    else if (verifiedFilter === "none") result = result.filter((c) => !c.isEmailVerified && !c.isPhoneVerified);

    if (phoneFilter) {
      const pf = phoneFilter.toLowerCase();
      result = result.filter((c) => (c.phone ?? "").toLowerCase().includes(pf));
    }

    let active = 0,
      blocked = 0,
      admins = 0;

    for (const c of result) {
      if (c.status === "Active") active++;
      else if (c.status === "Blocked") blocked++;
      if (c.role === "admin") admins++;
    }

    return { filteredCustomers: result, stats: { active, blocked, admins } };
  }, [customers, verifiedFilter, phoneFilter]);

  const selectedCustomer = useMemo(
    () => filteredCustomers.find((c) => c.id === selectedCustomerId) ?? null,
    [filteredCustomers, selectedCustomerId]
  );

  // Pre-format dates for table (avoid repeated new Date per cell)
  const formattedDates = useMemo(() => {
    const map = new Map<string, { joined: string; lastLogin: string }>();
    for (const c of filteredCustomers) {
      const joined = new Date(c.createdAt).toLocaleDateString("en-IN", {
        day: "2-digit",
        month: "short",
        year: "numeric",
      });
      const lastLogin = c.lastLoginAt
        ? new Date(c.lastLoginAt).toLocaleDateString("en-IN", {
          day: "2-digit",
          month: "short",
          year: "numeric",
        })
        : "Never";
      map.set(c.id, { joined, lastLogin });
    }
    return map;
  }, [filteredCustomers]);

  // View handler (no inline function per row)
  const onViewCustomer = useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      const id = (e.currentTarget.dataset.id as string) || "";
      if (id) dispatch(customersActions.setSelectedCustomerId(id));
    },
    [dispatch]
  );

  const onClosePanel = useCallback(() => {
    dispatch(customersActions.setSelectedCustomerId(null));
  }, [dispatch]);

  // Export handler (non-blocking-ish)
  const handleExport = useCallback(() => {
    window.setTimeout(() => {
      const headers = ["Name", "Email", "Status", "Role", "Phone", "Verified", "Joined"];
      const rows = filteredCustomers.map((c) => [
        c.name,
        c.email,
        c.status,
        c.role,
        c.phone || "",
        `Email: ${c.isEmailVerified}, Phone: ${c.isPhoneVerified}`,
        new Date(c.createdAt).toLocaleDateString(),
      ]);

      const csvContent = [
        headers.join(","),
        ...rows.map((r) =>
          r
            .map((cell) => {
              const val = String(cell ?? "");
              return val.includes(",") ? `"${val.replaceAll('"', '""')}"` : val;
            })
            .join(",")
        ),
      ].join("\n");

      const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
      const link = document.createElement("a");
      const url = URL.createObjectURL(blob);
      link.setAttribute("href", url);
      link.setAttribute("download", `customers_export_${new Date().toISOString().split("T")[0]}.csv`);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
    }, 0);
  }, [filteredCustomers]);

  const toggleRoleQuick = useCallback(() => {
    setRoleFilter((prev) => {
      // if All -> admin (quick view), admin -> user, user -> admin
      if (prev === "All") return "admin";
      return prev === "admin" ? "user" : "admin";
    });
    setPage(1);
  }, []);

  return (
    <div className="min-h-screen w-full space-y-6 text-[#18181B] bg-[#FDFDFD]">
      {/* --- PAGE HEADER --- */}
      <div>
        <h1 className="text-2xl md:text-3xl font-bold tracking-tight text-black">Customers</h1>
        <p className="text-[#71717A] text-sm mt-1">Manage users and their accounts.</p>
      </div>

      {/* --- STATS --- */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <QuickStat
          label="Total Users"
          value={`${totalCount}`}
          sub="All registered"
          icon={<User size={16} className="text-[#A1A1AA]" />}
          onClick={handleReset}
        />
        <QuickStat
          label="Active"
          value={`${stats.active}`}
          sub="Active accounts"
          icon={<CheckCircle2 size={16} className="text-emerald-500" />}
          onClick={() => {
            setStatusFilter("Active");
            setPage(1);
          }}
          active={statusFilter === "Active"}
        />
        <QuickStat
          label="Blocked"
          value={`${stats.blocked}`}
          sub="Suspended"
          icon={<XCircle size={16} className="text-rose-500" />}
          onClick={() => {
            setStatusFilter("Blocked");
            setPage(1);
          }}
          active={statusFilter === "Blocked"}
        />
        <QuickStat
          label="Admins"
          value={`${stats.admins}`}
          sub="Admin role"
          icon={<Shield size={16} className="text-blue-500" />}
          onClick={() => {
            setRoleFilter("admin");
            setPage(1);
          }}
          active={roleFilter === "admin"}
        />
      </div>

      {/* --- TABLE --- */}
      <div className="bg-white rounded-2xl border border-[#EEEEEE] shadow-sm overflow-hidden">
        {/* Toolbar */}
        <div className="p-4 border-b border-[#EEEEEE] flex flex-col md:flex-row justify-between items-center gap-4 bg-white">
          <div className="flex items-center gap-2 w-full md:w-auto justify-end">
            {/* User/Admin Toggle */}
            <button
              onClick={toggleRoleQuick}
              className={`flex items-center gap-2 px-3 py-1.5 border rounded-lg text-[11px] font-bold transition-all ${roleFilter === "admin"
                ? "bg-blue-600 text-white border-blue-600 hover:bg-blue-700"
                : "bg-black text-white border-black hover:bg-gray-800"
                }`}
              title="Quick toggle: Admins ↔ Users (All -> Admins)"
            >
              {roleFilter === "admin" ? <Shield size={14} /> : <User size={14} />}
              {roleFilter === "admin" ? "Show Users" : "Show Admins"}
            </button>

            <div className="h-6 w-px bg-[#EEEEEE] mx-1" />

            <button
              onClick={handleReset}
              className="p-2 text-[#A1A1AA] hover:text-rose-500 hover:bg-rose-50 rounded-lg transition-all"
              title="Clear Filters"
            >
              <RotateCcw size={16} />
            </button>

            <div className="h-6 w-px bg-[#EEEEEE] mx-1" />

            <button
              onClick={() => setIsFilterOpen((v) => !v)}
              className={`flex items-center gap-2 px-3 py-1.5 border rounded-lg text-[11px] font-bold transition-all ${isFilterOpen ? "bg-black text-white border-black" : "bg-white text-black border-[#EEEEEE] hover:bg-gray-50"
                }`}
            >
              <Filter size={14} /> {isFilterOpen ? "Hide Filters" : "Show Filters"}
            </button>

            {/* Column Visibility Dropdown */}
            <div className="relative" ref={columnsRef}>
              <button
                onClick={() => setIsColumnsOpen((v) => !v)}
                className={`flex items-center gap-2 px-3 py-1.5 border rounded-lg text-[11px] font-bold transition-all ${isColumnsOpen ? "bg-black text-white border-black" : "bg-white text-black border-[#EEEEEE] hover:bg-gray-50"
                  }`}
              >
                <Columns3 size={14} /> Columns
              </button>

              {isColumnsOpen && (
                <div className="absolute right-0 top-full mt-2 w-56 bg-white rounded-xl border border-[#EEEEEE] shadow-xl z-50 py-2 animate-in fade-in slide-in-from-top-1 duration-150">
                  <p className="px-4 py-2 text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest border-b border-[#EEEEEE]">
                    Toggle Columns
                  </p>

                  {COLUMNS.filter((c) => !c.alwaysVisible).map((col) => (
                    <label
                      key={col.key}
                      className="flex items-center gap-3 px-4 py-2 hover:bg-[#FAFAFA] cursor-pointer transition-colors"
                    >
                      <input
                        type="checkbox"
                        checked={visibleColumns[col.key]}
                        onChange={() => toggleColumn(col.key)}
                        className="w-3.5 h-3.5 rounded border-[#D4D4D8] text-black focus:ring-black/20 accent-black"
                      />
                      <span className="flex items-center gap-2 text-xs font-medium text-[#52525B]">
                        {col.icon}
                        {col.label}
                      </span>
                    </label>
                  ))}
                </div>
              )}
            </div>

            <button
              onClick={handleExport}
              className="flex items-center gap-2 px-3 py-2 bg-white border border-[#EEEEEE] rounded-lg text-xs font-bold hover:bg-[#FAFAFA] transition-colors"
            >
              <Download size={14} /> Export
            </button>
          </div>
        </div>

        {/* Loading / Error */}
        {status === "loading" && customers.length === 0 && (
          <div className="p-6 text-sm text-[#71717A]">Loading customers…</div>
        )}
        {status === "failed" && (
          <div className="p-6 text-sm text-rose-600">{error || "Failed to load customers"}</div>
        )}

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[1000px]">
            <thead className="bg-[#FAFAFA]">
              <tr className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest border-b border-[#EEEEEE]">
                {isVisible("index") && <th className="px-5 py-4 w-12 text-center">#</th>}
                {isVisible("customer") && <th className="px-5 py-4">Customer</th>}
                {isVisible("status") && <th className="px-5 py-4">Status</th>}
                {isVisible("role") && <th className="px-5 py-4">Role</th>}
                {isVisible("verified") && <th className="px-5 py-4">Verified</th>}
                {isVisible("phone") && <th className="px-5 py-4">Phone</th>}
                {isVisible("googleLinked") && <th className="px-5 py-4">Google</th>}
                {isVisible("language") && <th className="px-5 py-4">Language</th>}
                {isVisible("newsletter") && <th className="px-5 py-4">Newsletter</th>}
                {isVisible("lastLogin") && <th className="px-5 py-4">Last Login</th>}
                {isVisible("joined") && <th className="px-5 py-4">Joined</th>}
                {isVisible("actions") && <th className="px-5 py-4 text-right">Actions</th>}
              </tr>

              {isFilterOpen && (
                <tr className="bg-white border-b border-[#EEEEEE] animate-in fade-in slide-in-from-top-1 duration-200">
                  {isVisible("index") && (
                    <td className="px-5 py-3 text-center">
                      <ListFilter size={14} className="text-[#D4D4D8] mx-auto" />
                    </td>
                  )}

                  {isVisible("customer") && (
                    <td className="px-5 py-3">
                      <div className="relative">
                        <Search
                          className="absolute left-2 top-1/2 -translate-y-1/2 text-[#A1A1AA]"
                          size={12}
                        />
                        <input
                          type="text"
                          placeholder="Name / email..."
                          value={searchTerm}
                          onChange={(e) => setSearchTerm(e.target.value)}
                          className="w-full pl-7 pr-2 py-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none focus:bg-white focus:border-[#EEEEEE]"
                        />
                      </div>
                    </td>
                  )}

                  {isVisible("status") && (
                    <td className="px-5 py-3">
                      <select
                        value={statusFilter}
                        onChange={(e) => {
                          setStatusFilter(e.target.value as StatusFilter);
                          setPage(1);
                        }}
                        className="w-full p-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none cursor-pointer focus:bg-white focus:border-[#EEEEEE]"
                      >
                        <option value="All">All Status</option>
                        <option value="Active">Active</option>
                        <option value="Blocked">Blocked</option>
                      </select>
                    </td>
                  )}

                  {isVisible("role") && (
                    <td className="px-5 py-3">
                      <select
                        value={roleFilter}
                        onChange={(e) => {
                          setRoleFilter(e.target.value as RoleFilter);
                          setPage(1);
                        }}
                        className="w-full p-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none cursor-pointer focus:bg-white focus:border-[#EEEEEE]"
                      >
                        <option value="All">All Roles</option>
                        <option value="user">User</option>
                        <option value="admin">Admin</option>
                      </select>
                    </td>
                  )}

                  {isVisible("verified") && (
                    <td className="px-5 py-3">
                      <select
                        value={verifiedFilter}
                        onChange={(e) => {
                          setVerifiedFilter(e.target.value);
                          setPage(1);
                        }}
                        className="w-full p-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none cursor-pointer focus:bg-white focus:border-[#EEEEEE]"
                      >
                        <option value="">All</option>
                        <option value="email">Email ✓</option>
                        <option value="phone">Phone ✓</option>
                        <option value="both">Both ✓</option>
                        <option value="none">None ✗</option>
                      </select>
                    </td>
                  )}

                  {isVisible("phone") && (
                    <td className="px-5 py-3">
                      <div className="relative">
                        <Search
                          className="absolute left-2 top-1/2 -translate-y-1/2 text-[#A1A1AA]"
                          size={12}
                        />
                        <input
                          type="text"
                          placeholder="Phone..."
                          value={phoneFilter}
                          onChange={(e) => {
                            setPhoneFilter(e.target.value);
                            setPage(1);
                          }}
                          className="w-full pl-7 pr-2 py-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none focus:bg-white focus:border-[#EEEEEE]"
                        />
                      </div>
                    </td>
                  )}

                  {isVisible("googleLinked") && (
                    <td className="px-5 py-3">
                      <div className="text-[10px] text-[#A1A1AA] italic">—</div>
                    </td>
                  )}
                  {isVisible("language") && (
                    <td className="px-5 py-3">
                      <div className="text-[10px] text-[#A1A1AA] italic">—</div>
                    </td>
                  )}
                  {isVisible("newsletter") && (
                    <td className="px-5 py-3">
                      <div className="text-[10px] text-[#A1A1AA] italic">—</div>
                    </td>
                  )}
                  {isVisible("lastLogin") && (
                    <td className="px-5 py-3">
                      <div className="text-[10px] text-[#A1A1AA] italic">—</div>
                    </td>
                  )}
                  {isVisible("joined") && (
                    <td className="px-5 py-3">
                      <div className="text-[10px] text-[#A1A1AA] italic">—</div>
                    </td>
                  )}

                  {isVisible("actions") && (
                    <td className="px-5 py-3 text-right">
                      <button onClick={handleReset} className="text-[10px] font-bold text-rose-500 hover:underline px-2">
                        Clear
                      </button>
                    </td>
                  )}
                </tr>
              )}
            </thead>

            <tbody className="divide-y divide-[#EEEEEE]">
              {status === "loading" && customers.length === 0
                ? Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td className="px-5 py-4">
                      <div className="h-4 w-4 bg-gray-100 rounded mx-auto" />
                    </td>
                    <td className="px-5 py-4">
                      <div className="h-10 w-32 bg-gray-100 rounded-xl" />
                    </td>
                    <td className="px-5 py-4">
                      <div className="h-6 w-16 bg-gray-100 rounded-full" />
                    </td>
                    <td className="px-5 py-4">
                      <div className="h-6 w-14 bg-gray-100 rounded-full" />
                    </td>
                    <td className="px-5 py-4">
                      <div className="h-4 w-16 bg-gray-100 rounded" />
                    </td>
                    <td className="px-5 py-4">
                      <div className="h-4 w-24 bg-gray-100 rounded" />
                    </td>
                    <td className="px-5 py-4">
                      <div className="h-8 w-8 bg-gray-100 rounded-lg ml-auto" />
                    </td>
                  </tr>
                ))
                : filteredCustomers.map((c, index) => {
                  const fd = formattedDates.get(c.id);
                  return (
                    <CustomerRow
                      key={c.id}
                      customer={c}
                      index={index}
                      page={page}
                      limit={limit}
                      isVisible={isVisible}
                      onView={onViewCustomer}
                      joinedLabel={fd?.joined ?? "—"}
                      lastLoginLabel={fd?.lastLogin ?? "Never"}
                    />
                  );
                })}
            </tbody>
          </table>

          {status !== "loading" && filteredCustomers.length === 0 && (
            <div className="py-20 text-center space-y-3">
              <User className="mx-auto text-[#D4D4D8]" size={32} />
              <p className="text-sm font-bold text-[#18181B]">No matching results</p>
              <button onClick={handleReset} className="text-xs font-bold underline text-[#A1A1AA] hover:text-black">
                Reset all filters
              </button>
            </div>
          )}
        </div>

        {/* --- PAGINATION --- */}
        <div className="p-4 border-t border-[#EEEEEE] flex items-center justify-between bg-white">
          <div className="flex items-center gap-4">
            <div className="text-[11px] text-[#A1A1AA] font-medium">
              Showing {filteredCustomers.length} of {totalCount} users
            </div>
            <select
              value={limit}
              onChange={(e) => {
                setLimit(Number(e.target.value));
                setPage(1);
              }}
              className="p-1.5 bg-[#F9F9F9] border border-[#EEEEEE] rounded-lg text-xs outline-none focus:border-[#D4D4D8]"
            >
              <option value={5}>5 / page</option>
              <option value={10}>10 / page</option>
              <option value={20}>20 / page</option>
              <option value={50}>50 / page</option>
              <option value={100}>100 / page</option>
            </select>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page === 1 || status === "loading"}
              className="p-2 border border-[#EEEEEE] rounded-lg hover:bg-[#FAFAFA] disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronLeft size={14} />
            </button>
            <span className="text-xs font-bold px-2">Page {page}</span>
            <button
              onClick={() => setPage((p) => p + 1)}
              disabled={customers.length < limit || status === "loading"}
              className="p-2 border border-[#EEEEEE] rounded-lg hover:bg-[#FAFAFA] disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronRight size={14} />
            </button>
          </div>
        </div>
      </div>

      {/* --- CUSTOMER DETAILS SLIDE-OVER --- */}
      {selectedCustomer && <CustomerDetailPanel customer={selectedCustomer} onClose={onClosePanel} />}
    </div>
  );
};

export default CustomerManagement;
