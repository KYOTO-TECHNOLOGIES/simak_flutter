import React, { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { useDispatch, useSelector } from "react-redux";
import { useNavigate, useParams } from "react-router-dom";
import { ArrowLeft, Loader2, UploadCloud } from "lucide-react";
import {
    productsActions,
    selectProductsStatus,
    selectProductsError,
} from "./productsSlice";
import type { ProductDto } from "./productApi";
import { productsApi } from "./productApi";

/* ─────────────────────────────────────────────
    Wrapper Component: Handles Data Fetching
   ───────────────────────────────────────────── */
const EditProduct: React.FC = () => {
    const { id } = useParams();
    const productId = Number(id);
    const navigate = useNavigate();

    const [dto, setDto] = useState<ProductDto | null>(null);
    const [fetchError, setFetchError] = useState<string | null>(null);

    useEffect(() => {
        if (isNaN(productId)) return;
        let cancelled = false;

        const fetchProduct = async () => {
            try {
                const data = await productsApi.details(productId);
                if (!cancelled) setDto(data);
            } catch (e: any) {
                if (!cancelled) setFetchError(e?.message || "Failed to load product");
            }
        };

        fetchProduct();
        return () => { cancelled = true; };
    }, [productId]);

    if (fetchError) {
        return (
            <div className="min-h-screen flex flex-col items-center justify-center gap-4 bg-[#FDFDFD]">
                <p className="text-red-500 font-bold">{fetchError}</p>
                <button
                    onClick={() => navigate("/admin/products")}
                    className="px-6 py-2 bg-black text-white rounded-xl text-sm font-bold"
                >
                    Back to Products
                </button>
            </div>
        );
    }

    if (!dto) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-[#FDFDFD]">
                <Loader2 className="animate-spin text-zinc-300" size={40} />
            </div>
        );
    }

    return <EditProductForm dto={dto} productId={productId} />;
};

/* ─────────────────────────────────────────────
    Form Component: Handles Logic & Submission
   ───────────────────────────────────────────── */
interface EditProductFormProps {
    dto: ProductDto;
    productId: number;
}

const EditProductForm: React.FC<EditProductFormProps> = ({ dto, productId }) => {
    const dispatch = useDispatch();
    const navigate = useNavigate();

    const status = useSelector(selectProductsStatus);
    const error = useSelector(selectProductsError);

    const { register, handleSubmit, watch, reset, formState: { errors } } = useForm<Partial<ProductDto>>({
        defaultValues: dto // Initial values
    });

    // ✅ FIX: Force the form to update when data arrives or changes
    useEffect(() => {
        if (dto) {
            reset({
                name: dto.name || "",
                description: dto.description || "",
                price: dto.price,
                discount_price: dto.discount_price || "",
                stock: dto.stock,
                category: dto.category,
                sku: dto.sku || "",
                is_available: dto.is_available,
                expected_delivery_time: dto.expected_delivery_time || "",
            });
        }
    }, [dto, reset]);

    useEffect(() => {
        dispatch(productsActions.resetStatus());
        return () => { dispatch(productsActions.resetStatus()); };
    }, [dispatch]);

    useEffect(() => {
        if (status === "succeeded") {
            navigate("/admin/products");
        }
    }, [status, navigate]);

    const onSubmit = (data: Partial<ProductDto>) => {
        const formData = new FormData();

        // Use explicit appends to ensure clean data transmission
        formData.append("name", data.name || "");
        formData.append("description", data.description || "");
        formData.append("category", String(data.category));
        formData.append("price", String(data.price));
        formData.append("stock", String(data.stock));
        formData.append("is_available", String(Boolean(data.is_available)));

        if (data.discount_price !== undefined && data.discount_price !== null && data.discount_price !== "") {
            formData.append("discount_price", String(data.discount_price));
        }

        if (data.sku) formData.append("sku", String(data.sku));
        if (data.expected_delivery_time) {
            formData.append("expected_delivery_time", String(data.expected_delivery_time));
        }

        if (data.image && (data.image as any).length > 0) {
            formData.append("image", (data.image as any)[0]);
        }

        dispatch(productsActions.updateProductRequest({ id: productId, data: formData }));
    };

    return (
        <div className="min-h-screen bg-[#FDFDFD] p-6 md:p-12 space-y-8 animate-in slide-in-from-right duration-500">
            <div className="flex items-center justify-between max-w-4xl mx-auto">
                <div className="flex items-center gap-4">
                    <button onClick={() => navigate("/admin/products")} className="p-2 hover:bg-[#F4F4F5] rounded-full">
                        <ArrowLeft size={20} />
                    </button>
                    <div>
                        <h1 className="text-2xl font-bold tracking-tight">Edit Product</h1>
                        <p className="text-sm text-[#71717A]">Update your product inventory details.</p>
                    </div>
                </div>
            </div>

            {error && (
                <div className="max-w-4xl mx-auto bg-red-50 text-red-600 p-4 rounded-xl text-sm font-medium border border-red-100">
                    {error}
                </div>
            )}

            <form onSubmit={handleSubmit(onSubmit)} className="max-w-4xl mx-auto space-y-8">
                {/* Basic Info */}
                <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-6">
                    <h2 className="text-lg font-bold">Basic Information</h2>
                    <div className="grid gap-6">
                        <div className="space-y-2">
                            <label className="text-xs font-bold uppercase text-[#A1A1AA]">Product Name</label>
                            <input
                                {...register("name", { required: "Name is required" })}
                                className="w-full px-4 py-3 bg-[#FAFAFA] border-none rounded-xl text-sm font-medium focus:ring-2 focus:ring-black outline-none transition-all"
                                placeholder="Product name"
                            />
                            {errors.name && <p className="text-red-500 text-[10px] font-bold">{errors.name.message}</p>}
                        </div>
                        <div className="space-y-2">
                            <label className="text-xs font-bold uppercase text-[#A1A1AA]">Description</label>
                            <textarea
                                {...register("description", { required: "Description is required" })}
                                className="w-full px-4 py-3 bg-[#FAFAFA] border-none rounded-xl text-sm font-medium focus:ring-2 focus:ring-black outline-none transition-all h-32 resize-none"
                                placeholder="Describe the product..."
                            />
                            {errors.description && <p className="text-red-500 text-[10px] font-bold">{errors.description.message}</p>}
                        </div>
                    </div>
                </section>

                {/* Pricing & Inventory */}
                <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-6">
                    <h2 className="text-lg font-bold">Pricing & Inventory</h2>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                        <div className="space-y-2">
                            <label className="text-xs font-bold uppercase text-[#A1A1AA]">Price (AED)</label>
                            <input
                                type="number" step="0.01"
                                {...register("price", { required: "Price is required" })}
                                className="w-full px-4 py-3 bg-[#FAFAFA] border-none rounded-xl text-sm font-medium focus:ring-2 focus:ring-black outline-none"
                            />
                        </div>
                        <div className="space-y-2">
                            <label className="text-xs font-bold uppercase text-[#A1A1AA]">Discount Price</label>
                            <input
                                type="number" step="0.01"
                                {...register("discount_price")}
                                className="w-full px-4 py-3 bg-[#FAFAFA] border-none rounded-xl text-sm font-medium focus:ring-2 focus:ring-black outline-none"
                            />
                        </div>
                        <div className="space-y-2">
                            <label className="text-xs font-bold uppercase text-[#A1A1AA]">Stock</label>
                            <input
                                type="number"
                                {...register("stock", { required: "Stock is required", min: 0 })}
                                className="w-full px-4 py-3 bg-[#FAFAFA] border-none rounded-xl text-sm font-medium focus:ring-2 focus:ring-black outline-none"
                            />
                        </div>
                    </div>
                </section>

                {/* Organization */}
                <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-6">
                    <h2 className="text-lg font-bold">Organization</h2>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div className="space-y-2">
                            <label className="text-xs font-bold uppercase text-[#A1A1AA]">Category ID</label>
                            <input
                                type="number"
                                {...register("category", { required: "Category ID is required" })}
                                className="w-full px-4 py-3 bg-[#FAFAFA] border-none rounded-xl text-sm font-medium focus:ring-2 focus:ring-black outline-none transition-all"
                            />
                            {errors.category && <p className="text-red-500 text-[10px] font-bold">{errors.category.message}</p>}
                        </div>
                        <div className="space-y-2">
                            <label className="text-xs font-bold uppercase text-[#A1A1AA]">Unit / SKU</label>
                            <input
                                {...register("sku")}
                                className="w-full px-4 py-3 bg-[#FAFAFA] border-none rounded-xl text-sm font-medium focus:ring-2 focus:ring-black outline-none transition-all"
                            />
                        </div>
                    </div>
                    <div className="flex items-center gap-3 pt-2">
                        <input
                            type="checkbox"
                            {...register("is_available")}
                            className="w-5 h-5 accent-black rounded cursor-pointer"
                        />
                        <label className="text-sm font-medium cursor-pointer">Available for purchase</label>
                    </div>
                    <div className="space-y-2">
                        <label className="text-xs font-bold uppercase text-[#A1A1AA]">Expected Delivery Time</label>
                        <input
                            {...register("expected_delivery_time")}
                            placeholder="e.g. 2-3 business days"
                            className="w-full px-4 py-3 bg-[#FAFAFA] border-none rounded-xl text-sm font-medium focus:ring-2 focus:ring-black outline-none transition-all"
                        />
                    </div>
                </section>

                {/* Media */}
                <ImageUploadSection register={register} watch={watch} existingImageUrl={dto.image} />

                {/* Sticky Footer Actions */}
                <div className="flex items-center justify-end gap-4 pt-4">
                    <button
                        type="button"
                        onClick={() => navigate("/admin/products")}
                        className="px-6 py-3 rounded-xl font-bold text-sm text-zinc-500 hover:bg-[#F4F4F5]"
                    >
                        Discard Changes
                    </button>
                    <button
                        type="submit"
                        disabled={status === "loading"}
                        className="px-8 py-3 bg-black text-white rounded-xl font-bold text-sm hover:shadow-lg disabled:opacity-50 flex items-center gap-2"
                    >
                        {status === "loading" && <Loader2 size={16} className="animate-spin" />}
                        {status === "loading" ? "Updating..." : "Save Product"}
                    </button>
                </div>
            </form>
        </div>
    );
};

/* ─────────────────────────────────────────────
    Media Sub-component
   ───────────────────────────────────────────── */
const ImageUploadSection = ({ register, watch, existingImageUrl }: any) => {
    const files = watch("image");
    const [preview, setPreview] = useState<string | null>(null);

    useEffect(() => {
        // Only create a preview if the user has selected a NEW file (FileList)
        if (files && files.length > 0 && files[0] instanceof Blob) {
            const objectUrl = URL.createObjectURL(files[0]);
            setPreview(objectUrl);
            return () => URL.revokeObjectURL(objectUrl);
        }
    }, [files]);

    const activePreview = preview || existingImageUrl;

    return (
        <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-6">
            <h2 className="text-lg font-bold">Product Media</h2>
            <div className={`border-2 border-dashed border-[#E4E4E7] rounded-xl flex flex-col items-center justify-center text-center bg-[#FAFAFA] relative cursor-pointer overflow-hidden ${activePreview ? "p-0" : "p-10"}`}>
                <input type="file" accept="image/*" {...register("image")} className="absolute inset-0 opacity-0 z-10 cursor-pointer" />
                {activePreview ? (
                    <div className="relative w-full h-72">
                        <img src={activePreview} alt="Preview" className="w-full h-full object-contain" />
                        <div className="absolute inset-0 bg-black/20 flex items-center justify-center opacity-0 hover:opacity-100 transition-opacity z-20">
                            <span className="bg-white text-black px-4 py-2 rounded-lg text-xs font-bold">Replace Image</span>
                        </div>
                    </div>
                ) : (
                    <div className="space-y-4">
                        <div className="w-12 h-12 bg-white rounded-full mx-auto flex items-center justify-center"><UploadCloud size={24} className="text-zinc-400" /></div>
                        <p className="text-sm font-bold">Click to upload product image</p>
                    </div>
                )}
            </div>
        </section>
    );
};

export default EditProduct;