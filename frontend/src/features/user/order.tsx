import React, { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import {
    Package,
    Clock,
    CheckCircle,
    XCircle,
    ChevronRight,
    Truck,
    Calendar,
    AlertCircle
} from "lucide-react";
import { ordersApi, type OrderDto } from "../admin/orders/ordersApi";

const OrderPage: React.FC = () => {
    const [orders, setOrders] = useState<OrderDto[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        fetchOrders();
    }, []);

    const fetchOrders = async () => {
        try {
            setLoading(true);
            const data = await ordersApi.list();
            // If the API returns paginated results, we might need data.results
            // Based on the file viewed earlier, it returns { results: [], count: ... }
            setOrders(data.results || []);
        } catch (err) {
            setError("Failed to load your orders.");
        } finally {
            setLoading(false);
        }
    };

    const getStatusColor = (status: string) => {
        switch (status.toLowerCase()) {
            case "delivered":
            case "completed":
                return "text-emerald-600 bg-emerald-50 border-emerald-100";
            case "processing":
            case "confirmed":
                return "text-blue-600 bg-blue-50 border-blue-100";
            case "shipped":
                return "text-amber-600 bg-amber-50 border-amber-100";
            case "cancelled":
            case "returned":
                return "text-red-600 bg-red-50 border-red-100";
            default:
                return "text-slate-600 bg-slate-50 border-slate-100";
        }
    };

    const getStatusIcon = (status: string) => {
        switch (status.toLowerCase()) {
            case "delivered":
                return <CheckCircle size={14} />;
            case "processing":
                return <Package size={14} />;
            case "shipped":
                return <Truck size={14} />;
            case "cancelled":
                return <XCircle size={14} />;
            default:
                return <Clock size={14} />;
        }
    };

    return (
        <div className="min-h-screen bg-[#FDFDFD] font-sans text-slate-800 pb-20">
            {/* Header */}
            <div className="bg-white border-b border-slate-100 top-[60px] z-30">
                <div className="max-w-3xl mx-auto px-4 sm:px-6 py-8">
                    <h1 className="text-2xl font-black text-slate-900 tracking-tight flex items-center gap-3">
                        <Package className="text-rose-600" size={28} />
                        My Orders
                    </h1>
                    <p className="text-sm text-slate-500 mt-2 font-medium">
                        Track your past purchases and current deliveries.
                    </p>
                </div>
            </div>

            <main className="max-w-3xl mx-auto px-4 sm:px-6 py-8">
                {loading ? (
                    <div className="space-y-4">
                        {[1, 2, 3].map((i) => (
                            <div
                                key={i}
                                className="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm animate-pulse space-y-3"
                            >
                                <div className="h-5 bg-slate-100 rounded-full w-1/3" />
                                <div className="h-4 bg-slate-100 rounded-full w-1/4" />
                                <div className="h-16 bg-slate-50 rounded-2xl w-full" />
                            </div>
                        ))}
                    </div>
                ) : error ? (
                    <div className="text-center py-20 bg-white rounded-3xl border border-red-100 shadow-sm">
                        <AlertCircle className="mx-auto text-red-500 mb-4" size={32} />
                        <h3 className="text-lg font-bold text-slate-900">Oops!</h3>
                        <p className="text-slate-500 text-sm mt-1">{error}</p>
                        <button
                            onClick={fetchOrders}
                            className="mt-4 text-sm font-bold text-rose-600 hover:text-rose-700 underline"
                        >
                            Try Again
                        </button>
                    </div>
                ) : orders.length === 0 ? (
                    <div className="text-center py-24 bg-white rounded-[2.5rem] border border-slate-100 shadow-sm">
                        <div className="w-16 h-16 bg-rose-50 rounded-2xl flex items-center justify-center mx-auto mb-6 transform rotate-3">
                            <Package className="text-rose-500" size={32} />
                        </div>
                        <h3 className="text-xl font-black text-slate-900 mb-2">
                            No orders yet
                        </h3>
                        <p className="text-slate-400 text-sm mb-8 max-w-xs mx-auto">
                            Looks like you haven't placed any orders yet. Start shopping for
                            fresh catch!
                        </p>
                        <Link
                            to="/products"
                            className="inline-flex items-center gap-2 px-8 py-3.5 bg-rose-600 text-white rounded-2xl font-bold text-sm hover:bg-rose-700 hover:shadow-lg hover:shadow-rose-500/20 transition-all active:scale-95"
                        >
                            Start Shopping
                        </Link>
                    </div>
                ) : (
                    <div className="space-y-4">
                        {orders.map((order, index) => (
                            <motion.div
                                key={order.id}
                                initial={{ opacity: 0, y: 20 }}
                                animate={{ opacity: 1, y: 0 }}
                                transition={{ delay: index * 0.05 }}
                                className="group bg-white rounded-3xl border border-slate-100 p-6 hover:shadow-xl hover:shadow-rose-500/5 transition-all duration-300 relative overflow-hidden"
                            >
                                {/* Status Badge */}
                                <div
                                    className={`absolute top-6 right-6 px-3 py-1.5 rounded-full text-[10px] font-black uppercase tracking-widest border flex items-center gap-1.5 ${getStatusColor(
                                        order.status
                                    )}`}
                                >
                                    {getStatusIcon(order.status)}
                                    {order.status}
                                </div>

                                <div className="space-y-6">
                                    {/* Order Info */}
                                    <div>
                                        <div className="flex items-center gap-2 text-slate-400 text-[10px] font-bold uppercase tracking-widest mb-1.5">
                                            <Calendar size={12} />
                                            {new Date(order.created_at).toLocaleDateString("en-IN", {
                                                year: "numeric",
                                                month: "short",
                                                day: "numeric",
                                            })}
                                        </div>
                                        <h3 className="text-lg font-black text-slate-900">
                                            Order #{order.id}
                                        </h3>
                                    </div>

                                    {/* Items Preview */}
                                    <div className="flex gap-3 overflow-x-auto no-scrollbar pb-2">
                                        {order.items.slice(0, 4).map((item) => (
                                            <div
                                                key={item.id}
                                                className="flex-shrink-0 w-16 h-16 bg-slate-50 rounded-xl border border-slate-100 flex items-center justify-center relative"
                                            >
                                                {/* Placeholder for product image if available, else icon */}
                                                <Package size={20} className="text-slate-300" />
                                                <span className="absolute -bottom-1.5 -right-1.5 w-5 h-5 bg-white shadow-sm border border-slate-100 rounded-full flex items-center justify-center text-[9px] font-bold text-slate-600">
                                                    x{item.quantity}
                                                </span>
                                            </div>
                                        ))}
                                        {order.items.length > 4 && (
                                            <div className="flex-shrink-0 w-16 h-16 bg-slate-50 rounded-xl border border-slate-100 flex items-center justify-center text-xs font-bold text-slate-400">
                                                +{order.items.length - 4}
                                            </div>
                                        )}
                                    </div>

                                    {/* Footer */}
                                    <div className="pt-6 border-t border-slate-50 flex items-center justify-between">
                                        <div>
                                            <p className="text-[10px] font-bold uppercase tracking-widest text-slate-400 mb-0.5">Total Amount</p>
                                            <p className="text-lg font-black text-slate-900">AED {order.total_amount}</p>
                                        </div>

                                        <button className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-slate-50 text-slate-600 text-xs font-bold hover:bg-rose-50 hover:text-rose-600 transition-colors">
                                            View Details <ChevronRight size={14} />
                                        </button>
                                    </div>
                                </div>
                            </motion.div>
                        ))}
                    </div>
                )}
            </main>
        </div>
    );
};

export default OrderPage;
