import React, { useEffect, useMemo, useState, useRef } from "react";
import { useDispatch, useSelector } from "react-redux";
import {
  Search,
  Filter,
  Eye,
  XCircle,
  Download,
  Package,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  RotateCcw,
  ShoppingBag,
  Clock,
  Truck,
  CheckCircle2,
  ListFilter,
  Columns3,
  Calendar,
  MapPin,
  CreditCard,
  Hash,
  MoreHorizontal,
} from "lucide-react";

import {
  ordersActions,
  selectOrders,
  selectOrdersStatus,
  selectOrdersError,
  selectOrdersTotal,
} from "./ordersSlice";
import type { Order, OrderStatus, PaymentStatus } from "./ordersSlice";

/* --- FILTER TYPES --- */
type FilterOrderStatus = OrderStatus | "All";
type FilterPaymentStatus = PaymentStatus | "All";

/* --- Column definitions --- */
type ColumnKey =
  | "index"
  | "order"
  | "customer"
  | "items"
  | "total"
  | "payment"
  | "status"
  | "deliveryDate"
  | "deliverySlot"
  | "city"
  | "paymentMethod"
  | "transactionId"
  | "actions";

interface ColumnDef {
  key: ColumnKey;
  label: string;
  icon?: React.ReactNode;
  defaultVisible: boolean;
  alwaysVisible?: boolean; // cannot be toggled off
}

const COLUMNS: ColumnDef[] = [
  { key: "index", label: "#", defaultVisible: true, alwaysVisible: true },
  { key: "order", label: "Order / Date", defaultVisible: true },
  { key: "customer", label: "Customer", defaultVisible: true },
  { key: "items", label: "Items", defaultVisible: true },
  { key: "total", label: "Total", defaultVisible: true },
  { key: "payment", label: "Payment", defaultVisible: true },
  { key: "status", label: "Status", defaultVisible: true },
  { key: "deliveryDate", label: "Delivery Date", icon: <Calendar size={12} />, defaultVisible: false },
  { key: "deliverySlot", label: "Delivery Slot", icon: <Clock size={12} />, defaultVisible: false },
  { key: "city", label: "City", icon: <MapPin size={12} />, defaultVisible: false },
  { key: "paymentMethod", label: "Pay Method", icon: <CreditCard size={12} />, defaultVisible: false },
  { key: "transactionId", label: "Transaction ID", icon: <Hash size={12} />, defaultVisible: false },
  { key: "actions", label: "Actions", defaultVisible: true, alwaysVisible: true },
];

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
const OrderManagement: React.FC = () => {
  const dispatch = useDispatch();

  const orders = useSelector(selectOrders);
  const totalCount = useSelector(selectOrdersTotal);
  const status = useSelector(selectOrdersStatus);
  const error = useSelector(selectOrdersError);

  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState<FilterOrderStatus>("All");
  const [paymentFilter, setPaymentFilter] = useState<FilterPaymentStatus>("All");
  const [customerFilter, setCustomerFilter] = useState("");
  const [cityFilter, setCityFilter] = useState("");
  const [deliveryDateFilter, setDeliveryDateFilter] = useState("");
  const [deliverySlotFilter, setDeliverySlotFilter] = useState("");
  const [paymentMethodFilter, setPaymentMethodFilter] = useState("");
  const [transactionIdFilter, setTransactionIdFilter] = useState("");
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

  // Close dropdown on outside click
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
      ordersActions.fetchOrdersRequest({
        q: debouncedSearch || undefined,
        status: statusFilter === "All" ? undefined : statusFilter.toLowerCase(),
        payment_status: paymentFilter === "All" ? undefined : paymentFilter.toLowerCase(),
        page,
        limit,
        offset,
      })
    );
  }, [dispatch, debouncedSearch, statusFilter, paymentFilter, page, limit]);

  const handleReset = () => {
    setSearchTerm("");
    setStatusFilter("All");
    setPaymentFilter("All");
    setCustomerFilter("");
    setCityFilter("");
    setDeliveryDateFilter("");
    setDeliverySlotFilter("");
    setPaymentMethodFilter("");
    setTransactionIdFilter("");
    setPage(1);
  };

  // Client-side filtering for columns not supported by API
  const filteredOrders = useMemo(() => {
    let result = orders;
    if (customerFilter) {
      result = result.filter((o) =>
        (o.shippingAddress.fullName || "").toLowerCase().includes(customerFilter.toLowerCase())
      );
    }
    if (cityFilter) {
      result = result.filter((o) =>
        o.shippingAddress.city.toLowerCase().includes(cityFilter.toLowerCase())
      );
    }
    if (deliveryDateFilter) {
      result = result.filter((o) =>
        o.deliveryDate?.startsWith(deliveryDateFilter)
      );
    }
    if (deliverySlotFilter) {
      result = result.filter((o) =>
        o.deliverySlot?.toLowerCase().includes(deliverySlotFilter.toLowerCase())
      );
    }
    if (paymentMethodFilter) {
      result = result.filter((o) =>
        o.paymentMethod.toLowerCase().includes(paymentMethodFilter.toLowerCase())
      );
    }
    if (transactionIdFilter) {
      result = result.filter((o) =>
        o.payment?.transactionId?.toLowerCase().includes(transactionIdFilter.toLowerCase())
      );
    }
    return result;
  }, [orders, cityFilter, deliveryDateFilter, deliverySlotFilter, paymentMethodFilter, transactionIdFilter, customerFilter]);

  // Stats
  const totalRevenue = filteredOrders.reduce((sum, o) => sum + o.total, 0);
  const processingCount = filteredOrders.filter(
    (o) => o.status === "Processing" || o.status === "Confirmed"
  ).length;
  const shippedCount = filteredOrders.filter((o) => o.status === "Shipped").length;
  const deliveredCount = filteredOrders.filter((o) => o.status === "Delivered").length;

  // Unique slots from data for dropdown
  const uniqueSlots = useMemo(() =>
    [...new Set(orders.map((o) => o.deliverySlot).filter(Boolean) as string[])],
    [orders]
  );

  // Export handler
  const handleExport = () => {
    const headers = ["Order ID", "Customer", "Items", "Total", "Status", "Date", "Payment", "Payment Method"];
    const rows = filteredOrders.map(o => [
      o.orderNumber,
      o.shippingAddress.fullName || "",
      o.items.length,
      o.total,
      o.status,
      new Date(o.createdAt).toLocaleDateString(),
      o.paymentStatus,
      o.paymentMethod
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
    link.setAttribute("download", `orders_export_${new Date().toISOString().split('T')[0]}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="min-h-screen w-full space-y-6 text-[#18181B] bg-[#FDFDFD]">
      {/* --- PAGE HEADER --- */}
      <div>
        <h1 className="text-2xl md:text-3xl font-bold tracking-tight text-black">Orders</h1>
        <p className="text-[#71717A] text-sm mt-1">Track and manage all customer orders.</p>
      </div>

      {/* --- STATS --- */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <QuickStat
          label="Total Orders"
          value={`${totalCount}`}
          sub={`AED ${totalRevenue.toLocaleString("en-IN", { minimumFractionDigits: 2 })}`}
          icon={<ShoppingBag size={16} className="text-[#A1A1AA]" />}
        />
        <QuickStat
          label="Processing"
          value={`${processingCount}`}
          sub="Awaiting fulfillment"
          icon={<Clock size={16} className="text-amber-500" />}
        />
        <QuickStat
          label="Shipped"
          value={`${shippedCount}`}
          sub="In transit"
          icon={<Truck size={16} className="text-blue-500" />}
        />
        <QuickStat
          label="Delivered"
          value={`${deliveredCount}`}
          sub="Completed"
          icon={<CheckCircle2 size={16} className="text-emerald-500" />}
        />
      </div>

      {/* --- TABLE --- */}
      <div className="bg-white rounded-2xl border border-[#EEEEEE] shadow-sm overflow-hidden">
        {/* Toolbar */}
        <div className="p-4 border-b border-[#EEEEEE] flex flex-col md:flex-row justify-between items-center gap-4 bg-white">

          <div className="flex items-center gap-2 w-full md:w-auto justify-end">
            <button
              onClick={handleReset}
              className="p-2 text-[#A1A1AA] hover:text-rose-500 hover:bg-rose-50 rounded-lg transition-all"
              title="Clear Filters"
            >
              <RotateCcw size={16} />
            </button>
            <div className="h-6 w-px bg-[#EEEEEE] mx-1" />
            <button
              onClick={() => setIsFilterOpen(!isFilterOpen)}
              className={`flex items-center gap-2 px-3 py-1.5 border rounded-lg text-[11px] font-bold transition-all ${isFilterOpen
                ? "bg-black text-white border-black"
                : "bg-white text-black border-[#EEEEEE] hover:bg-gray-50"
                }`}
            >
              <Filter size={14} /> {isFilterOpen ? "Hide Filters" : "Show Filters"}
            </button>

            {/* Column Visibility Dropdown */}
            <div className="relative" ref={columnsRef}>
              <button
                onClick={() => setIsColumnsOpen(!isColumnsOpen)}
                className={`flex items-center gap-2 px-3 py-1.5 border rounded-lg text-[11px] font-bold transition-all ${isColumnsOpen
                  ? "bg-black text-white border-black"
                  : "bg-white text-black border-[#EEEEEE] hover:bg-gray-50"
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
        {status === "loading" && orders.length === 0 && (
          <div className="p-6 text-sm text-[#71717A]">Loading orders…</div>
        )}
        {status === "failed" && (
          <div className="p-6 text-sm text-rose-600">{error || "Failed to load orders"}</div>
        )}

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[900px]">
            <thead className="bg-[#FAFAFA]">
              <tr className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest border-b border-[#EEEEEE]">
                {isVisible("index") && <th className="px-5 py-4 w-12 text-center">#</th>}
                {isVisible("order") && <th className="px-5 py-4">Order / Date</th>}
                {isVisible("customer") && <th className="px-5 py-4">Customer</th>}
                {isVisible("items") && <th className="px-5 py-4">Items</th>}
                {isVisible("total") && <th className="px-5 py-4">Total</th>}
                {isVisible("payment") && <th className="px-5 py-4">Payment</th>}
                {isVisible("status") && <th className="px-5 py-4">Status</th>}
                {isVisible("deliveryDate") && <th className="px-5 py-4">Delivery Date</th>}
                {isVisible("deliverySlot") && <th className="px-5 py-4">Delivery Slot</th>}
                {isVisible("city") && <th className="px-5 py-4">City</th>}
                {isVisible("paymentMethod") && <th className="px-5 py-4">Pay Method</th>}
                {isVisible("transactionId") && <th className="px-5 py-4">Transaction ID</th>}
                {isVisible("actions") && <th className="px-5 py-4 text-right">Actions</th>}
              </tr>

              {isFilterOpen && (
                <tr className="bg-white border-b border-[#EEEEEE] animate-in fade-in slide-in-from-top-1 duration-200">
                  {isVisible("index") && (
                    <td className="px-5 py-3 text-center">
                      <ListFilter size={14} className="text-[#D4D4D8] mx-auto" />
                    </td>
                  )}
                  {isVisible("order") && (
                    <td className="px-5 py-3">
                      <div className="relative">
                        <Search className="absolute left-2 top-1/2 -translate-y-1/2 text-[#A1A1AA]" size={12} />
                        <input
                          type="text"
                          placeholder="Order #..."
                          value={searchTerm}
                          onChange={(e) => setSearchTerm(e.target.value)}
                          className="w-full pl-7 pr-2 py-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none focus:bg-white focus:border-[#EEEEEE]"
                        />
                      </div>
                    </td>
                  )}
                  {isVisible("customer") && (
                    <td className="px-5 py-3">
                      <td className="px-5 py-3">
                        <input
                          type="text"
                          placeholder="Customer..."
                          value={customerFilter}
                          onChange={(e) => setCustomerFilter(e.target.value)}
                          className="w-full p-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none focus:bg-white focus:border-[#EEEEEE]"
                        />
                      </td>
                    </td>
                  )}
                  {isVisible("items") && (
                    <td className="px-5 py-3">
                      <div className="text-[10px] text-[#A1A1AA] font-medium italic">—</div>
                    </td>
                  )}
                  {isVisible("total") && (
                    <td className="px-5 py-3">
                      <div className="text-[10px] text-[#A1A1AA] font-medium italic">—</div>
                    </td>
                  )}

                  {isVisible("payment") && (
                    <td className="px-5 py-3">
                      <select
                        value={paymentFilter}
                        onChange={(e) => setPaymentFilter(e.target.value as FilterPaymentStatus)}
                        className="w-full p-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none cursor-pointer focus:bg-white focus:border-[#EEEEEE]"
                      >
                        <option value="All">All</option>
                        <option value="Paid">Paid</option>
                        <option value="Pending">Pending</option>
                        <option value="Refunded">Refunded</option>
                      </select>
                    </td>
                  )}
                  {isVisible("status") && (
                    <td className="px-5 py-3">
                      <select
                        value={statusFilter}
                        onChange={(e) => setStatusFilter(e.target.value as FilterOrderStatus)}
                        className="w-full p-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none cursor-pointer focus:bg-white focus:border-[#EEEEEE]"
                      >
                        <option value="All">All Status</option>
                        <option value="Pending">Pending</option>
                        <option value="Paid">Paid</option>
                        <option value="Confirmed">Confirmed</option>
                        <option value="Processing">Processing</option>
                        <option value="Shipped">Shipped</option>
                        <option value="Delivered">Delivered</option>
                        <option value="Cancelled">Cancelled</option>
                      </select>
                    </td>
                  )}
                  {isVisible("deliveryDate") && (
                    <td className="px-5 py-3">
                      <input
                        type="date"
                        value={deliveryDateFilter}
                        onChange={(e) => setDeliveryDateFilter(e.target.value)}
                        className="w-full p-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none focus:bg-white focus:border-[#EEEEEE]"
                      />
                    </td>
                  )}
                  {isVisible("deliverySlot") && (
                    <td className="px-5 py-3">
                      <select
                        value={deliverySlotFilter}
                        onChange={(e) => setDeliverySlotFilter(e.target.value)}
                        className="w-full p-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none cursor-pointer focus:bg-white focus:border-[#EEEEEE]"
                      >
                        <option value="">All Slots</option>
                        {uniqueSlots.map((slot) => (
                          <option key={slot} value={slot}>{slot}</option>
                        ))}
                      </select>
                    </td>
                  )}
                  {isVisible("city") && (
                    <td className="px-5 py-3">
                      <input
                        type="text"
                        placeholder="City..."
                        value={cityFilter}
                        onChange={(e) => setCityFilter(e.target.value)}
                        className="w-full p-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none focus:bg-white focus:border-[#EEEEEE]"
                      />
                    </td>
                  )}
                  {isVisible("paymentMethod") && (
                    <td className="px-5 py-3">
                      <input
                        type="text"
                        placeholder="Pay method..."
                        value={paymentMethodFilter}
                        onChange={(e) => setPaymentMethodFilter(e.target.value)}
                        className="w-full p-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none focus:bg-white focus:border-[#EEEEEE]"
                      />
                    </td>
                  )}
                  {isVisible("transactionId") && (
                    <td className="px-5 py-3">
                      <input
                        type="text"
                        placeholder="TXN ID..."
                        value={transactionIdFilter}
                        onChange={(e) => setTransactionIdFilter(e.target.value)}
                        className="w-full p-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none focus:bg-white focus:border-[#EEEEEE]"
                      />
                    </td>
                  )}
                  {isVisible("actions") && (
                    <td className="px-5 py-3 text-right">
                      <button
                        onClick={handleReset}
                        className="text-[10px] font-bold text-rose-500 hover:underline px-2"
                      >
                        Clear
                      </button>
                    </td>
                  )}
                </tr>
              )}
            </thead>

            <tbody className="divide-y divide-[#EEEEEE]">
              {status === "loading" && orders.length === 0
                ? Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td className="px-5 py-4"><div className="h-4 w-4 bg-gray-100 rounded mx-auto" /></td>
                    <td className="px-5 py-4"><div className="h-4 w-24 bg-gray-100 rounded" /></td>
                    <td className="px-5 py-4"><div className="h-4 w-28 bg-gray-100 rounded" /></td>
                    <td className="px-5 py-4"><div className="h-4 w-10 bg-gray-100 rounded" /></td>
                    <td className="px-5 py-4"><div className="h-4 w-16 bg-gray-100 rounded" /></td>
                    <td className="px-5 py-4"><div className="h-6 w-14 bg-gray-100 rounded-full" /></td>
                    <td className="px-5 py-4"><div className="h-6 w-20 bg-gray-100 rounded-full" /></td>
                    <td className="px-5 py-4"><div className="h-8 w-8 bg-gray-100 rounded-lg ml-auto" /></td>
                  </tr>
                ))
                : filteredOrders.map((order, index) => (
                  <tr
                    key={order.id}
                    className="group hover:bg-[#FBFBFA] transition-colors"
                  >
                    {isVisible("index") && (
                      <td className="px-5 py-4 text-xs font-mono text-[#A1A1AA] text-center">
                        {(page - 1) * limit + index + 1}
                      </td>
                    )}

                    {isVisible("order") && (
                      <td className="px-5 py-4">
                        <p className="text-xs font-bold font-mono text-black">{order.orderNumber}</p>
                        <p className="text-[10px] text-[#A1A1AA] mt-0.5">
                          {new Date(order.createdAt).toLocaleDateString("en-IN", {
                            day: "2-digit",
                            month: "short",
                            year: "numeric",
                          })}
                        </p>
                      </td>
                    )}

                    {isVisible("customer") && (
                      <td className="px-5 py-4">
                        <p className="text-xs font-bold">{order.shippingAddress.fullName || "—"}</p>
                        <p className="text-[10px] text-[#A1A1AA]">{order.shippingAddress.phoneNumber || "—"}</p>
                      </td>
                    )}

                    {isVisible("items") && (
                      <td className="px-5 py-4">
                        <span className="text-xs font-bold text-[#52525B]">
                          {order.items.length} item{order.items.length !== 1 ? "s" : ""}
                        </span>
                      </td>
                    )}

                    {isVisible("total") && (
                      <td className="px-5 py-4">
                        <span className="text-sm font-black">
                          AED {order.total.toLocaleString("en-IN", { minimumFractionDigits: 2 })}
                        </span>
                      </td>
                    )}

                    {isVisible("payment") && (
                      <td className="px-5 py-4">
                        <PaymentBadge status={order.paymentStatus} />
                      </td>
                    )}

                    {isVisible("status") && (
                      <td className="px-5 py-4">
                        <OrderStatusBadge status={order.status} />
                      </td>
                    )}

                    {isVisible("deliveryDate") && (
                      <td className="px-5 py-4">
                        <span className="text-xs text-[#52525B] font-medium">
                          {order.deliveryDate
                            ? new Date(order.deliveryDate).toLocaleDateString("en-IN", {
                              day: "2-digit",
                              month: "short",
                              year: "numeric",
                            })
                            : "—"}
                        </span>
                      </td>
                    )}

                    {isVisible("deliverySlot") && (
                      <td className="px-5 py-4">
                        <span className="text-xs text-[#52525B] font-medium">
                          {order.deliverySlot || "—"}
                        </span>
                      </td>
                    )}

                    {isVisible("city") && (
                      <td className="px-5 py-4">
                        <span className="text-xs text-[#52525B] font-medium">
                          {order.shippingAddress.city || "—"}
                        </span>
                      </td>
                    )}

                    {isVisible("paymentMethod") && (
                      <td className="px-5 py-4">
                        <span className="text-[10px] font-bold uppercase bg-[#F4F4F5] text-[#52525B] px-2.5 py-1 rounded-full">
                          {order.paymentMethod}
                        </span>
                      </td>
                    )}

                    {isVisible("transactionId") && (
                      <td className="px-5 py-4">
                        <span className="text-[10px] font-mono text-[#A1A1AA]">
                          {order.payment?.transactionId || "—"}
                        </span>
                      </td>
                    )}

                    {isVisible("actions") && (
                      <td className="px-5 py-4 text-right relative">
                        {/* Action Menu Popover */}
                        <div className="flex items-center justify-end group/actions">
                          <button className="p-2 text-[#A1A1AA] hover:text-black hover:bg-gray-100 rounded-lg transition-colors">
                            <MoreHorizontal size={16} />
                          </button>
                          {/* Hover Dropdown */}
                          <div className="absolute right-8 top-1/2 -translate-y-1/2 hidden group-hover/actions:block w-32 bg-white border border-[#EEEEEE] shadow-xl rounded-lg z-20 py-1">
                            <button
                              onClick={() => setSelectedOrder(order)}
                              className="w-full text-left px-3 py-2 text-[11px] font-bold text-gray-700 hover:bg-gray-50 flex items-center gap-2"
                            >
                              <Eye size={12} /> View Details
                            </button>
                            {/* Quick Status Update if needed can go here */}
                          </div>
                        </div>
                      </td>
                    )}
                  </tr>
                ))}
            </tbody>
          </table>

          {status !== "loading" && orders.length === 0 && (
            <div className="py-20 text-center space-y-3">
              <ShoppingBag className="mx-auto text-[#D4D4D8]" size={32} />
              <p className="text-sm font-bold text-[#18181B]">No orders found</p>
              <p className="text-xs text-[#A1A1AA]">Orders will appear here as customers place them.</p>
              <button
                onClick={handleReset}
                className="text-xs font-bold underline text-[#A1A1AA] hover:text-black"
              >
                Reset all filters
              </button>
            </div>
          )}
        </div>

        {/* --- PAGINATION --- */}
        <div className="p-4 border-t border-[#EEEEEE] flex items-center justify-between bg-white">
          <div className="flex items-center gap-4">
            <div className="text-[11px] text-[#A1A1AA] font-medium">
              Showing {filteredOrders.length} of {totalCount} orders
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
              disabled={orders.length < limit || status === "loading"}
              className="p-2 border border-[#EEEEEE] rounded-lg hover:bg-[#FAFAFA] disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronRight size={14} />
            </button>
          </div>
        </div>
      </div>

      {/* --- ORDER DETAILS SLIDE-OVER --- */}
      {selectedOrder && (
        <OrderDetailsPanel
          order={selectedOrder}
          onClose={() => setSelectedOrder(null)}
        />
      )}
    </div>
  );
};

/* ── ORDER DETAILS SLIDE-OVER ── */
const OrderDetailsPanel = ({
  order,
  onClose,
}: {
  order: Order;
  onClose: () => void;
}) => {
  const dispatch = useDispatch();
  const [isStatusOpen, setIsStatusOpen] = useState(false);

  const handleStatusUpdate = (newStatus: OrderStatus) => {
    dispatch(ordersActions.updateStatusRequest({ id: order.id, status: newStatus }));
    setIsStatusOpen(false);
  };

  const statusOptions: OrderStatus[] = [
    "Pending", "Confirmed", "Processing", "Shipped", "Delivered", "Cancelled", "Returned", "Paid"
  ];

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
            <div className="p-2.5 bg-gray-900 text-white rounded-xl">
              <Package size={18} />
            </div>
            <div>
              <h2 className="text-lg font-black">{order.orderNumber}</h2>
              <span className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest">
                Order Details
              </span>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 border border-[#EEEEEE] rounded-lg hover:bg-gray-50 transition-colors"
          >
            <XCircle size={18} />
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {/* Status Banner */}
          <div className="bg-[#FAFAFA] p-4 rounded-xl border border-[#EEEEEE] flex justify-between items-center relative">
            <div>
              <p className="text-[10px] font-bold text-[#A1A1AA] uppercase">Current Status</p>
              <div className="mt-1">
                <OrderStatusBadge status={order.status} />
              </div>
            </div>

            <div className="relative">
              <button
                onClick={() => setIsStatusOpen(!isStatusOpen)}
                className="bg-black text-white px-4 py-2 rounded-lg text-xs font-bold flex items-center gap-2 hover:bg-gray-800 transition-colors"
              >
                Update Status <ChevronDown size={14} />
              </button>
              {isStatusOpen && (
                <div className="absolute right-0 mt-2 w-40 bg-white border border-gray-100 rounded-xl shadow-xl z-50 py-1 overflow-hidden animate-in fade-in zoom-in-95 duration-200">
                  {statusOptions.map(s => (
                    <button
                      key={s}
                      onClick={() => handleStatusUpdate(s)}
                      className={`w-full text-left px-4 py-2.5 text-xs font-bold hover:bg-gray-50 transition-colors ${order.status === s ? 'text-black bg-gray-50' : 'text-gray-600'}`}
                    >
                      {s}
                    </button>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Customer & Shipping Info */}
          <div className="grid grid-cols-2 gap-5">
            <InfoField label="Customer" value={order.shippingAddress.fullName || "—"} />
            <InfoField label="Phone" value={order.shippingAddress.phoneNumber || "—"} />
            <InfoField label="City" value={order.shippingAddress.city || "—"} />
            <InfoField label="Area" value={order.shippingAddress.area || "—"} />
            <InfoField label="Address" value={order.shippingAddress.streetAddress || "—"} />
            <InfoField label="Emirate" value={order.shippingAddress.emirate || "—"} />
            <InfoField label="Payment Method" value={order.paymentMethod} />
            <InfoField label="Payment">
              <PaymentBadge status={order.paymentStatus} />
            </InfoField>
            <InfoField
              label="Order Date"
              value={new Date(order.createdAt).toLocaleDateString("en-IN", {
                day: "2-digit",
                month: "long",
                year: "numeric",
              })}
            />
            {order.deliveryDate && (
              <InfoField
                label="Delivery Date"
                value={new Date(order.deliveryDate).toLocaleDateString("en-IN", {
                  day: "2-digit",
                  month: "long",
                  year: "numeric",
                })}
              />
            )}
            {order.deliverySlot && (
              <InfoField label="Delivery Slot" value={order.deliverySlot} />
            )}
            {order.payment?.transactionId && (
              <InfoField label="Transaction ID" value={order.payment.transactionId} />
            )}
          </div>

          {/* Order Items */}
          <div className="space-y-4">
            <h4 className="text-[10px] font-bold uppercase tracking-widest text-[#A1A1AA] border-b border-[#EEEEEE] pb-2">
              Purchased Items
            </h4>
            {order.items?.length > 0 ? (
              order.items.map((item) => (
                <div
                  key={item.id}
                  className="flex justify-between items-center py-3 border-b border-dashed border-[#EEEEEE] last:border-0"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-lg bg-[#F4F4F5] flex items-center justify-center">
                      <Package size={16} className="text-[#A1A1AA]" />
                    </div>
                    <div>
                      {/* Ensure productName and other fields prevent crash if missing properties on item */}
                      <p className="text-xs font-bold">{item.productName || "Unknown Product"}</p>
                      <p className="text-[10px] text-[#A1A1AA]">
                        Qty: {item.quantity || 0} · AED {(item.price || 0).toFixed(2)}/ea
                      </p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-xs font-bold">AED {(item.subtotal || 0).toFixed(2)}</p>
                  </div>
                </div>
              ))
            ) : (
              <p className="text-xs text-[#A1A1AA] italic">No items in this order.</p>
            )}

            {/* Summary */}
            <div className="pt-4 space-y-2 border-t border-[#EEEEEE]">
              <div className="flex justify-between items-center pt-1">
                <span className="text-sm font-bold">Total Amount</span>
                <span className="text-xl font-black text-emerald-600">
                  AED {(order.total || 0).toLocaleString("en-IN", { minimumFractionDigits: 2 })}
                </span>
              </div>
            </div>
          </div>

          {/* Delivery Notes */}
          {order.deliveryNotes && (
            <div>
              <h4 className="text-[10px] font-bold uppercase tracking-widest text-[#A1A1AA] mb-2">
                Delivery Notes
              </h4>
              <p className="text-xs text-[#52525B] bg-[#FAFAFA] p-3 rounded-lg border border-[#EEEEEE]">
                {order.deliveryNotes}
              </p>
            </div>
          )}

          {/* Status History */}
          {order.statusHistory?.length > 0 && (
            <div>
              <h4 className="text-[10px] font-bold uppercase tracking-widest text-[#A1A1AA] mb-3 border-b border-[#EEEEEE] pb-2">
                Status History
              </h4>
              <div className="space-y-3">
                {order.statusHistory.map((entry, i) => (
                  <div key={i} className="flex items-start gap-3">
                    <div className="mt-1 w-2 h-2 rounded-full bg-[#A1A1AA] flex-shrink-0" />
                    <div>
                      <p className="text-xs font-bold text-[#18181B]">{entry.status}</p>
                      <p className="text-[10px] text-[#A1A1AA]">
                        {entry.notes} ·{" "}
                        {entry.createdAt ? new Date(entry.createdAt).toLocaleString("en-IN", {
                          day: "2-digit",
                          month: "short",
                          year: "numeric",
                          hour: "2-digit",
                          minute: "2-digit",
                        }) : "-"}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </>
  );
};

/* ── SUB-COMPONENTS ── */
function OrderStatusBadge({ status }: { status: OrderStatus }) {
  const styles: Record<OrderStatus, string> = {
    Pending: "bg-gray-50 text-gray-600 border-gray-200",
    Confirmed: "bg-blue-50 text-blue-600 border-blue-100",
    Processing: "bg-amber-50 text-amber-600 border-amber-100",
    Shipped: "bg-indigo-50 text-indigo-600 border-indigo-100",
    Delivered: "bg-emerald-50 text-emerald-600 border-emerald-100",
    Cancelled: "bg-rose-50 text-rose-600 border-rose-100",
    Returned: "bg-orange-50 text-orange-600 border-orange-100",
    Paid: "bg-green-50 text-green-700 border-green-200",
  };
  const dots: Record<OrderStatus, string> = {
    Pending: "bg-gray-400",
    Confirmed: "bg-blue-500",
    Processing: "bg-amber-500",
    Shipped: "bg-indigo-500",
    Delivered: "bg-emerald-500",
    Cancelled: "bg-rose-500",
    Returned: "bg-orange-500",
    Paid: "bg-green-600",
  };
  return (
    <span
      className={`inline-flex items-center gap-1.5 text-[10px] font-bold px-2.5 py-1 rounded-full uppercase border ${styles[status]}`}
    >
      <span className={`w-1.5 h-1.5 rounded-full ${dots[status]}`} />
      {status}
    </span>
  );
}

function PaymentBadge({ status }: { status: PaymentStatus }) {
  const styles: Record<PaymentStatus, string> = {
    Paid: "bg-emerald-50 text-emerald-600 border-emerald-100",
    Success: "bg-emerald-50 text-emerald-600 border-emerald-100",
    Pending: "bg-amber-50 text-amber-600 border-amber-100",
    Refunded: "bg-violet-50 text-violet-600 border-violet-100",
    Failed: "bg-rose-50 text-rose-600 border-rose-100",
  };
  return (
    <span
      className={`text-[9px] font-bold px-2.5 py-1 rounded-full uppercase border ${styles[status]}`}
    >
      {status}
    </span>
  );
}

function InfoField({
  label,
  value,
  children,
}: {
  label: string;
  value?: string;
  children?: React.ReactNode;
}) {
  return (
    <div className="space-y-1">
      <p className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-wide">{label}</p>
      {children ?? <p className="text-sm font-bold text-[#18181B]">{value}</p>}
    </div>
  );
}

function QuickStat({
  label,
  value,
  sub,
  icon,
}: {
  label: string;
  value: string;
  sub: string;
  icon: React.ReactNode;
}) {
  return (
    <div className="p-5 bg-white border border-[#EEEEEE] rounded-2xl shadow-sm hover:border-[#D4D4D8] transition-colors">
      <div className="flex items-center justify-between">
        <p className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest">{label}</p>
        {icon}
      </div>
      <h3 className="text-2xl font-bold mt-1 tracking-tight">{value}</h3>
      <p className="text-[11px] text-emerald-600 font-medium mt-1">{sub}</p>
    </div>
  );
}

export default OrderManagement;