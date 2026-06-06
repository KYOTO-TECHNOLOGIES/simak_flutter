import React, { useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { Trash2, Plus, Minus, ArrowRight, ShoppingBag, ShieldCheck } from 'lucide-react';
import { useAppDispatch, useAppSelector } from '../../hooks';
import {
    fetchCartRequest,
    removeFromCart,
    updateQuantity,
    selectCartItems,
    selectCartTotal,
    selectCartError,
} from '../admin/cart/cartSlice';

const CartPage: React.FC = () => {
    const navigate = useNavigate();
    const dispatch = useAppDispatch();
    const cartItems = useAppSelector(selectCartItems);
    const cartTotal = useAppSelector(selectCartTotal);
    const cartError = useAppSelector(selectCartError);
    const isAuthenticated = useAppSelector((s) => s.auth.isAuthenticated);
    const checkingAuth = useAppSelector((s) => s.auth.checkingAuth);

    // Fetch cart from API only if cart is empty (e.g. after page refresh)
    // If items already exist in Redux (from optimistic addToCart), skip
    // to avoid overwriting local items before sync completes
    useEffect(() => {
        if (!checkingAuth && isAuthenticated && cartItems.length === 0) {
            dispatch(fetchCartRequest());
        }
    }, [dispatch, checkingAuth, isAuthenticated]); // intentionally omit cartItems

    // Loading state removed as requested

    // Error state
    if (cartError) {
        return (
            <div className="min-h-screen bg-stone-50 flex flex-col items-center justify-center gap-4">
                <ShoppingBag size={40} className="text-stone-300" />
                <p className="text-red-500 font-bold">{cartError}</p>
                <button
                    onClick={() => navigate('/products')}
                    className="px-6 py-2 bg-red-900 text-white rounded-full font-bold hover:bg-red-800 transition-colors"
                >
                    Continue Shopping
                </button>
            </div>
        );
    }

    const shippingCost = cartTotal > 500 ? 0 : 50; // Free shipping over AED 500
    const finalTotal = cartTotal + shippingCost;

    if (cartItems.length === 0) {
        return (
            <div className="min-h-screen bg-stone-50 flex flex-col items-center justify-center p-4">
                <div className="w-24 h-24 bg-white rounded-full flex items-center justify-center mb-6 shadow-sm">
                    <ShoppingBag size={40} className="text-stone-300" />
                </div>
                <h2 className="text-2xl font-black text-stone-900 mb-2">Your cart is empty</h2>
                <p className="text-stone-500 mb-8 max-w-sm text-center">
                    Looks like you haven't added any fresh catch to your cart yet.
                </p>
                <button
                    onClick={() => navigate('/products')}
                    className="px-8 py-3 bg-red-900 text-white rounded-full font-bold hover:bg-red-800 transition-colors flex items-center gap-2"
                >
                    Start Shopping <ArrowRight size={18} />
                </button>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-stone-50 font-sans text-stone-800 pb-20">
            {/* Header */}
            <div className="bg-red-950 border-b border-red-900 sticky top-0 z-20 shadow-md">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4 flex items-center justify-between">
                    <h1 className="text-xl font-black text-white flex items-center gap-2">
                        <ShoppingBag size={20} className="text-yellow-500" /> Your Cart ({cartItems.length})
                    </h1>
                    <button
                        onClick={() => navigate('/products')}
                        className="text-sm font-bold text-red-200 hover:text-white transition-colors"
                    >
                        Continue Shopping
                    </button>
                </div>
            </div>

            <main className="max-w-7xl mx-auto px-4 sm:px-6 py-8 grid grid-cols-1 lg:grid-cols-3 gap-8 lg:gap-12">
                {/* Cart Items List */}
                <div className="lg:col-span-2 space-y-4">
                    <AnimatePresence>
                        {cartItems.map((item) => (
                            <motion.div
                                key={item.id}
                                layout
                                initial={{ opacity: 0, y: 10 }}
                                animate={{ opacity: 1, y: 0 }}
                                exit={{ opacity: 0, x: -100 }}
                                className="bg-white rounded-2xl p-4 border border-stone-200 flex gap-4 hover:shadow-lg transition-shadow"
                            >
                                {/* Image */}
                                <div className="w-24 h-24 bg-stone-50 rounded-xl overflow-hidden flex-shrink-0">
                                    <img
                                        src={item.image || "https://via.placeholder.com/100"}
                                        alt={item.name}
                                        className="w-full h-full object-cover"
                                    />
                                </div>

                                {/* Details */}
                                <div className="flex-1 flex flex-col justify-between">
                                    <div className="flex justify-between items-start gap-2">
                                        <div>
                                            <Link to={`/products/${item.id}`} className="font-bold text-stone-900 hover:text-red-600 transition-colors line-clamp-1">
                                                {item.name}
                                            </Link>
                                            <p className="text-xs text-stone-500 font-medium">1 {item.sku || 'unit'}</p>
                                        </div>
                                        <button
                                            onClick={() => dispatch(removeFromCart(item.id))}
                                            className="text-stone-300 hover:text-red-500 transition-colors p-1"
                                        >
                                            <Trash2 size={18} />
                                        </button>
                                    </div>

                                    <div className="flex items-end justify-between mt-2">
                                        {/* Quantity Control */}
                                        <div className="flex items-center gap-3 bg-stone-50 rounded-lg p-1 border border-stone-200">
                                            <button
                                                onClick={() => dispatch(updateQuantity({ id: item.id, quantity: item.quantity - 1 }))}
                                                className="w-7 h-7 flex items-center justify-center bg-white rounded-md text-stone-600 hover:text-black shadow-sm disabled:opacity-50"
                                                disabled={item.quantity <= 1}
                                            >
                                                <Minus size={14} />
                                            </button>
                                            <span className="text-sm font-bold w-6 text-center">{item.quantity}</span>
                                            <button
                                                onClick={() => dispatch(updateQuantity({ id: item.id, quantity: item.quantity + 1 }))}
                                                className="w-7 h-7 flex items-center justify-center bg-white rounded-md text-stone-600 hover:text-black shadow-sm disabled:opacity-50"
                                                disabled={item.quantity >= item.stock}
                                            >
                                                <Plus size={14} />
                                            </button>
                                        </div>

                                        {/* Price */}
                                        <div className="text-right">
                                            {item.discountPrice ? (
                                                <div className="flex flex-col items-end leading-none">
                                                    <span className="text-[10px] text-stone-400 line-through">AED {item.price * item.quantity}</span>
                                                    <span className="text-lg font-black text-red-900">AED {item.finalPrice * item.quantity}</span>
                                                </div>
                                            ) : (
                                                <span className="text-lg font-black text-red-900">AED {item.price * item.quantity}</span>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            </motion.div>
                        ))}
                    </AnimatePresence>
                </div>

                {/* Summary Panel */}
                <div className="lg:col-span-1">
                    <div className="bg-white rounded-3xl p-6 border border-stone-200 shadow-sm sticky top-24 space-y-6">
                        <h2 className="text-lg font-black text-stone-900">Order Summary</h2>

                        <div className="space-y-3 pb-6 border-b border-stone-100">
                            <div className="flex justify-between text-sm text-stone-500">
                                <span>Subtotal</span>
                                <span className="font-bold text-stone-900">AED {cartTotal}</span>
                            </div>
                            <div className="flex justify-between text-sm text-stone-500">
                                <span>Shipping</span>
                                <span className="font-bold text-green-600">{shippingCost === 0 ? "Free" : `AED ${shippingCost}`}</span>
                            </div>
                            {shippingCost > 0 && (
                                <p className="text-xs text-stone-400 italic">
                                    Add AED {500 - cartTotal} more for free shipping
                                </p>
                            )}
                        </div>

                        <div className="flex justify-between items-end">
                            <span className="text-sm font-bold text-stone-900">Total</span>
                            <span className="text-2xl font-black text-red-900">AED {finalTotal}</span>
                        </div>

                        <button
                            className="w-full py-4 bg-red-900 text-white rounded-xl font-bold hover:bg-red-800 transition-all shadow-lg flex items-center justify-center gap-2 group shadow-red-900/20"
                            onClick={() => navigate('/checkout')}
                        >
                            Proceed to Checkout <ArrowRight size={18} className="group-hover:translate-x-1 transition-transform" />
                        </button>

                        <div className="flex items-center justify-center gap-2 text-xs text-stone-400 bg-stone-50 py-2 rounded-lg">
                            <ShieldCheck size={14} className="text-yellow-500" /> Secure Checkout
                        </div>
                    </div>
                </div>
            </main>
        </div>
    );
};

export default CartPage;
