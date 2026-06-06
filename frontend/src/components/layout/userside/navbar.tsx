import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { ShoppingCart, User, MapPin, Phone, LogOut, LogIn, Bell, Package, Menu, X, ChevronRight } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { useAppDispatch, useAppSelector } from '../../../hooks';
import { logout } from '../../../features/auth/authSlice';
import { selectCartItems } from '../../../features/admin/cart/cartSlice';

const Navbar: React.FC = () => {
    const dispatch = useAppDispatch();
    const navigate = useNavigate();
    const isAuthenticated = useAppSelector((state: any) => state.auth.isAuthenticated);
    const cartItems = useAppSelector(selectCartItems);
    const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

    const handleLogout = () => {
        dispatch(logout());
        navigate('/login');
    };

    return (
        <div className="w-full font-sans text-slate-800 select-none">
            {/* ═══ 1  TOP UTILITY BAR ════════════════════════════ */}
            <div className="bg-red-950 text-red-50 text-[11px]">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 py-2.5 flex items-center justify-between">

                    <div className="flex items-center gap-5">
                        <span className="flex items-center gap-1.5 hover:text-white transition-colors cursor-pointer">
                            <MapPin size={12} className="text-yellow-400" />
                            <span className="hidden sm:inline">Delivering to your doorstep</span>
                        </span>
                        <span className="hidden md:flex items-center gap-1.5 hover:text-white transition-colors cursor-pointer">
                            <Phone size={12} className="text-yellow-400" />
                            +91 90470 11110
                        </span>
                    </div>

                    <div className="flex items-center gap-1">
                        {['Offers', 'Track Order', 'Support'].map((link) => (
                            <Link
                                key={link}
                                to="#"
                                className="px-3 py-1 rounded-md hover:bg-white/5 hover:text-white transition-all"
                            >
                                {link}
                            </Link>
                        ))}
                    </div>
                </div>
            </div>

            {/* ═══ 2  MAIN HEADER ════════════════════════════════ */}
            <header className="bg-white/80 backdrop-blur-lg border-b border-slate-100 sticky top-0 z-40">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 py-2 flex items-center justify-between gap-4">

                    {/* Logo */}
                    <Link to="/" className="flex-shrink-0 flex items-center gap-3 group">
                        <div className="relative">
                            <div className="w-9 h-9 rounded-xl bg-red-600 flex items-center justify-center shadow-lg shadow-red-500/30 group-hover:shadow-red-500/50 transition-shadow">
                                <span className="text-white font-black text-lg leading-none">F</span>
                            </div>
                        </div>
                        <div className="hidden sm:block">
                            <p className="text-base font-extrabold tracking-tight text-slate-900 leading-none">
                                Fresh<span className="text-red-600">Ma</span>
                            </p>
                            <p className="text-[8px] text-slate-400 font-semibold tracking-[0.2em] uppercase mt-0.5">Online Fish Market</p>
                        </div>
                    </Link>

                    {/* Location */}
                    <button className="hidden lg:flex items-center gap-2.5 border border-slate-200 rounded-xl px-4 py-2.5 hover:border-red-300 hover:bg-red-50/40 transition-all group">
                        <div className="w-8 h-8 rounded-lg bg-red-50 flex items-center justify-center group-hover:bg-red-100 transition-colors">
                            <MapPin size={16} className="text-red-600" />
                        </div>
                        <div className="text-left">
                            <p className="text-[10px] text-slate-400 font-medium leading-none">Deliver to</p>
                            <p className="text-sm font-bold text-slate-800 group-hover:text-red-700 transition-colors">Select Location ▾</p>
                        </div>
                    </button>

                    {/* Actions */}
                    <div className="flex items-center gap-2">
                        {/* Desktop Links */}
                        <Link to="/products" className="hidden md:block text-xs font-bold text-slate-700 hover:text-red-600 transition-colors px-2">
                            Shop
                        </Link>

                        {isAuthenticated ? (
                            <Link to="/cart" className="relative flex flex-col items-center gap-0.5 min-w-[3.5rem] py-1.5 rounded-xl hover:bg-stone-50 transition-colors group">
                                <ShoppingCart size={18} className="text-stone-400 group-hover:text-red-600 transition-colors" />
                                <span className="text-[9px] font-semibold text-stone-400 group-hover:text-red-600 transition-colors">Cart</span>
                                {/* Badge */}
                                <span className="absolute top-0.5 right-1.5 bg-red-600 text-white text-[9px] font-bold rounded-full w-4 h-4 flex items-center justify-center ring-2 ring-white min-w-[16px] min-h-[16px]">
                                    {cartItems.length}
                                </span>
                            </Link>
                        ) : null}

                        {/* Desktop Account Dropdown / Login Button */}
                        {isAuthenticated ? (
                            <div className="relative group z-50 hidden md:block">
                                <button className="flex flex-col items-center gap-0.5 min-w-[3.5rem] py-1.5 rounded-xl hover:bg-slate-50 transition-colors">
                                    <User size={18} className="text-slate-400 group-hover:text-red-600 transition-colors" />
                                    <span className="text-[9px] font-semibold text-slate-400 group-hover:text-red-600 transition-colors">Account</span>
                                </button>

                                <div className="absolute right-0 top-full pt-2 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 transform origin-top-right w-48">
                                    <div className="bg-white rounded-2xl shadow-xl border border-slate-100 p-2">
                                        <Link to="/profile" className="flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-slate-50 transition-colors text-xs font-bold text-slate-600 hover:text-red-600">
                                            <User size={14} /> My Profile
                                        </Link>
                                        <Link to="/orders" className="flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-slate-50 transition-colors text-xs font-bold text-slate-600 hover:text-red-600">
                                            <Package size={14} /> My Orders
                                        </Link>
                                        <Link to="/notifications" className="flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-slate-50 transition-colors text-xs font-bold text-slate-600 hover:text-red-600">
                                            <Bell size={14} /> Notifications
                                        </Link>
                                        <div className="h-px bg-slate-100 my-1" />
                                        <button
                                            onClick={handleLogout}
                                            className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-red-50 transition-colors text-xs font-bold text-slate-600 hover:text-red-600"
                                        >
                                            <LogOut size={14} /> Logout
                                        </button>
                                    </div>
                                </div>
                            </div>
                        ) : (
                            <Link
                                to="/login"
                                className="hidden md:flex items-center gap-2 px-5 py-2 bg-red-600 text-white rounded-xl text-xs font-bold shadow-lg shadow-red-500/20 hover:bg-red-700 transition-colors"
                            >
                                <LogIn size={14} /> Login
                            </Link>
                        )}

                        {/* Mobile Menu Button - Separated from Account Group */}
                        <button
                            onClick={() => setIsMobileMenuOpen(true)}
                            className="md:hidden flex flex-col items-center justify-center w-10 h-10 rounded-xl hover:bg-slate-50 text-slate-500 hover:text-red-600 transition-colors"
                        >
                            <Menu size={24} />
                        </button>
                    </div>
                </div>
            </header >

            {/* ═══ MOBILE MENU DRAWER ════════════════════════════ */}
            <AnimatePresence>
                {
                    isMobileMenuOpen && (
                        <>
                            {/* Backdrop */}
                            <motion.div
                                initial={{ opacity: 0 }}
                                animate={{ opacity: 1 }}
                                exit={{ opacity: 0 }}
                                onClick={() => setIsMobileMenuOpen(false)}
                                className="fixed inset-0 bg-black/60 z-[60] backdrop-blur-sm md:hidden"
                            />

                            {/* Drawer */}
                            <motion.div
                                initial={{ x: '100%' }}
                                animate={{ x: 0 }}
                                exit={{ x: '100%' }}
                                transition={{ type: 'spring', damping: 25, stiffness: 200 }}
                                className="fixed top-0 right-0 h-full w-[280px] bg-white z-[70] shadow-2xl flex flex-col md:hidden"
                            >
                                {/* Header */}
                                <div className="p-4 border-b border-slate-100 flex items-center justify-between bg-red-50/50">
                                    <span className="font-bold text-lg text-slate-800">Menu</span>
                                    <button
                                        onClick={() => setIsMobileMenuOpen(false)}
                                        className="p-2 hover:bg-red-100 text-slate-500 hover:text-red-600 rounded-full transition-colors"
                                    >
                                        <X size={20} />
                                    </button>
                                </div>

                                {/* Content */}
                                <div className="flex-1 overflow-y-auto py-4">
                                    {/* User Section */}
                                    <div className="px-4 mb-6">
                                        {isAuthenticated ? (
                                            <div className="p-4 bg-white rounded-2xl border border-slate-100 shadow-sm">
                                                <div className="flex items-center gap-3 mb-3">
                                                    <div className="w-10 h-10 rounded-full bg-red-50 flex items-center justify-center text-red-600 font-bold border border-red-100">
                                                        <User size={20} />
                                                    </div>
                                                    <div>
                                                        <p className="text-sm font-bold text-slate-900">Welcome Back</p>
                                                        <p className="text-xs text-slate-500">Member</p>
                                                    </div>
                                                </div>
                                                <Link
                                                    to="/profile"
                                                    onClick={() => setIsMobileMenuOpen(false)}
                                                    className="flex items-center justify-between w-full px-3 py-2 bg-slate-50 rounded-xl text-xs font-bold text-slate-600 hover:text-red-600 transition-colors"
                                                >
                                                    View Profile <ChevronRight size={14} />
                                                </Link>
                                            </div>
                                        ) : (
                                            <div className="p-4 bg-red-50 rounded-2xl border border-red-100 text-center">
                                                <p className="text-sm font-bold text-red-900 mb-3">Welcome to FreshMa</p>
                                                <Link
                                                    to="/login"
                                                    onClick={() => setIsMobileMenuOpen(false)}
                                                    className="block w-full py-2.5 bg-red-600 text-white rounded-xl text-sm font-bold shadow-lg shadow-red-500/20 hover:bg-red-700 transition-colors"
                                                >
                                                    Login / Register
                                                </Link>
                                            </div>
                                        )}
                                    </div>

                                    {/* Navigation Links */}
                                    <div className="px-4 space-y-1">
                                        <p className="px-4 text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2">Shop</p>
                                        {[
                                            { label: 'Home', href: '/', icon: <div className="w-4 h-4 rounded-full bg-slate-200" /> }, // Fallback icon or change to import
                                            { label: 'All Products', href: '/products', icon: <Package size={18} /> },
                                            { label: 'My Cart', href: '/cart', icon: <ShoppingCart size={18} />, badge: cartItems.length },
                                            // { label: 'Wishlist', href: '/wishlist', icon: <Heart size={18} /> },
                                            { label: 'Offers', href: '/offers', icon: <div className="w-4 h-4 rounded-full bg-yellow-400/50" /> },
                                        ].map((link, i) => (
                                            <Link
                                                key={i} // simple key
                                                to={link.href}
                                                onClick={() => setIsMobileMenuOpen(false)}
                                                className="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-slate-50 text-slate-600 font-medium transition-colors"
                                            >
                                                <div className="w-5 flex justify-center text-slate-400">{link.icon}</div>
                                                <span className="flex-1">{link.label}</span>
                                                {link.badge !== undefined && link.badge > 0 && (
                                                    <span className="bg-red-600 text-white text-[10px] font-bold px-2 py-0.5 rounded-full">
                                                        {link.badge}
                                                    </span>
                                                )}
                                            </Link>
                                        ))}
                                    </div>

                                    <div className="border-t border-slate-100 my-4" />

                                    <div className="px-4 space-y-1">
                                        <p className="px-4 text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2">Account</p>
                                        {[
                                            { label: 'Track Order', href: '/orders', icon: <MapPin size={18} /> },
                                            { label: 'Notifications', href: '/notifications', icon: <Bell size={18} /> },
                                            { label: 'Support', href: '/support', icon: <Phone size={18} /> },
                                        ].map((link) => (
                                            <Link
                                                key={link.label}
                                                to={link.href}
                                                onClick={() => setIsMobileMenuOpen(false)}
                                                className="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-slate-50 text-slate-600 font-medium transition-colors"
                                            >
                                                <div className="w-5 flex justify-center text-slate-400">{link.icon}</div>
                                                <span className="flex-1">{link.label}</span>
                                            </Link>
                                        ))}
                                    </div>

                                    {isAuthenticated && (
                                        <div className="px-4 mt-6">
                                            <button
                                                onClick={() => {
                                                    handleLogout();
                                                    setIsMobileMenuOpen(false);
                                                }}
                                                className="flex items-center gap-3 w-full px-4 py-3 rounded-xl bg-slate-50 text-slate-600 hover:text-red-600 hover:bg-red-50 font-bold transition-all border border-slate-100"
                                            >
                                                <div className="w-5 flex justify-center"><LogOut size={18} /></div>
                                                Logout
                                            </button>
                                        </div>
                                    )}
                                </div>
                            </motion.div>
                        </>
                    )
                }
            </AnimatePresence>
        </div>
    );
};

export default Navbar;
