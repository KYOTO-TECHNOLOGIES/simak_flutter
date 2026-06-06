import React, { useEffect, useState, useMemo, useRef } from "react";
import { useDispatch, useSelector } from "react-redux";
import {
  CreditCard, Wallet, Banknote, Landmark, RefreshCcw,
  Search, Filter, Download, ChevronRight, X, CheckCircle2,
  AlertCircle, Clock, ArrowUpRight, ArrowDownRight,
  Receipt, User, ShieldCheck,
  LayoutDashboard, ListOrdered, Undo2, HandCoins, BarChart3,
  ChevronLeft, Columns3, Eye,
} from "lucide-react";

import {
  paymentsActions,
  selectPayments,
  selectPaymentsStatus,
  selectPaymentsError,
  selectPaymentsTotal,
} from "./paymentsSlice";
import type { Payment, PaymentStatus, PaymentMethod } from "./paymentsSlice";

/* --- COLUMN VISIBILITY --- */
type ColumnKey = "paymentId" | "order" | "customer" | "amount" | "method" | "status" | "date" | "orderStatus";

interface ColumnDef {
  key: ColumnKey;
  label: string;
  defaultVisible: boolean;
  alwaysVisible?: boolean;
}

const COLUMNS: ColumnDef[] = [
  { key: "paymentId", label: "Payment ID", defaultVisible: true, alwaysVisible: true },
  { key: "order", label: "Order", defaultVisible: true },
  { key: "customer", label: "Customer", defaultVisible: true },
  { key: "amount", label: "Amount", defaultVisible: true },
  { key: "method", label: "Method", defaultVisible: true },
  { key: "status", label: "Status", defaultVisible: true },
  { key: "date", label: "Date", defaultVisible: true },
  { key: "orderStatus", label: "Order Status", defaultVisible: false },
];

/* --- TYPES --- */
type ViewType = "dashboard" | "payments" | "refunds" | "settlements" | "cod" | "disputes";

// Debounce hook
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value);
  useEffect(() => {
    const handler = setTimeout(() => setDebouncedValue(value), delay);
    return () => clearTimeout(handler);
  }, [value, delay]);
  return debouncedValue;
}

/* --- MAIN COMPONENT --- */
const PaymentManagement: React.FC = () => {
  const dispatch = useDispatch();

  const payments = useSelector(selectPayments);
  const totalCount = useSelector(selectPaymentsTotal);
  const status = useSelector(selectPaymentsStatus);
  const error = useSelector(selectPaymentsError);

  const [currentView, setCurrentView] = useState<ViewType>("payments");
  const [selectedPayment, setSelectedPayment] = useState<Payment | null>(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState<PaymentStatus | "All">("All");
  const [methodFilter, setMethodFilter] = useState<PaymentMethod | "All">("All");
  const [orderFilter, setOrderFilter] = useState("");
  const [customerFilter, setCustomerFilter] = useState("");
  const [amountMin, setAmountMin] = useState("");
  const [amountMax, setAmountMax] = useState("");
  const [showFilters, setShowFilters] = useState(false);
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(5);
  const debouncedSearch = useDebounce(searchTerm, 500);

  // Column visibility
  const [visibleColumns, setVisibleColumns] = useState<Record<ColumnKey, boolean>>(() => {
    const init: Record<string, boolean> = {};
    COLUMNS.forEach((c) => (init[c.key] = c.defaultVisible));
    return init as Record<ColumnKey, boolean>;
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

  const toggleColumn = (key: ColumnKey) => {
    const col = COLUMNS.find((c) => c.key === key);
    if (col?.alwaysVisible) return;
    setVisibleColumns((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  const isVisible = (key: ColumnKey) => visibleColumns[key];

  useEffect(() => {
    const offset = (page - 1) * limit;
    dispatch(
      paymentsActions.fetchPaymentsRequest({
        q: debouncedSearch || undefined,
        payment_status:
          statusFilter === "All"
            ? undefined
            : statusFilter.toLowerCase(),
        payment_method:
          methodFilter === "All"
            ? undefined
            : methodFilter.toLowerCase(),
        page,
        limit,
        offset,
      })
    );
  }, [dispatch, debouncedSearch, statusFilter, methodFilter, page, limit]);

  const clearFilters = () => {
    setSearchTerm("");
    setStatusFilter("All");
    setMethodFilter("All");
    setOrderFilter("");
    setCustomerFilter("");
    setAmountMin("");
    setAmountMax("");
    setPage(1);
  };

  const hasActiveFilters = !!(searchTerm || statusFilter !== "All" || methodFilter !== "All" || orderFilter || customerFilter || amountMin || amountMax);

  // Client-side filtering for columns not supported by API
  const filteredPayments = useMemo(() => {
    let result = payments;
    if (orderFilter) {
      result = result.filter((p) =>
        p.orderNumber.toLowerCase().includes(orderFilter.toLowerCase())
      );
    }
    if (customerFilter) {
      result = result.filter((p) =>
        p.customerName.toLowerCase().includes(customerFilter.toLowerCase())
      );
    }
    if (amountMin) {
      const min = parseFloat(amountMin);
      if (!isNaN(min)) result = result.filter((p) => p.amount >= min);
    }
    if (amountMax) {
      const max = parseFloat(amountMax);
      if (!isNaN(max)) result = result.filter((p) => p.amount <= max);
    }
    return result;
    return result;
  }, [payments, orderFilter, customerFilter, amountMin, amountMax]);

  // Export handler
  const handleExport = () => {
    const headers = ["Payment ID", "Order", "Customer", "Amount", "Method", "Status", "Date"];
    const rows = filteredPayments.map(p => [
      p.paymentId,
      p.orderNumber,
      p.customerName,
      p.amount,
      p.paymentMethod,
      p.paymentStatus,
      new Date(p.date).toLocaleDateString()
    ]);
    const csvContent = [
      headers.join(","),
      ...rows.map(r => r.map(c => {
        const val = String(c || "");
        return val.includes(',') ? `"${val}"` : val;
      }).join(","))
    ].join("\n");

    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const link = document.createElement("a");
    const url = URL.createObjectURL(blob);
    link.setAttribute("href", url);
    link.setAttribute("download", `payments_export_${new Date().toISOString().split('T')[0]}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  // Stats computed from loaded data
  const totalCollected = filteredPayments
    .filter((p) => p.paymentStatus === "Success")
    .reduce((sum, p) => sum + p.amount, 0);
  const successRate = filteredPayments.length > 0
    ? ((filteredPayments.filter((p) => p.paymentStatus === "Success").length / filteredPayments.length) * 100).toFixed(1)
    : "0";
  const pendingCod = filteredPayments
    .filter((p) => p.paymentMethod === "COD" && p.paymentStatus === "Pending")
    .reduce((sum, p) => sum + p.amount, 0);
  const refundedAmount = filteredPayments
    .filter((p) => p.paymentStatus === "Refunded")
    .reduce((sum, p) => sum + p.amount, 0);

  return (
    <div className="min-h-screen w-full space-y-6 text-[#18181B] bg-[#FDFDFD]">
      {/* --- PAGE HEADER --- */}
      <div>
        <h1 className="text-2xl md:text-3xl font-bold tracking-tight text-black">
          Payments
        </h1>
        <p className="text-[#71717A] text-sm mt-1">
          Track transactions, refunds, and settlements.
        </p>
      </div>

      {/* --- TOP NAVIGATION --- */}
      <nav className="flex items-center gap-1 bg-white p-1.5 border border-[#EEEEEE] rounded-2xl w-fit shadow-sm overflow-x-auto no-scrollbar">
        <NavTab id="dashboard" active={currentView} label="Overview" icon={<LayoutDashboard size={14} />} onClick={setCurrentView} />
        <NavTab id="payments" active={currentView} label="Payments" icon={<ListOrdered size={14} />} onClick={setCurrentView} />
        <NavTab id="refunds" active={currentView} label="Refunds" icon={<Undo2 size={14} />} onClick={setCurrentView} />
        <NavTab id="cod" active={currentView} label="COD" icon={<HandCoins size={14} />} onClick={setCurrentView} />
        <NavTab id="settlements" active={currentView} label="Settlements" icon={<Landmark size={14} />} onClick={setCurrentView} />
        <NavTab id="disputes" active={currentView} label="Disputes" icon={<ShieldCheck size={14} />} onClick={setCurrentView} />
      </nav>

      {/* --- RENDER VIEWS --- */}
      <main className="min-h-[60vh]">
        {currentView === "dashboard" && (
          <DashboardView
            totalCollected={totalCollected}
            successRate={successRate}
            pendingCod={pendingCod}
            refundedAmount={refundedAmount}
            payments={filteredPayments}
          />
        )}

        {currentView === "payments" && (
          <PaymentsListView
            payments={filteredPayments}
            totalCount={totalCount}
            page={page}
            limit={limit}
            onLimitChange={(newLimit) => { setLimit(newLimit); setPage(1); }}
            status={status}
            error={error}
            searchTerm={searchTerm}
            statusFilter={statusFilter}
            methodFilter={methodFilter}
            orderFilter={orderFilter}
            customerFilter={customerFilter}
            amountMin={amountMin}
            amountMax={amountMax}
            showFilters={showFilters}
            hasActiveFilters={hasActiveFilters}
            isVisible={isVisible}
            isColumnsOpen={isColumnsOpen}
            visibleColumns={visibleColumns}
            columnsRef={columnsRef}
            onSearchChange={setSearchTerm}
            onStatusChange={setStatusFilter}
            onMethodChange={setMethodFilter}
            onOrderFilterChange={setOrderFilter}
            onCustomerFilterChange={setCustomerFilter}
            onAmountMinChange={setAmountMin}
            onAmountMaxChange={setAmountMax}
            onToggleFilters={() => setShowFilters(!showFilters)}
            onToggleColumns={() => setIsColumnsOpen(!isColumnsOpen)}
            onToggleColumn={toggleColumn}
            onClearFilters={clearFilters}
            onPageChange={setPage}
            onSelect={setSelectedPayment}
            onExport={handleExport}
          />
        )}

        {currentView === "refunds" && <RefundsView payments={filteredPayments} />}
        {currentView === "cod" && <CODView payments={filteredPayments} />}
        {currentView === "settlements" && <SettlementsView totalCollected={totalCollected} />}
        {currentView === "disputes" && <DisputesView />}
      </main>

      {/* --- PAYMENT DETAIL DRAWER --- */}
      {selectedPayment && (
        <PaymentDetailDrawer
          payment={selectedPayment}
          onClose={() => setSelectedPayment(null)}
        />
      )}
    </div>
  );
};

/* ── 1. DASHBOARD VIEW ── */
const DashboardView = ({
  totalCollected,
  successRate,
  pendingCod,
  refundedAmount,
  payments,
}: {
  totalCollected: number;
  successRate: string;
  pendingCod: number;
  refundedAmount: number;
  payments: Payment[];
}) => {
  const methodCounts = useMemo(() => {
    const total = payments.length || 1;
    const counts: Record<string, number> = {};
    payments.forEach((p) => {
      counts[p.paymentMethod] = (counts[p.paymentMethod] || 0) + 1;
    });
    return Object.entries(counts)
      .map(([method, count]) => ({
        label: method,
        percentage: Math.round((count / total) * 100),
      }))
      .sort((a, b) => b.percentage - a.percentage);
  }, [payments]);

  return (
    <div className="space-y-6 animate-in slide-in-from-bottom-2 duration-500">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard label="Total Collected" value={`AED ${totalCollected.toLocaleString("en-IN")}`} trend="+12.5%" trendType="up" sub="This Month" />
        <StatCard label="Success Rate" value={`${successRate}%`} trend="+0.4%" trendType="up" sub="Gateway health" />
        <StatCard label="Pending COD" value={`AED ${pendingCod.toLocaleString("en-IN")}`} trend="-5.1%" trendType="down" sub="Collection due" />
        <StatCard label="Refunded" value={`AED ${refundedAmount.toLocaleString("en-IN")}`} trend="" trendType="up" sub={`Total ${payments.filter((p) => p.paymentStatus === "Refunded").length} refunds`} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 bg-white border border-[#EEEEEE] rounded-2xl p-6 h-64 flex flex-col justify-center items-center text-gray-400 shadow-sm">
          <BarChart3 size={40} className="mb-2 opacity-20" />
          <p className="text-[10px] font-bold uppercase tracking-widest">Revenue Flow Visualization</p>
          <p className="text-[10px] text-[#D4D4D8] mt-1">Chart coming soon</p>
        </div>
        <div className="bg-white border border-[#EEEEEE] rounded-2xl p-6 h-64 shadow-sm">
          <h4 className="text-[10px] font-bold uppercase tracking-widest text-[#A1A1AA] mb-4">Method Split</h4>
          <div className="space-y-4">
            {methodCounts.length > 0 ? (
              methodCounts.slice(0, 4).map((m) => (
                <MethodBar key={m.label} label={m.label} percentage={m.percentage} color={methodColor(m.label)} />
              ))
            ) : (
              <p className="text-xs text-[#A1A1AA] italic">No data yet</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

/* ── 2. PAYMENTS LIST VIEW ── */
const PaymentsListView = ({
  payments,
  totalCount,
  page,
  status,
  error,
  searchTerm,
  statusFilter,
  methodFilter,
  orderFilter,
  customerFilter,
  amountMin,
  amountMax,
  showFilters,
  hasActiveFilters,
  isVisible,
  isColumnsOpen,
  visibleColumns,
  columnsRef,
  onSearchChange,
  onStatusChange,
  onMethodChange,
  onOrderFilterChange,
  onCustomerFilterChange,
  onAmountMinChange,
  onAmountMaxChange,
  onToggleFilters,
  onToggleColumns,
  onToggleColumn,
  onClearFilters,
  onPageChange,
  onLimitChange,
  limit,
  onSelect,
  onExport,
}: {
  payments: Payment[];
  totalCount: number;
  page: number;
  limit: number;
  onLimitChange: (limit: number) => void;
  status: string;
  error: string | null;
  searchTerm: string;
  statusFilter: PaymentStatus | "All";
  methodFilter: PaymentMethod | "All";
  orderFilter: string;
  customerFilter: string;
  amountMin: string;
  amountMax: string;
  showFilters: boolean;
  hasActiveFilters: boolean;
  isVisible: (key: ColumnKey) => boolean;
  isColumnsOpen: boolean;
  visibleColumns: Record<ColumnKey, boolean>;
  columnsRef: React.RefObject<HTMLDivElement | null>;
  onSearchChange: (v: string) => void;
  onStatusChange: (v: PaymentStatus | "All") => void;
  onMethodChange: (v: PaymentMethod | "All") => void;
  onOrderFilterChange: (v: string) => void;
  onCustomerFilterChange: (v: string) => void;
  onAmountMinChange: (v: string) => void;
  onAmountMaxChange: (v: string) => void;
  onToggleFilters: () => void;
  onToggleColumns: () => void;
  onToggleColumn: (key: ColumnKey) => void;
  onClearFilters: () => void;
  onPageChange: (p: number) => void;
  onSelect: (p: Payment) => void;
  onExport: () => void;
}) => (
  <div className="animate-in fade-in space-y-4">
    <div className="bg-white rounded-2xl border border-[#EEEEEE] shadow-sm overflow-hidden">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center p-4 gap-4 bg-white border-b border-[#EEEEEE]">
        <div className="flex items-center gap-2 w-full sm:w-auto justify-end">
          {hasActiveFilters && (
            <button onClick={onClearFilters} className="px-3 py-1.5 text-[10px] font-bold text-rose-600 hover:bg-rose-50 rounded-lg transition-colors">
              Reset
            </button>
          )}
          <button
            onClick={onToggleFilters}
            className={`flex items-center gap-2 px-4 py-2 border rounded-xl text-xs font-bold transition-all ${showFilters ? "bg-black text-white border-black" : "bg-white text-black border-[#EEEEEE] hover:bg-gray-50"}`}
          >
            <Filter size={14} /> {showFilters ? "Hide" : "Filter"}
          </button>

          {/* Column Visibility Dropdown */}
          <div className="relative" ref={columnsRef}>
            <button
              onClick={onToggleColumns}
              className={`flex items-center gap-2 px-4 py-2 border rounded-xl text-xs font-bold transition-all ${isColumnsOpen ? "bg-black text-white border-black" : "bg-white text-black border-[#EEEEEE] hover:bg-gray-50"}`}
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
                      onChange={() => onToggleColumn(col.key)}
                      className="w-3.5 h-3.5 rounded border-[#D4D4D8] text-black focus:ring-black/20 accent-black"
                    />
                    <span className="text-xs font-medium text-[#52525B]">{col.label}</span>
                  </label>
                ))}
              </div>
            )}
          </div>

          <button
            onClick={onExport}
            className="flex items-center gap-2 px-4 py-2 bg-white border border-[#EEEEEE] rounded-xl text-xs font-bold hover:bg-[#FAFAFA] transition-colors"
          >
            <Download size={14} /> Export
          </button>
        </div>
      </div>

      {/* Loading / Error */}
      {status === "loading" && payments.length === 0 && (
        <div className="p-6 text-sm text-[#71717A]">Loading transactions…</div>
      )}
      {status === "failed" && (
        <div className="p-6 text-sm text-rose-600">{error || "Failed to load payments"}</div>
      )}

      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse min-w-[900px]">
          <thead>
            <tr className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest bg-[#FAFAFA] border-b border-[#EEEEEE]">
              {isVisible("paymentId") && <th className="px-5 py-4">Payment ID</th>}
              {isVisible("order") && <th className="px-5 py-4">Order</th>}
              {isVisible("customer") && <th className="px-5 py-4">Customer</th>}
              {isVisible("amount") && <th className="px-5 py-4">Amount</th>}
              {isVisible("method") && <th className="px-5 py-4">Method</th>}
              {isVisible("status") && <th className="px-5 py-4">Status</th>}
              {isVisible("date") && <th className="px-5 py-4">Date</th>}
              {isVisible("orderStatus") && <th className="px-5 py-4">Order Status</th>}
              <th className="px-5 py-4 text-right">Detail</th>
            </tr>

            {showFilters && (
              <tr className="bg-white border-b border-[#EEEEEE] animate-in slide-in-from-top-1 duration-200">
                {isVisible("paymentId") && (
                  <td className="px-4 py-3">
                    <div className="relative">
                      <Search className="absolute left-2 top-1/2 -translate-y-1/2 text-[#A1A1AA]" size={12} />
                      <input
                        type="text"
                        placeholder="Search ID..."
                        value={searchTerm}
                        onChange={(e) => onSearchChange(e.target.value)}
                        className="w-full pl-7 pr-2 py-1.5 bg-[#F9F9F9] border border-transparent rounded-lg text-[11px] outline-none focus:bg-white focus:border-[#EEEEEE] font-medium"
                      />
                    </div>
                  </td>
                )}
                {isVisible("order") && (
                  <td className="px-4 py-3">
                    <input
                      type="text"
                      placeholder="Order..."
                      value={orderFilter}
                      onChange={(e) => onOrderFilterChange(e.target.value)}
                      className="w-full p-1.5 bg-[#F9F9F9] border border-transparent rounded-lg text-[11px] outline-none focus:bg-white focus:border-[#EEEEEE] font-medium"
                    />
                  </td>
                )}
                {isVisible("customer") && (
                  <td className="px-4 py-3">
                    <input
                      type="text"
                      placeholder="Customer..."
                      value={customerFilter}
                      onChange={(e) => onCustomerFilterChange(e.target.value)}
                      className="w-full p-1.5 bg-[#F9F9F9] border border-transparent rounded-lg text-[11px] outline-none focus:bg-white focus:border-[#EEEEEE] font-medium"
                    />
                  </td>
                )}
                {isVisible("amount") && (
                  <td className="px-4 py-3">
                    <div className="flex gap-1">
                      <input type="number" placeholder="Min" value={amountMin} onChange={(e) => onAmountMinChange(e.target.value)} className="w-1/2 p-1.5 bg-[#F9F9F9] border border-transparent rounded-lg text-[11px] outline-none focus:bg-white focus:border-[#EEEEEE] font-medium" />
                      <input type="number" placeholder="Max" value={amountMax} onChange={(e) => onAmountMaxChange(e.target.value)} className="w-1/2 p-1.5 bg-[#F9F9F9] border border-transparent rounded-lg text-[11px] outline-none focus:bg-white focus:border-[#EEEEEE] font-medium" />
                    </div>
                  </td>
                )}
                {isVisible("method") && (
                  <td className="px-4 py-3">
                    <select
                      value={methodFilter}
                      onChange={(e) => onMethodChange(e.target.value as PaymentMethod | "All")}
                      className="w-full p-1.5 bg-[#F9F9F9] border border-transparent rounded-lg text-[11px] outline-none cursor-pointer focus:bg-white focus:border-[#EEEEEE] font-medium"
                    >
                      <option value="All">All Methods</option>
                      <option value="UPI">UPI</option>
                      <option value="Card">Card</option>
                      <option value="COD">COD</option>
                      <option value="NetBanking">NetBanking</option>
                      <option value="Wallet">Wallet</option>
                    </select>
                  </td>
                )}
                {isVisible("status") && (
                  <td className="px-4 py-3">
                    <select
                      value={statusFilter}
                      onChange={(e) => onStatusChange(e.target.value as PaymentStatus | "All")}
                      className="w-full p-1.5 bg-[#F9F9F9] border border-transparent rounded-lg text-[11px] outline-none cursor-pointer focus:bg-white focus:border-[#EEEEEE] font-medium"
                    >
                      <option value="All">All Status</option>
                      <option value="Success">Success</option>
                      <option value="Pending">Pending</option>
                      <option value="Failed">Failed</option>
                      <option value="Refunded">Refunded</option>
                    </select>
                  </td>
                )}
                {isVisible("date") && (
                  <td className="px-4 py-3"><div className="text-[10px] text-[#A1A1AA] italic">—</div></td>
                )}
                {isVisible("orderStatus") && (
                  <td className="px-4 py-3"><div className="text-[10px] text-[#A1A1AA] italic">—</div></td>
                )}
                <td className="px-4 py-3 text-right">
                  <button onClick={onClearFilters} className="text-[10px] font-bold text-rose-500 hover:underline px-2">Clear</button>
                </td>
              </tr>
            )}
          </thead>
          <tbody className="divide-y divide-[#EEEEEE]">
            {status === "loading" && payments.length === 0
              ? Array.from({ length: 5 }).map((_, i) => (
                <tr key={i} className="animate-pulse">
                  <td className="px-5 py-4"><div className="h-4 w-20 bg-gray-100 rounded" /></td>
                  <td className="px-5 py-4"><div className="h-4 w-16 bg-gray-100 rounded" /></td>
                  <td className="px-5 py-4"><div className="h-4 w-24 bg-gray-100 rounded" /></td>
                  <td className="px-5 py-4"><div className="h-4 w-16 bg-gray-100 rounded" /></td>
                  <td className="px-5 py-4"><div className="h-4 w-12 bg-gray-100 rounded" /></td>
                  <td className="px-5 py-4"><div className="h-6 w-16 bg-gray-100 rounded-full" /></td>
                  <td className="px-5 py-4"><div className="h-6 w-6 bg-gray-100 rounded ml-auto" /></td>
                </tr>
              ))
              : payments.map((p) => (
                <tr
                  key={p.id}
                  className="group hover:bg-[#FBFBFA] transition-colors cursor-pointer"
                  onClick={() => onSelect(p)}
                >
                  {isVisible("paymentId") && (
                    <td className="px-5 py-4">
                      <p className="text-xs font-bold">{p.paymentId}</p>
                    </td>
                  )}
                  {isVisible("order") && (
                    <td className="px-5 py-4 text-xs font-mono font-bold text-blue-600">
                      {p.orderNumber}
                    </td>
                  )}
                  {isVisible("customer") && (
                    <td className="px-5 py-4">
                      <p className="text-xs font-bold">{p.customerName}</p>
                      {p.customerEmail && <p className="text-[10px] text-[#A1A1AA]">{p.customerEmail}</p>}
                    </td>
                  )}
                  {isVisible("amount") && (
                    <td className="px-5 py-4 font-mono text-sm font-bold">
                      AED {p.amount.toLocaleString("en-IN")}
                    </td>
                  )}
                  {isVisible("method") && (
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-1.5 text-[10px] font-bold text-[#71717A]">
                        <MethodIcon method={p.paymentMethod} />
                        {p.paymentMethod}
                      </div>
                    </td>
                  )}
                  {isVisible("status") && (
                    <td className="px-5 py-4">
                      <PaymentStatusBadge status={p.paymentStatus} />
                    </td>
                  )}
                  {isVisible("date") && (
                    <td className="px-5 py-4">
                      <p className="text-[11px] text-[#52525B] font-medium">
                        {new Date(p.date).toLocaleDateString("en-IN", {
                          day: "2-digit",
                          month: "short",
                          year: "numeric",
                        })}
                      </p>
                    </td>
                  )}
                  {isVisible("orderStatus") && (
                    <td className="px-5 py-4">
                      <span className="text-[10px] font-bold px-2.5 py-1 rounded-full uppercase border bg-slate-50 text-slate-600 border-slate-100">
                        {p.orderStatus || "—"}
                      </span>
                    </td>
                  )}
                  <td className="px-5 py-4 text-right">
                    <button
                      className="p-2 text-[#A1A1AA] hover:text-black hover:bg-[#F4F4F5] rounded-lg transition-all inline-block"
                      title="View Details"
                    >
                      <Eye size={16} />
                    </button>
                  </td>
                </tr>
              ))}
          </tbody>
        </table>

        {status !== "loading" && payments.length === 0 && (
          <div className="py-20 text-center space-y-3">
            <CreditCard className="mx-auto text-[#D4D4D8]" size={32} />
            <p className="text-sm font-bold text-[#18181B]">No transactions found</p>
            <p className="text-xs text-[#A1A1AA]">Payments will appear here as orders are placed.</p>
            <button onClick={onClearFilters} className="text-xs font-bold underline text-[#A1A1AA] hover:text-black">
              Reset all filters
            </button>
          </div>
        )}
      </div>

      {/* Pagination */}
      <div className="p-4 border-t border-[#EEEEEE] flex items-center justify-between bg-white">
        <div className="flex items-center gap-4">
          <div className="text-[11px] text-[#A1A1AA] font-medium">
            Showing {payments.length} of {totalCount} transactions
          </div>
          <select
            value={limit}
            onChange={(e) => onLimitChange(Number(e.target.value))}
            className="p-1.5 bg-[#F9F9F9] border border-[#EEEEEE] rounded-lg text-xs outline-none focus:border-[#D4D4D8]"
          >
            <option value={5}>5 / page</option>
            <option value={10}>10 / page</option>
            <option value={20}>20 / page</option>
            <option value={50}>50 / page</option>
          </select>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => onPageChange(Math.max(1, page - 1))}
            disabled={page === 1 || status === "loading"}
            className="p-2 border border-[#EEEEEE] rounded-lg hover:bg-[#FAFAFA] disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            <ChevronLeft size={14} />
          </button>
          <span className="text-xs font-bold px-2">Page {page}</span>
          <button
            onClick={() => onPageChange(page + 1)}
            disabled={payments.length < limit || status === "loading"}
            className="p-2 border border-[#EEEEEE] rounded-lg hover:bg-[#FAFAFA] disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            <ChevronRight size={14} />
          </button>
        </div>
      </div>
    </div>
  </div>
);

/* ── 3. PAYMENT DETAIL DRAWER ── */
const PaymentDetailDrawer = ({
  payment,
  onClose,
}: {
  payment: Payment;
  onClose: () => void;
}) => {
  const [activeTab, setActiveTab] = useState<"summary" | "timeline" | "refund">("summary");

  return (
    <>
      <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 transition-opacity" onClick={onClose} />
      <div className="fixed inset-y-0 right-0 w-full max-w-xl bg-white z-[60] shadow-2xl flex flex-col animate-in slide-in-from-right duration-300">
        {/* Header */}
        <div className="p-6 border-b flex justify-between items-center bg-[#FAFAFA]">
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-xl font-bold">{payment.paymentId}</h2>
              <PaymentStatusBadge status={payment.paymentStatus} />
            </div>
            <p className="text-xs text-[#71717A] mt-1 flex items-center gap-1">
              <Clock size={12} />
              {new Date(payment.date).toLocaleDateString("en-IN", {
                day: "2-digit",
                month: "short",
                year: "numeric",
                hour: "2-digit",
                minute: "2-digit",
              })}
            </p>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-white border border-[#EEEEEE] rounded-full transition-colors shadow-sm">
            <X size={20} />
          </button>
        </div>

        {/* Detail Tabs */}
        <div className="flex px-6 border-b bg-white sticky top-0">
          {(["summary", "timeline", "refund"] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-4 py-4 text-[10px] font-bold uppercase tracking-widest border-b-2 transition-all ${activeTab === tab
                ? "border-black text-black"
                : "border-transparent text-[#A1A1AA] hover:text-black"
                }`}
            >
              {tab}
            </button>
          ))}
        </div>

        <div className="flex-1 overflow-y-auto p-8 space-y-8 no-scrollbar">
          {activeTab === "summary" && (
            <div className="space-y-8 animate-in fade-in duration-300">
              <div className="grid grid-cols-2 gap-4">
                <DetailBox label="Order Total" value={`AED ${payment.amount.toLocaleString("en-IN")}`} icon={<Receipt size={14} />} />
                <DetailBox label="Payment Method" value={payment.paymentMethod} icon={<Wallet size={14} />} />
                <DetailBox label="Order" value={payment.orderNumber} icon={<Landmark size={14} />} />
                <DetailBox label="Customer" value={`${payment.customerName}`} icon={<User size={14} />} />
              </div>

              <div className="space-y-4">
                <h4 className="text-[10px] font-bold uppercase text-[#A1A1AA] tracking-widest">Settlement Breakdown</h4>
                <div className="p-4 bg-[#F9F9F9] rounded-xl space-y-3 border border-[#EEEEEE]">
                  <div className="flex justify-between text-xs">
                    <span className="text-[#71717A]">Base Amount</span>
                    <span className="font-bold font-mono">AED {(payment.amount * 0.9524).toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between text-xs">
                    <span className="text-[#71717A]">Gateway Fee (~2%)</span>
                    <span className="font-bold font-mono">AED {(payment.amount * 0.02).toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between text-xs border-t pt-3 border-gray-200">
                    <span className="text-[#71717A]">Net Settlement</span>
                    <span className="font-bold font-mono text-emerald-600">AED {(payment.amount * 0.98).toFixed(2)}</span>
                  </div>
                </div>
              </div>
            </div>
          )}

          {activeTab === "timeline" && (
            <div className="space-y-6 animate-in fade-in duration-300">
              <TimelineItem time={new Date(payment.date).toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit", second: "2-digit" })} title="Payment Captured" desc="Successfully processed" status="success" />
              <TimelineItem time="—" title="Payment Authorized" desc="User completed verification" status="success" />
              <TimelineItem time="—" title="Payment Created" desc="Transaction initiated from Checkout" status="success" />
            </div>
          )}

          {activeTab === "refund" && (
            <div className="space-y-6 animate-in fade-in duration-300">
              <div className="bg-rose-50 border border-rose-100 p-4 rounded-xl flex items-start gap-3 shadow-sm">
                <AlertCircle size={18} className="text-rose-600 shrink-0" />
                <p className="text-xs text-rose-800 leading-relaxed font-medium">
                  Refunds typically take 5-7 business days to reflect in the customer's bank account after initiation.
                </p>
              </div>
              <div className="space-y-4">
                <div className="flex flex-col gap-1">
                  <label className="text-[10px] font-bold uppercase text-[#A1A1AA]">Refund Amount</label>
                  <input type="text" placeholder={`Max AED ${payment.amount.toLocaleString("en-IN")}`} className="w-full p-3 border rounded-xl text-sm font-bold focus:ring-1 focus:ring-black outline-none transition-all shadow-sm" />
                </div>
                <button className="w-full py-4 bg-rose-600 text-white rounded-xl text-xs font-bold hover:bg-rose-700 transition-all flex items-center justify-center gap-2 shadow-lg shadow-rose-100">
                  <RefreshCcw size={14} /> Initiate Refund
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="p-6 border-t bg-[#FAFAFA] flex gap-3">
          <button className="flex-1 py-3 bg-white border border-[#EEEEEE] rounded-xl text-xs font-bold hover:bg-gray-50 flex items-center justify-center gap-2 transition-all shadow-sm">
            <Download size={14} /> Receipt
          </button>
          <button className="flex-1 py-3 bg-black text-white rounded-xl text-xs font-bold hover:bg-[#222] flex items-center justify-center gap-2 transition-all shadow-md">
            View Order
          </button>
        </div>
      </div>
    </>
  );
};

/* ── SUB-VIEWS ── */
const CODView = ({ payments }: { payments: Payment[] }) => {
  const codPayments = payments.filter((p) => p.paymentMethod === "COD");
  return (
    <div className="bg-white rounded-2xl border border-[#EEEEEE] shadow-sm overflow-hidden animate-in fade-in">
      <table className="w-full text-left">
        <thead className="bg-[#FAFAFA] border-b border-[#EEEEEE]">
          <tr className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest">
            <th className="px-6 py-4">Order</th>
            <th className="px-6 py-4">Customer</th>
            <th className="px-6 py-4">Amount</th>
            <th className="px-6 py-4">Status</th>
            <th className="px-6 py-4 text-right">Action</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-[#EEEEEE]">
          {codPayments.length > 0 ? (
            codPayments.map((p) => (
              <tr key={p.id} className="text-sm group hover:bg-[#FAFAFA] transition-colors">
                <td className="px-6 py-4 font-mono text-xs font-bold">{p.orderNumber}</td>
                <td className="px-6 py-4 text-xs">{p.customerName}</td>
                <td className="px-6 py-4 font-mono font-bold">AED {p.amount.toLocaleString("en-IN")}</td>
                <td className="px-6 py-4"><PaymentStatusBadge status={p.paymentStatus} /></td>
                <td className="px-6 py-4 text-right">
                  <button className="px-4 py-1.5 bg-black text-white rounded-lg text-[10px] font-bold shadow-sm">Mark Collected</button>
                </td>
              </tr>
            ))
          ) : (
            <tr>
              <td colSpan={5} className="px-6 py-12 text-center text-xs text-[#A1A1AA]">No COD orders found</td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
};

const RefundsView = ({ payments }: { payments: Payment[] }) => {
  const refunded = payments.filter((p) => p.paymentStatus === "Refunded");
  return (
    <div className="bg-white rounded-2xl border border-[#EEEEEE] shadow-sm overflow-hidden animate-in fade-in">
      <table className="w-full text-left">
        <thead className="bg-[#FAFAFA] border-b border-[#EEEEEE]">
          <tr className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest">
            <th className="px-6 py-4">Payment ID</th>
            <th className="px-6 py-4">Order</th>
            <th className="px-6 py-4">Amount</th>
            <th className="px-6 py-4">Status</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-[#EEEEEE]">
          {refunded.length > 0 ? (
            refunded.map((p) => (
              <tr key={p.id} className="text-sm group hover:bg-[#FAFAFA] transition-colors">
                <td className="px-6 py-4 font-mono text-xs font-bold">{p.paymentId}</td>
                <td className="px-6 py-4 font-mono text-xs text-blue-600 font-bold">{p.orderNumber}</td>
                <td className="px-6 py-4 font-bold text-rose-600">AED {p.amount.toLocaleString("en-IN")}</td>
                <td className="px-6 py-4"><PaymentStatusBadge status={p.paymentStatus} /></td>
              </tr>
            ))
          ) : (
            <tr>
              <td colSpan={4} className="px-6 py-12 text-center text-xs text-[#A1A1AA]">No refunds found</td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
};

const SettlementsView = ({ totalCollected }: { totalCollected: number }) => (
  <div className="grid grid-cols-1 md:grid-cols-3 gap-4 animate-in fade-in">
    <div className="p-6 bg-white border border-[#EEEEEE] rounded-2xl shadow-sm">
      <p className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest">Next Payout</p>
      <h4 className="text-2xl font-bold mt-1">AED {(totalCollected * 0.3).toLocaleString("en-IN", { minimumFractionDigits: 2 })}</h4>
      <p className="text-[10px] text-[#A1A1AA] mt-2">Scheduled estimate</p>
    </div>
    <div className="p-6 bg-white border border-[#EEEEEE] rounded-2xl shadow-sm">
      <p className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest">Last Settlement</p>
      <h4 className="text-2xl font-bold mt-1">AED {(totalCollected * 0.7).toLocaleString("en-IN", { minimumFractionDigits: 2 })}</h4>
      <p className="text-[10px] text-emerald-600 font-bold mt-2 flex items-center gap-1"><CheckCircle2 size={10} /> Processed</p>
    </div>
    <div className="p-6 bg-white border border-[#EEEEEE] rounded-2xl shadow-sm">
      <p className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest">Total Settled</p>
      <h4 className="text-2xl font-bold mt-1">AED {totalCollected.toLocaleString("en-IN", { minimumFractionDigits: 2 })}</h4>
      <p className="text-[10px] text-[#A1A1AA] mt-2">All time</p>
    </div>
  </div>
);

const DisputesView = () => (
  <div className="bg-white p-12 border border-[#EEEEEE] rounded-2xl shadow-sm text-center space-y-4 animate-in fade-in">
    <div className="w-20 h-20 bg-emerald-50 text-emerald-600 rounded-full flex items-center justify-center mx-auto shadow-inner">
      <ShieldCheck size={40} />
    </div>
    <h3 className="text-xl font-bold">All clear!</h3>
    <p className="text-sm text-[#71717A] max-w-xs mx-auto">
      There are no open customer disputes or chargebacks at this moment.
    </p>
  </div>
);

/* ── HELPER COMPONENTS ── */
const NavTab = ({ id, active, label, icon, onClick }: any) => (
  <button
    onClick={() => onClick(id)}
    className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all whitespace-nowrap ${active === id
      ? "bg-black text-white shadow-md"
      : "text-[#71717A] hover:bg-[#F4F4F5] hover:text-black"
      }`}
  >
    {icon} {label}
  </button>
);

const StatCard = ({ label, value, trend, trendType, sub }: any) => (
  <div className="bg-white border border-[#EEEEEE] rounded-2xl p-5 shadow-sm hover:shadow-md transition-shadow">
    <p className="text-[10px] font-bold uppercase text-[#A1A1AA] tracking-widest">{label}</p>
    <div className="flex items-baseline gap-2 mt-1">
      <h3 className="text-2xl font-bold">{value}</h3>
      {trend && (
        <span className={`text-[10px] font-bold flex items-center gap-0.5 ${trendType === "up" ? "text-emerald-600" : "text-rose-600"}`}>
          {trendType === "up" ? <ArrowUpRight size={10} /> : <ArrowDownRight size={10} />} {trend}
        </span>
      )}
    </div>
    <p className="text-[10px] text-[#A1A1AA] mt-1 font-medium">{sub}</p>
  </div>
);

const MethodBar = ({ label, percentage, color }: { label: string; percentage: number; color: string }) => (
  <div className="space-y-1">
    <div className="flex justify-between text-[10px] font-bold">
      <span>{label}</span>
      <span className="text-[#71717A]">{percentage}%</span>
    </div>
    <div className="w-full h-1.5 bg-gray-100 rounded-full overflow-hidden shadow-inner">
      <div className={`h-full ${color} transition-all duration-1000`} style={{ width: `${percentage}%` }} />
    </div>
  </div>
);

function methodColor(method: string): string {
  const colors: Record<string, string> = {
    UPI: "bg-emerald-500",
    Card: "bg-blue-500",
    COD: "bg-amber-500",
    NetBanking: "bg-slate-400",
    Wallet: "bg-violet-500",
    "N/A": "bg-gray-300",
  };
  return colors[method] ?? "bg-gray-300";
}

const MethodIcon = ({ method }: { method: PaymentMethod }) => {
  if (method === "UPI") return <Landmark size={12} />;
  if (method === "COD") return <Banknote size={12} />;
  if (method === "Wallet") return <Wallet size={12} />;
  return <CreditCard size={12} />;
};

const PaymentStatusBadge = ({ status }: { status: PaymentStatus }) => {
  const styles: Record<PaymentStatus, string> = {
    Success: "bg-emerald-50 text-emerald-600 border-emerald-100",
    Failed: "bg-rose-50 text-rose-600 border-rose-100",
    Pending: "bg-amber-50 text-amber-600 border-amber-100",
    Refunded: "bg-violet-50 text-violet-600 border-violet-100",
  };
  return (
    <span className={`text-[9px] font-bold px-2.5 py-1 rounded-full uppercase border shadow-sm ${styles[status]}`}>
      {status}
    </span>
  );
};

const TimelineItem = ({ time, title, desc, status }: any) => (
  <div className="flex gap-4">
    <div className="flex flex-col items-center">
      <div className={`w-2.5 h-2.5 rounded-full mt-1.5 ring-4 ring-white shadow-sm ${status === "success" ? "bg-emerald-500" : "bg-gray-300"}`} />
      <div className="w-px h-full bg-gray-100 mt-1" />
    </div>
    <div className="pb-8">
      <p className="text-[10px] font-mono text-[#A1A1AA] font-bold">{time}</p>
      <p className="text-sm font-bold text-[#18181B]">{title}</p>
      <p className="text-xs text-[#71717A] mt-1 leading-relaxed">{desc}</p>
    </div>
  </div>
);

const DetailBox = ({ label, value, icon }: any) => (
  <div className="p-4 border border-[#EEEEEE] rounded-xl space-y-1.5 shadow-sm bg-white hover:border-gray-300 transition-colors">
    <div className="flex items-center gap-1.5 text-[#A1A1AA] font-bold uppercase tracking-widest text-[9px]">
      {icon} <span>{label}</span>
    </div>
    <p className="text-sm font-bold truncate text-[#18181B]">{value}</p>
  </div>
);

export default PaymentManagement;