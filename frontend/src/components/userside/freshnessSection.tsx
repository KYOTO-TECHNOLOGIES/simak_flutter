import React, { useEffect, useRef, useState } from "react";
import {
    Snowflake,
    Timer,
    Anchor,
    Award,
    ArrowRight,
} from "lucide-react";

/* ── Freshness Promise Data ── */
const promises = [
    {
        icon: <Anchor size={22} />,
        title: "Boat-to-Box in Hours",
        desc: "Our fish is sourced directly from fishing harbours every morning — never from cold storage.",
        stat: "< 6 hrs",
        statLabel: "Ocean to packing",
    },
    {
        icon: <Snowflake size={22} />,
        title: "Unbroken Cold Chain",
        desc: "From the moment we pack to the second you unbox — temperature stays between 0°C–4°C.",
        stat: "0°– 4°C",
        statLabel: "Maintained throughout",
    },
    {
        icon: <Timer size={22} />,
        title: "Delivered Same Day",
        desc: "Morning orders reach you by evening. We don't warehouse fish — it goes straight to you.",
        stat: "< 12 hrs",
        statLabel: "Order to doorstep",
    },
    {
        icon: <Award size={22} />,
        title: "Freshness Guarantee",
        desc: "If it doesn't pass the smell & texture test, we'll refund you instantly — no questions asked.",
        stat: "100%",
        statLabel: "Refund if not fresh",
    },
];

/* ── Timeline Steps ── */
const timeline = [
    { time: "4:00 AM", event: "Boats return to harbour", emoji: "⛵" },
    { time: "5:30 AM", event: "Catch sorted & auctioned", emoji: "🐟" },
    { time: "7:00 AM", event: "Cleaned & vacuum packed", emoji: "📦" },
    { time: "8:30 AM", event: "Loaded into cold-chain vans", emoji: "🚚" },
    { time: "By Evening", event: "At your doorstep", emoji: "🏠" },
];

/* ── Component ── */
const FreshnessSection: React.FC = () => {
    return (
        <section className="relative bg-white py-20 px-4 sm:px-6 lg:px-8 overflow-hidden">
            {/* Background decoration */}
            <div className="pointer-events-none absolute top-20 right-0 w-[500px] h-[500px] bg-red-50/30 rounded-full blur-3xl" />
            <div className="pointer-events-none absolute bottom-10 left-0 w-[400px] h-[400px] bg-yellow-50/20 rounded-full blur-3xl" />

            <div className="relative mx-auto max-w-7xl">
                {/* Header */}
                <div className="text-center mb-16">
                    <div className="inline-flex items-center gap-2 px-4 py-1.5 bg-red-50 border border-red-100 rounded-full mb-4">
                        <Snowflake size={14} className="text-red-500" />
                        <span className="text-[11px] font-bold uppercase tracking-widest text-red-600">
                            Freshness Promise
                        </span>
                    </div>
                    <h2 className="text-3xl sm:text-4xl font-extrabold text-zinc-900 tracking-tight">
                        So Fresh, You Can{" "}
                        <span className="text-red-600">
                            Smell the Ocean
                        </span>
                    </h2>
                    <p className="mt-4 text-zinc-500 text-sm max-w-lg mx-auto leading-relaxed">
                        We obsess over freshness so you don't have to. Here's how we make sure every piece of seafood
                        reaches you at peak quality.
                    </p>
                </div>

                {/* Promise Cards */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5 mb-20">
                    {promises.map((p, i) => (
                        <PromiseCard key={i} promise={p} index={i} />
                    ))}
                </div>

                {/* Journey Timeline */}
                <div className="relative max-w-3xl mx-auto">
                    <div className="text-center mb-10">
                        <h3 className="text-xl font-bold text-zinc-900">Today's Catch Journey</h3>
                        <p className="text-xs text-zinc-400 mt-1">
                            A typical day — from harbour to your home
                        </p>
                    </div>

                    {/* Timeline line */}
                    <div className="absolute left-1/2 -translate-x-px top-[100px] bottom-[60px] w-[2px] bg-red-200 hidden sm:block" />

                    <div className="space-y-6 sm:space-y-0">
                        {timeline.map((step, i) => (
                            <TimelineStep key={i} step={step} index={i} isLeft={i % 2 === 0} />
                        ))}
                    </div>
                </div>

                {/* Bottom CTA */}
                <div className="text-center mt-16">
                    <div className="inline-flex items-center gap-3 px-6 py-3 bg-yellow-50 border border-yellow-100 rounded-2xl">
                        <Snowflake size={18} className="text-yellow-600" />
                        <span className="text-sm font-bold text-zinc-700">
                            Every order ships with gel ice packs & insulated packaging
                        </span>
                        <ArrowRight size={16} className="text-yellow-500" />
                    </div>
                </div>
            </div>
        </section>
    );
};

/* ── Promise Card ── */
interface PromiseData {
    icon: React.ReactNode;
    title: string;
    desc: string;
    stat: string;
    statLabel: string;
}

const PromiseCard: React.FC<{ promise: PromiseData; index: number }> = ({
    promise,
    index,
}) => {
    const ref = useRef<HTMLDivElement>(null);
    const [visible, setVisible] = useState(false);

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

    return (
        <div
            ref={ref}
            className={`group relative bg-white border border-zinc-100 rounded-2xl p-6 hover:shadow-lg hover:-translate-y-1 transition-all duration-500 cursor-default ${visible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"
                }`}
            style={{ transitionDelay: `${index * 100}ms` }}
        >
            {/* Icon */}
            <div className="w-11 h-11 rounded-xl bg-red-600 text-white flex items-center justify-center shadow-md mb-4 group-hover:scale-110 transition-transform duration-300">
                {promise.icon}
            </div>

            <h3 className="text-sm font-bold text-zinc-900 mb-1.5">{promise.title}</h3>
            <p className="text-xs text-zinc-500 leading-relaxed mb-4">{promise.desc}</p>

            <div className="pt-4 border-t border-zinc-100 flex items-baseline gap-2">
                <span className="text-xl font-extrabold text-yellow-500">
                    {promise.stat}
                </span>
                <span className="text-[10px] text-zinc-400 font-medium">{promise.statLabel}</span>
            </div>
        </div>
    );
};

/* ── Timeline Step ── */
const TimelineStep: React.FC<{
    step: { time: string; event: string; emoji: string };
    index: number;
    isLeft: boolean;
}> = ({ step, index, isLeft }) => {
    const ref = useRef<HTMLDivElement>(null);
    const [visible, setVisible] = useState(false);

    useEffect(() => {
        const el = ref.current;
        if (!el) return;
        const obs = new IntersectionObserver(
            ([e]) => { if (e.isIntersecting) setVisible(true); },
            { threshold: 0.3 }
        );
        obs.observe(el);
        return () => obs.disconnect();
    }, []);

    return (
        <div
            ref={ref}
            className={`relative sm:flex items-center sm:h-20 transition-all duration-500 ${visible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-6"
                } ${isLeft ? "sm:flex-row" : "sm:flex-row-reverse"}`}
            style={{ transitionDelay: `${index * 100}ms` }}
        >
            {/* Content */}
            <div className={`flex-1 ${isLeft ? "sm:text-right sm:pr-10" : "sm:text-left sm:pl-10"}`}>
                <div
                    className={`inline-flex items-center gap-3 px-4 py-2.5 bg-white border border-zinc-100 rounded-xl shadow-sm hover:shadow-md transition-shadow ${isLeft ? "sm:flex-row-reverse" : ""
                        }`}
                >
                    <span className="text-xl">{step.emoji}</span>
                    <div className={isLeft ? "sm:text-right" : ""}>
                        <p className="text-xs font-bold text-zinc-900">{step.event}</p>
                        <p className="text-[10px] text-zinc-400 font-mono">{step.time}</p>
                    </div>
                </div>
            </div>

            {/* Center dot */}
            <div className="hidden sm:flex absolute left-1/2 -translate-x-1/2 w-4 h-4 rounded-full bg-white border-[3px] border-red-400 shadow-sm z-10" />

            {/* Spacer for other side */}
            <div className="flex-1 hidden sm:block" />
        </div>
    );
};

export default FreshnessSection;
