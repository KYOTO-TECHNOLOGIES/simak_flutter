import React from "react";
import {
    Fish,
    Phone,
    Mail,
    MapPin,
    Clock,
    Facebook,
    Instagram,
    Twitter,
    Youtube,
    ArrowRight,
    CreditCard,
    Smartphone,
    Banknote,
    ShieldCheck,
} from "lucide-react";

/* ── Footer Links ── */
const shopLinks = [
    { label: "All Seafood", href: "/" },
    { label: "Prawns & Shrimp", href: "/" },
    { label: "Fish", href: "/" },
    { label: "Crab & Lobster", href: "/" },
    { label: "Squid & Octopus", href: "/" },
    { label: "Ready to Cook", href: "/" },
    { label: "Combo Packs", href: "/" },
];

const companyLinks = [
    { label: "About Us", href: "/" },
    { label: "Our Story", href: "/" },
    { label: "Freshness Promise", href: "/" },
    { label: "Careers", href: "/" },
    { label: "Blog", href: "/" },
    { label: "Press", href: "/" },
];

const supportLinks = [
    { label: "Help Center", href: "/" },
    { label: "Track Order", href: "/" },
    { label: "Shipping Info", href: "/" },
    { label: "Returns & Refunds", href: "/" },
    { label: "Contact Us", href: "/" },
    { label: "FAQs", href: "/" },
];

const legalLinks = [
    { label: "Privacy Policy", href: "/" },
    { label: "Terms of Service", href: "/" },
    { label: "Refund Policy", href: "/" },
    { label: "Cookie Policy", href: "/" },
];

const socials = [
    { icon: <Instagram size={18} />, href: "#", label: "Instagram" },
    { icon: <Facebook size={18} />, href: "#", label: "Facebook" },
    { icon: <Twitter size={18} />, href: "#", label: "Twitter" },
    { icon: <Youtube size={18} />, href: "#", label: "YouTube" },
];

/* ── Component ── */
const Footer: React.FC = () => {
    const year = new Date().getFullYear();

    return (
        <footer className="bg-red-950 text-red-200/80">
            {/* Newsletter Banner */}
            <div className="px-4 sm:px-6 lg:px-8 pt-8 pb-6">
                <div className="mx-auto max-w-7xl">
                    <div className="bg-red-900 border border-red-800 rounded-2xl p-6 flex flex-col sm:flex-row items-center justify-between gap-4">

                        <div>
                            <h3 className="text-lg font-bold text-white mb-1">
                                🦐 Get Fresh Deals in Your Inbox
                            </h3>
                            <p className="text-xs text-red-200/60">
                                Weekly offers, new arrivals & seasonal recipes. No spam, ever.
                            </p>
                        </div>
                        <div className="relative flex w-full sm:w-auto gap-2">
                            <input
                                type="email"
                                placeholder="Enter your email"
                                className="flex-1 sm:w-64 px-4 py-3 bg-red-950/50 border border-red-800 rounded-xl text-sm text-white placeholder:text-red-300/50 focus:outline-none focus:border-yellow-500 transition-colors"
                            />
                            <button className="px-5 py-3 bg-yellow-500 text-red-900 rounded-xl text-sm font-bold hover:bg-yellow-400 transition-all shadow-lg hover:shadow-yellow-500/25 active:scale-[0.98] flex items-center gap-1.5">
                                Subscribe
                                <ArrowRight size={14} />
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            {/* Main Footer Grid */}
            <div className="px-4 sm:px-6 lg:px-8 pb-6">
                <div className="mx-auto max-w-7xl">
                    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-8">
                        {/* Brand Column */}
                        <div className="col-span-2 sm:col-span-3 lg:col-span-1">
                            <div className="flex items-center gap-2 mb-4">
                                <div className="w-9 h-9 bg-yellow-500 rounded-xl flex items-center justify-center shadow-lg">
                                    <Fish size={18} className="text-red-900" />
                                </div>
                                <span className="text-lg font-extrabold text-white tracking-tight">
                                    FreshMa
                                </span>
                            </div>
                            <p className="text-xs text-red-200/60 leading-relaxed mb-5 max-w-xs">
                                India's freshest seafood, delivered to your doorstep. From harbour to home in hours — cleaned, packed & ready to cook.
                            </p>

                            {/* Contact */}
                            <div className="space-y-2.5 mb-6">
                                <a href="tel:+919876543210" className="flex items-center gap-2.5 text-xs hover:text-yellow-400 transition-colors">
                                    <Phone size={13} className="text-red-300" />
                                    +91 98765 43210
                                </a>
                                <a href="mailto:hello@freshcatch.in" className="flex items-center gap-2.5 text-xs hover:text-yellow-400 transition-colors">
                                    <Mail size={13} className="text-red-300" />
                                    hello@freshma.in
                                </a>
                                <div className="flex items-center gap-2.5 text-xs hover:text-yellow-400 transition-colors">
                                    <MapPin size={13} className="text-red-300 shrink-0" />
                                    kerala , india
                                </div>
                                <div className="flex items-center gap-2.5 text-xs hover:text-yellow-400 transition-colors">
                                    <Clock size={13} className="text-red-300" />
                                    6 AM – 9 PM, Mon–Sun
                                </div>
                            </div>

                          {/* Socials */}
                            <div className="flex items-center gap-2">
                                {socials.map((s) => (
                                    <a
                                        key={s.label}
                                        href={s.href}
                                        aria-label={s.label}
                                        className="w-9 h-9 rounded-xl bg-red-900 hover:bg-yellow-500/20 border border-red-800 hover:border-yellow-500/40 flex items-center justify-center text-red-300 hover:text-yellow-400 transition-all"
                                    >
                                        {s.icon}
                                    </a>
                                ))}
                            </div>
                        </div>

                        {/* Shop */}
                        <div>
                            <h4 className="text-xs font-bold text-white uppercase tracking-widest mb-4">
                                Shop
                            </h4>
                            <ul className="space-y-2.5">
                                {shopLinks.map((link) => (
                                    <li key={link.label}>
                                        <a href={link.href} className="text-xs hover:text-yellow-400 transition-colors">
                                            {link.label}
                                        </a>
                                    </li>
                                ))}
                            </ul>
                        </div>

                        {/* Company */}
                        <div>
                            <h4 className="text-xs font-bold text-white uppercase tracking-widest mb-4">
                                Company
                            </h4>
                            <ul className="space-y-2.5">
                                {companyLinks.map((link) => (
                                    <li key={link.label}>
                                        <a href={link.href} className="text-xs hover:text-yellow-400 transition-colors">
                                            {link.label}
                                        </a>
                                    </li>
                                ))}
                            </ul>
                        </div>

                        {/* Support */}
                        <div>
                            <h4 className="text-xs font-bold text-white uppercase tracking-widest mb-4">
                                Support
                            </h4>
                            <ul className="space-y-2.5">
                                {supportLinks.map((link) => (
                                    <li key={link.label}>
                                        <a href={link.href} className="text-xs hover:text-yellow-400 transition-colors">
                                            {link.label}
                                        </a>
                                    </li>
                                ))}
                            </ul>
                        </div>

                        {/* Download & Payment */}
                        <div>
                            <h4 className="text-xs font-bold text-white uppercase tracking-widest mb-4">
                                Download App
                            </h4>
                            <div className="space-y-2 mb-6">
                                <button className="flex items-center gap-2 w-full px-3 py-2.5 bg-red-900 border border-red-800 rounded-xl hover:bg-red-800 transition-all">
                                    <Smartphone size={16} className="text-red-300" />
                                    <div className="text-left">
                                        <p className="text-[9px] text-red-200/60 leading-none">Get it on</p>
                                        <p className="text-xs font-bold text-white leading-tight">Google Play</p>
                                    </div>
                                </button>
                                <button className="flex items-center gap-2 w-full px-3 py-2.5 bg-red-900 border border-red-800 rounded-xl hover:bg-red-800 transition-all">
                                    <Smartphone size={16} className="text-red-300" />
                                    <div className="text-left">
                                        <p className="text-[9px] text-red-200/60 leading-none">Download on</p>
                                        <p className="text-xs font-bold text-white leading-tight">App Store</p>
                                    </div>
                                </button>
                            </div>

                            <h4 className="text-xs font-bold text-white uppercase tracking-widest mb-3">
                                We Accept
                            </h4>
                            <div className="flex flex-wrap gap-2">
                                {[
                                    { icon: <CreditCard size={14} />, label: "Cards" },
                                    { icon: <Smartphone size={14} />, label: "UPI" },
                                    { icon: <Banknote size={14} />, label: "COD" },
                                ].map((pm) => (
                                    <div
                                        key={pm.label}
                                        className="flex items-center gap-1.5 px-2.5 py-1.5 bg-red-900 border border-red-800 rounded-lg"
                                    >
                                        <span className="text-red-300">{pm.icon}</span>
                                        <span className="text-[10px] font-medium text-red-200/80">{pm.label}</span>
                                    </div>
                                ))}
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Bottom Bar */}
            <div className="border-t border-red-900">
                <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-5 flex flex-col sm:flex-row items-center justify-between gap-3">
                    <div className="flex items-center gap-2 text-xs text-red-200/60">
                        <ShieldCheck size={14} className="text-yellow-500" />
                        <span>FSSAI Licensed • 100% Secure Payments</span>
                    </div>

                    <p className="text-xs text-red-200/60">
                        © {year} FreshCatch. All rights reserved.
                    </p>

                    <div className="flex items-center gap-4">
                        {legalLinks.map((link) => (
                            <a
                                key={link.label}
                                href={link.href}
                                className="text-[10px] text-red-200/60 hover:text-yellow-400 transition-colors"
                            >
                                {link.label}
                            </a>
                        ))}
                    </div>
                </div>
            </div>
        </footer>
    );
};

export default Footer;
