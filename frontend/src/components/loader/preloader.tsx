import { useEffect, useRef } from "react";
import { motion } from "framer-motion";
import gsap from "gsap";

const ShrimpLoader = ({ label }: { label?: string }) => {
    const containerRef = useRef(null);

    useEffect(() => {
        const ctx = gsap.context(() => {
            // 1. Logo Box Bounce & Pulse
            gsap.fromTo(".logo-box",
                { scale: 0.8, y: 10 },
                {
                    scale: 1,
                    y: 0,
                    duration: 1.2,
                    repeat: -1,
                    yoyo: true,
                    ease: "sine.inOut"
                }
            );

            // 2. Ripple Rings (The "Waves")
            gsap.fromTo(".ripple-ring",
                { scale: 0.8, opacity: 0.5 },
                {
                    scale: 2.5,
                    opacity: 0,
                    duration: 2,
                    repeat: -1,
                    stagger: 0.6,
                    ease: "power2.out"
                }
            );

            // 3. Light Sweep Effect
            gsap.to(".sweep", {
                x: "200%",
                duration: 1.5,
                repeat: -1,
                ease: "power2.inOut",
                repeatDelay: 0.5
            });

            // 4. Text Reveal
            gsap.fromTo(".loader-brand-text",
                { opacity: 0, y: 10, letterSpacing: "0.2em" },
                {
                    opacity: 1,
                    y: 0,
                    letterSpacing: "0.4em",
                    duration: 1,
                    delay: 0.3,
                    ease: "power3.out"
                }
            );

        }, containerRef);

        return () => ctx.revert();
    }, []);

    return (
        <div ref={containerRef} className="fixed inset-0 z-[9999] bg-white flex flex-col items-center justify-center overflow-hidden cursor-wait">

            {/* Subtle Gradient Backdrop */}
            <div className="absolute inset-0 bg-gradient-to-b from-stone-50 to-white opacity-50" />

            <div className="relative flex flex-col items-center z-10">

                {/* --- LOGO CONTAINER --- */}
                <div className="relative w-40 h-40 flex items-center justify-center">

                    {/* Ripple Rings */}
                    <div className="ripple-ring absolute w-24 h-24 rounded-2xl border-2 border-red-100" />
                    <div className="ripple-ring absolute w-24 h-24 rounded-2xl border-2 border-red-50" />
                    <div className="ripple-ring absolute w-24 h-24 rounded-2xl border-2 border-red-50/50" />

                    {/* The Logo Box */}
                    <div className="logo-box relative w-20 h-20 rounded-[22px] bg-red-600 flex items-center justify-center shadow-2xl shadow-red-500/40 overflow-hidden">
                        <span className="text-white font-black text-4xl leading-none select-none">F</span>

                        {/* Light Sweep Effect */}
                        <div className="sweep absolute top-0 -left-full w-full h-full bg-gradient-to-r from-transparent via-white/30 to-transparent skew-x-[-20deg]" />
                    </div>
                </div>

                {/* --- BRAND TEXT --- */}
                <div className="mt-8 flex flex-col items-center gap-3">
                    <h1 className="loader-brand-text text-[18px] font-black tracking-[0.4em] uppercase text-slate-900 flex">
                        Fresh<span className="text-red-600">Ma</span>
                    </h1>

                    {/* Progress Line */}
                    <div className="relative w-32 h-[1px] bg-slate-100 overflow-hidden rounded-full">
                        <motion.div
                            initial={{ x: "-100%" }}
                            animate={{ x: "100%" }}
                            transition={{ duration: 1.5, repeat: Infinity, ease: "easeInOut" }}
                            className="absolute inset-0 bg-gradient-to-r from-transparent via-red-500 to-transparent"
                        />
                    </div>

                    <p className="text-[9px] text-slate-400 font-bold uppercase tracking-[0.3em] mt-1 opacity-60">
                        {label || "Online Fish Market"}
                    </p>
                </div>

            </div>

            {/* Version / Est tag */}
            <div className="absolute bottom-12 text-[10px] text-slate-300 font-medium tracking-widest uppercase">
                Est. 2026
            </div>
        </div>
    );
};

export default ShrimpLoader;