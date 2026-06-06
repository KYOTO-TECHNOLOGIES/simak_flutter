import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { useNavigate } from 'react-router-dom';
import { useAppDispatch, useAppSelector } from '../../hooks';
import { selectCartItems, selectCartTotal, clearCart } from '../admin/cart/cartSlice';
import { ordersApi } from '../admin/orders/ordersApi';
import { CheckCircle, MapPin, CreditCard, Truck, ArrowLeft, Loader2 } from 'lucide-react';
import { motion } from 'framer-motion';

interface CheckoutFormInputs {
    fullName: string;
    phoneNumber: string;
    email: string;
    address: string;
    city: string;
    state: string;
    zipCode: string;
    paymentMethod: 'COD' | 'ONLINE';
}

const CheckoutPage: React.FC = () => {
    const navigate = useNavigate();
    const dispatch = useAppDispatch();
    const cartItems = useAppSelector(selectCartItems);
    const cartTotal = useAppSelector(selectCartTotal);
    const [submitting, setSubmitting] = useState(false);
    const [orderSuccess, setOrderSuccess] = useState(false);

    const { register, handleSubmit, formState: { errors } } = useForm<CheckoutFormInputs>({
        defaultValues: {
            paymentMethod: 'COD'
        }
    });

    const shippingCost = cartTotal > 500 ? 0 : 50;
    const finalTotal = cartTotal + shippingCost;

    const onSubmit = async (data: CheckoutFormInputs) => {
        setSubmitting(true);
        try {
            // Prepare payload
            const orderPayload = {
                items: cartItems.map(item => ({
                    product_id: item.id,
                    quantity: item.quantity,
                    price: item.finalPrice
                })),
                shipping_address: {
                    full_name: data.fullName,
                    phone_number: data.phoneNumber,
                    street_address: data.address,
                    city: data.city,
                    state: data.state,
                    postal_code: data.zipCode,
                    email: data.email
                },
                payment_method: data.paymentMethod,
                total_amount: finalTotal
            };

            await ordersApi.create(orderPayload);
            dispatch(clearCart());
            setOrderSuccess(true);
            setTimeout(() => {
                navigate('/');
            }, 3000);
        } catch (error) {
            console.error("Failed to place order", error);
            // Handle error (show toast/alert)
            alert("Failed to place order. Please try again.");
        } finally {
            setSubmitting(false);
        }
    };

    if (cartItems.length === 0 && !orderSuccess) {
        return (
            <div className="min-h-screen bg-slate-50 flex flex-col items-center justify-center">
                <p className="text-slate-500 mb-4">Your cart is empty.</p>
                <button onClick={() => navigate('/products')} className="text-rose-600 hover:underline">
                    Go Shopping
                </button>
            </div>
        );
    }

    if (orderSuccess) {
        return (
            <div className="min-h-screen bg-green-50 flex flex-col items-center justify-center p-4 text-center">
                <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    className="w-24 h-24 bg-green-100 rounded-full flex items-center justify-center text-green-600 mb-6"
                >
                    <CheckCircle size={48} />
                </motion.div>
                <h2 className="text-3xl font-black text-slate-900 mb-2">Order Placed Successfully!</h2>
                <p className="text-slate-600 mb-6">Thank you for your fresh catch. We're preparing it now.</p>
                <p className="text-sm text-slate-400">Redirecting to home...</p>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-[#FDFDFD] font-sans text-slate-800 pb-20">
            {/* Header */}
            <div className="bg-white border-b border-slate-100 sticky top-0 z-20">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4 flex items-center gap-4">
                    <button onClick={() => navigate('/cart')} className="text-slate-400 hover:text-rose-600">
                        <ArrowLeft size={20} />
                    </button>
                    <h1 className="text-xl font-black text-slate-900">Checkout</h1>
                </div>
            </div>

            <main className="max-w-7xl mx-auto px-4 sm:px-6 py-8 grid grid-cols-1 lg:grid-cols-3 gap-8 lg:gap-12">

                {/* Form Section */}
                <div className="lg:col-span-2 space-y-8">
                    <form id="checkout-form" onSubmit={handleSubmit(onSubmit)} className="space-y-8">

                        {/* Shipping Address */}
                        <div className="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm space-y-6">
                            <div className="flex items-center gap-3 mb-2">
                                <div className="p-2 bg-amber-50 rounded-lg text-amber-600"><MapPin size={20} /></div>
                                <h2 className="text-lg font-black text-slate-900">Shipping Details</h2>
                            </div>

                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <div className="space-y-1">
                                    <label className="text-xs font-bold text-slate-500 uppercase">Full Name</label>
                                    <input
                                        {...register("fullName", { required: "Name is required" })}
                                        className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-rose-500 outline-none transition-all"
                                        placeholder="John Doe"
                                    />
                                    {errors.fullName && <p className="text-rose-500 text-xs mt-1">{errors.fullName.message}</p>}
                                </div>
                                <div className="space-y-1">
                                    <label className="text-xs font-bold text-slate-500 uppercase">Phone Number</label>
                                    <input
                                        {...register("phoneNumber", { required: "Phone is required" })}
                                        className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-rose-500 outline-none transition-all"
                                        placeholder="+91 9876543210"
                                    />
                                    {errors.phoneNumber && <p className="text-rose-500 text-xs mt-1">{errors.phoneNumber.message}</p>}
                                </div>
                                <div className="space-y-1 md:col-span-2">
                                    <label className="text-xs font-bold text-slate-500 uppercase">Email Address</label>
                                    <input
                                        {...register("email", { required: "Email is required", pattern: { value: /^\S+@\S+$/i, message: "Invalid email" } })}
                                        className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-rose-500 outline-none transition-all"
                                        placeholder="john@example.com"
                                    />
                                    {errors.email && <p className="text-rose-500 text-xs mt-1">{errors.email.message}</p>}
                                </div>
                                <div className="space-y-1 md:col-span-2">
                                    <label className="text-xs font-bold text-slate-500 uppercase">Street Address</label>
                                    <textarea
                                        {...register("address", { required: "Address is required" })}
                                        className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-rose-500 outline-none transition-all"
                                        placeholder="123 Ocean Drive, Apt 4B"
                                        rows={2}
                                    />
                                    {errors.address && <p className="text-rose-500 text-xs mt-1">{errors.address.message}</p>}
                                </div>
                                <div className="space-y-1">
                                    <label className="text-xs font-bold text-slate-500 uppercase">City</label>
                                    <input
                                        {...register("city", { required: "City is required" })}
                                        className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-rose-500 outline-none transition-all"
                                        placeholder="Mumbai"
                                    />
                                    {errors.city && <p className="text-rose-500 text-xs mt-1">{errors.city.message}</p>}
                                </div>
                                <div className="space-y-1">
                                    <label className="text-xs font-bold text-slate-500 uppercase">State</label>
                                    <input
                                        {...register("state", { required: "State is required" })}
                                        className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-rose-500 outline-none transition-all"
                                        placeholder="Maharashtra"
                                    />
                                    {errors.state && <p className="text-rose-500 text-xs mt-1">{errors.state.message}</p>}
                                </div>
                                <div className="space-y-1">
                                    <label className="text-xs font-bold text-slate-500 uppercase">Zip Code</label>
                                    <input
                                        {...register("zipCode", { required: "Zip Code is required" })}
                                        className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-rose-500 outline-none transition-all"
                                        placeholder="400001"
                                    />
                                    {errors.zipCode && <p className="text-rose-500 text-xs mt-1">{errors.zipCode.message}</p>}
                                </div>
                            </div>
                        </div>

                        {/* Payment Method */}
                        <div className="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm space-y-6">
                            <div className="flex items-center gap-3 mb-2">
                                <div className="p-2 bg-green-50 rounded-lg text-green-600"><CreditCard size={20} /></div>
                                <h2 className="text-lg font-black text-slate-900">Payment Method</h2>
                            </div>

                            <div className="space-y-3">
                                <label className="flex items-center gap-4 p-4 border border-slate-200 rounded-xl cursor-pointer hover:border-rose-500 transition-colors has-[:checked]:border-rose-500 has-[:checked]:bg-rose-50">
                                    <input type="radio" value="COD" {...register("paymentMethod")} className="w-5 h-5 text-rose-600 focus:ring-rose-500" />
                                    <div className="flex-1">
                                        <p className="font-bold text-slate-900">Cash on Delivery</p>
                                        <p className="text-xs text-slate-500">Pay when you receive your order</p>
                                    </div>
                                    <Truck size={20} className="text-slate-400" />
                                </label>
                                <label className="flex items-center gap-4 p-4 border border-slate-200 rounded-xl cursor-not-allowed opacity-60">
                                    <input type="radio" value="ONLINE" disabled className="w-5 h-5 text-rose-600 focus:ring-rose-500" />
                                    <div className="flex-1">
                                        <p className="font-bold text-slate-900">Online Payment (Coming Soon)</p>
                                        <p className="text-xs text-slate-500">Credit Card, UPI, Net Banking</p>
                                    </div>
                                    <CreditCard size={20} className="text-slate-400" />
                                </label>
                            </div>
                        </div>
                    </form>
                </div>

                {/* Order Summary */}
                <div className="lg:col-span-1">
                    <div className="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm sticky top-24 space-y-6">
                        <h2 className="text-lg font-black text-slate-900">Order Summary</h2>

                        <div className="space-y-4 max-h-60 overflow-y-auto pr-2 custom-scrollbar">
                            {cartItems.map((item) => (
                                <div key={item.id} className="flex gap-4">
                                    <div className="w-16 h-16 bg-slate-50 rounded-lg overflow-hidden flex-shrink-0">
                                        <img src={item.image || ""} alt={item.name} className="w-full h-full object-cover" />
                                    </div>
                                    <div className="flex-1">
                                        <p className="text-sm font-bold text-slate-900 line-clamp-1">{item.name}</p>
                                        <p className="text-xs text-slate-500">{item.quantity} x AED {item.finalPrice}</p>
                                    </div>
                                    <div className="text-sm font-bold text-slate-900">
                                        AED {item.finalPrice * item.quantity}
                                    </div>
                                </div>
                            ))}
                        </div>

                        <div className="border-t border-slate-100 pt-4 space-y-2">
                            <div className="flex justify-between text-sm text-slate-500">
                                <span>Subtotal</span>
                                <span className="font-bold text-slate-900">AED {cartTotal}</span>
                            </div>
                            <div className="flex justify-between text-sm text-slate-500">
                                <span>Shipping</span>
                                <span className="font-bold text-green-600">{shippingCost === 0 ? "Free" : `AED ${shippingCost}`}</span>
                            </div>
                            <div className="flex justify-between items-end pt-2 border-t border-slate-100 mt-2">
                                <span className="text-base font-bold text-slate-900">Total</span>
                                <span className="text-2xl font-black text-slate-900">AED {finalTotal}</span>
                            </div>
                        </div>

                        <button
                            type="submit"
                            form="checkout-form"
                            disabled={submitting}
                            className="w-full py-4 bg-rose-600 text-white rounded-xl font-bold hover:bg-rose-700 transition-all shadow-lg flex items-center justify-center gap-2 disabled:opacity-70 disabled:cursor-not-allowed shadow-rose-500/20"
                        >
                            {submitting ? <Loader2 className="animate-spin" /> : "Place Order"}
                        </button>
                    </div>
                </div>
            </main>
        </div>
    );
};

export default CheckoutPage;
