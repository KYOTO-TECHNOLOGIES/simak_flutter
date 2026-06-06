import React, { useEffect, useRef, useState } from "react";
import {
    Search,
    ShoppingBag,
    Truck,
    UtensilsCrossed,
    ChevronRight,
    Waves,
} from "lucide-react";

/* ── Steps Data ── */
const steps = [
    {
        number: "01",
        icon: <Search size={28} />,
        title: "Browse & Pick",
        description:
            "Explore our daily catch — from Pomfret and Prawns to Squid and Surmai. Filter by type, size, or prep style.",
        detail: "Cleaned • Steaks • Fillets • Whole",
        gradient: "",
        bg: "bg-red-50",
        accent: "text-red-600",
    },
    {
        number: "02",
        icon: <ShoppingBag size={28} />,
        title: "Add to Cart & Pay",
        description:
            "Choose your quantity, pick a delivery slot, and pay securely via UPI, Cards, or Cash on Delivery.",
        detail: "UPI • Cards • COD • Wallets",
        gradient: "",
        bg: "bg-yellow-50",
        accent: "text-amber-800",
    },
    {
        number: "03",
        icon: <Truck size={28} />,
        title: "We Pack & Ship",
        description:
            "Your order is hygienically cleaned, vacuum-packed with ice, and dispatched in our insulated cold-chain boxes.",
        detail: "Ice-packed • Vacuum-sealed • Insulated",
        gradient: "",
        bg: "bg-red-50",
        accent: "text-red-600",
    },
    {
        number: "04",
        icon: <UtensilsCrossed size={28} />,
        title: "Cook & Enjoy!",
        description:
            "Receive fresh seafood at your door — ready to cook. Try our chef-curated recipes for the perfect dish.",
        detail: "Same-day delivery • Recipe cards included",
        gradient: "",
        bg: "bg-yellow-50",
        accent: "text-amber-800",
    },
];

/* ── Component ── */
const HowItWorksSection: React.FC = () => {
    return (
        <section className="relative bg-white py-20 px-4 sm:px-6 lg:px-8 overflow-hidden">
            {/* Decorative waves */}
            <div className="pointer-events-none absolute top-0 left-0 right-0 h-20 bg-white" />
            <div className="pointer-events-none absolute -bottom-10 left-1/2 -translate-x-1/2 opacity-[0.03]">
                <Waves size={600} strokeWidth={0.5} />
            </div>

            <div className="relative mx-auto max-w-6xl">
                {/* Header */}
                <div className="text-center mb-16">
                    <div className="inline-flex items-center gap-2 px-4 py-1.5 bg-zinc-100 rounded-full mb-4">
                        <Waves size={14} className="text-cyan-500" />
                        <span className="text-[11px] font-bold uppercase tracking-widest text-zinc-600">
                            How It Works
                        </span>
                    </div>
                    <h2 className="text-3xl sm:text-4xl font-extrabold text-zinc-900 tracking-tight">
                        From Ocean to{" "}
                        <span className="text-red-600">
                            Your Plate
                        </span>
                    </h2>
                    <p className="mt-4 text-zinc-500 text-sm max-w-lg mx-auto leading-relaxed">
                        Four simple steps to the freshest seafood you've ever tasted. No middlemen, no delays — just pure freshness.
                    </p>
                </div>

                {/* Steps */}
                <div className="relative">
                    {/* Connecting line (desktop) */}
                    <div className="hidden lg:block absolute top-[72px] left-[10%] right-[10%] h-[2px]">
                        <div className="w-full h-full bg-red-100 rounded-full" />
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8 lg:gap-6">
                        {steps.map((step, i) => (
                            <StepCard key={i} step={step} index={i} isLast={i === steps.length - 1} />
                        ))}
                    </div>
                </div>

                {/* CTA */}
                <div className="text-center mt-16">
                    <button className="group inline-flex items-center gap-2 px-8 py-3.5 bg-red-600 text-white rounded-2xl text-sm font-bold shadow-xl hover:shadow-2xl hover:bg-red-700 transition-all duration-300 active:scale-[0.98]">
                        Start Shopping
                        <ChevronRight
                            size={16}
                            className="transition-transform group-hover:translate-x-1"
                        />
                    </button>
                    <p className="mt-3 text-[11px] text-zinc-400">
                        Free delivery on orders above AED 999
                    </p>
                </div>
            </div>
        </section>
    );
};

/* ── Step Card ── */
interface StepData {
    number: string;
    icon: React.ReactNode;
    title: string;
    description: string;
    detail: string;
    gradient: string;
    bg: string;
    accent: string;
}

const StepCard: React.FC<{ step: StepData; index: number; isLast: boolean }> = ({
    step,
    index,
    isLast,
}) => {
    const ref = useRef<HTMLDivElement>(null);
    const [visible, setVisible] = useState(false);

    useEffect(() => {
        const el = ref.current;
        if (!el) return;
        const obs = new IntersectionObserver(
            ([e]) => {
                if (e.isIntersecting) setVisible(true);
            },
            { threshold: 0.15 }
        );
        obs.observe(el);
        return () => obs.disconnect();
    }, []);

    return (
        <div
            ref={ref}
            className={`relative flex flex-col items-center text-center transition-all duration-600 ${visible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-10"
                }`}
            style={{ transitionDelay: `${index * 120}ms` }}
        >
            {/* Step number */}
            <div className="relative z-10 mb-5">
                {/* Glow ring */}
                <div
                    className={`absolute -inset-3 rounded-full ${index % 2 === 0 ? 'bg-red-400' : 'bg-yellow-500'} opacity-20 blur-md transition-all duration-500 group-hover:opacity-30`}
                />

                {/* Icon circle */}
                <div
                    className={`relative w-[72px] h-[72px] rounded-2xl ${index % 2 === 0 ? 'bg-red-600' : 'bg-yellow-500'} text-white flex items-center justify-center shadow-lg transition-all duration-300 hover:scale-110 hover:shadow-xl cursor-default`}
                >
                    {step.icon}
                </div>

                {/* Number badge */}
                <div className="absolute -top-2 -right-2 w-7 h-7 bg-white border-2 border-zinc-100 rounded-full flex items-center justify-center shadow-sm">
                    <span className="text-[10px] font-extrabold text-zinc-700">
                        {step.number}
                    </span>
                </div>
            </div>

            {/* Arrow connector (mobile/tablet between cards) */}
            {!isLast && (
                <div className="lg:hidden flex justify-center my-2">
                    <ChevronRight size={16} className="text-zinc-300 rotate-90" />
                </div>
            )}

            {/* Text */}
            <h3 className="text-sm font-bold text-zinc-900 mb-2">{step.title}</h3>
            <p className="text-xs text-zinc-500 leading-relaxed max-w-[220px] mb-3">
                {step.description}
            </p>

            {/* Detail tag */}
            <div className={`inline-flex px-3 py-1 ${step.bg} rounded-lg`}>
                <span className={`text-[10px] font-bold ${step.accent}`}>
                    {step.detail}
                </span>
            </div>
        </div>
    );
};

export default HowItWorksSection;
