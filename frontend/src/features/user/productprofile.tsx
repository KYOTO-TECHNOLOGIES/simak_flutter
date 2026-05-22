import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { productsApi, type ProductDto, type ProductImageDto } from "../admin/products/productApi";
import { motion } from "framer-motion";
import { Star, ShoppingCart, Truck, ShieldCheck, ArrowLeft, Minus, Plus, Heart, Zap } from "lucide-react";
import { useAppDispatch, useRequireAuth } from "../../hooks";
import { addToCart } from "../admin/cart/cartSlice";

const ProductProfile: React.FC = () => {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const dispatch = useAppDispatch();
    const requireAuth = useRequireAuth();
    const [product, setProduct] = useState<ProductDto | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [selectedImage, setSelectedImage] = useState<string | null>(null);
    const [quantity, setQuantity] = useState(1);
    const [isWishlisted, setIsWishlisted] = useState(false);

    useEffect(() => {
        checkWishlist();
    }, [product]);

    const checkWishlist = () => {
        if (!product) return;
        try {
            const stored = localStorage.getItem("wishlist");
            if (stored) {
                const items = JSON.parse(stored) as ProductDto[];
                setIsWishlisted(items.some(item => item.id === product.id));
            }
        } catch (err) {
            console.error(err);
        }
    };

    const toggleWishlist = () => {
        if (!product) return;
        try {
            const stored = localStorage.getItem("wishlist");
            let items: ProductDto[] = stored ? JSON.parse(stored) : [];

            if (isWishlisted) {
                items = items.filter(item => item.id !== product.id);
                setIsWishlisted(false);
            } else {
                if (!items.find(item => item.id === product.id)) {
                    items.push(product);
                }
                setIsWishlisted(true);
            }
            localStorage.setItem("wishlist", JSON.stringify(items));
            window.dispatchEvent(new Event("storage"));
        } catch (err) {
            console.error(err);
        }
    };

    useEffect(() => {
        const fetchProduct = async () => {
            if (!id) return;
            try {
                setLoading(true);
                const data = await productsApi.details(parseInt(id));
                setProduct(data);
                setSelectedImage(data.image);
            } catch (err: any) {
                setError("Failed to load product details.");
            } finally {
                setLoading(false);
            }
        };
        fetchProduct();
    }, [id]);

    if (loading) {
        return (
            <div className="min-h-screen bg-slate-50 flex items-center justify-center">
                <div className="animate-pulse flex flex-col items-center">
                    <div className="w-12 h-12 bg-slate-200 rounded-full mb-4"></div>
                    <div className="h-4 bg-slate-200 rounded w-32"></div>
                </div>
            </div>
        );
    }

    if (error || !product) {
        return (
            <div className="min-h-screen bg-slate-50 flex flex-col items-center justify-center">
                <p className="text-red-500 font-bold mb-4">{error || "Product not found"}</p>
                <button
                    onClick={() => navigate('/products')}
                    className="flex items-center gap-2 text-slate-600 hover:text-slate-900 font-bold"
                >
                    <ArrowLeft size={16} /> Back to Shop
                </button>
            </div>
        );
    }

    // Combine main image and gallery images
    const allImages = [
        product.image ? { id: -1, image: product.image, is_feature: true } : null,
        ...(product.images || [])
    ].filter(Boolean) as ({ id: number; image: string; is_feature?: boolean } & Partial<ProductImageDto>)[];

    const discountPercentage = product.discount_price
        ? Math.round(((parseFloat(product.price) - parseFloat(product.discount_price)) / parseFloat(product.price)) * 100)
        : 0;

    return (
        <div className="min-h-screen bg-white font-sans text-stone-800 pb-20">
            {/* ─── Breadcrumb / Back ─── */}
            <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6">
                <button
                    onClick={() => navigate(-1)}
                    className="flex items-center gap-2 text-sm font-bold text-stone-500 hover:text-red-600 transition-colors"
                >
                    <ArrowLeft size={16} /> Back
                </button>
            </div>

            <main className="max-w-7xl mx-auto px-4 sm:px-6 grid grid-cols-1 lg:grid-cols-2 gap-12 lg:gap-20">

                {/* ─── Product Gallery ─── */}
                <div className="space-y-6">
                    {/* Main Image */}
                    <motion.div
                        initial={{ opacity: 0, scale: 0.95 }}
                        animate={{ opacity: 1, scale: 1 }}
                        className="relative aspect-[4/3] bg-slate-50 rounded-3xl overflow-hidden border border-slate-100"
                    >
                        <img
                            src={selectedImage || "https://via.placeholder.com/600x450?text=No+Image"}
                            alt={product.name}
                            className="w-full h-full object-cover"
                        />

                        {/* Badges */}
                        <div className="absolute top-4 left-4 flex flex-col gap-2">
                            {product.discount_price && (
                                <span className="px-3 py-1.5 bg-red-600 text-white text-xs font-black uppercase tracking-widest rounded-lg shadow-lg shadow-red-600/30">
                                    {discountPercentage}% OFF
                                </span>
                            )}
                            {!product.is_available && (
                                <span className="px-3 py-1.5 bg-red-900 text-white text-xs font-black uppercase tracking-widest rounded-lg shadow-lg">
                                    Out of Stock
                                </span>
                            )}
                        </div>
                    </motion.div>

                    {/* Thumbnails */}
                    {allImages.length > 1 && (
                        <div className="flex gap-4 overflow-x-auto pb-2 no-scrollbar">
                            {allImages.map((img, idx) => (
                                <button
                                    key={img.id || idx}
                                    onClick={() => setSelectedImage(img.image)}
                                    className={`relative w-24 h-24 flex-shrink-0 rounded-2xl overflow-hidden border-2 transition-all ${selectedImage === img.image
                                        ? "border-red-600 ring-2 ring-red-600/20"
                                        : "border-transparent hover:border-stone-200"
                                        }`}
                                >
                                    <img
                                        src={img.image}
                                        alt={`View ${idx + 1}`}
                                        className="w-full h-full object-cover"
                                    />
                                </button>
                            ))}
                        </div>
                    )}
                </div>

                {/* ─── Product Details ─── */}
                <div className="space-y-8">
                    {/* Header Info */}
                    <div className="space-y-2">
                        <div className="flex items-center gap-2 mb-2">
                            <span className="text-xs font-bold uppercase tracking-widest text-red-600 bg-red-50 px-2 py-1 rounded-md">
                                {product.category_name}
                            </span>
                            {product.average_rating > 0 && (
                                <div className="flex items-center gap-1 text-yellow-500">
                                    <Star size={14} fill="currentColor" />
                                    <span className="text-sm font-bold text-stone-700">{product.average_rating} ({product.total_reviews} reviews)</span>
                                </div>
                            )}
                        </div>

                        <h1 className="text-4xl md:text-5xl font-black text-stone-900 leading-tight">
                            {product.name}
                        </h1>
                        <p className="text-stone-500 leading-relaxed text-lg">
                            {product.description}
                        </p>
                    </div>

                    {/* Price Block */}
                    <div className="p-6 bg-stone-50 rounded-3xl border border-stone-100 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-6">
                        <div>
                            <p className="text-sm text-stone-400 font-bold mb-1">Price per {product.sku}</p>
                            <div className="flex items-baseline gap-3">
                                {product.discount_price ? (
                                    <>
                                        <span className="text-4xl font-black text-stone-900">AED {product.discount_price}</span>
                                        <span className="text-xl text-stone-400 line-through font-bold">AED {product.price}</span>
                                    </>
                                ) : (
                                    <span className="text-4xl font-black text-stone-900">AED {product.price}</span>
                                )}
                            </div>
                        </div>

                        {/* Quantity & Add to Cart */}
                        <div className="flex flex-col gap-3 w-full sm:w-auto">
                            <div className="flex items-center gap-4 bg-white rounded-xl p-1 border border-stone-200 shadow-sm w-fit">
                                <button
                                    onClick={() => setQuantity(Math.max(1, quantity - 1))}
                                    className="w-10 h-10 flex items-center justify-center text-stone-600 hover:bg-stone-100 rounded-lg transition-colors"
                                >
                                    <Minus size={18} />
                                </button>
                                <span className="text-lg font-black w-8 text-center">{quantity}</span>
                                <button
                                    onClick={() => setQuantity(quantity + 1)}
                                    className="w-10 h-10 flex items-center justify-center text-stone-600 hover:bg-stone-100 rounded-lg transition-colors"
                                >
                                    <Plus size={18} />
                                </button>
                            </div>
                        </div>
                    </div>

                    {/* Actions */}
                    <div className="flex gap-3">
                        <button
                            onClick={() => {
                                requireAuth(() => {
                                    if (product) {
                                        dispatch(addToCart({
                                            id: product.id,
                                            name: product.name,
                                            price: parseFloat(product.price),
                                            discountPrice: product.discount_price ? parseFloat(product.discount_price) : undefined,
                                            finalPrice: product.discount_price ? parseFloat(product.discount_price) : parseFloat(product.price),
                                            image: product.image,
                                            quantity: quantity,
                                            stock: product.stock,
                                            sku: product.sku,
                                            category: product.category_name
                                        }));
                                        navigate('/cart');
                                    }
                                })();
                            }}
                            disabled={!product.is_available}
                            className="flex-1 py-4 bg-stone-900 text-white text-base font-black rounded-2xl hover:bg-stone-800 shadow-xl shadow-stone-900/10 hover:shadow-stone-900/30 transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-3 active:scale-[0.98]"
                        >
                            <ShoppingCart size={22} />
                            {product.is_available ? "Add to Cart" : "Out of Stock"}
                        </button>
                        <button
                            onClick={() => {
                                requireAuth(() => {
                                    if (product) {
                                        dispatch(addToCart({
                                            id: product.id,
                                            name: product.name,
                                            price: parseFloat(product.price),
                                            discountPrice: product.discount_price ? parseFloat(product.discount_price) : undefined,
                                            finalPrice: product.discount_price ? parseFloat(product.discount_price) : parseFloat(product.price),
                                            image: product.image,
                                            quantity: quantity,
                                            stock: product.stock,
                                            sku: product.sku,
                                            category: product.category_name
                                        }));
                                        navigate('/checkout');
                                    }
                                })();
                            }}
                            disabled={!product.is_available}
                            className="flex-1 py-4 bg-red-600 text-white text-base font-black rounded-2xl hover:bg-red-700 shadow-xl shadow-red-600/20 hover:shadow-red-600/30 transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-3 active:scale-[0.98]"
                        >
                            <Zap size={22} />
                            Buy Now
                        </button>
                        <motion.button
                            onClick={toggleWishlist}
                            whileTap={{ scale: 0.8 }}
                            animate={{ scale: isWishlisted ? [1, 1.2, 1] : 1 }}
                            transition={{ duration: 0.3 }}
                            className={`p-4 border-2 rounded-2xl transition-all ${isWishlisted
                                ? "bg-red-50 border-red-100 text-red-600"
                                : "bg-white border-stone-100 text-stone-400 hover:text-red-500 hover:border-red-100 hover:bg-red-50"
                                }`}
                        >
                            <Heart size={24} fill={isWishlisted ? "currentColor" : "none"} />
                        </motion.button>
                    </div>

                    {/* Meta Info */}
                    <div className="grid grid-cols-2 gap-4 text-sm">
                        <div className="flex items-center gap-3 p-4 bg-white rounded-2xl border border-stone-100">
                            <div className="p-2 bg-yellow-50 rounded-xl text-yellow-600">
                                <Truck size={20} />
                            </div>
                            <div>
                                <p className="font-bold text-stone-900">Fast Delivery</p>
                                <p className="text-stone-500 text-xs">Within 2 hours</p>
                            </div>
                        </div>
                        <div className="flex items-center gap-3 p-4 bg-white rounded-2xl border border-stone-100">
                            <div className="p-2 bg-yellow-50 rounded-xl text-yellow-600">
                                <ShieldCheck size={20} />
                            </div>
                            <div>
                                <p className="font-bold text-stone-900">Fresh Guaranteed</p>
                                <p className="text-stone-500 text-xs">Certified Quality</p>
                            </div>
                        </div>
                    </div>
                </div>
            </main >
        </div >
    );
};

export default ProductProfile;
