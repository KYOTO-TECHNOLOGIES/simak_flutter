import React from 'react';
import { Routes, Route, Navigate, Outlet } from 'react-router-dom';
import { PrivateRoute } from './PrivateRoute';

// User components
import Home from '../features/user/home';
import Register from '../features/user/register';
import Login from '../features/user/login';
import UserProductsPage from '../features/user/products';
import ProductProfile from '../features/user/productprofile';
import CartPage from '../features/user/cart';
import CheckoutPage from '../features/user/checkout';
import NotificationPage from '../features/user/notification';
import Navbar from '../components/layout/userside/navbar';
import Footer from '../components/layout/userside/footer';
import OrderPage from '../features/user/order';
import ProfilePage from '../features/user/profile';
// import WishlistPage from '../features/user/wishlist';

// Admin components
import Dashboard from '../features/admin/dashboard/dashboard';
import AdminLayout from '../components/layout/adminside/AdminLayout';
import OrderManagement from '../features/admin/orders/orders';
import CartManagement from '../features/admin/cart/cart';
import CustomerManagement from '../features/admin/customers/customers';
import ReviewsManagement from '../features/admin/reviews/reviews';
import PaymentManagement from '../features/admin/payments/payments';
import SettingsPage from '../features/admin/settings/settings';
import ProductManagement from '../features/admin/products/products';
import AddProduct from '../features/admin/products/AddProduct';
import EditProduct from '../features/admin/products/EditProduct';

/* Layout wrapper that adds Navbar to user-facing pages */
const UserLayout = () => (
  <>
    <Navbar />
    <Outlet />
    <Footer />
  </>
);

export const AppRoutes: React.FC = () => {
  return (
    <Routes>
      {/* --- USER ROUTES (with Navbar) --- */}
      <Route element={<UserLayout />}>
        {/* Public user routes */}
        <Route path="/" element={<Home />} />
        <Route path="/products" element={<UserProductsPage />} />
        <Route path="/products/:id" element={<ProductProfile />} />
        <Route path="/register" element={<Register />} />
        <Route path="/login" element={<Login />} />

        {/* Protected user routes — require login */}
        <Route element={<PrivateRoute />}>
          <Route path="/cart" element={<CartPage />} />
          <Route path="/checkout" element={<CheckoutPage />} />
          <Route path="/orders" element={<OrderPage />} />
          <Route path="/profile" element={<ProfilePage />} />
          <Route path="/notifications" element={<NotificationPage />} />
          {/* <Route path="/wishlist" element={<WishlistPage />} /> */}
        </Route>
      </Route>

      {/* --- ADMIN ROUTES (Nested) --- */}
      {/* AdminLayout is the "Parent". It contains the Sidebar and Header */}
      <Route path="/admin" element={<PrivateRoute roles={['admin']} />}>
        <Route element={<AdminLayout />}>
          {/* Redirect /admin to /admin/dashboard automatically */}
          <Route index element={<Navigate to="dashboard" replace />} />

          {/* These children will render inside the <Outlet /> of AdminLayout */}
          <Route path="dashboard" element={<Dashboard />} />
          <Route path="orders" element={<OrderManagement />} />
          <Route path="cart" element={<CartManagement />} />
          <Route path="users" element={<CustomerManagement />} />
          <Route path="products" element={<ProductManagement />} />
          <Route path="products/add" element={<AddProduct />} />
          <Route path="products/edit/:id" element={<EditProduct />} />
          <Route path="reviews" element={<ReviewsManagement />} />
          <Route path="payments" element={<PaymentManagement />} />
          <Route path="settings" element={<SettingsPage />} />
        </Route>
      </Route>

      {/* Fallback for 404 - Redirect to home */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
};
