import React, { Suspense, lazy } from 'react';
import { Routes, Route, Navigate, Outlet } from 'react-router-dom';
import LoginPage from '../pages/auth/Login';
import RegisterPage from '../pages/auth/Register';
import ForgotPasswordPage from '../pages/auth/ForgotPassword';
import ResetPasswordPage from '../pages/auth/ResetPassword';
import AuthCallback from '../pages/auth/Callback';
const DashboardPage = lazy(() => import('../pages/provider/Dashboard'));
const LocationsPage = lazy(() => import('../pages/provider/Locations'));
const LocationEditPage = lazy(() => import('../pages/provider/Locations/[id]'));
const AddLocationPage = lazy(() => import('../pages/provider/AddLocation'));
const ProfilePage = lazy(() => import('../pages/provider/Profile'));
const OrdersPage = lazy(() => import('../pages/provider/Orders'));
const OrderDetailPage = lazy(() => import('../pages/provider/Orders/[id]'));
const ProviderLayout = lazy(() => import('../layouts/ProviderLayout/ProviderLayout'));

// Admin pages are also split so they do not delay the provider application.
const AdminLayout = lazy(() => import('../layouts/AdminLayout').then((module) => ({ default: module.AdminLayout })));
const AdminDashboard = lazy(() => import('../pages/admin/Dashboard').then((module) => ({ default: module.AdminDashboard })));
const UserManagement = lazy(() => import('../pages/admin/UserManagement').then((module) => ({ default: module.UserManagement })));
const AddUser = lazy(() => import('../pages/admin/AddUser').then((module) => ({ default: module.AddUser })));
const UserDetail = lazy(() => import('../pages/admin/UserDetail').then((module) => ({ default: module.UserDetail })));
const LocationManagement = lazy(() => import('../pages/admin/LocationManagement').then((module) => ({ default: module.LocationManagement })));
const AddLocation = lazy(() => import('../pages/admin/AddLocation').then((module) => ({ default: module.AddLocation })));
const LocationDetail = lazy(() => import('../pages/admin/LocationDetail').then((module) => ({ default: module.LocationDetail })));
const ReviewManagement = lazy(() => import('../pages/admin/ReviewManagement').then((module) => ({ default: module.ReviewManagement })));
const ReviewDetail = lazy(() => import('../pages/admin/ReviewDetail').then((module) => ({ default: module.ReviewDetail })));
const ItineraryReviewDetail = lazy(() => import('../pages/admin/ItineraryReviewDetail').then((module) => ({ default: module.ItineraryReviewDetail })));
const AlgorithmSettings = lazy(() => import('../pages/admin/AlgorithmSettings').then((module) => ({ default: module.AlgorithmSettings })));
const AlgorithmRunner = lazy(() => import('../pages/admin/AlgorithmRunner').then((module) => ({ default: module.AlgorithmRunner })));
const AlgorithmRunHistory = lazy(() => import('../pages/admin/AlgorithmRunHistory').then((module) => ({ default: module.AlgorithmRunHistory })));
const AdminProfilePage = lazy(() => import('../pages/admin/Profile'));

const RouteLoading = () => (
  <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', color: '#64748b' }}>
    Đang tải...
  </div>
);

const AppRoutes: React.FC = () => {
  return (
    <Suspense fallback={<RouteLoading />}>
    <Routes>
      {/* Auth Routes */}
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />
      <Route path="/forgot-password" element={<ForgotPasswordPage />} />
      <Route path="/reset-password" element={<ResetPasswordPage />} />
      <Route path="/auth/callback" element={<AuthCallback />} />

      {/* Provider Routes */}
      <Route element={<ProviderLayout />}>
        <Route path="/dashboard" element={<DashboardPage />} />
        <Route path="/locations" element={<LocationsPage />} />
        <Route path="/locations/:id" element={<LocationEditPage />} />
        <Route path="/add-location" element={<AddLocationPage />} />
        <Route path="/profile" element={<ProfilePage />} />
        <Route path="/orders" element={<OrdersPage />} />
        <Route path="/orders/:id" element={<OrderDetailPage />} />
      </Route>

      {/* Admin Routes */}
      <Route element={<AdminLayout><Outlet /></AdminLayout>}>
        <Route path="/admin" element={<Navigate to="/admin/dashboard" replace />} />
        <Route path="/admin/dashboard" element={<AdminDashboard />} />
        <Route path="/admin/users" element={<UserManagement />} />
        <Route path="/admin/users/add" element={<AddUser />} />
        <Route path="/admin/users/:id" element={<UserDetail />} />
        <Route path="/admin/locations" element={<LocationManagement />} />
        <Route path="/admin/locations/add" element={<AddLocation />} />
        <Route path="/admin/locations/:id" element={<LocationDetail />} />
        <Route path="/admin/reviews" element={<ReviewManagement />} />
        <Route path="/admin/reviews/:id" element={<ReviewDetail />} />
        <Route path="/admin/itinerary-reviews/:id" element={<ItineraryReviewDetail />} />
        <Route path="/admin/algorithm-settings" element={<AlgorithmSettings />} />
        <Route path="/admin/algorithm-runner" element={<AlgorithmRunner />} />
        <Route path="/admin/algorithm-history" element={<AlgorithmRunHistory />} />
        <Route path="/admin/profile" element={<AdminProfilePage />} />
      </Route>

      {/* Default Redirect */}
      <Route path="/" element={<Navigate to="/login" replace />} />
    </Routes>
    </Suspense>
  );
};

export default AppRoutes;
