import React, { useEffect, useRef, useState } from "react";
import {
    Star,
    ShoppingCart,
    ChevronLeft,
    ChevronRight,
    Flame,
    Eye,
    Sparkles,
} from "lucide-react";
import { api } from "../../services/api";
import { useAppDispatch, useRequireAuth } from "../../hooks";
import { addToCart } from "../../features/admin/cart/cartSlice";

/* ── Types ── */
interface ProductImage {
    id: number;
    image: string;
    is_feature: boolean;
}

interface Product {
    id: number;
    name: string;
    slug: string;
    description: string;
    category_name: string;
    price: string;
    discount_price: string | null;
    final_price: string;
    stock: number;
    is_available: boolean;
    image: string | null;
    images: ProductImage[];
    average_rating: number;
    total_reviews: number;
}

/* ── Product Card ── */
const ProductCard: React.FC<{
    product: Product;
    image: string;
    discount: number;
    index: number;
    onAddToCart: () => void;
}> = ({ product, image, discount, index, onAddToCart }) => {
    const ref = useRef<HTMLDivElement>(null);
    const [visible, setVisible] = useState(false);
    const [imgLoaded, setImgLoaded] = useState(false);

    useEffect(() => {
        const el = ref.current;
        if (!el) return;
        const obs = new IntersectionObserver(
            ([e]) => { if (e.isIntersecting) setVisible(true); },
            { threshold: 0.1 }
        );
        obs.observe(el);
        return () => obs.disconnect();
    }, []);

    const price = parseFloat(product.price);
    const finalPrice = parseFloat(product.final_price);
    const rating = product.average_rating || 0;

    return (
        <div
            ref={ref}
            className={`group relative min-w-[280px] max-w-[280px] bg-white rounded-2xl border border-zinc-100 overflow-hidden snap-start transition-all duration-500 hover:shadow-xl hover:-translate-y-1 cursor-pointer ${visible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"
                }`}
            style={{ transitionDelay: `${index * 60}ms` }}
        >
            {/* Image */}
            <div className="relative h-52 bg-zinc-50 overflow-hidden">
                {image && (
                    <img
                        src={image}
                        alt={product.name}
                        onLoad={() => setImgLoaded(true)}
                        className={`w-full h-full object-cover transition-all duration-700 group-hover:scale-110 ${imgLoaded ? "opacity-100" : "opacity-0"
                            }`}
                    />
                )}
                {!imgLoaded && (
                    <div className="absolute inset-0 flex items-center justify-center text-zinc-300">
                        <Sparkles size={32} />
                    </div>
                )}

                {/* Discount badge */}
                {discount > 0 && (
                    <div className="absolute top-3 left-3 px-2.5 py-1 bg-red-600 text-white rounded-lg text-[10px] font-bold shadow-md">
                        {discount}% OFF
                    </div>
                )}

                {/* Out of stock overlay */}
                {!product.is_available && (
                    <div className="absolute inset-0 bg-black/40 flex items-center justify-center backdrop-blur-[2px]">
                        <span className="px-4 py-1.5 bg-white/90 rounded-full text-xs font-bold text-zinc-700">
                            Out of Stock
                        </span>
                    </div>
                )}

                {/* Quick view on hover */}
                <div className="absolute inset-0 bg-black/20 opacity-0 group-hover:opacity-100 transition-all duration-300 flex items-end justify-center pb-4">
                    <button className="px-4 py-2 bg-white/90 backdrop-blur-sm rounded-full text-xs font-bold text-zinc-800 flex items-center gap-1.5 shadow-lg hover:bg-white transition-all">
                        <Eye size={14} /> Quick View
                    </button>
                </div>
            </div>

            {/* Details */}
            <div className="p-5">
                {/* Category */}
                <p className="text-[10px] font-bold uppercase tracking-widest text-zinc-400 mb-1">
                    {product.category_name || "Seafood"}
                </p>

                {/* Name */}
                <h3 className="text-sm font-bold text-zinc-900 leading-snug line-clamp-2 mb-2 group-hover:text-red-600 transition-colors">
                    {product.name}
                </h3>

                {/* Rating */}
                {rating > 0 && (
                    <div className="flex items-center gap-1.5 mb-3">
                        <div className="flex items-center gap-0.5">
                            {[...Array(5)].map((_, i) => (
                                <Star
                                    key={i}
                                    size={12}
                                    className={i < Math.round(rating) ? "fill-yellow-400 text-yellow-400" : "text-zinc-200"}
                                />
                            ))}
                        </div>
                        <span className="text-[10px] text-zinc-400">
                            ({product.total_reviews})
                        </span>
                    </div>
                )}

                {/* Price + Cart */}
                <div className="flex items-center justify-between">
                    <div className="flex items-baseline gap-2">
                        <span className="text-lg font-extrabold text-zinc-900">
                            AED {Math.round(finalPrice)}
                        </span>
                        {discount > 0 && (
                            <span className="text-xs text-zinc-400 line-through">
                                AED {Math.round(price)}
                            </span>
                        )}
                    </div>
                    <button
                        onClick={() => onAddToCart()}
                        disabled={!product.is_available}
                        className="p-2.5 rounded-xl bg-red-900 text-white hover:bg-red-700 disabled:bg-zinc-200 disabled:text-zinc-400 disabled:cursor-not-allowed transition-all duration-300 shadow-md hover:shadow-lg active:scale-95"
                    >
                        <ShoppingCart size={16} />
                    </button>
                </div>
            </div>
        </div>
    );
};

/* ── Main Section ── */
const BestsellersSection: React.FC = () => {
    const [products, setProducts] = useState<Product[]>([]);
    const [loading, setLoading] = useState(true);
    const scrollRef = useRef<HTMLDivElement>(null);
    const [canScrollLeft, setCanScrollLeft] = useState(false);
    const [canScrollRight, setCanScrollRight] = useState(true);
    const dispatch = useAppDispatch();
    const requireAuth = useRequireAuth();

    useEffect(() => {
        const fetchProducts = async () => {
            try {
                const res = await api.get<{ results: Product[]; count: number }>(
                    "/products/products/",
                    { params: { limit: 12 } }
                );
                setProducts(res.data.results || []);
            } catch (err) {
                console.error("Failed to fetch bestsellers:", err);
            } finally {
                setLoading(false);
            }
        };
        fetchProducts();
    }, []);

    const updateScrollButtons = () => {
        const el = scrollRef.current;
        if (!el) return;
        setCanScrollLeft(el.scrollLeft > 10);
        setCanScrollRight(el.scrollLeft < el.scrollWidth - el.clientWidth - 10);
    };

    useEffect(() => {
        const el = scrollRef.current;
        if (!el) return;
        el.addEventListener("scroll", updateScrollButtons);
        updateScrollButtons();
        return () => el.removeEventListener("scroll", updateScrollButtons);
    }, [products]);

    const scroll = (dir: "left" | "right") => {
        const el = scrollRef.current;
        if (!el) return;
        el.scrollBy({ left: dir === "left" ? -340 : 340, behavior: "smooth" });
    };

    const getProductImage = (p: Product) => {
        const featured = p.images?.find((img) => img.is_feature);
        if (featured) return featured.image;
        if (p.images?.[0]) return p.images[0].image;
        return p.image || "";
    };

    const getDiscount = (p: Product) => {
        const price = parseFloat(p.price);
        const final = parseFloat(p.final_price);
        if (!price || !final || price <= final) return 0;
        return Math.round(((price - final) / price) * 100);
    };

    const handleAddToCart = (product: Product) => {
        requireAuth(() => {
            const price = parseFloat(product.price);
            const discountPrice = product.discount_price ? parseFloat(product.discount_price) : undefined;
            const finalPrice = parseFloat(product.final_price) || discountPrice || price;
            dispatch(addToCart({
                id: product.id,
                name: product.name,
                price,
                discountPrice,
                finalPrice,
                image: product.image,
                sku: product.slug,
                stock: product.stock,
                quantity: 1
            }));
        })();
    };

    return (
        <section className="relative bg-[#FAFAF8] py-20 px-4 sm:px-6 lg:px-8 overflow-hidden">
            {/* Decorative blob */}
            <div className="pointer-events-none absolute -top-32 -right-32 w-96 h-96 bg-red-50 rounded-full blur-3xl opacity-60" />
            <div className="pointer-events-none absolute -bottom-32 -left-32 w-80 h-80 bg-yellow-50 rounded-full blur-3xl opacity-50" />

            <div className="relative mx-auto max-w-7xl">
                {/* Header */}
                <div className="flex items-end justify-between mb-10">
                    <div>
                        <div className="inline-flex items-center gap-2 px-4 py-1.5 bg-red-50 border border-red-100 rounded-full mb-3">
                            <Flame size={14} className="text-red-500" />
                            <span className="text-[11px] font-bold uppercase tracking-widest text-red-600">
                                Bestsellers
                            </span>
                        </div>
                        <h2 className="text-3xl sm:text-4xl font-extrabold text-zinc-900 tracking-tight">
                            Our Most <span className="text-red-600">Loved</span> Catches
                        </h2>
                        <p className="mt-2 text-zinc-500 text-sm max-w-md">
                            Fresh picks your neighbors can't stop ordering. Straight from the ocean — cleaned, packed & ready to cook.
                        </p>
                    </div>

                    {/* Nav arrows */}
                    <div className="hidden sm:flex items-center gap-2">
                        <button
                            onClick={() => scroll("left")}
                            disabled={!canScrollLeft}
                            className="p-2.5 rounded-xl border border-zinc-200 bg-white hover:bg-zinc-50 disabled:opacity-30 disabled:cursor-not-allowed transition-all shadow-sm"
                        >
                            <ChevronLeft size={18} />
                        </button>
                        <button
                            onClick={() => scroll("right")}
                            disabled={!canScrollRight}
                            className="p-2.5 rounded-xl border border-zinc-200 bg-white hover:bg-zinc-50 disabled:opacity-30 disabled:cursor-not-allowed transition-all shadow-sm"
                        >
                            <ChevronRight size={18} />
                        </button>
                    </div>
                </div>

                {/* Skeleton loader */}
                {loading && (
                    <div className="flex gap-5 overflow-hidden">
                        {[...Array(4)].map((_, i) => (
                            <div key={i} className="min-w-[280px] bg-white rounded-2xl border border-zinc-100 overflow-hidden animate-pulse">
                                <div className="h-52 bg-zinc-100" />
                                <div className="p-5 space-y-3">
                                    <div className="h-3 w-16 bg-zinc-100 rounded" />
                                    <div className="h-4 w-3/4 bg-zinc-100 rounded" />
                                    <div className="h-3 w-1/2 bg-zinc-100 rounded" />
                                    <div className="flex justify-between">
                                        <div className="h-5 w-16 bg-zinc-100 rounded" />
                                        <div className="h-8 w-8 bg-zinc-100 rounded-lg" />
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                )}

                {/* Product Carousel */}
                {!loading && products.length > 0 && (
                    <div
                        ref={scrollRef}
                        className="flex gap-5 overflow-x-auto pb-4 scrollbar-hide snap-x snap-mandatory"
                        style={{ scrollbarWidth: "none", msOverflowStyle: "none" }}
                    >
                        {products.map((product, i) => (
                            <ProductCard
                                key={product.id}
                                product={product}
                                image={getProductImage(product)}
                                discount={getDiscount(product)}
                                index={i}
                                onAddToCart={() => handleAddToCart(product)}
                            />
                        ))}
                    </div>
                )}

                {/* Empty state */}
                {!loading && products.length === 0 && (
                    <div className="text-center py-16">
                        <Sparkles className="mx-auto text-zinc-300 mb-4" size={48} />
                        <p className="text-zinc-400 text-sm">No products available yet. Check back soon!</p>
                    </div>
                )}
            </div>

            {/* Hide scrollbar CSS */}
            <style>{`.scrollbar-hide::-webkit-scrollbar { display: none; }`}</style>
        </section>
    );
};

export default BestsellersSection;
