import React, { useEffect, useMemo } from "react";
import { useDispatch, useSelector } from "react-redux";
import {
  Package,
  AlertCircle,
  ArrowUpRight,
  ArrowDownRight,
  MoreHorizontal,
  ShoppingCart,
  Users,
  CreditCard,
  Star,
  TrendingUp,
  ChevronRight,
  MessageSquare,
} from "lucide-react";

/* ── Redux selectors ── */
import { ordersActions, selectOrders, selectOrdersTotal, selectOrdersStatus } from "../orders/ordersSlice";
import { selectProducts, selectProductsTotal, selectProductsStatus } from "../products/productsSlice";
import { productsActions } from "../products/productsSlice";
import { selectCustomers, selectCustomersTotal } from "../customers/customersSlice";
import { customersActions } from "../customers/customersSlice";
import { selectPayments } from "../payments/paymentsSlice";
import { paymentsActions } from "../payments/paymentsSlice";
import { selectReviews, selectReviewsTotal } from "../reviews/reviewsSlice";
import { reviewsActions } from "../reviews/reviewsSlice";
import type { Order } from "../orders/ordersSlice";
import type { Product } from "../products/productsSlice";

/* ── MAIN COMPONENT ── */
const Dashboard: React.FC = () => {
  const dispatch = useDispatch();

  // Selectors
  const orders = useSelector(selectOrders);
  const ordersTotal = useSelector(selectOrdersTotal);
  const ordersStatus = useSelector(selectOrdersStatus);
  const products = useSelector(selectProducts);
  const productsTotal = useSelector(selectProductsTotal);
  const productsStatus = useSelector(selectProductsStatus);
  const customers = useSelector(selectCustomers);
  const customersTotal = useSelector(selectCustomersTotal);
  const payments = useSelector(selectPayments);
  const reviews = useSelector(selectReviews);
  const reviewsTotal = useSelector(selectReviewsTotal);

  // Dispatch fetches on mount if data is empty
  useEffect(() => {
    if (orders.length === 0 && ordersStatus !== "loading") {
      dispatch(ordersActions.fetchOrdersRequest({ limit: 10, page: 1 }));
    }
    if (products.length === 0 && productsStatus !== "loading") {
      dispatch(productsActions.fetchProductsRequest({ limit: 20, page: 1 }));
    }
    if (customers.length === 0) {
      dispatch(customersActions.fetchCustomersRequest({ limit: 10, page: 1 }));
    }
    if (payments.length === 0) {
      dispatch(paymentsActions.fetchPaymentsRequest({ limit: 10, page: 1 }));
    }
    if (reviews.length === 0) {
      dispatch(reviewsActions.fetchReviewsRequest({ limit: 10, page: 1 }));
    }
  }, [dispatch]);

  // Computed stats
  const completedOrders = useMemo(
    () => orders.filter((o) => o.status === "Delivered").length,
    [orders]
  );
  const pendingOrders = useMemo(
    () => orders.filter((o) => ["Pending", "Confirmed", "Processing"].includes(o.status)).length,
    [orders]
  );
  const canceledOrders = useMemo(
    () => orders.filter((o) => o.status === "Cancelled").length,
    [orders]
  );
  const totalRevenue = useMemo(
    () => payments.filter((p) => p.paymentStatus === "Success").reduce((s, p) => s + p.amount, 0),
    [payments]
  );
  const avgRating = useMemo(
    () => reviews.length > 0 ? (reviews.reduce((s, r) => s + r.rating, 0) / reviews.length).toFixed(1) : "0.0",
    [reviews]
  );
  const lowStockProducts = useMemo(
    () => products.filter((p) => p.stock <= 10).sort((a, b) => a.stock - b.stock).slice(0, 5),
    [products]
  );
  const recentOrders = useMemo(
    () => [...orders].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()).slice(0, 5),
    [orders]
  );
  const activeProducts = useMemo(
    () => products.filter((p) => p.status === "Active").length,
    [products]
  );

  // Payment method breakdown
  const methodBreakdown = useMemo(() => {
    const total = payments.length || 1;
    const counts: Record<string, number> = {};
    payments.forEach((p) => {
      counts[p.paymentMethod] = (counts[p.paymentMethod] || 0) + 1;
    });
    return Object.entries(counts)
      .map(([method, count]) => ({ label: method, percentage: Math.round((count / total) * 100) }))
      .sort((a, b) => b.percentage - a.percentage)
      .slice(0, 4);
  }, [payments]);

  // Order status breakdown
  const statusBreakdown = useMemo(() => {
    const total = orders.length || 1;
    const counts: Record<string, number> = {};
    orders.forEach((o) => {
      counts[o.status] = (counts[o.status] || 0) + 1;
    });
    return Object.entries(counts)
      .map(([status, count]) => ({ label: status, percentage: Math.round((count / total) * 100) }))
      .sort((a, b) => b.percentage - a.percentage)
      .slice(0, 5);
  }, [orders]);

  const isLoading = ordersStatus === "loading" || productsStatus === "loading";

  return (
    <div className="min-h-screen text-[#121212] font-sans pb-12 sm:px-6 lg:px-10">
      {/* --- PAGE HEADER --- */}
      <div className="mb-6">
        <h1 className="text-2xl md:text-3xl font-bold tracking-tight text-black">Dashboard</h1>
        <p className="text-[#71717A] text-sm mt-1">Your store at a glance.</p>
      </div>

      {/* --- TOP STATS GRID --- */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <StatCard
          label="Total Revenue"
          value={`AED ${totalRevenue.toLocaleString("en-IN")}`}
          icon={<CreditCard size={18} strokeWidth={1.5} />}
          trend="up"
        />
        <StatCard
          label="Total Orders"
          value={`${ordersTotal}`}
          sub={`${completedOrders} delivered`}
          icon={<ShoppingCart size={18} strokeWidth={1.5} />}
          trend="up"
        />
        <StatCard
          label="Products"
          value={`${productsTotal}`}
          sub={`${activeProducts} active`}
          icon={<Package size={18} strokeWidth={1.5} />}
          trend="up"
        />
        <StatCard
          label="Customers"
          value={`${customersTotal}`}
          icon={<Users size={18} strokeWidth={1.5} />}
          trend="up"
        />
      </div>

      {/* --- SECONDARY STATS --- */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <MiniStat label="Pending Orders" value={`${pendingOrders}`} color="text-amber-600 bg-amber-50" />
        <MiniStat label="Canceled" value={`${canceledOrders}`} color="text-rose-600 bg-rose-50" />
        <MiniStat label="Avg Rating" value={`${avgRating} ★`} color="text-amber-600 bg-amber-50" />
        <MiniStat label="Reviews" value={`${reviewsTotal}`} color="text-blue-600 bg-blue-50" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* LEFT COLUMN - 9/12 */}
        <div className="lg:col-span-9 space-y-6">

          {/* CUSTOMER ACTIVITY CHART (aesthetic placeholder with real legend) */}
          <div className="bg-white rounded-2xl border border-[#EEEEEE] p-5 shadow-sm">
            <div className="flex justify-between items-center mb-6">
              <h2 className="font-bold text-gray-800 text-xs uppercase tracking-widest">Revenue Overview</h2>
              <div className="flex items-center gap-4">
                <div className="hidden sm:flex items-center gap-4">
                  <div className="flex items-center gap-1.5"><div className="w-2 h-2 rounded-full bg-[#5D5FEF]" /><span className="text-[10px] font-bold text-gray-400">Orders</span></div>
                  <div className="flex items-center gap-1.5"><div className="w-2 h-2 rounded-full bg-[#FFB340]" /><span className="text-[10px] font-bold text-gray-400">Revenue</span></div>
                </div>
                <MoreHorizontal size={16} className="text-gray-400 cursor-pointer" />
              </div>
            </div>

            <div className="h-48 w-full relative">
              <div className="absolute inset-0 flex flex-col justify-between text-[9px] text-gray-400 font-bold h-[80%] pointer-events-none">
                <span>AED {(totalRevenue * 1.2).toLocaleString("en-IN", { maximumFractionDigits: 0 })}</span>
                <span>AED {(totalRevenue * 0.6).toLocaleString("en-IN", { maximumFractionDigits: 0 })}</span>
                <span>AED 0</span>
              </div>

              <div className="ml-12 h-full relative">
                <div className="absolute inset-0 flex flex-col justify-between h-[80%] pt-1 pointer-events-none opacity-40">
                  {[...Array(3)].map((_, i) => <div key={i} className="w-full border-t border-dashed border-gray-200" />)}
                </div>

                <svg className="w-full h-full pt-2 pb-8 overflow-visible" viewBox="0 0 1000 100" preserveAspectRatio="none">
                  <path d="M0,80 C150,75 300,85 500,60 C700,40 850,55 1000,45" fill="none" stroke="#FFB340" strokeWidth="2.5" strokeLinecap="round" />
                  <path d="M0,60 C150,55 300,40 500,45 C700,20 850,15 1000,5" fill="none" stroke="#5D5FEF" strokeWidth="2.5" strokeLinecap="round" />
                  <circle cx="700" cy="20" r="3" fill="white" stroke="#121212" strokeWidth="2" />
                </svg>

                <div className="flex justify-between absolute bottom-0 w-full text-[9px] text-gray-400 font-bold uppercase">
                  {['Jan', 'Mar', 'May', 'Jul', 'Sep', 'Nov'].map(m => <span key={m}>{m}</span>)}
                </div>
              </div>
            </div>
          </div>

          {/* RECENT ORDERS — from real data */}
          <div className="bg-white rounded-2xl border border-[#EEEEEE] overflow-hidden shadow-sm">
            <div className="px-5 py-4 border-b border-[#EEEEEE] bg-[#FAFAFA] flex justify-between items-center">
              <h2 className="text-[10px] font-bold uppercase tracking-widest text-[#A1A1AA]">Recent Orders</h2>
              <button className="text-[10px] font-bold text-[#71717A] hover:text-black flex items-center gap-1 transition-colors">
                View All <ChevronRight size={12} />
              </button>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left">
                <thead>
                  <tr className="text-[10px] font-bold text-[#A1A1AA] uppercase bg-white border-b border-[#EEEEEE]">
                    <th className="px-5 py-3">Order</th>
                    <th className="px-5 py-3">Items</th>
                    <th className="px-5 py-3">Date</th>
                    <th className="px-5 py-3 text-right">Total</th>
                    <th className="px-5 py-3 text-right">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#F4F4F5]">
                  {isLoading && recentOrders.length === 0 ? (
                    Array.from({ length: 3 }).map((_, i) => (
                      <tr key={i} className="animate-pulse">
                        <td className="px-5 py-4"><div className="h-4 w-16 bg-gray-100 rounded" /></td>
                        <td className="px-5 py-4"><div className="h-4 w-24 bg-gray-100 rounded" /></td>
                        <td className="px-5 py-4"><div className="h-4 w-16 bg-gray-100 rounded" /></td>
                        <td className="px-5 py-4"><div className="h-4 w-12 bg-gray-100 rounded ml-auto" /></td>
                        <td className="px-5 py-4"><div className="h-5 w-16 bg-gray-100 rounded-full ml-auto" /></td>
                      </tr>
                    ))
                  ) : recentOrders.length > 0 ? (
                    recentOrders.map((order) => (
                      <RecentOrderRow key={order.id} order={order} />
                    ))
                  ) : (
                    <tr>
                      <td colSpan={5} className="px-5 py-8 text-center text-xs text-[#A1A1AA]">
                        No orders yet
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* RIGHT COLUMN - 3/12 */}
        <div className="lg:col-span-3 space-y-6">
          {/* LOW STOCK ALERT — from real products data */}
          <div className="bg-white rounded-2xl border border-rose-100 p-5 shadow-sm">
            <div className="flex items-center gap-2 mb-4 text-rose-600">
              <AlertCircle size={14} />
              <h2 className="text-[10px] font-bold uppercase tracking-widest">Low Stock</h2>
            </div>
            <div className="space-y-3">
              {lowStockProducts.length > 0 ? (
                lowStockProducts.map((item) => (
                  <LowStockItem key={item.id} product={item} />
                ))
              ) : (
                <p className="text-xs text-[#A1A1AA] italic py-2">All products are well stocked!</p>
              )}
            </div>
          </div>

          {/* ORDER STATUS BREAKDOWN */}
          <div className="bg-white rounded-2xl border border-[#EEEEEE] p-5 shadow-sm">
            <h2 className="text-[10px] font-bold uppercase tracking-widest text-[#A1A1AA] mb-4">Order Status</h2>
            <div className="space-y-3">
              {statusBreakdown.length > 0 ? (
                statusBreakdown.map((s) => (
                  <BreakdownBar key={s.label} label={s.label} percentage={s.percentage} color={statusColor(s.label)} />
                ))
              ) : (
                <p className="text-xs text-[#A1A1AA] italic">No order data</p>
              )}
            </div>
          </div>

          {/* PAYMENT METHOD BREAKDOWN */}
          <div className="bg-white rounded-2xl border border-[#EEEEEE] p-5 shadow-sm">
            <h2 className="text-[10px] font-bold uppercase tracking-widest text-[#A1A1AA] mb-4">Payment Methods</h2>
            <div className="space-y-3">
              {methodBreakdown.length > 0 ? (
                methodBreakdown.map((m) => (
                  <BreakdownBar key={m.label} label={m.label} percentage={m.percentage} color={methodColor(m.label)} />
                ))
              ) : (
                <p className="text-xs text-[#A1A1AA] italic">No payment data</p>
              )}
            </div>
          </div>

          {/* QUICK REVIEW STATS */}
          <div className="bg-white rounded-2xl border border-[#EEEEEE] p-5 shadow-sm">
            <div className="flex items-center gap-2 mb-3">
              <MessageSquare size={14} className="text-[#A1A1AA]" />
              <h2 className="text-[10px] font-bold uppercase tracking-widest text-[#A1A1AA]">Reviews</h2>
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold">{avgRating}</span>
              <div className="flex gap-0.5">
                {[...Array(5)].map((_, i) => (
                  <Star
                    key={i}
                    size={12}
                    className={i < Math.round(parseFloat(avgRating)) ? "fill-amber-400 text-amber-400" : "text-slate-200"}
                  />
                ))}
              </div>
            </div>
            <p className="text-[10px] text-[#A1A1AA] mt-1">{reviewsTotal} total reviews</p>
          </div>
        </div>
      </div>
    </div>
  );
};

/* ── SUB-COMPONENTS ── */

const StatCard = ({ label, value, sub, icon, trend }: {
  label: string; value: string; sub?: string; icon: React.ReactNode; trend: "up" | "down";
}) => (
  <div className="bg-white p-5 rounded-2xl border border-[#EEEEEE] transition-all hover:shadow-sm hover:border-[#D4D4D8]">
    <div className="flex justify-between items-start mb-3">
      <div className="text-[#71717A]">{icon}</div>
      <div className={`flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full ${trend === "up" ? "text-emerald-600 bg-emerald-50" : "text-rose-600 bg-rose-50"}`}>
        {trend === "up" ? <ArrowUpRight size={10} /> : <ArrowDownRight size={10} />}
        <TrendingUp size={10} />
      </div>
    </div>
    <p className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest">{label}</p>
    <h3 className="text-2xl font-bold mt-1 tracking-tight">{value}</h3>
    {sub && <p className="text-[10px] text-emerald-600 font-medium mt-0.5">{sub}</p>}
  </div>
);

const MiniStat = ({ label, value, color }: { label: string; value: string; color: string }) => (
  <div className="bg-white p-4 rounded-2xl border border-[#EEEEEE] flex items-center justify-between hover:border-[#D4D4D8] transition-colors">
    <p className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-wider">{label}</p>
    <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${color}`}>{value}</span>
  </div>
);

const RecentOrderRow = ({ order }: { order: Order }) => {
  const itemNames = order.items.length > 0
    ? order.items.map((i) => i.productName).join(", ")
    : "—";

  return (
    <tr className="text-xs hover:bg-[#FBFBFA] transition-colors">
      <td className="px-5 py-4">
        <p className="font-mono text-[10px] font-bold text-[#71717A]">{order.orderNumber}</p>
      </td>
      <td className="px-5 py-4">
        <p className="font-bold truncate max-w-[180px]">{itemNames}</p>
      </td>
      <td className="px-5 py-4 text-[#A1A1AA]">
        {new Date(order.createdAt).toLocaleDateString("en-IN", { day: "2-digit", month: "short" })}
      </td>
      <td className="px-5 py-4 font-bold text-right font-mono">AED {order.total.toLocaleString("en-IN")}</td>
      <td className="px-5 py-4 text-right">
        <OrderStatusBadge status={order.status} />
      </td>
    </tr>
  );
};

const OrderStatusBadge = ({ status }: { status: string }) => {
  const styles: Record<string, string> = {
    delivered: "border-emerald-100 text-emerald-600 bg-emerald-50",
    confirmed: "border-blue-100 text-blue-600 bg-blue-50",
    processing: "border-amber-100 text-amber-600 bg-amber-50",
    pending: "border-gray-200 text-gray-600 bg-gray-50",
    shipped: "border-indigo-100 text-indigo-600 bg-indigo-50",
    cancelled: "border-rose-100 text-rose-600 bg-rose-50",
  };
  return (
    <span className={`text-[9px] font-bold px-2 py-0.5 rounded border capitalize ${styles[status] || "border-gray-200 text-gray-600 bg-gray-50"}`}>
      {status}
    </span>
  );
};

const LowStockItem = ({ product }: { product: Product }) => (
  <div className="flex flex-col gap-1 pb-2 border-b border-gray-50 last:border-0">
    <p className="text-[11px] font-bold truncate">{product.name}</p>
    <div className="flex justify-between items-center">
      <span className={`text-[9px] font-bold px-1.5 py-0.5 rounded ${product.stock === 0 ? "bg-rose-100 text-rose-700" : "bg-orange-50 text-orange-600"}`}>
        {product.stock === 0 ? "Out of Stock" : `${product.stock} left`}
      </span>
      <span className="text-[9px] font-mono text-[#A1A1AA]">₹{product.price.toLocaleString("en-IN")}</span>
    </div>
  </div>
);

const BreakdownBar = ({ label, percentage, color }: { label: string; percentage: number; color: string }) => (
  <div className="space-y-1">
    <div className="flex justify-between text-[10px] font-bold">
      <span className="capitalize">{label}</span>
      <span className="text-[#71717A]">{percentage}%</span>
    </div>
    <div className="w-full h-1.5 bg-gray-100 rounded-full overflow-hidden">
      <div className={`h-full ${color} transition-all duration-700`} style={{ width: `${percentage}%` }} />
    </div>
  </div>
);

function statusColor(status: string): string {
  const colors: Record<string, string> = {
    delivered: "bg-emerald-500",
    confirmed: "bg-blue-500",
    processing: "bg-amber-500",
    pending: "bg-gray-400",
    shipped: "bg-indigo-500",
    cancelled: "bg-rose-500",
  };
  return colors[status] ?? "bg-gray-300";
}

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

export default Dashboard;