import React, { useState, useEffect, useCallback } from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

/* ─── Banner Data ─────────────────────────────────────── */
const banners = [
  {
    id: 1,
    tag: 'Fresh Catch',
    title: 'Premium Prawns',
    subtitle: 'Succulent, sweet, and delivered straight from the coast within 24 hours.',
    highlight: 'Cleaned & Deveined',
    cta: 'Order Prawns',
    img: 'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?q=80&w=1200&auto=format&fit=crop',
    price: 'AED 299',
    oldPrice: 'AED 429',
    accent: 'text-yellow-400',
  },
  {
    id: 2,
    tag: 'Live Stock',
    title: 'Mud Crabs',
    subtitle: 'Meaty, flavorful mud crabs perfect for your favorite curry recipes.',
    highlight: 'Live Catch',
    cta: 'Buy Crabs',
    img: 'https://images.unsplash.com/photo-1550747528-cdb45925b3f7?q=80&w=1200&auto=format&fit=crop',
    price: 'AED 369',
    oldPrice: 'AED 459',
    accent: 'text-red-500',
  },
  {
    id: 3,
    tag: 'Best Seller',
    title: 'Jumbo Shrimps',
    subtitle: 'Extra large, juicy shrimps that are perfect for grilling or frying.',
    highlight: 'Antibiotic Free',
    cta: 'Get Shrimps',
    img: 'https://images.unsplash.com/photo-1615141982883-c7ad0e69fd62?q=80&w=1200&auto=format&fit=crop',
    price: 'AED 499',
    oldPrice: 'AED 699',
    accent: 'text-orange-400',
  },
  {
    id: 4,
    tag: 'Exotic',
    title: 'Rock Lobsters',
    subtitle: 'A gourmet delight. Sweet, tender meat for a luxurious dining experience.',
    highlight: 'Premium Choice',
    cta: 'Shop Lobsters',
    img: 'https://images.unsplash.com/photo-1559737558-2f5a35f4523b?q=80&w=1200&auto=format&fit=crop',
    price: 'AED 1,059',
    oldPrice: 'AED 1,720',
    accent: 'text-red-600',
  },
];



const Hero: React.FC = () => {
  const [current, setCurrent] = useState(0);
  const [isHovering, setIsHovering] = useState(false);
  const [direction, setDirection] = useState(1);

  const next = useCallback(() => {
    setDirection(1);
    setCurrent((p) => (p + 1) % banners.length);
  }, []);

  const prev = useCallback(() => {
    setDirection(-1);
    setCurrent((p) => (p - 1 + banners.length) % banners.length);
  }, []);

  const goTo = useCallback((i: number) => {
    setDirection(i > current ? 1 : -1);
    setCurrent(i);
  }, [current]);

  useEffect(() => {
    if (isHovering) return;
    const id = setInterval(next, 6000);
    return () => clearInterval(id);
  }, [next, isHovering]);

  const banner = banners[current];

  /* 1. Background Animation (Slide) */
  const slideVariants = {
    enter: (dir: number) => ({ x: dir > 0 ? '100%' : '-100%', opacity: 1 }),
    center: { x: 0, opacity: 1 },
    exit: (dir: number) => ({ x: dir > 0 ? '-50%' : '50%', opacity: 1 }), // Keep opacity 1 to avoid showing white bg
  };

  /* 2. Text Animation (Fade Only) */
  const fadeVariants = {
    initial: { opacity: 0 },
    animate: { opacity: 1, transition: { duration: 0.5, delay: 0.2 } },
    exit: { opacity: 0, transition: { duration: 0.3 } }
  };

  return (
    <div className="w-full bg-white font-sans text-slate-800 select-none pb-8">

      {/* ═══ HERO CAROUSEL ═══════════════════════ */}
      <section className="relative w-full max-w-7xl mx-auto px-0 sm:px-4 pt-4 sm:pt-6 group/carousel">
        <div
          className="relative h-[300px] sm:h-[360px] md:h-[420px] w-full overflow-hidden sm:rounded-[2rem] shadow-xl shadow-slate-200"
          onMouseEnter={() => setIsHovering(true)}
          onMouseLeave={() => setIsHovering(false)}
        >

          {/* LAYER 1: Background Image & Gradient (Moving) */}
          <AnimatePresence initial={false} custom={direction}>
            <motion.div
              key={banner.id}
              custom={direction}
              variants={slideVariants}
              initial="enter"
              animate="center"
              exit="exit"
              transition={{ x: { type: "spring", stiffness: 300, damping: 30 } }}
              className="absolute inset-0 z-0"
            >
              <motion.img
                src={banner.img}
                alt={banner.title}
                initial={{ scale: 1 }}
                animate={{ scale: 1.1 }}
                transition={{ duration: 10, ease: "linear" }}
                className="w-full h-full object-cover"
              />
              {/* Gradients moving WITH the image for consistency */}
              <div className="absolute inset-0 bg-gradient-to-r from-black/90 via-black/50 to-transparent sm:via-black/40" />
              <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent opacity-60" />
            </motion.div>
          </AnimatePresence>

          {/* LAYER 2: Text Content (Static Position, Fading In/Out) */}
          <div className="absolute inset-0 z-10 flex flex-col justify-center px-6 sm:px-12 md:px-20 lg:px-24 pointer-events-none">
            <div className="max-w-2xl pointer-events-auto">
              <AnimatePresence mode="wait">
                <motion.div
                  key={banner.id}
                  variants={fadeVariants}
                  initial="initial"
                  animate="animate"
                  exit="exit"
                  className="space-y-4"
                >

                  {/* Highlight Tag */}
                  <div className="inline-flex items-center gap-2 mb-4">
                    <span className="px-3 py-1 bg-yellow-500 text-black text-xs font-bold uppercase tracking-wider rounded-full shadow-lg shadow-yellow-500/20">
                      {banner.highlight}
                    </span>
                    <span className="bg-white/10 backdrop-blur-md border border-white/20 text-white text-xs font-medium px-3 py-1 rounded-full">
                      {banner.tag}
                    </span>
                  </div>

                  {/* Title */}
                  <h1 className="text-3xl sm:text-4xl md:text-6xl font-black text-white leading-[1.1] mb-3 tracking-tight">
                    {banner.title.split(' ')[0]} <br />
                    <span className={`text-transparent bg-clip-text bg-gradient-to-r from-white to-slate-200`}>
                      {banner.title.split(' ').slice(1).join(' ')}
                    </span>
                  </h1>

                  {/* Subtitle */}
                  <p className="text-sm sm:text-base text-slate-200 mb-6 max-w-lg leading-relaxed font-medium line-clamp-2 sm:line-clamp-none">
                    {banner.subtitle}
                  </p>

                  {/* Price & CTA */}
                  <div className="flex flex-wrap items-center gap-4 sm:gap-6">
                    <div className="flex flex-col">
                      <span className="text-[10px] sm:text-xs text-slate-400 font-medium uppercase tracking-wider">Starting at</span>
                      <div className="flex items-baseline gap-2">
                        <span className="text-3xl sm:text-4xl font-bold text-white">{banner.price}</span>
                        <span className="text-lg text-slate-500 line-through Decoration-2">{banner.oldPrice}</span>
                      </div>
                    </div>

                    <button className="group relative px-6 py-3 bg-red-600 text-white rounded-full font-bold text-sm sm:text-base shadow-lg shadow-red-600/30 overflow-hidden transition-transform hover:scale-105 active:scale-95">
                      <span className="relative z-10 flex items-center gap-2">
                        {banner.cta} <ChevronRight size={16} />
                      </span>
                      <div className="absolute inset-0 bg-gradient-to-r from-red-600 to-red-500 group-hover:from-red-500 group-hover:to-red-400 transition-colors" />
                    </button>
                  </div>

                </motion.div>
              </AnimatePresence>
            </div>
          </div>

          {/* Navigation Controls */}
          <div className="absolute bottom-8 right-8 z-20 hidden md:flex gap-3">
            <button
              onClick={prev}
              className="p-4 rounded-full bg-white/10 hover:bg-white/20 backdrop-blur-md border border-white/10 text-white transition-all hover:scale-110 active:scale-95 group"
            >
              <ChevronLeft size={24} className="group-hover:-translate-x-0.5 transition-transform" />
            </button>
            <button
              onClick={next}
              className="p-4 rounded-full bg-white text-slate-900 shadow-lg shadow-white/10 transition-all hover:scale-110 active:scale-95 group"
            >
              <ChevronRight size={24} className="group-hover:translate-x-0.5 transition-transform" />
            </button>
          </div>

          {/* Mobile Navigation */}
          <button onClick={prev} className="absolute left-4 top-1/2 -translate-y-1/2 z-20 md:hidden p-2 rounded-full bg-black/20 text-white backdrop-blur-sm">
            <ChevronLeft size={24} />
          </button>
          <button onClick={next} className="absolute right-4 top-1/2 -translate-y-1/2 z-20 md:hidden p-2 rounded-full bg-black/20 text-white backdrop-blur-sm">
            <ChevronRight size={24} />
          </button>

          {/* Progress Indicators */}
          <div className="absolute bottom-6 left-6 md:left-24 z-20 flex gap-2">
            {banners.map((_, i) => (
              <button
                key={i}
                onClick={() => goTo(i)}
                className={`h-1.5 rounded-full transition-all duration-300 ${i === current ? 'w-8 bg-red-500' : 'w-2 bg-white/40 hover:bg-white/60'
                  }`}
              />
            ))}
          </div>
        </div>
      </section>
    </div>
  );
};

export default Hero;