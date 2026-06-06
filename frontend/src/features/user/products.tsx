import React, { useEffect, useState, useCallback, memo } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { productsApi, type ProductDto } from "../admin/products/productApi";
import { motion, AnimatePresence } from "framer-motion";
import { Search, ShoppingCart, Star, Filter, ArrowRight, Zap, ChevronLeft, ChevronRight } from "lucide-react";
import { useAppDispatch, useRequireAuth } from "../../hooks";
import { addToCart } from "../admin/cart/cartSlice";
import { useNavigate } from "react-router-dom";
import ShrimpLoader from "../../components/loader/preloader";

// --- Extracted Memoized Product Card ---
const ProductCard = memo(({
    product,
    onAddToCart,
    onBuyNow
}: {
    product: ProductDto;
    onAddToCart: (e: React.MouseEvent, p: ProductDto) => void;
    onBuyNow: (e: React.MouseEvent, p: ProductDto) => void;
}) => {
    return (
        <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95 }}
            transition={{ duration: 0.4, ease: [0.23, 1, 0.32, 1] }}
            className="group relative bg-white rounded-[2rem] p-3 hover:shadow-2xl hover:shadow-slate-200/50 transition-all duration-300 border border-slate-100 hover:border-slate-200 h-full"
        >
            <Link to={`/products/${product.id}`} className="block h-full flex flex-col">
                {/* Image Container with aspect-ratio to prevent Layout Shift */}
                <div className="relative aspect-[3/4] bg-slate-50 rounded-[1.5rem] overflow-hidden mb-4 isolate">
                    <img
                        src={product.image || "https://via.placeholder.com/400x500?text=Fresh+Catch"}
                        alt={product.name}
                        loading="lazy" // Native Lazy Loading
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700 ease-out"
                    />

                    {/* Gradient Overlay */}
                    <div className="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />

                    {/* Badges */}
                    <div className="absolute top-3 left-3 flex flex-col gap-2 z-10">
                        {product.discount_price && (
                            <span className="px-2.5 py-1 bg-rose-500 text-white text-[10px] font-bold uppercase tracking-wider rounded-lg shadow-sm">
                                Sale
                            </span>
                        )}
                        {product.average_rating > 4.5 && (
                            <span className="px-2.5 py-1 bg-amber-400 text-black text-[10px] font-bold uppercase tracking-wider rounded-lg shadow-sm flex items-center gap-1">
                                <Star size={10} fill="black" /> Top Rated
                            </span>
                        )}
                    </div>

                    {/* Quick Action Buttons */}
                    <div className="absolute bottom-3 right-3 flex flex-col gap-2 translate-y-12 opacity-0 group-hover:translate-y-0 group-hover:opacity-100 transition-all duration-300 z-20">
                        <button
                            onClick={(e) => onAddToCart(e, product)}
                            disabled={!product.is_available}
                            className="w-10 h-10 bg-white shadow-xl text-slate-900 rounded-full flex items-center justify-center hover:bg-red-600 hover:text-white transition-all duration-300 disabled:opacity-50"
                            title="Add to Cart"
                        >
                            <ShoppingCart size={18} />
                        </button>

                    </div>

                    {/* Out of Stock Overlay */}
                    {!product.is_available && (
                        <div className="absolute inset-0 bg-slate-900/10 backdrop-blur-[1px] flex items-center justify-center z-10">
                            <div className="bg-white/95 backdrop-blur-sm px-4 py-2 rounded-xl shadow-xl">
                                <span className="text-slate-900 text-xs font-black uppercase tracking-widest">Out of Stock</span>
                            </div>
                        </div>
                    )}
                </div>

                {/* Content */}
                <div className="px-2 pb-2 flex-grow flex flex-col">
                    <div className="mb-1 flex items-center justify-between">
                        <span className="text-[10px] font-extrabold uppercase tracking-widest text-red-600 bg-red-50 px-2 py-0.5 rounded-md">
                            {product.category_name || "Seafood"}
                        </span>
                        <div className="flex items-center gap-1">
                            <Star size={12} className="text-amber-400 fill-amber-400" />
                            <span className="text-xs font-bold text-slate-700">{product.average_rating ? Number(product.average_rating).toFixed(1) : "New"}</span>
                        </div>
                    </div>

                    <h3 className="text-base font-bold text-slate-900 leading-snug mb-1 line-clamp-2">
                        {product.name}
                    </h3>
                    <p className="text-xs text-slate-500 mb-4 line-clamp-1">{product.description || "Fresh and premium quality."}</p>

                    <div className="mt-auto pt-3 border-t border-slate-50 space-y-3">
                        <div className="flex items-center justify-between">
                            <div className="flex flex-col">
                                {product.discount_price ? (
                                    <>
                                        <span className="text-[10px] text-slate-400 line-through font-medium">AED {product.price}</span>
                                        <span className="text-lg font-black text-slate-900">AED {product.discount_price}</span>
                                    </>
                                ) : (
                                    <span className="text-lg font-black text-slate-900">AED {product.price}</span>
                                )}
                            </div>

                            <div className="flex items-center gap-2 text-xs font-bold text-slate-900 group/btn">
                                <span className="hidden sm:inline-block opacity-0 -translate-x-2 group-hover:opacity-100 group-hover:translate-x-0 transition-all duration-300 text-slate-500">View</span>
                                <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center group-hover:bg-slate-900 group-hover:text-white transition-colors duration-300">
                                    <ArrowRight size={14} />
                                </div>
                            </div>
                        </div>

                        {/* Buy Now Button */}
                        <button
                            onClick={(e) => onBuyNow(e, product)}
                            disabled={!product.is_available}
                            className="w-full py-2.5 bg-red-600 text-white text-xs font-bold rounded-xl hover:bg-red-700 transition-all duration-300 flex items-center justify-center gap-2 shadow-md hover:shadow-lg active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            <Zap size={14} />
                            Buy Now
                        </button>
                    </div>
                </div>
            </Link>
        </motion.div>
    );
});

const UserProductsPage: React.FC = () => {
    const dispatch = useAppDispatch();
    const navigate = useNavigate();
    const requireAuth = useRequireAuth();
    const [products, setProducts] = useState<ProductDto[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [searchParams, setSearchParams] = useSearchParams();
    const LIMIT = 12;

    // Pagination state
    const [currentPage, setCurrentPage] = useState(Number(searchParams.get("page")) || 1);
    const [totalCount, setTotalCount] = useState(0);

    // Filters state
    const [searchTerm, setSearchTerm] = useState(searchParams.get("q") || "");
    const category = searchParams.get("category");

    // Memoize the filter sync to URL to prevent excessive re-renders
    useEffect(() => {
        const handler = setTimeout(() => {
            const params: any = {};
            if (searchTerm) params.q = searchTerm;
            if (category) params.category = category;
            if (currentPage > 1) params.page = currentPage;
            setSearchParams(params, { replace: true });
        }, 500);

        return () => clearTimeout(handler);
    }, [searchTerm, category, currentPage, setSearchParams]);

    // Reset pagination on filter change
    useEffect(() => {
        setCurrentPage(1);
    }, [searchTerm, category]);

    // Fetch Products
    useEffect(() => {
        let isMounted = true;
        const fetchProducts = async () => {
            try {
                setLoading(true);
                const params: any = {
                    limit: LIMIT,
                    offset: (currentPage - 1) * LIMIT
                };
                if (searchTerm) params.q = searchTerm;
                if (category) params.category = category;

                const data = await productsApi.list(params);
                if (isMounted) {
                    setProducts(data.results);
                    setTotalCount(data.count || 0);
                }
            } catch (err: any) {
                if (isMounted) setError("Failed to load products. Please try again.");
            } finally {
                if (isMounted) setLoading(false);
            }
        };

        const timeout = setTimeout(fetchProducts, 300);
        return () => {
            isMounted = false;
            clearTimeout(timeout);
        };
    }, [searchTerm, category, currentPage]);

    const handleAddToCart = useCallback((e: React.MouseEvent, product: ProductDto) => {
        e.preventDefault();
        e.stopPropagation();

        requireAuth(() => {
            const price = parseFloat(product.price);
            const discountPrice = product.discount_price ? parseFloat(product.discount_price) : undefined;
            const finalPrice = discountPrice || price;

            dispatch(addToCart({
                id: product.id,
                name: product.name,
                price: price,
                discountPrice: discountPrice,
                finalPrice: finalPrice,
                image: product.image,
                sku: product.sku,
                stock: product.stock,
                quantity: 1
            }));
        })();
    }, [dispatch, requireAuth]);

    const handleBuyNow = useCallback((e: React.MouseEvent, product: ProductDto) => {
        e.preventDefault();
        e.stopPropagation();

        requireAuth(() => {
            const price = parseFloat(product.price);
            const discountPrice = product.discount_price ? parseFloat(product.discount_price) : undefined;
            const finalPrice = discountPrice || price;

            dispatch(addToCart({
                id: product.id,
                name: product.name,
                price: price,
                discountPrice: discountPrice,
                finalPrice: finalPrice,
                image: product.image,
                sku: product.sku,
                stock: product.stock,
                quantity: 1
            }));
            navigate('/checkout');
        })();
    }, [dispatch, navigate, requireAuth]);

    // Scroll to top on page change
    useEffect(() => {
        window.scrollTo({ top: 0, behavior: "smooth" });
    }, [currentPage]);

    const totalPages = Math.ceil(totalCount / LIMIT);

    return (
        <div className="min-h-screen bg-slate-50 font-sans text-slate-800 selection:bg-red-100 selection:text-red-900">

            {/* ─── Static Filter Bar ─── */}
            <div className="relative z-30 bg-white border-b border-slate-100 shadow-sm">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4">
                    <div className="flex flex-col md:flex-row items-center justify-between gap-4">

                        {/* Search Input */}
                        <div className="relative w-full md:w-96 group">
                            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-red-500 transition-colors" size={20} />
                            <input
                                type="text"
                                placeholder="Search lobsters, prawns, crabs..."
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                                className="w-full pl-12 pr-4 py-3 bg-slate-100/50 hover:bg-slate-100 border border-transparent focus:bg-white focus:border-red-200 focus:ring-4 focus:ring-red-500/10 rounded-2xl text-sm font-semibold text-slate-900 outline-none transition-all placeholder:text-slate-400"
                            />
                        </div>
                    </div>
                </div>
            </div>

            {/* ─── Product Grid ─── */}
            <main className="max-w-7xl mx-auto px-4 sm:px-6 py-8">
                {loading && products.length === 0 ? (
                    <div className="flex items-center justify-center min-h-[50vh]">
                        <ShrimpLoader />
                    </div>
                ) : error ? (
                    <div className="flex flex-col items-center justify-center py-20 bg-white rounded-3xl shadow-sm border border-slate-100 p-8">
                        <div className="w-16 h-16 bg-red-50 text-red-500 rounded-full flex items-center justify-center mb-4">
                            <Filter size={32} />
                        </div>
                        <p className="text-slate-900 font-bold text-lg mb-2">{error}</p>
                        <button onClick={() => window.location.reload()} className="px-6 py-2 bg-slate-900 text-white rounded-full text-sm font-bold hover:bg-slate-800 transition-colors">
                            Try Again
                        </button>
                    </div>
                ) : products.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-32 text-center">
                        <div className="w-24 h-24 bg-slate-100 rounded-full flex items-center justify-center mb-6">
                            <Search className="text-slate-300" size={40} />
                        </div>
                        <h3 className="text-2xl font-black text-slate-900 mb-2">No catch found</h3>
                        <p className="text-slate-500 mb-8 max-w-sm">We couldn't find any products matching "{searchTerm}".</p>
                        <button
                            onClick={() => { setSearchTerm(""); }}
                            className="px-8 py-3 bg-slate-900 text-white rounded-full font-bold text-sm hover:bg-slate-800 transition-all hover:scale-105 active:scale-95 shadow-xl shadow-slate-900/20"
                        >
                            Clear search
                        </button>
                    </div>
                ) : (
                    <>
                        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 sm:gap-8">
                            <AnimatePresence mode="popLayout">
                                {products.map((product) => (
                                    <ProductCard
                                        key={product.id}
                                        product={product}
                                        onAddToCart={handleAddToCart}
                                        onBuyNow={handleBuyNow}
                                    />
                                ))}
                            </AnimatePresence>
                        </div>

                        {/* Pagination UI */}
                        {totalPages > 1 && (
                            <div className="mt-16 flex flex-col items-center gap-6">
                                <div className="flex items-center gap-2">
                                    <button
                                        disabled={currentPage === 1}
                                        onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))}
                                        className="w-12 h-12 rounded-2xl bg-white border border-slate-200 flex items-center justify-center text-slate-600 hover:border-red-500 hover:text-red-500 disabled:opacity-30 disabled:hover:border-slate-200 disabled:hover:text-slate-600 transition-all shadow-sm active:scale-90"
                                    >
                                        <ChevronLeft size={20} />
                                    </button>

                                    <div className="flex items-center gap-2">
                                        {[...Array(totalPages)].map((_, i) => {
                                            const pageNum = i + 1;
                                            // Simple logic for brevity: show first, last, and current ± 1
                                            if (
                                                pageNum === 1 ||
                                                pageNum === totalPages ||
                                                Math.abs(pageNum - currentPage) <= 1
                                            ) {
                                                return (
                                                    <button
                                                        key={pageNum}
                                                        onClick={() => setCurrentPage(pageNum)}
                                                        className={`w-12 h-12 rounded-2xl font-bold text-sm transition-all shadow-sm active:scale-90 ${currentPage === pageNum
                                                            ? "bg-red-600 text-white shadow-red-200"
                                                            : "bg-white border border-slate-200 text-slate-600 hover:border-red-500 hover:text-red-500"
                                                            }`}
                                                    >
                                                        {pageNum}
                                                    </button>
                                                );
                                            } else if (
                                                Math.abs(pageNum - currentPage) === 2
                                            ) {
                                                return <span key={pageNum} className="text-slate-300">...</span>;
                                            }
                                            return null;
                                        })}
                                    </div>

                                    <button
                                        disabled={currentPage === totalPages}
                                        onClick={() => setCurrentPage(prev => Math.min(totalPages, prev + 1))}
                                        className="w-12 h-12 rounded-2xl bg-white border border-slate-200 flex items-center justify-center text-slate-600 hover:border-red-500 hover:text-red-500 disabled:opacity-30 disabled:hover:border-slate-200 disabled:hover:text-slate-600 transition-all shadow-sm active:scale-90"
                                    >
                                        <ChevronRight size={20} />
                                    </button>
                                </div>

                                <p className="text-[10px] font-black uppercase tracking-[0.2em] text-slate-400">
                                    Showing <span className="text-slate-900">{(currentPage - 1) * LIMIT + 1}</span> to <span className="text-slate-900">{Math.min(currentPage * LIMIT, totalCount)}</span> of <span className="text-slate-900">{totalCount}</span> Products
                                </p>
                            </div>
                        )}
                    </>
                )}
            </main>
        </div>
    );
};

export default UserProductsPage;
