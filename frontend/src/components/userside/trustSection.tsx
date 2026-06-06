import React, { useEffect, useRef, useState } from "react";
import {
    ShieldCheck,
    Truck,
    ThermometerSnowflake,
    Fish,
    Clock,
    BadgeCheck,
    Star,
    Leaf,
} from "lucide-react";

/* ── Trust Section ──
   Social proof & trust badges for the seafood e-commerce store.
*/

const trustBadges = [
    {
        icon: <ThermometerSnowflake size={28} />,
        title: "Cold-Chain Delivered",
        desc: "Temperature-controlled packaging from dock to doorstep.",
        color: "bg-red-600",
        bg: "bg-red-50",
        border: "border-red-100",
    },
    {
        icon: <Fish size={28} />,
        title: "100% Fresh Catch",
        desc: "Sourced daily from trusted fishermen — never frozen twice.",
        color: "bg-yellow-500",
        bg: "bg-yellow-50",
        border: "border-yellow-100",
    },
    {
        icon: <Truck size={28} />,
        title: "Same-Day Delivery",
        desc: "Order before 10 AM, get it by evening. Guaranteed.",
        color: "bg-red-600",
        bg: "bg-red-50",
        border: "border-red-100",
    },
    {
        icon: <ShieldCheck size={28} />,
        title: "Quality Assured",
        desc: "FSSAI certified. Hygienically cleaned & vacuum packed.",
        color: "bg-yellow-500",
        bg: "bg-yellow-50",
        border: "border-yellow-100",
    },
    {
        icon: <Clock size={28} />,
        title: "Easy Returns",
        desc: "Not satisfied? Get a full refund within 4 hours of delivery.",
        color: "bg-red-600",
        bg: "bg-red-50",
        border: "border-red-100",
    },
    {
        icon: <Leaf size={28} />,
        title: "Sustainably Sourced",
        desc: "We support local fisheries and responsible harvesting.",
        color: "bg-yellow-500",
        bg: "bg-yellow-50",
        border: "border-yellow-100",
    },
];

const stats = [
    { value: "25,000+", label: "Happy Customers" },
    { value: "50+", label: "Varieties" },
    { value: "4.8★", label: "Average Rating" },
    { value: "98%", label: "On-Time Delivery" },
];

const TrustSection: React.FC = () => {
    return (
        <section className="relative overflow-hidden bg-white py-20 px-4 sm:px-6 lg:px-8">
            {/* Subtle background pattern */}
            <div className="pointer-events-none absolute inset-0 opacity-[0.03]">
                <div
                    className="h-full w-full"
                    style={{
                        backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23000' fill-opacity='1'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
                    }}
                />
            </div>

            <div className="relative mx-auto max-w-7xl">
                {/* Header */}
                <div className="text-center mb-16">
                    <div className="inline-flex items-center gap-2 px-4 py-1.5 bg-red-50 rounded-full mb-4">
                        <BadgeCheck size={14} className="text-red-600" />
                        <span className="text-[11px] font-bold uppercase tracking-widest text-red-800">
                            Why Choose Us
                        </span>
                    </div>
                    <h2 className="text-3xl sm:text-4xl font-extrabold text-zinc-900 tracking-tight">
                        Fresh Fish, <span className="text-red-600">Delivered Right</span>
                    </h2>
                    <p className="mt-4 text-zinc-500 max-w-xl mx-auto text-sm leading-relaxed">
                        From ocean to your kitchen — we handle everything so you get the freshest seafood,
                        every single time, without compromise.
                    </p>
                </div>

                {/* Trust Badges Grid */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5 mb-20">
                    {trustBadges.map((badge, i) => (
                        <TrustCard key={i} badge={badge} index={i} />
                    ))}
                </div>

                {/* Stats Bar */}
                <div className="relative rounded-3xl bg-red-950 p-8 sm:p-12 overflow-hidden">
                    {/* Glow */}
                    <div className="absolute -top-20 left-1/2 -translate-x-1/2 w-80 h-80 bg-red-800/20 rounded-full blur-3xl" />
                    <div className="absolute -bottom-20 right-1/4 w-60 h-60 bg-yellow-600/10 rounded-full blur-3xl" />

                    <div className="relative grid grid-cols-2 lg:grid-cols-4 gap-8">
                        {stats.map((stat, i) => (
                            <AnimatedStat key={i} stat={stat} index={i} />
                        ))}
                    </div>
                </div>

                {/* Customer Reviews Snippet */}
                <div className="mt-16 text-center">
                    <div className="inline-flex items-center gap-1 mb-4">
                        {[...Array(5)].map((_, i) => (
                            <Star key={i} size={18} className="fill-yellow-400 text-yellow-400" />
                        ))}
                    </div>
                    <p className="text-zinc-600 text-sm italic max-w-lg mx-auto leading-relaxed">
                        "The prawns were incredibly fresh — like they just came off the boat! Packaging was ice-cold and delivery was on time. Best seafood delivery service in the city."
                    </p>
                    <p className="mt-3 text-xs font-bold text-zinc-800">
                        — Priya R., Mumbai
                    </p>
                    <p className="text-[10px] text-zinc-400 mt-1">Verified Purchase</p>
                </div>
            </div>
        </section>
    );
};

/* ── Trust Card ── */
interface TrustBadge {
    icon: React.ReactNode;
    title: string;
    desc: string;
    color: string;
    bg: string;
    border: string;
}

const TrustCard: React.FC<{ badge: TrustBadge; index: number }> = ({ badge, index }) => {
    const ref = useRef<HTMLDivElement>(null);
    const [visible, setVisible] = useState(false);

    useEffect(() => {
        const el = ref.current;
        if (!el) return;
        const obs = new IntersectionObserver(
            ([entry]) => { if (entry.isIntersecting) setVisible(true); },
            { threshold: 0.15 }
        );
        obs.observe(el);
        return () => obs.disconnect();
    }, []);

    return (
        <div
            ref={ref}
            className={`group relative ${badge.bg} ${badge.border} border rounded-2xl p-6 transition-all duration-500 hover:shadow-lg hover:-translate-y-1 cursor-default ${visible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-6"
                }`}
            style={{ transitionDelay: `${index * 80}ms` }}
        >
            {/* Icon */}
            <div className={`inline-flex p-3 rounded-xl ${badge.color} text-white shadow-md mb-4 transition-transform duration-300 group-hover:scale-110`}>
                {badge.icon}
            </div>

            <h3 className="text-sm font-bold text-zinc-900 mb-1">{badge.title}</h3>
            <p className="text-xs text-zinc-500 leading-relaxed">{badge.desc}</p>
        </div>
    );
};

/* ── Animated Stat ── */
const AnimatedStat: React.FC<{ stat: { value: string; label: string }; index: number }> = ({
    stat,
    index,
}) => {
    const ref = useRef<HTMLDivElement>(null);
    const [visible, setVisible] = useState(false);

    useEffect(() => {
        const el = ref.current;
        if (!el) return;
        const obs = new IntersectionObserver(
            ([entry]) => { if (entry.isIntersecting) setVisible(true); },
            { threshold: 0.3 }
        );
        obs.observe(el);
        return () => obs.disconnect();
    }, []);

    return (
        <div
            ref={ref}
            className={`text-center transition-all duration-700 ${visible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-4"
                }`}
            style={{ transitionDelay: `${index * 120}ms` }}
        >
            <p className="text-2xl sm:text-3xl font-extrabold text-yellow-400">
                {stat.value}
            </p>
            <p className="text-xs text-zinc-400 mt-1 font-medium tracking-wide uppercase">
                {stat.label}
            </p>
        </div>
    );
};

export default TrustSection;
