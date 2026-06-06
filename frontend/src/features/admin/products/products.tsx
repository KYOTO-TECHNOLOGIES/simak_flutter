import React, { useEffect, useMemo, useState, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import {
    Search,
    Filter,
    RotateCcw,
    ChevronRight,
    ChevronLeft,
    Download,
    ListFilter,
    Package,
    Star,
    AlertTriangle,
    Eye,
    X,
    Tag,
    Box,
    IndianRupee,
    TrendingUp,
    Plus,
    Columns3,
    Clock,
    Edit3,
    Trash2,
} from "lucide-react";

import {
    productsActions,
    selectProducts,
    selectProductsStatus,
    selectProductsError,
    selectProductsTotal,
    selectSelectedProductId,
} from "./productsSlice";
import type { Product } from "./productsSlice";

/* --- LOCAL UI TYPES --- */
type StatusFilter = "All" | "Active" | "Draft" | "Out of Stock";

/* --- Column definitions --- */
type ColumnKey =
    | "index"
    | "product"
    | "status"
    | "category"
    | "price"
    | "stock"
    | "sku"
    | "rating"
    | "deliveryTime"
    | "discountPrice"
    | "actions";

interface ColumnDef {
    key: ColumnKey;
    label: string;
    icon?: React.ReactNode;
    defaultVisible: boolean;
    alwaysVisible?: boolean;
}

const COLUMNS: ColumnDef[] = [
    { key: "index", label: "#", defaultVisible: true, alwaysVisible: true },
    { key: "product", label: "Product", defaultVisible: true },
    { key: "status", label: "Status", defaultVisible: true },
    { key: "category", label: "Category", defaultVisible: true },
    { key: "price", label: "Price", defaultVisible: true },
    { key: "stock", label: "Stock", defaultVisible: true },
    { key: "sku", label: "SKU", defaultVisible: true },
    { key: "rating", label: "Rating", icon: <Star size={12} />, defaultVisible: false },
    { key: "deliveryTime", label: "Delivery Time", icon: <Clock size={12} />, defaultVisible: false },
    { key: "discountPrice", label: "Discount Price", icon: <Tag size={12} />, defaultVisible: false },
    { key: "actions", label: "Actions", defaultVisible: true, alwaysVisible: true },
];

// Simple debounce hook
function useDebounce<T>(value: T, delay: number): T {
    const [debouncedValue, setDebouncedValue] = useState(value);
    useEffect(() => {
        const handler = setTimeout(() => setDebouncedValue(value), delay);
        return () => clearTimeout(handler);
    }, [value, delay]);
    return debouncedValue;
}

/* --- MAIN COMPONENT --- */
const ProductManagement: React.FC = () => {
    const dispatch = useDispatch();
    const navigate = useNavigate();

    // Redux data
    const products = useSelector(selectProducts);
    const totalCount = useSelector(selectProductsTotal);
    const status = useSelector(selectProductsStatus);
    const error = useSelector(selectProductsError);
    const selectedProductId = useSelector(selectSelectedProductId);

    // Filter states
    const [isFilterOpen, setIsFilterOpen] = useState(false);
    const [searchTerm, setSearchTerm] = useState("");
    const [statusFilter, setStatusFilter] = useState<StatusFilter>("All");
    const [categoryFilter, setCategoryFilter] = useState("");
    const [minPrice, setMinPrice] = useState("");
    const [maxPrice, setMaxPrice] = useState("");
    const [minStock, setMinStock] = useState("");
    const [maxStock, setMaxStock] = useState("");
    const [skuFilter, setSkuFilter] = useState("");
    const [ratingFilter, setRatingFilter] = useState("");
    const [deliveryTimeFilter, setDeliveryTimeFilter] = useState("");
    const [page, setPage] = useState(1);
    const [limit, setLimit] = useState(5);
    const debouncedSearch = useDebounce(searchTerm, 500);

    // Column visibility
    const [visibleColumns, setVisibleColumns] = useState<Record<ColumnKey, boolean>>(() => {
        const init: Record<string, boolean> = {};
        COLUMNS.forEach((c) => (init[c.key] = c.defaultVisible));
        return init as Record<ColumnKey, boolean>;
    });
    const [isColumnsOpen, setIsColumnsOpen] = useState(false);
    const columnsRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        const handler = (e: MouseEvent) => {
            if (columnsRef.current && !columnsRef.current.contains(e.target as Node)) {
                setIsColumnsOpen(false);
            }
        };
        document.addEventListener("mousedown", handler);
        return () => document.removeEventListener("mousedown", handler);
    }, []);

    const toggleColumn = (key: ColumnKey) => {
        const col = COLUMNS.find((c) => c.key === key);
        if (col?.alwaysVisible) return;
        setVisibleColumns((prev) => ({ ...prev, [key]: !prev[key] }));
    };

    const isVisible = (key: ColumnKey) => visibleColumns[key];

    // Fetch when params change
    useEffect(() => {
        const offset = (page - 1) * limit;
        dispatch(
            productsActions.fetchProductsRequest({
                q: debouncedSearch || undefined,
                status: statusFilter === "All" ? undefined : statusFilter,
                category: categoryFilter || undefined,
                page,
                limit,
                offset,
            })
        );
    }, [dispatch, debouncedSearch, statusFilter, categoryFilter, page, limit]);

    const handleReset = () => {
        setSearchTerm("");
        setStatusFilter("All");
        setCategoryFilter("");
        setMinPrice("");
        setMaxPrice("");
        setMinStock("");
        setMaxStock("");
        setSkuFilter("");
        setRatingFilter("");
        setDeliveryTimeFilter("");
        setPage(1);
    };

    // Client-side filtering for columns not supported by API
    const filteredProducts = useMemo(() => {
        let result = products;
        if (minPrice) {
            const min = parseFloat(minPrice);
            if (!isNaN(min)) result = result.filter((p) => p.finalPrice >= min);
        }
        if (maxPrice) {
            const max = parseFloat(maxPrice);
            if (!isNaN(max)) result = result.filter((p) => p.finalPrice <= max);
        }
        if (minStock) {
            const min = parseInt(minStock);
            if (!isNaN(min)) result = result.filter((p) => p.stock >= min);
        }
        if (maxStock) {
            const max = parseInt(maxStock);
            if (!isNaN(max)) result = result.filter((p) => p.stock <= max);
        }
        if (skuFilter) {
            result = result.filter((p) =>
                p.sku.toLowerCase().includes(skuFilter.toLowerCase())
            );
        }
        if (ratingFilter) {
            const minRating = parseFloat(ratingFilter);
            if (!isNaN(minRating)) result = result.filter((p) => p.averageRating >= minRating);
        }
        if (deliveryTimeFilter) {
            result = result.filter((p) =>
                p.expectedDeliveryTime?.toLowerCase().includes(deliveryTimeFilter.toLowerCase())
            );
        }
        return result;
    }, [products, minPrice, maxPrice, minStock, maxStock, skuFilter, ratingFilter, deliveryTimeFilter]);

    // Unique categories From data for dropdown
    const uniqueCategories = useMemo(() =>
        [...new Set(products.map((p) => p.categoryName).filter(Boolean))],
        [products]
    );

    const selectedProduct = useMemo(
        () => filteredProducts.find((p) => p.id === selectedProductId) ?? null,
        [filteredProducts, selectedProductId]
    );

    const handleDelete = (id: number) => {
        if (window.confirm("Are you sure you want to delete this product? This action cannot be undone.")) {
            dispatch(productsActions.deleteProductRequest(id));
        }
    };

    // Export handler
    const handleExport = () => {
        const headers = ["ID", "Name", "Category", "Price", "Stock", "Status", "SKU", "Rating"];
        const rows = filteredProducts.map(p => [
            p.id,
            p.name,
            p.categoryName,
            p.finalPrice,
            p.stock,
            p.status,
            p.sku,
            p.averageRating
        ]);
        const csvContent = [
            headers.join(","),
            ...rows.map(r => r.map(c => {
                const val = String(c || "");
                return val.includes(',') ? `"${val}"` : val;
            }).join(","))
        ].join("\n");

        const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
        const link = document.createElement("a");
        const url = URL.createObjectURL(blob);
        link.setAttribute("href", url);
        link.setAttribute("download", `products_export_${new Date().toISOString().split('T')[0]}.csv`);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    };

    // Compute stats from current page data
    const activeCount = filteredProducts.filter((p) => p.status === "Active").length;
    const outOfStockCount = filteredProducts.filter((p) => p.status === "Out of Stock").length;
    const lowStockCount = filteredProducts.filter((p) => p.stock > 0 && p.stock <= 20).length;

    return (
        <div className="min-h-screen w-full space-y-6 text-[#18181B] bg-[#FDFDFD]">
            {/* --- PAGE HEADER --- */}
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-end gap-4">
                <div>
                    <h1 className="text-2xl md:text-3xl font-bold tracking-tight text-black">Products</h1>
                    <p className="text-[#71717A] text-sm mt-1">Manage your inventory and catalog.</p>
                </div>
                <button
                    onClick={() => navigate("add")}
                    className="flex items-center gap-2 px-4 py-2.5 bg-black text-white rounded-xl text-xs font-bold hover:bg-[#222] transition-all shadow-sm"
                >
                    <Plus size={14} /> Add Product
                </button>
            </div>

            {/* --- STATS OVERVIEW --- */}
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                <QuickStat
                    label="Total Products"
                    value={`${totalCount}`}
                    sub="All products"
                    icon={<Package size={16} className="text-[#A1A1AA]" />}
                />
                <QuickStat
                    label="Active"
                    value={`${activeCount}`}
                    sub="Published & selling"
                    icon={<TrendingUp size={16} className="text-emerald-500" />}
                />
                <QuickStat
                    label="Out of Stock"
                    value={`${outOfStockCount}`}
                    sub="Needs restocking"
                    icon={<AlertTriangle size={16} className="text-rose-500" />}
                />
                <QuickStat
                    label="Low Stock"
                    value={`${lowStockCount}`}
                    sub="≤ 20 units"
                    icon={<AlertTriangle size={16} className="text-amber-500" />}
                />
            </div>

            {/* --- TABLE CONTAINER --- */}
            <div className="bg-white rounded-2xl border border-[#EEEEEE] shadow-sm overflow-hidden">
                {/* TABLE TOOLBAR */}
                <div className="p-4 border-b border-[#EEEEEE] flex flex-col md:flex-row justify-between items-center gap-4 bg-white">

                    <div className="flex items-center gap-2 w-full md:w-auto justify-end">
                        <button
                            onClick={handleReset}
                            className="p-2 text-[#A1A1AA] hover:text-rose-500 hover:bg-rose-50 rounded-lg transition-all"
                            title="Clear Filters"
                        >
                            <RotateCcw size={16} />
                        </button>

                        <div className="h-6 w-px bg-[#EEEEEE] mx-1" />

                        <button
                            onClick={() => setIsFilterOpen(!isFilterOpen)}
                            className={`flex items-center gap-2 px-3 py-1.5 border rounded-lg text-[11px] font-bold transition-all ${isFilterOpen
                                ? "bg-black text-white border-black"
                                : "bg-white text-black border-[#EEEEEE] hover:bg-gray-50"
                                }`}
                        >
                            <Filter size={14} /> {isFilterOpen ? "Hide Filters" : "Show Filters"}
                        </button>

                        {/* Column Visibility Dropdown */}
                        <div className="relative" ref={columnsRef}>
                            <button
                                onClick={() => setIsColumnsOpen(!isColumnsOpen)}
                                className={`flex items-center gap-2 px-3 py-1.5 border rounded-lg text-[11px] font-bold transition-all ${isColumnsOpen
                                    ? "bg-black text-white border-black"
                                    : "bg-white text-black border-[#EEEEEE] hover:bg-gray-50"
                                    }`}
                            >
                                <Columns3 size={14} /> Columns
                            </button>
                            {isColumnsOpen && (
                                <div className="absolute right-0 top-full mt-2 w-56 bg-white rounded-xl border border-[#EEEEEE] shadow-xl z-50 py-2 animate-in fade-in slide-in-from-top-1 duration-150">
                                    <p className="px-4 py-2 text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest border-b border-[#EEEEEE]">
                                        Toggle Columns
                                    </p>
                                    {COLUMNS.filter((c) => !c.alwaysVisible).map((col) => (
                                        <label
                                            key={col.key}
                                            className="flex items-center gap-3 px-4 py-2 hover:bg-[#FAFAFA] cursor-pointer transition-colors"
                                        >
                                            <input
                                                type="checkbox"
                                                checked={visibleColumns[col.key]}
                                                onChange={() => toggleColumn(col.key)}
                                                className="w-3.5 h-3.5 rounded border-[#D4D4D8] text-black focus:ring-black/20 accent-black"
                                            />
                                            <span className="flex items-center gap-2 text-xs font-medium text-[#52525B]">
                                                {col.icon}
                                                {col.label}
                                            </span>
                                        </label>
                                    ))}
                                </div>
                            )}
                        </div>

                        <button
                            onClick={handleExport}
                            className="flex items-center gap-2 px-3 py-2 bg-white border border-[#EEEEEE] rounded-lg text-xs font-bold hover:bg-[#FAFAFA] transition-colors"
                        >
                            <Download size={14} /> Export
                        </button>
                    </div>
                </div>

                {/* Status/Error */}
                {status === "loading" && products.length === 0 && (
                    <div className="p-6 text-sm text-[#71717A]">Loading products…</div>
                )}
                {status === "failed" && (
                    <div className="p-6 text-sm text-rose-600">
                        {error || "Failed to load products"}
                    </div>
                )}

                <div className="overflow-x-auto">
                    <table className="w-full text-left border-collapse min-w-[1100px]">
                        <thead className="bg-[#FAFAFA]">
                            <tr className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest border-b border-[#EEEEEE]">
                                {isVisible("index") && <th className="px-6 py-4 w-12 text-center">#</th>}
                                {isVisible("product") && <th className="px-6 py-4">Product</th>}
                                {isVisible("status") && <th className="px-6 py-4">Status</th>}
                                {isVisible("category") && <th className="px-6 py-4">Category</th>}
                                {isVisible("price") && <th className="px-6 py-4">Price</th>}
                                {isVisible("stock") && <th className="px-6 py-4">Stock</th>}
                                {isVisible("sku") && <th className="px-6 py-4">SKU</th>}
                                {isVisible("rating") && <th className="px-6 py-4">Rating</th>}
                                {isVisible("deliveryTime") && <th className="px-6 py-4">Delivery</th>}
                                {isVisible("discountPrice") && <th className="px-6 py-4">Discount</th>}
                                {isVisible("actions") && <th className="px-6 py-4 text-right">Actions</th>}
                            </tr>

                            {isFilterOpen && (
                                <tr className="bg-white border-b border-[#EEEEEE] animate-in fade-in slide-in-from-top-1 duration-200">
                                    {isVisible("index") && (
                                        <td className="px-6 py-3 text-center">
                                            <ListFilter size={14} className="text-[#D4D4D8] mx-auto" />
                                        </td>
                                    )}
                                    {isVisible("product") && (
                                        <td className="px-6 py-3">
                                            <div className="relative">
                                                <Search className="absolute left-2 top-1/2 -translate-y-1/2 text-[#A1A1AA]" size={12} />
                                                <input
                                                    type="text"
                                                    placeholder="Filter name..."
                                                    value={searchTerm}
                                                    onChange={(e) => setSearchTerm(e.target.value)}
                                                    className="w-full pl-7 pr-2 py-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none focus:bg-white focus:border-[#EEEEEE]"
                                                />
                                            </div>
                                        </td>
                                    )}
                                    {isVisible("status") && (
                                        <td className="px-6 py-3">
                                            <select
                                                value={statusFilter}
                                                onChange={(e) => setStatusFilter(e.target.value as StatusFilter)}
                                                className="w-full p-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none cursor-pointer focus:bg-white focus:border-[#EEEEEE]"
                                            >
                                                <option value="All">All Status</option>
                                                <option value="Active">Active</option>
                                                <option value="Draft">Draft</option>
                                                <option value="Out of Stock">Out of Stock</option>
                                            </select>
                                        </td>
                                    )}
                                    {isVisible("category") && (
                                        <td className="px-6 py-3">
                                            <select
                                                value={categoryFilter}
                                                onChange={(e) => setCategoryFilter(e.target.value)}
                                                className="w-full p-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none cursor-pointer focus:bg-white focus:border-[#EEEEEE]"
                                            >
                                                <option value="">All Categories</option>
                                                {uniqueCategories.map((cat) => (
                                                    <option key={cat} value={cat}>{cat}</option>
                                                ))}
                                            </select>
                                        </td>
                                    )}
                                    {isVisible("price") && (
                                        <td className="px-6 py-3">
                                            <div className="flex gap-1">
                                                <input
                                                    type="number"
                                                    placeholder="Min"
                                                    value={minPrice}
                                                    onChange={(e) => setMinPrice(e.target.value)}
                                                    className="w-1/2 p-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none focus:bg-white focus:border-[#EEEEEE]"
                                                />
                                                <input
                                                    type="number"
                                                    placeholder="Max"
                                                    value={maxPrice}
                                                    onChange={(e) => setMaxPrice(e.target.value)}
                                                    className="w-1/2 p-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none focus:bg-white focus:border-[#EEEEEE]"
                                                />
                                            </div>
                                        </td>
                                    )}
                                    {isVisible("stock") && (
                                        <td className="px-6 py-3">
                                            <div className="flex gap-1">
                                                <input
                                                    type="number"
                                                    placeholder="Min"
                                                    value={minStock}
                                                    onChange={(e) => setMinStock(e.target.value)}
                                                    className="w-1/2 p-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none focus:bg-white focus:border-[#EEEEEE]"
                                                />
                                                <input
                                                    type="number"
                                                    placeholder="Max"
                                                    value={maxStock}
                                                    onChange={(e) => setMaxStock(e.target.value)}
                                                    className="w-1/2 p-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none focus:bg-white focus:border-[#EEEEEE]"
                                                />
                                            </div>
                                        </td>
                                    )}
                                    {isVisible("sku") && (
                                        <td className="px-6 py-3">
                                            <input
                                                type="text"
                                                placeholder="SKU..."
                                                value={skuFilter}
                                                onChange={(e) => setSkuFilter(e.target.value)}
                                                className="w-full p-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none focus:bg-white focus:border-[#EEEEEE]"
                                            />
                                        </td>
                                    )}
                                    {isVisible("rating") && (
                                        <td className="px-6 py-3">
                                            <select
                                                value={ratingFilter}
                                                onChange={(e) => setRatingFilter(e.target.value)}
                                                className="w-full p-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none cursor-pointer focus:bg-white focus:border-[#EEEEEE]"
                                            >
                                                <option value="">All</option>
                                                <option value="4">★ 4+</option>
                                                <option value="3">★ 3+</option>
                                                <option value="2">★ 2+</option>
                                                <option value="1">★ 1+</option>
                                            </select>
                                        </td>
                                    )}
                                    {isVisible("deliveryTime") && (
                                        <td className="px-6 py-3">
                                            <input
                                                type="text"
                                                placeholder="Delivery..."
                                                value={deliveryTimeFilter}
                                                onChange={(e) => setDeliveryTimeFilter(e.target.value)}
                                                className="w-full p-2 bg-[#F9F9F9] border border-transparent rounded-md text-[11px] outline-none focus:bg-white focus:border-[#EEEEEE]"
                                            />
                                        </td>
                                    )}
                                    {isVisible("discountPrice") && <td className="px-6 py-3"><div className="text-[10px] text-[#A1A1AA] italic">—</div></td>}
                                    {isVisible("actions") && (
                                        <td className="px-6 py-3 text-right">
                                            <button onClick={handleReset} className="text-[10px] font-bold text-rose-500 hover:underline px-2">
                                                Clear
                                            </button>
                                        </td>
                                    )}
                                </tr>
                            )}
                        </thead>

                        <tbody className="divide-y divide-[#EEEEEE]">
                            {status === "loading" && products.length === 0 ? (
                                Array.from({ length: 5 }).map((_, i) => (
                                    <tr key={i} className="animate-pulse">
                                        <td className="px-6 py-4"><div className="h-4 w-4 bg-gray-100 rounded" /></td>
                                        <td className="px-6 py-4"><div className="h-10 w-40 bg-gray-100 rounded-xl" /></td>
                                        <td className="px-6 py-4"><div className="h-6 w-16 bg-gray-100 rounded-full" /></td>
                                        <td className="px-6 py-4"><div className="h-4 w-20 bg-gray-100 rounded" /></td>
                                        <td className="px-6 py-4"><div className="h-4 w-16 bg-gray-100 rounded" /></td>
                                        <td className="px-6 py-4"><div className="h-4 w-12 bg-gray-100 rounded" /></td>
                                        <td className="px-6 py-4"><div className="h-4 w-20 bg-gray-100 rounded" /></td>
                                        <td className="px-6 py-4"><div className="h-8 w-20 bg-gray-100 rounded-lg ml-auto" /></td>
                                    </tr>
                                ))
                            ) : (
                                filteredProducts.map((p, index) => (
                                    <tr key={p.id} className="group hover:bg-[#FBFBFA] transition-colors">
                                        {isVisible("index") && (
                                            <td className="px-6 py-4 text-xs font-mono text-[#A1A1AA] text-center">
                                                {(page - 1) * limit + index + 1}
                                            </td>
                                        )}

                                        {isVisible("product") && (
                                            <td className="px-6 py-4">
                                                <div className="flex items-center gap-3">
                                                    <div className="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center text-xs font-bold border border-[#EEEEEE] overflow-hidden flex-shrink-0">
                                                        {p.imageUrl ? (
                                                            <img src={p.imageUrl} alt={p.name} className="w-full h-full object-cover" />
                                                        ) : (
                                                            <Package size={16} className="text-[#A1A1AA]" />
                                                        )}
                                                    </div>
                                                    <div className="min-w-0">
                                                        <p className="text-sm font-bold truncate">{p.name}</p>
                                                        <p className="text-[11px] text-[#A1A1AA] truncate">{p.slug}</p>
                                                    </div>
                                                </div>
                                            </td>
                                        )}

                                        {isVisible("status") && (
                                            <td className="px-6 py-4">
                                                <span
                                                    className={`text-[10px] font-bold px-2.5 py-1 rounded-full uppercase border ${p.status === "Active"
                                                        ? "bg-emerald-50 text-emerald-600 border-emerald-100"
                                                        : p.status === "Out of Stock"
                                                            ? "bg-rose-50 text-rose-600 border-rose-100"
                                                            : "bg-slate-50 text-slate-500 border-slate-200"
                                                        }`}
                                                >
                                                    {p.status}
                                                </span>
                                            </td>
                                        )}

                                        {isVisible("category") && (
                                            <td className="px-6 py-4">
                                                <div className="flex items-center gap-1.5">
                                                    <Tag size={10} className="text-[#A1A1AA]" />
                                                    <span className="text-xs font-medium">{p.categoryName}</span>
                                                </div>
                                            </td>
                                        )}

                                        {isVisible("price") && (
                                            <td className="px-6 py-4">
                                                <p className="text-sm font-bold">AED {p.finalPrice.toLocaleString()}</p>
                                                {p.discountPrice !== null && p.discountPrice < p.price && (
                                                    <p className="text-[10px] text-[#A1A1AA] line-through">
                                                        AED {p.price.toLocaleString()}
                                                    </p>
                                                )}
                                            </td>
                                        )}

                                        {isVisible("stock") && (
                                            <td className="px-6 py-4">
                                                <div className="flex items-center gap-2">
                                                    <span
                                                        className={`text-sm font-mono font-bold ${p.stock <= 0
                                                            ? "text-rose-600"
                                                            : p.stock <= 20
                                                                ? "text-amber-600"
                                                                : "text-[#18181B]"
                                                            }`}
                                                    >
                                                        {p.stock}
                                                    </span>
                                                    <div className="flex-1 h-1.5 bg-[#F4F4F5] rounded-full overflow-hidden max-w-[60px]">
                                                        <div
                                                            className={`h-full rounded-full ${p.stock <= 0
                                                                ? "bg-rose-500"
                                                                : p.stock <= 20
                                                                    ? "bg-amber-400"
                                                                    : "bg-emerald-500"
                                                                }`}
                                                            style={{
                                                                width: `${Math.min((p.stock / 60) * 100, 100)}%`,
                                                            }}
                                                        />
                                                    </div>
                                                </div>
                                            </td>
                                        )}

                                        {isVisible("sku") && (
                                            <td className="px-6 py-4">
                                                <span className="text-xs font-mono text-[#71717A]">{p.sku}</span>
                                            </td>
                                        )}

                                        {isVisible("rating") && (
                                            <td className="px-6 py-4">
                                                <div className="flex items-center gap-1">
                                                    <Star size={12} className={`${p.averageRating > 0 ? "fill-amber-400 text-amber-400" : "text-[#D4D4D8]"}`} />
                                                    <span className="text-xs font-bold">{p.averageRating > 0 ? p.averageRating.toFixed(1) : "—"}</span>
                                                    {p.totalReviews > 0 && (
                                                        <span className="text-[9px] text-[#A1A1AA]">({p.totalReviews})</span>
                                                    )}
                                                </div>
                                            </td>
                                        )}

                                        {isVisible("deliveryTime") && (
                                            <td className="px-6 py-4">
                                                <span className="text-xs text-[#52525B] font-medium">
                                                    {p.expectedDeliveryTime || "—"}
                                                </span>
                                            </td>
                                        )}

                                        {isVisible("discountPrice") && (
                                            <td className="px-6 py-4">
                                                {p.discountPrice !== null ? (
                                                    <span className="text-xs font-bold text-emerald-600">
                                                        AED {p.discountPrice.toLocaleString()}
                                                    </span>
                                                ) : (
                                                    <span className="text-[10px] text-[#A1A1AA]">—</span>
                                                )}
                                            </td>
                                        )}

                                        {isVisible("actions") && (
                                            <td className="px-6 py-4 text-right">
                                                <div className="flex items-center justify-end gap-2">
                                                    <button
                                                        onClick={() => dispatch(productsActions.setSelectedProductId(p.id))}
                                                        className="p-2 text-[#A1A1AA] hover:text-white hover:bg-black rounded-lg transition-all"
                                                        title="View Details"
                                                    >
                                                        <Eye size={16} />
                                                    </button>
                                                    <button
                                                        onClick={() => navigate(`edit/${p.id}`)}
                                                        className="p-2 text-[#A1A1AA] hover:text-white hover:bg-black rounded-lg transition-all"
                                                        title="Edit Product"
                                                    >
                                                        <Edit3 size={16} />
                                                    </button>
                                                    <button
                                                        onClick={() => handleDelete(p.id)}
                                                        className="p-2 text-[#A1A1AA] hover:text-white hover:bg-rose-500 rounded-lg transition-all"
                                                        title="Delete Product"
                                                    >
                                                        <Trash2 size={16} />
                                                    </button>
                                                </div>
                                            </td>
                                        )}
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>

                    {status !== "loading" && products.length === 0 && (
                        <div className="py-20 text-center space-y-3">
                            <Package className="mx-auto text-[#D4D4D8]" size={32} />
                            <p className="text-sm font-bold text-[#18181B]">No products found</p>
                            <button
                                onClick={handleReset}
                                className="text-xs font-bold underline text-[#A1A1AA] hover:text-black"
                            >
                                Reset all filters
                            </button>
                        </div>
                    )}
                </div>

                {/* --- PAGINATION CONTROLS --- */}
                <div className="p-4 border-t border-[#EEEEEE] flex items-center justify-between bg-white">
                    <div className="flex items-center gap-4">
                        <div className="text-[11px] text-[#A1A1AA] font-medium">
                            Showing {products.length} of {totalCount} products
                        </div>
                        <select
                            value={limit}
                            onChange={(e) => { setLimit(Number(e.target.value)); setPage(1); }}
                            className="p-1.5 bg-[#F9F9F9] border border-[#EEEEEE] rounded-lg text-xs outline-none focus:border-[#D4D4D8]"
                        >
                            <option value={5}>5 / page</option>
                            <option value={10}>10 / page</option>
                            <option value={20}>20 / page</option>
                            <option value={50}>50 / page</option>
                        </select>
                    </div>
                    <div className="flex items-center gap-2">
                        <button
                            onClick={() => setPage((p) => Math.max(1, p - 1))}
                            disabled={page === 1 || status === "loading"}
                            className="p-2 border border-[#EEEEEE] rounded-lg hover:bg-[#FAFAFA] disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                        >
                            <ChevronLeft size={14} />
                        </button>
                        <span className="text-xs font-bold px-2">Page {page}</span>
                        <button
                            onClick={() => setPage((p) => p + 1)}
                            disabled={products.length < limit || status === "loading"}
                            className="p-2 border border-[#EEEEEE] rounded-lg hover:bg-[#FAFAFA] disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                        >
                            <ChevronRight size={14} />
                        </button>
                    </div>
                </div>
            </div>

            {/* --- PRODUCT DETAIL PANEL --- */}
            {selectedProduct && (
                <ProductDetailPanel
                    product={selectedProduct}
                    onClose={() => dispatch(productsActions.setSelectedProductId(null))}
                    onDelete={(id) => {
                        handleDelete(id);
                        dispatch(productsActions.setSelectedProductId(null));
                    }}
                />
            )}
        </div>
    );
};

/* --- PRODUCT DETAIL SLIDE-OVER PANEL --- */
const ProductDetailPanel = ({
    product,
    onClose,
    onDelete,
}: {
    product: Product;
    onClose: () => void;
    onDelete: (id: number) => void;
}) => {
    const navigate = useNavigate();

    return (
        <>
            <div className="fixed inset-0 bg-black/30 backdrop-blur-sm z-50" onClick={onClose} />
            <div className="fixed inset-y-0 right-0 w-full max-w-xl bg-white z-50 shadow-2xl flex flex-col animate-in slide-in-from-right duration-300">
                {/* Header */}
                <div className="p-6 border-b flex justify-between items-center bg-[#FAFAFA]">
                    <div className="flex items-center gap-4">
                        <div className="w-14 h-14 rounded-xl bg-slate-100 flex items-center justify-center border border-[#EEEEEE] overflow-hidden flex-shrink-0">
                            {product.imageUrl ? (
                                <img src={product.imageUrl} alt={product.name} className="w-full h-full object-cover" />
                            ) : (
                                <Package size={24} className="text-[#A1A1AA]" />
                            )}
                        </div>
                        <div>
                            <h2 className="text-lg font-bold">{product.name}</h2>
                            <p className="text-[11px] text-[#71717A]">
                                SKU: {product.sku} • ID: {product.id}
                            </p>
                        </div>
                    </div>
                    <button onClick={onClose} className="p-2 hover:bg-gray-100 rounded-full transition-colors">
                        <X size={20} />
                    </button>
                </div>

                {/* Content */}
                <div className="flex-1 overflow-y-auto p-6 space-y-8">
                    {/* Status & Category */}
                    <div className="grid grid-cols-2 gap-4">
                        <InfoBox
                            label="Status"
                            value={product.status}
                            icon={
                                <span
                                    className={`w-2 h-2 rounded-full inline-block ${product.status === "Active"
                                        ? "bg-emerald-500"
                                        : product.status === "Out of Stock"
                                            ? "bg-rose-500"
                                            : "bg-slate-400"
                                        }`}
                                />
                            }
                        />
                        <InfoBox label="Category" value={product.categoryName} icon={<Tag size={14} />} />
                    </div>

                    {/* Pricing */}
                    <div className="space-y-3">
                        <h4 className="text-[10px] font-bold uppercase text-[#A1A1AA] tracking-widest">Pricing</h4>
                        <div className="grid grid-cols-3 gap-3">
                            <div className="p-4 border border-[#EEEEEE] rounded-xl bg-[#FDFDFD]">
                                <div className="flex items-center gap-1.5 text-[#A1A1AA] mb-1">
                                    <IndianRupee size={12} />
                                    <span className="text-[9px] font-bold uppercase tracking-widest">MRP</span>
                                </div>
                                <p className="text-lg font-bold">AED {product.price.toLocaleString()}</p>
                            </div>
                            <div className="p-4 border border-[#EEEEEE] rounded-xl bg-[#FDFDFD]">
                                <div className="flex items-center gap-1.5 text-[#A1A1AA] mb-1">
                                    <IndianRupee size={12} />
                                    <span className="text-[9px] font-bold uppercase tracking-widest">Discount</span>
                                </div>
                                <p className="text-lg font-bold text-[#71717A]">
                                    {product.discountPrice !== null ? `AED ${product.discountPrice.toLocaleString()}` : "—"}
                                </p>
                            </div>
                            <div className="p-4 border border-[#EEEEEE] rounded-xl bg-[#FDFDFD]">
                                <div className="flex items-center gap-1.5 text-[#A1A1AA] mb-1">
                                    <IndianRupee size={12} />
                                    <span className="text-[9px] font-bold uppercase tracking-widest">Final</span>
                                </div>
                                <p className="text-lg font-bold text-emerald-600">AED {product.finalPrice.toLocaleString()}</p>
                            </div>
                        </div>
                    </div>

                    {/* Inventory & Delivery */}
                    <div className="space-y-3">
                        <h4 className="text-[10px] font-bold uppercase text-[#A1A1AA] tracking-widest">Inventory & Delivery</h4>
                        <div className="grid grid-cols-2 gap-4">
                            <InfoBox label="Stock" value={`${product.stock} units`} icon={<Box size={14} />} />
                            <InfoBox label="Available" value={product.isAvailable ? "Yes" : "No"} icon={<Package size={14} />} />
                            <InfoBox label="Delivery Time" value={product.expectedDeliveryTime || "—"} icon={<Clock size={14} />} />
                            <InfoBox
                                label="Rating"
                                value={product.averageRating > 0 ? `${product.averageRating.toFixed(1)} (${product.totalReviews} reviews)` : "No reviews"}
                                icon={<Star size={14} />}
                            />
                        </div>
                    </div>

                    {/* Images Gallery */}
                    {product.images?.length > 0 && (
                        <div className="space-y-3">
                            <h4 className="text-[10px] font-bold uppercase text-[#A1A1AA] tracking-widest">Gallery</h4>
                            <div className="grid grid-cols-4 gap-2">
                                {product.images.map((img) => (
                                    <div key={img.id} className="aspect-square rounded-lg overflow-hidden border border-[#EEEEEE] relative">
                                        <img src={img.url} alt="" className="w-full h-full object-cover" />
                                        {img.isFeature && (
                                            <span className="absolute top-1 left-1 text-[8px] font-bold bg-black text-white px-1.5 py-0.5 rounded-full">
                                                FEATURED
                                            </span>
                                        )}
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}

                    {/* Description */}
                    {product.description && (
                        <div className="space-y-3">
                            <h4 className="text-[10px] font-bold uppercase text-[#A1A1AA] tracking-widest">Description</h4>
                            <p className="text-sm text-[#52525B] leading-relaxed">{product.description}</p>
                        </div>
                    )}
                </div>

                {/* Footer */}
                <div className="p-6 border-t bg-[#FAFAFA] flex gap-3">
                    <button
                        onClick={() => navigate(`edit/${product.id}`)}
                        className="flex-1 py-3 bg-black text-white rounded-xl text-xs font-bold hover:bg-[#222] flex items-center justify-center gap-2 transition-all"
                    >
                        Edit Product
                    </button>
                    <button
                        onClick={() => onDelete(product.id)}
                        className="px-4 py-3 bg-white border border-rose-100 text-rose-600 rounded-xl text-xs font-bold hover:bg-rose-50 transition-all"
                    >
                        Delete
                    </button>
                </div>
            </div>
        </>
    );
};

/* --- SUB-COMPONENTS --- */
const QuickStat = ({
    label,
    value,
    sub,
    icon,
}: {
    label: string;
    value: string;
    sub: string;
    icon: React.ReactNode;
}) => (
    <div className="p-5 bg-white border border-[#EEEEEE] rounded-2xl shadow-sm hover:border-[#D4D4D8] transition-colors">
        <div className="flex items-center justify-between">
            <p className="text-[10px] font-bold text-[#A1A1AA] uppercase tracking-widest">{label}</p>
            {icon}
        </div>
        <h3 className="text-2xl font-bold mt-1 tracking-tight">{value}</h3>
        <p className="text-[11px] text-emerald-600 font-medium mt-1">{sub}</p>
    </div>
);

const InfoBox = ({
    label,
    value,
    icon,
}: {
    label: string;
    value: string;
    icon: React.ReactNode;
}) => (
    <div className="p-4 border border-[#EEEEEE] rounded-xl space-y-1.5 bg-[#FDFDFD]">
        <div className="flex items-center gap-2 text-[#A1A1AA]">
            {icon} <span className="text-[9px] font-bold uppercase tracking-widest">{label}</span>
        </div>
        <p className="text-sm font-bold">{value}</p>
    </div>
);

export default ProductManagement;
