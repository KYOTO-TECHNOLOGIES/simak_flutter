import React, { useEffect, useRef, useState } from "react";
import {
    Tag,
    Copy,
    Check,
    Clock,
    Zap,
    Gift,
    Percent,
    Truck,
    ArrowRight,
} from "lucide-react";

/* ── Offers Data ── */
const offers = [
    {
        id: 1,
        badge: "NEW USER",
        title: "Flat AED 200 Off",
        subtitle: "On your first order above AED 799",
        code: "FRESHSTART",
        gradient: "bg-red-600",
        glow: "bg-red-500/20",
        icon: <Gift size={20} />,
        expiry: "No expiry",
        terms: "Min order AED 799 • First order only",
    },
    {
        id: 2,
        badge: "WEEKEND",
        title: "Buy 2 Get 1 Free",
        subtitle: "On all Prawns & Shrimp varieties",
        code: "PRAWN3",
        gradient: "bg-yellow-500",
        glow: "bg-yellow-500/20",
        icon: <Zap size={20} />,
        expiry: "Sat & Sun only",
        terms: "Same variety • Max 3 free/order",
    },
    {
        id: 3,
        badge: "FREE DELIVERY",
        title: "Free Shipping",
        subtitle: "On all orders above AED 999",
        code: "FREEFISH",
        gradient: "bg-red-800",
        glow: "bg-red-500/20",
        icon: <Truck size={20} />,
        expiry: "This month",
        terms: "Applicable for standard delivery",
    },
    {
        id: 4,
        badge: "COMBO DEAL",
        title: "Seafood Party Pack",
        subtitle: "Pomfret + Prawns + Surmai at 30% off",
        code: "PARTY30",
        gradient: "bg-yellow-600",
        glow: "bg-yellow-500/20",
        icon: <Percent size={20} />,
        expiry: "Limited stock",
        terms: "While supplies last • Cannot combine",
    },
];

/* ── Banner ── */
const bannerOffer = {
    title: "🦐 Mega Seafood Sale — Up to 40% Off!",
    subtitle: "Fresh catches at unbeatable prices. This weekend only.",
    cta: "Shop the Sale",
    gradient: "bg-red-950",
};

/* ── Component ── */
const OffersSection: React.FC = () => {
    return (
        <section className="relative bg-[#FAFAF8] py-20 px-4 sm:px-6 lg:px-8 overflow-hidden">
            {/* Decorative */}
            <div className="pointer-events-none absolute top-0 left-1/2 -translate-x-1/2 w-[600px] h-[600px] bg-red-50/50 rounded-full blur-3xl" />

            <div className="relative mx-auto max-w-7xl">
                {/* Header */}
                <div className="text-center mb-14">
                    <div className="inline-flex items-center gap-2 px-4 py-1.5 bg-red-50 border border-red-100 rounded-full mb-4">
                        <Tag size={14} className="text-red-500" />
                        <span className="text-[11px] font-bold uppercase tracking-widest text-red-600">
                            Deals & Offers
                        </span>
                    </div>
                    <h2 className="text-3xl sm:text-4xl font-extrabold text-zinc-900 tracking-tight">
                        Save Big on{" "}
                        <span className="text-red-600">
                            Fresh Catches
                        </span>
                    </h2>
                    <p className="mt-3 text-zinc-500 text-sm max-w-md mx-auto">
                        Grab these exclusive deals before they swim away. Use the codes at checkout.
                    </p>
                </div>

                {/* Offer Cards Grid */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5 mb-12">
                    {offers.map((offer, i) => (
                        <OfferCard key={offer.id} offer={offer} index={i} />
                    ))}
                </div>

                {/* Banner CTA */}
                <BannerCTA />
            </div>
        </section>
    );
};

/* ── Offer Card ── */
interface Offer {
    id: number;
    badge: string;
    title: string;
    subtitle: string;
    code: string;
    gradient: string;
    glow: string;
    icon: React.ReactNode;
    expiry: string;
    terms: string;
}

const OfferCard: React.FC<{ offer: Offer; index: number }> = ({ offer, index }) => {
    const ref = useRef<HTMLDivElement>(null);
    const [visible, setVisible] = useState(false);
    const [copied, setCopied] = useState(false);

    useEffect(() => {
        const el = ref.current;
        if (!el) return;
        const obs = new IntersectionObserver(
            ([e]) => { if (e.isIntersecting) setVisible(true); },
            { threshold: 0.15 }
        );
        obs.observe(el);
        return () => obs.disconnect();
    }, []);

    const handleCopy = async () => {
        try {
            await navigator.clipboard.writeText(offer.code);
            setCopied(true);
            setTimeout(() => setCopied(false), 2000);
        } catch {
            // fallback
            setCopied(true);
            setTimeout(() => setCopied(false), 2000);
        }
    };

    return (
        <div
            ref={ref}
            className={`group relative bg-white border border-zinc-100 rounded-2xl overflow-hidden hover:shadow-xl hover:-translate-y-1 transition-all duration-500 cursor-default ${visible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"
                }`}
            style={{ transitionDelay: `${index * 80}ms` }}
        >
            {/* Top gradient strip */}
            <div className={`h-1.5 ${offer.gradient}`} />

            <div className="p-5">
                {/* Badge + Icon */}
                <div className="flex items-start justify-between mb-4">
                    <span className={`px-2.5 py-1 ${offer.gradient} text-white rounded-lg text-[9px] font-bold uppercase tracking-wider`}>
                        {offer.badge}
                    </span>
                    <div className={`p-2 rounded-xl ${offer.glow} transition-transform group-hover:scale-110 duration-300`}>
                        {offer.icon}
                    </div>
                </div>

                {/* Title */}
                <h3 className="text-lg font-extrabold text-zinc-900 mb-1">{offer.title}</h3>
                <p className="text-xs text-zinc-500 mb-4 leading-relaxed">{offer.subtitle}</p>

                {/* Coupon Code */}
                <div className="flex items-center gap-2 mb-4">
                    <div className="flex-1 px-3 py-2.5 bg-zinc-50 border border-dashed border-zinc-300 rounded-xl flex items-center justify-between">
                        <span className="text-xs font-mono font-bold text-zinc-700 tracking-wider">
                            {offer.code}
                        </span>
                        <button
                            onClick={handleCopy}
                            className="p-1 hover:bg-zinc-200 rounded-md transition-colors"
                            title="Copy code"
                        >
                            {copied ? (
                                <Check size={14} className="text-red-600" />
                            ) : (
                                <Copy size={14} className="text-zinc-400" />
                            )}
                        </button>
                    </div>
                </div>

                {/* Footer */}
                <div className="flex items-center justify-between pt-3 border-t border-zinc-100">
                    <div className="flex items-center gap-1 text-zinc-400">
                        <Clock size={11} />
                        <span className="text-[10px] font-medium">{offer.expiry}</span>
                    </div>
                    <span className="text-[10px] text-zinc-400">{offer.terms}</span>
                </div>
            </div>
        </div>
    );
};

/* ── Banner CTA ── */
const BannerCTA: React.FC = () => {
    const ref = useRef<HTMLDivElement>(null);
    const [visible, setVisible] = useState(false);

    useEffect(() => {
        const el = ref.current;
        if (!el) return;
        const obs = new IntersectionObserver(
            ([e]) => { if (e.isIntersecting) setVisible(true); },
            { threshold: 0.2 }
        );
        obs.observe(el);
        return () => obs.disconnect();
    }, []);

    return (
        <div
            ref={ref}
            className={`relative rounded-3xl ${bannerOffer.gradient} overflow-hidden transition-all duration-700 ${visible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"
                }`}
        >
            {/* Glow effects */}
            <div className="absolute -top-20 left-1/4 w-60 h-60 bg-orange-500/10 rounded-full blur-3xl" />
            <div className="absolute -bottom-20 right-1/4 w-80 h-80 bg-amber-500/10 rounded-full blur-3xl" />

            {/* Pattern overlay */}
            <div className="absolute inset-0 opacity-[0.04]">
                <div
                    className="h-full w-full"
                    style={{
                        backgroundImage: `url("data:image/svg+xml,%3Csvg width='20' height='20' viewBox='0 0 20 20' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='%23fff' fill-opacity='1'%3E%3Ccircle cx='3' cy='3' r='1.5'/%3E%3C/g%3E%3C/svg%3E")`,
                    }}
                />
            </div>

            <div className="relative flex flex-col sm:flex-row items-center justify-between p-8 sm:p-12 gap-6">
                <div>
                    <h3 className="text-2xl sm:text-3xl font-extrabold text-white mb-2">
                        {bannerOffer.title}
                    </h3>
                    <p className="text-sm text-zinc-400">{bannerOffer.subtitle}</p>
                </div>
                <button className="group flex items-center gap-2 px-8 py-3.5 bg-white text-red-900 rounded-2xl text-sm font-bold shadow-xl hover:shadow-2xl hover:bg-zinc-50 transition-all duration-300 active:scale-[0.98] shrink-0">
                    {bannerOffer.cta}
                    <ArrowRight size={16} className="transition-transform group-hover:translate-x-1" />
                </button>
            </div>
        </div>
    );
};

export default OffersSection;
