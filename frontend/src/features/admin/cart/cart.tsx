import React, { useEffect, useState, useMemo, useRef } from "react";
import { useDispatch, useSelector } from "react-redux";
import {
  ShoppingCart,
  Search,
  RefreshCcw,
  ChevronLeft,
  ChevronRight,
  Download,
  ShoppingBag,
  X,
  Columns3,
  PackageX,
} from "lucide-react";
import {
  adminCartsActions,
  selectAdminCarts,
  selectAdminCartsStatus,
  selectAdminCartsError,
  selectAdminCartsTotal,
} from "./cartSlice";
import type { AdminCart, AdminCartItem } from "./cartSlice";

/* ── Helpers ── */
const formatCurrency = (amount: number) =>
  new Intl.NumberFormat("en-AE", { style: "currency", currency: "AED" }).format(amount);

const formatTimeAgo = (dateString: string) => {
  const diffMs = Date.now() - new Date(dateString).getTime();
  const mins = Math.floor(diffMs / 60000);
  if (mins < 1) return "Just now";
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  return `${Math.floor(hours / 24)}d ago`;
};

const getCartStatus = (updatedAt: string): "Active" | "Abandoned" => {
  const diffHours = (Date.now() - new Date(updatedAt).getTime()) / 3600000;
  return diffHours < 1 ? "Active" : "Abandoned";
};

/* ── Debounce ── */
function useDebounce<T>(value: T, delay: number): T {
  const [dv, setDv] = useState(value);
  useEffect(() => {
    const t = setTimeout(() => setDv(value), delay);
    return () => clearTimeout(t);
  }, [value, delay]);
  return dv;
}

/* ── Column config ── */
type ColumnKey = "index" | "cartId" | "customer" | "items" | "total" | "status" | "updated";

interface ColumnDef {
  key: ColumnKey;
  label: string;
  defaultVisible: boolean;
  alwaysVisible?: boolean;
}

const COLUMNS: ColumnDef[] = [
  { key: "index", label: "#", defaultVisible: true, alwaysVisible: true },
  { key: "cartId", label: "Cart ID", defaultVisible: true, alwaysVisible: true },
  { key: "customer", label: "Customer", defaultVisible: true },
  { key: "items", label: "Items", defaultVisible: true },
  { key: "total", label: "Total", defaultVisible: true },
  { key: "status", label: "Status", defaultVisible: true },
  { key: "updated", label: "Last seen", defaultVisible: true },
];

/* ══════════════════════════════════════════
   MAIN COMPONENT
══════════════════════════════════════════ */
const CartManagement: React.FC = () => {
  const dispatch = useDispatch();
  const carts = useSelector(selectAdminCarts);
  const totalCount = useSelector(selectAdminCartsTotal);
  const status = useSelector(selectAdminCartsStatus);
  const error = useSelector(selectAdminCartsError);

  /* --- Filters --- */
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState<"All" | "Active" | "Abandoned">("All");
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(5);
  const debouncedSearch = useDebounce(searchTerm, 500);

  /* --- Column visibility --- */
  const [visibleColumns, setVisibleColumns] = useState<Record<ColumnKey, boolean>>(() => {
    const init: Record<string, boolean> = {};
    COLUMNS.forEach(c => (init[c.key] = c.defaultVisible));
    return init as Record<ColumnKey, boolean>;
  });
  const [isColumnsOpen, setIsColumnsOpen] = useState(false);
  const columnsRef = useRef<HTMLDivElement>(null);

  /* --- Detail drawer --- */
  const [selectedCart, setSelectedCart] = useState<AdminCart | null>(null);

  /* --- Outside click for columns dropdown --- */
  useEffect(() => {
    const h = (e: MouseEvent) => {
      if (columnsRef.current && !columnsRef.current.contains(e.target as Node))
        setIsColumnsOpen(false);
    };
    document.addEventListener("mousedown", h);
    return () => document.removeEventListener("mousedown", h);
  }, []);

  const toggleColumn = (key: ColumnKey) => {
    const col = COLUMNS.find(c => c.key === key);
    if (col?.alwaysVisible) return;
    setVisibleColumns(prev => ({ ...prev, [key]: !prev[key] }));
  };

  const isVisible = (key: ColumnKey) => visibleColumns[key];

  /* --- Fetch --- */
  useEffect(() => {
    const offset = (page - 1) * limit;
    dispatch(
      adminCartsActions.fetchCartsRequest({
        q: debouncedSearch || undefined,
        page,
        limit,
        offset,
      })
    );
  }, [dispatch, debouncedSearch, page, limit]);

  const handleReset = () => {
    setSearchTerm("");
    setStatusFilter("All");
    setPage(1);
  };

  /* --- Client-side status filter (status not sent to API) --- */
  const filteredCarts = useMemo(() => {
    if (statusFilter === "All") return carts;
    return carts.filter(c => getCartStatus(c.updatedAt) === statusFilter);
  }, [carts, statusFilter]);

  /* --- Stats --- */
  const stats = useMemo(() => {
    const all = carts;
    const activeCount = all.filter(c => getCartStatus(c.updatedAt) === "Active").length;
    const abandonedCarts = all.filter(c => getCartStatus(c.updatedAt) === "Abandoned");
    const recoveryVal = abandonedCarts.reduce((s, c) => s + c.totalPrice, 0);
    const abandonedRate = all.length > 0
      ? ((abandonedCarts.length / all.length) * 100).toFixed(1) + "%"
      : "0%";
    return { total: totalCount, activeCount, abandonedRate, recoveryVal };
  }, [carts, totalCount]);

  /* --- Export CSV --- */
  const handleExport = () => {
    const headers = ["Cart ID", "User ID", "Items", "Total (AED)", "Status", "Last Updated"];
    const rows = filteredCarts.map(c => [
      `CRT-${c.id}`,
      c.userId,
      c.totalItems,
      c.totalPrice.toFixed(2),
      getCartStatus(c.updatedAt),
      new Date(c.updatedAt).toLocaleDateString(),
    ]);
    const csv = [headers, ...rows].map(r => r.join(",")).join("\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `carts_export_${new Date().toISOString().split("T")[0]}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  return (
    <div className="min-h-screen w-full space-y-6 text-[#18181B] bg-[#FDFDFD]">

      {/* ── PAGE HEADER ── */}
      <div>
        <h1 className="text-2xl md:text-3xl font-bold tracking-tight text-black">Cart Management</h1>
        <p className="text-[#71717A] text-sm mt-1">Monitor active sessions and recover abandoned carts.</p>
      </div>

      {/* ── STAT CARDS ── */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: "Total Carts", value: stats.total.toString(), sub: "All loaded" },
          { label: "Active Carts", value: stats.activeCount.toString(), sub: "Within 1 hour" },
          { label: "Abandoned Rate", value: stats.abandonedRate, sub: "Inactive > 1hr" },
          { label: "Recovery Potential", value: formatCurrency(stats.recoveryVal), sub: "In abandoned carts" },
        ].map((s, i) => (
          <div key={i} className="p-5 bg-white border border-[#EEEEEE] rounded-2xl shadow-sm hover:border-[#D4D4D8] transition-colors">
            <p className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest">{s.label}</p>
            <h3 className="text-2xl font-bold mt-1 tracking-tight">{s.value}</h3>
            <p className="text-[11px] text-emerald-600 font-medium mt-1">{s.sub}</p>
          </div>
        ))}
      </div>

      {/* ── TABLE CARD ── */}
      <div className="bg-white rounded-2xl border border-[#EEEEEE] shadow-sm overflow-hidden">

        {/* Toolbar */}
        <div className="p-4 border-b border-[#EEEEEE] flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-white">

          {/* Left: search + status tabs */}
          <div className="flex items-center gap-2 w-full sm:w-auto">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-[#A1A1AA]" size={13} />
              <input
                type="text"
                placeholder="Search by user ID…"
                value={searchTerm}
                onChange={e => { setSearchTerm(e.target.value); setPage(1); }}
                className="pl-8 pr-3 py-2 bg-[#F9F9F9] border border-transparent rounded-xl text-xs outline-none focus:bg-white focus:border-[#EEEEEE] w-56 font-medium"
              />
            </div>
            {(["All", "Active", "Abandoned"] as const).map(s => (
              <button
                key={s}
                onClick={() => { setStatusFilter(s); setPage(1); }}
                className={`px-3 py-1.5 text-[11px] font-bold rounded-lg border transition-all ${statusFilter === s
                    ? "bg-black text-white border-black"
                    : "bg-white text-[#71717A] border-[#EEEEEE] hover:bg-[#FAFAFA]"
                  }`}
              >
                {s}
              </button>
            ))}
          </div>

          {/* Right: actions */}
          <div className="flex items-center gap-2">
            {(searchTerm || statusFilter !== "All") && (
              <button
                onClick={handleReset}
                className="px-3 py-1.5 text-[10px] font-bold text-rose-600 hover:bg-rose-50 rounded-lg transition-colors"
              >
                Reset
              </button>
            )}

            {/* Column picker */}
            <div className="relative" ref={columnsRef}>
              <button
                onClick={() => setIsColumnsOpen(!isColumnsOpen)}
                className={`flex items-center gap-2 px-4 py-2 border rounded-xl text-xs font-bold transition-all ${isColumnsOpen ? "bg-black text-white border-black" : "bg-white text-black border-[#EEEEEE] hover:bg-gray-50"
                  }`}
              >
                <Columns3 size={14} /> Columns
              </button>
              {isColumnsOpen && (
                <div className="absolute right-0 top-full mt-2 w-52 bg-white rounded-xl border border-[#EEEEEE] shadow-xl z-50 py-2 animate-in fade-in slide-in-from-top-1 duration-150">
                  <p className="px-4 py-2 text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest border-b border-[#EEEEEE]">
                    Toggle Columns
                  </p>
                  {COLUMNS.filter(c => !c.alwaysVisible).map(col => (
                    <label key={col.key} className="flex items-center gap-3 px-4 py-2 hover:bg-[#FAFAFA] cursor-pointer transition-colors">
                      <input
                        type="checkbox"
                        checked={visibleColumns[col.key]}
                        onChange={() => toggleColumn(col.key)}
                        className="w-3.5 h-3.5 rounded border-[#D4D4D8] accent-black"
                      />
                      <span className="text-xs font-medium text-[#52525B]">{col.label}</span>
                    </label>
                  ))}
                </div>
              )}
            </div>

            <button
              onClick={() => dispatch(adminCartsActions.fetchCartsRequest({ page, limit }))}
              className="flex items-center gap-2 px-4 py-2 bg-white border border-[#EEEEEE] rounded-xl text-xs font-bold hover:bg-[#FAFAFA] transition-colors"
            >
              <RefreshCcw size={13} className={status === "loading" ? "animate-spin" : ""} /> Refresh
            </button>
            <button
              onClick={handleExport}
              className="flex items-center gap-2 px-4 py-2 bg-white border border-[#EEEEEE] rounded-xl text-xs font-bold hover:bg-[#FAFAFA] transition-colors"
            >
              <Download size={14} /> Export
            </button>
          </div>
        </div>

        {/* Error */}
        {status === "failed" && (
          <div className="p-4 text-sm text-rose-600 border-b border-[#EEEEEE]">
            {error || "Failed to load carts."}
          </div>
        )}

        {/* Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[640px]">
            <thead>
              <tr className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest bg-[#FAFAFA] border-b border-[#EEEEEE]">
                {isVisible("index") && <th className="px-5 py-4 w-12 text-center">#</th>}
                {isVisible("cartId") && <th className="px-5 py-4">Cart ID</th>}
                {isVisible("customer") && <th className="px-5 py-4">Customer</th>}
                {isVisible("items") && <th className="px-5 py-4">Items</th>}
                {isVisible("total") && <th className="px-5 py-4">Total</th>}
                {isVisible("status") && <th className="px-5 py-4">Status</th>}
                {isVisible("updated") && <th className="px-5 py-4">Last Seen</th>}
                <th className="px-5 py-4 text-right">Detail</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#EEEEEE]">
              {status === "loading" && filteredCarts.length === 0
                ? Array.from({ length: limit }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td className="px-5 py-4"><div className="h-4 w-8 bg-gray-100 rounded mx-auto" /></td>
                    <td className="px-5 py-4"><div className="h-4 w-20 bg-gray-100 rounded" /></td>
                    <td className="px-5 py-4"><div className="h-4 w-24 bg-gray-100 rounded" /></td>
                    <td className="px-5 py-4"><div className="h-4 w-12 bg-gray-100 rounded" /></td>
                    <td className="px-5 py-4"><div className="h-4 w-20 bg-gray-100 rounded" /></td>
                    <td className="px-5 py-4"><div className="h-5 w-16 bg-gray-100 rounded-full" /></td>
                    <td className="px-5 py-4"><div className="h-4 w-16 bg-gray-100 rounded" /></td>
                    <td className="px-5 py-4"><div className="h-6 w-6 bg-gray-100 rounded ml-auto" /></td>
                  </tr>
                ))
                : filteredCarts.map((cart, index) => {
                  const cartStatus = getCartStatus(cart.updatedAt);
                  return (
                    <tr
                      key={cart.id}
                      className="group hover:bg-[#FBFBFA] transition-colors cursor-pointer"
                      onClick={() => setSelectedCart(cart)}
                    >
                      {isVisible("index") && (
                        <td className="px-5 py-4 text-xs font-mono text-[#A1A1AA] text-center">
                          {(page - 1) * limit + index + 1}
                        </td>
                      )}
                      {isVisible("cartId") && (
                        <td className="px-5 py-4">
                          <span className="text-xs font-mono font-bold">CRT-{cart.id}</span>
                        </td>
                      )}
                      {isVisible("customer") && (
                        <td className="px-5 py-4">
                          <p className="text-xs font-bold">User #{cart.userId}</p>
                          <p className="text-[10px] text-[#A1A1AA]">ID: {cart.userId}</p>
                        </td>
                      )}
                      {isVisible("items") && (
                        <td className="px-5 py-4 text-xs font-medium">
                          {cart.totalItems} {cart.totalItems === 1 ? "item" : "items"}
                        </td>
                      )}
                      {isVisible("total") && (
                        <td className="px-5 py-4 font-mono text-sm font-bold">
                          {formatCurrency(cart.totalPrice)}
                        </td>
                      )}
                      {isVisible("status") && (
                        <td className="px-5 py-4">
                          <span
                            className={`text-[10px] font-bold px-2.5 py-1 rounded-full uppercase border ${cartStatus === "Active"
                                ? "bg-emerald-50 text-emerald-600 border-emerald-100"
                                : "bg-slate-50 text-slate-500 border-slate-200"
                              }`}
                          >
                            {cartStatus}
                          </span>
                        </td>
                      )}
                      {isVisible("updated") && (
                        <td className="px-5 py-4 text-[11px] text-[#52525B] font-medium">
                          {formatTimeAgo(cart.updatedAt)}
                        </td>
                      )}
                      <td className="px-5 py-4 text-right">
                        <button
                          className="p-2 text-[#A1A1AA] hover:text-black hover:bg-[#F4F4F5] rounded-lg transition-all inline-block"
                          title="View Cart"
                          onClick={e => { e.stopPropagation(); setSelectedCart(cart); }}
                        >
                          <ShoppingBag size={15} />
                        </button>
                      </td>
                    </tr>
                  );
                })}
            </tbody>
          </table>

          {status !== "loading" && filteredCarts.length === 0 && (
            <div className="py-20 text-center space-y-3">
              <ShoppingCart className="mx-auto text-[#D4D4D8]" size={32} />
              <p className="text-sm font-bold text-[#18181B]">No carts found</p>
              <p className="text-xs text-[#A1A1AA]">Carts appear here when users add products.</p>
              {(searchTerm || statusFilter !== "All") && (
                <button onClick={handleReset} className="text-xs font-bold underline text-[#A1A1AA] hover:text-black">
                  Reset filters
                </button>
              )}
            </div>
          )}
        </div>

        {/* Pagination */}
        <div className="p-4 border-t border-[#EEEEEE] flex items-center justify-between bg-white">
          <div className="flex items-center gap-4">
            <div className="text-[11px] text-[#A1A1AA] font-medium">
              Showing {filteredCarts.length} of {totalCount} carts
            </div>
            <select
              value={limit}
              onChange={e => { setLimit(Number(e.target.value)); setPage(1); }}
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
              onClick={() => setPage(p => Math.max(1, p - 1))}
              disabled={page === 1 || status === "loading"}
              className="p-2 border border-[#EEEEEE] rounded-lg hover:bg-[#FAFAFA] disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronLeft size={14} />
            </button>
            <span className="text-xs font-bold px-2">Page {page}</span>
            <button
              onClick={() => setPage(p => p + 1)}
              disabled={filteredCarts.length < limit || status === "loading"}
              className="p-2 border border-[#EEEEEE] rounded-lg hover:bg-[#FAFAFA] disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronRight size={14} />
            </button>
          </div>
        </div>
      </div>

      {/* ── CART DETAIL DRAWER ── */}
      {selectedCart && (
        <CartDetailDrawer cart={selectedCart} onClose={() => setSelectedCart(null)} />
      )}
    </div>
  );
};

/* ══════════════════════════════════════════
   CART DETAIL DRAWER
══════════════════════════════════════════ */
const CartDetailDrawer = ({
  cart,
  onClose,
}: {
  cart: AdminCart;
  onClose: () => void;
}) => {
  const cartStatus = getCartStatus(cart.updatedAt);

  return (
    <>
      <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50" onClick={onClose} />
      <div className="fixed inset-y-0 right-0 w-full max-w-xl bg-white z-[60] shadow-2xl flex flex-col animate-in slide-in-from-right duration-300">

        {/* Header */}
        <div className="p-6 border-b border-[#EEEEEE] flex justify-between items-start bg-[#FAFAFA]">
          <div>
            <div className="flex items-center gap-3">
              <h2 className="text-xl font-bold">CRT-{cart.id}</h2>
              <span
                className={`text-[10px] font-bold px-2.5 py-1 rounded-full uppercase border ${cartStatus === "Active"
                    ? "bg-emerald-50 text-emerald-600 border-emerald-100"
                    : "bg-slate-50 text-slate-500 border-slate-200"
                  }`}
              >
                {cartStatus}
              </span>
            </div>
            <p className="text-xs text-[#71717A] mt-1">
              User #{cart.userId} · Last updated {formatTimeAgo(cart.updatedAt)}
            </p>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-white border border-[#EEEEEE] rounded-full transition-colors shadow-sm"
          >
            <X size={18} />
          </button>
        </div>

        {/* Summary row */}
        <div className="grid grid-cols-3 divide-x divide-[#EEEEEE] border-b border-[#EEEEEE]">
          {[
            { label: "Items", value: `${cart.totalItems}` },
            { label: "Total", value: formatCurrency(cart.totalPrice) },
            { label: "Created", value: new Date(cart.createdAt).toLocaleDateString("en-AE", { day: "2-digit", month: "short", year: "numeric" }) },
          ].map(s => (
            <div key={s.label} className="p-4 text-center">
              <p className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest">{s.label}</p>
              <p className="text-sm font-bold mt-1">{s.value}</p>
            </div>
          ))}
        </div>

        {/* Items list */}
        <div className="flex-1 overflow-y-auto p-6 space-y-3 no-scrollbar">
          <h4 className="text-[10px] font-bold uppercase tracking-widest text-[#A1A1AA] border-b border-[#EEEEEE] pb-2 mb-4">
            Cart Items ({cart.items.length})
          </h4>
          {cart.items.length === 0 ? (
            <div className="py-10 text-center space-y-2">
              <PackageX className="mx-auto text-[#D4D4D8]" size={28} />
              <p className="text-xs text-[#A1A1AA]">No items in this cart.</p>
            </div>
          ) : (
            cart.items.map(item => <CartItemRow key={item.id} item={item} />)
          )}
        </div>
      </div>
    </>
  );
};

/* ── Cart Item Row inside Drawer ── */
const CartItemRow = ({ item }: { item: AdminCartItem }) => (
  <div className="flex items-center gap-4 p-3 bg-[#FAFAFA] rounded-xl border border-[#EEEEEE] hover:border-[#D4D4D8] transition-colors">
    {item.productImage ? (
      <img
        src={item.productImage}
        alt={item.productName}
        className="w-12 h-12 rounded-lg object-cover border border-[#EEEEEE] flex-shrink-0"
      />
    ) : (
      <div className="w-12 h-12 rounded-lg bg-[#F4F4F5] flex items-center justify-center flex-shrink-0">
        <ShoppingBag size={18} className="text-[#D4D4D8]" />
      </div>
    )}
    <div className="flex-1 min-w-0">
      <p className="text-xs font-bold truncate">{item.productName}</p>
      <p className="text-[10px] text-[#A1A1AA]">SKU: {item.sku} · {item.categoryName}</p>
      <p className="text-[10px] text-[#71717A] mt-0.5">
        {formatCurrency(item.finalPrice)} × {item.quantity}
      </p>
    </div>
    <div className="text-right flex-shrink-0">
      <p className="text-sm font-bold font-mono">{formatCurrency(item.subtotal)}</p>
      <p className="text-[10px] text-[#A1A1AA]">qty {item.quantity}</p>
    </div>
  </div>
);

export default CartManagement;