import React from "react";
import { useDispatch, useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import {
    User,
    Mail,
    Phone,
    LogOut,
    Shield,
    ChevronRight,
    Camera,
    Bell,
    Settings,
    CreditCard
} from "lucide-react";
import { logout } from "../auth/authSlice";

const ProfilePage: React.FC = () => {
    const dispatch = useDispatch();
    const navigate = useNavigate();
    const { user, isAuthenticated } = useSelector((state: any) => state.auth);

    const handleLogout = () => {
        dispatch(logout() as any);
        navigate("/login");
    };

    if (!isAuthenticated || !user) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-[#FDFDFD]">
                <div className="text-center space-y-4">
                    <div className="w-16 h-16 bg-slate-50 rounded-full flex items-center justify-center mx-auto text-slate-300">
                        <User size={32} />
                    </div>
                    <p className="text-slate-500 font-medium">Please login to view your profile.</p>
                    <button
                        onClick={() => navigate("/login")}
                        className="px-6 py-2 bg-rose-600 text-white rounded-xl font-bold text-sm hover:bg-rose-700 transition-colors"
                    >
                        Go to Login
                    </button>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-[#FDFDFD] font-sans text-slate-800 pb-20">
            {/* Header / Background Pattern */}
            <div className="h-48 bg-rose-600 relative overflow-hidden">
                <div className="absolute inset-0 opacity-10">
                    <div className="absolute top-0 left-0 w-64 h-64 bg-white rounded-full -translate-x-1/2 -translate-y-1/2 blur-3xl" />
                    <div className="absolute bottom-0 right-0 w-96 h-96 bg-red-400 rounded-full translate-x-1/4 translate-y-1/4 blur-3xl" />
                </div>
            </div>

            <main className="max-w-3xl mx-auto px-4 sm:px-6 -mt-24 relative z-10">
                {/* Profile Card */}
                <div className="bg-white rounded-[2.5rem] border border-slate-100 shadow-xl shadow-slate-200/40 p-8 md:p-10 space-y-8">
                    {/* Top Section */}
                    <div className="flex flex-col md:flex-row items-center gap-6 text-center md:text-left">
                        <div className="relative group">
                            <div className="w-32 h-32 rounded-[2.5rem] bg-rose-50 flex items-center justify-center border-4 border-white shadow-lg overflow-hidden">
                                <User size={48} className="text-rose-500" />
                            </div>
                            <button className="absolute bottom-1 right-1 p-2.5 bg-white rounded-2xl shadow-lg border border-slate-100 text-slate-400 hover:text-rose-600 transition-all opacity-0 group-hover:opacity-100 transform translate-y-2 group-hover:translate-y-0">
                                <Camera size={16} />
                            </button>
                        </div>
                        <div className="flex-1 space-y-1">
                            <h1 className="text-3xl font-black text-slate-900 tracking-tight">
                                {user.first_name || user.username || "Account Member"}
                            </h1>
                            <div className="flex flex-wrap justify-center md:justify-start gap-2">
                                <span className="inline-flex items-center gap-1.5 px-3 py-1 bg-emerald-50 text-emerald-600 rounded-full text-[10px] font-black uppercase tracking-widest border border-emerald-100">
                                    Active Account
                                </span>
                                <span className="inline-flex items-center gap-1.5 px-3 py-1 bg-slate-50 text-slate-500 rounded-full text-[10px] font-black uppercase tracking-widest border border-slate-100">
                                    <Shield size={10} /> {user.role || "User"}
                                </span>
                            </div>
                        </div>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <InfoItem
                            icon={<Mail size={18} />}
                            label="Email Address"
                            value={user.email || "Not provided"}
                        />
                        <InfoItem
                            icon={<Phone size={18} />}
                            label="Phone Number"
                            value={user.phone_number || "Not provided"}
                        />
                    </div>

                    {/* Quick Menu */}
                    <div className="space-y-4 pt-4 border-t border-slate-50">
                        <h4 className="text-[10px] font-black uppercase tracking-[0.2em] text-slate-400 px-2">
                            Account Settings
                        </h4>
                        <div className="grid grid-cols-1 gap-2">
                            <MenuButton icon={<Bell size={18} />} label="Notifications" sub="Alerts, offers & status" />
                            <MenuButton icon={<CreditCard size={18} />} label="Payments" sub="Saved cards & methods" />
                            <MenuButton icon={<Settings size={18} />} label="Security" sub="Password & verification" />
                        </div>
                    </div>

                    {/* Action Footer */}
                    <div className="pt-6">
                        <button
                            onClick={handleLogout}
                            className="w-full flex items-center justify-center gap-2 py-4 bg-slate-50 text-slate-600 rounded-2xl font-bold text-sm hover:bg-rose-50 hover:text-rose-600 transition-all border border-slate-100"
                        >
                            <LogOut size={18} /> Sign Out Account
                        </button>
                    </div>
                </div>

                {/* Footer Help */}
                <div className="mt-8 text-center">
                    <p className="text-xs text-slate-400 font-medium font-sans">
                        Need help? <button className="text-rose-500 font-bold hover:underline">Contact Support</button>
                    </p>
                </div>
            </main>
        </div>
    );
};

const InfoItem = ({ icon, label, value }: { icon: React.ReactNode, label: string, value: string }) => (
    <div className="p-5 bg-[#FAFAFA] rounded-3xl border border-zinc-100 space-y-1">
        <div className="flex items-center gap-2 text-slate-400 mb-1">
            {icon}
            <span className="text-[10px] font-black uppercase tracking-widest">{label}</span>
        </div>
        <p className="text-sm font-bold text-slate-800 truncate">{value}</p>
    </div>
);

const MenuButton = ({ icon, label, sub }: { icon: React.ReactNode, label: string, sub: string }) => (
    <button className="flex items-center gap-4 p-4 rounded-3xl hover:bg-slate-50 transition-all group border border-transparent hover:border-slate-100">
        <div className="w-12 h-12 rounded-2xl bg-white border border-slate-100 flex items-center justify-center text-slate-400 group-hover:text-rose-500 group-hover:bg-rose-50 transition-colors shadow-sm">
            {icon}
        </div>
        <div className="flex-1 text-left">
            <p className="text-sm font-bold text-slate-900">{label}</p>
            <p className="text-[11px] text-slate-400 font-medium">{sub}</p>
        </div>
        <ChevronRight size={16} className="text-slate-300 group-hover:text-rose-500 transition-colors" />
    </button>
);

export default ProfilePage;
