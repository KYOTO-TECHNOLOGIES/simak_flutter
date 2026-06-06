import React, { useState, useEffect } from 'react';
import { Outlet, Link, useLocation } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { logout } from '../../../features/auth/authSlice';
import {
  LayoutDashboard,
  ShoppingBag,
  Package,
  Users,
  Star,
  CreditCard,
  Settings,
  Bell,
  ChevronLeft,
  ChevronRight,
  ShoppingCart,
  Menu,
  X,
  LogOut,
  ScanLine
} from 'lucide-react';
import ScannerModal from './ScannerModal';

interface NavItem {
  label: string;
  path: string;
  icon: React.ReactNode;
}

const AdminLayout: React.FC = () => {
  const location = useLocation();
  const dispatch = useDispatch();
  const { user } = useSelector((state: any) => state.auth); // Using any for state to avoid strict check if RootState import is tricky, but preferably use RootState if I import it. I'll use any as quick fix or try to import RootState. I'll use any for now to be safe against broken imports. user is any anyway.
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [isScannerOpen, setIsScannerOpen] = useState(false);

  const handleScan = (data: string) => {
    // Here you can handle the scanned data
    // e.g. navigate to order page, product page, or show details
    alert(`Scanned QR Code:\n${data}`);
    // Optional: close scanner after successful scan?
    // setIsScannerOpen(false); 
  };

  const handleLogout = () => {
    dispatch(logout());
  };

  // Automatically close mobile menu on route change
  useEffect(() => {
    setIsMobileMenuOpen(false);
  }, [location.pathname]);

  const navigation: NavItem[] = [
    { label: 'Overview', path: '/admin/dashboard', icon: <LayoutDashboard size={18} strokeWidth={1.5} /> },
    { label: 'Orders', path: '/admin/orders', icon: <ShoppingBag size={18} strokeWidth={1.5} /> },
    { label: 'Carts', path: '/admin/cart', icon: <ShoppingCart size={18} strokeWidth={1.5} /> },
    { label: 'Products', path: '/admin/products', icon: <Package size={18} strokeWidth={1.5} /> },
    { label: 'Users', path: '/admin/users', icon: <Users size={18} strokeWidth={1.5} /> },
    { label: 'Reviews', path: '/admin/reviews', icon: <Star size={18} strokeWidth={1.5} /> },
    { label: 'Payments', path: '/admin/payments', icon: <CreditCard size={18} strokeWidth={1.5} /> },
    { label: 'Settings', path: '/admin/settings', icon: <Settings size={18} strokeWidth={1.5} /> },
  ];

  return (
    <div className="flex h-screen bg-white text-[#121212] font-sans overflow-hidden">
      {/* --- SIDEBAR: Mobile Overlay --- */}
      {isMobileMenuOpen && (
        <div
          className="fixed inset-0 bg-black/20 backdrop-blur-sm z-30 lg:hidden"
          onClick={() => setIsMobileMenuOpen(false)}
        />
      )}

      {/* --- SIDEBAR --- */}
      <aside
        className={`
          fixed inset-y-0 left-0 z-40 bg-[#FAFAFA] border-r border-[#EEEEEE] transition-all duration-300 ease-[cubic-bezier(0.2,0,0,1)]
          lg:translate-x-0 lg:static 
          ${isMobileMenuOpen ? 'translate-x-0 w-64' : '-translate-x-full lg:translate-x-0'}
          ${isSidebarOpen ? 'lg:w-64' : 'lg:w-20'}
          flex flex-col
        `}
      >
        <div className="h-20 flex items-center justify-between px-6">
          <div className="flex items-center">
            <div className="w-8 h-8 bg-black flex items-center justify-center text-white font-mono font-bold text-sm">F</div>
            {(isSidebarOpen || isMobileMenuOpen) && (
              <span className="ml-3 font-bold text-sm tracking-[0.2em] uppercase">FreshMa</span>
            )}
          </div>
          <button
            onClick={() => setIsSidebarOpen(!isSidebarOpen)}
            className="hidden lg:block text-[#A1A1AA] hover:text-black transition-colors"
          >
            {isSidebarOpen ? <ChevronLeft size={20} /> : <ChevronRight size={20} />}
          </button>
          <button className="lg:hidden" onClick={() => setIsMobileMenuOpen(false)}>
            <X size={20} />
          </button>
        </div>

        <nav className="flex-1 mt-2 px-3 space-y-0.5">
          {navigation.map((item) => {
            const isActive = location.pathname === item.path;
            return (
              <Link
                key={item.label}
                to={item.path}
                className={`flex items-center gap-3 px-3 py-2.5 rounded-md transition-all duration-200 group ${isActive
                  ? 'bg-white text-black shadow-[0_1px_3px_rgba(0,0,0,0.1)] border border-[#E5E5E5]'
                  : 'text-[#71717A] hover:text-black hover:bg-[#F4F4F5]'
                  }`}
              >
                <span className={`${isActive ? 'text-black' : 'text-[#A1A1AA] group-hover:text-black'}`}>
                  {item.icon}
                </span>
                {(isSidebarOpen || isMobileMenuOpen) && (
                  <span className="text-[13px] font-medium tracking-tight whitespace-nowrap">{item.label}</span>
                )}
              </Link>
            );
          })}
        </nav>

        <div className="p-4 border-t border-[#EEEEEE] space-y-1">
          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-3 px-3 py-3 text-[#71717A] hover:text-red-600 transition-all rounded-md hover:bg-red-50"
          >
            <LogOut size={16} strokeWidth={1.5} />
            {(isSidebarOpen || isMobileMenuOpen) && <span className="text-xs font-semibold tracking-widest uppercase">Logout</span>}
          </button>
        </div>
      </aside>

      {/* --- MAIN CONTENT AREA --- */}
      <div className="flex-1 flex flex-col relative overflow-hidden">

        {/* --- HEADER --- */}
        <header className="h-16 flex items-center justify-between px-4 md:px-8 border-b border-[#EEEEEE] bg-white">
          <div className="flex items-center gap-4">
            <button
              onClick={() => setIsMobileMenuOpen(true)}
              className="lg:hidden text-[#A1A1AA] hover:text-black"
            >
              <Menu size={20} />
            </button>
          </div>

          <div className="flex items-center gap-3 md:gap-6">
            {/* QA Scan Button */}
            <button
              className="text-[#A1A1AA] hover:text-black transition-colors"
              title="Scan QR Code"
              onClick={() => setIsScannerOpen(true)}
            >
              <ScanLine size={18} strokeWidth={1.5} />
            </button>

            <button className="text-[#A1A1AA] hover:text-black relative">
              <Bell size={18} strokeWidth={1.5} />
              <span className="absolute -top-0.5 -right-0.5 w-1.5 h-1.5 bg-black rounded-full"></span>
            </button>

            <div className="flex items-center gap-3 border-l border-[#EEEEEE] pl-4 md:pl-6">
              <div className="text-right hidden md:block">
                <p className="text-[12px] font-bold leading-none">
                  {user?.full_name || user?.email || "Admin"}
                </p>
                <p className="text-[10px] text-[#A1A1AA] uppercase tracking-wider mt-1">
                  {user?.is_superuser ? "Proprietor" : "Staff"}
                </p>
              </div>
              <div className="w-8 h-8 rounded-full bg-[#F4F4F5] border border-[#E5E5E5] flex items-center justify-center text-[10px] font-bold hover:bg-black hover:text-white transition-all cursor-pointer">
                {(user?.full_name?.[0] || user?.email?.[0] || "A").toUpperCase()}
              </div>
            </div>
          </div>
        </header>

        {/* --- VIEWPORT --- */}
        <main className="flex-1 overflow-y-auto bg-white pt-2 px-4 pb-4 md:pt-4 md:px-8 md:pb-8 lg:pt-6 lg:px-12 lg:pb-12">
          <div className="max-w-6xl mx-auto">
            <Outlet />
          </div>
        </main>
      </div>

      {/* --- QR SCANNER MODAL --- */}
      <ScannerModal
        isOpen={isScannerOpen}
        onClose={() => setIsScannerOpen(false)}
        onScan={handleScan}
      />
    </div>
  );
};

export default AdminLayout;