import React from 'react';
import { Routes, Route, Navigate, Outlet } from 'react-router-dom';
import LoginPage from '../pages/auth/Login';
import RegisterPage from '../pages/auth/Register';
import ForgotPasswordPage from '../pages/auth/ForgotPassword';
import ResetPasswordPage from '../pages/auth/ResetPassword';
import AuthCallback from '../pages/auth/Callback';
import DashboardPage from '../pages/provider/Dashboard';
import LocationsPage from '../pages/provider/Locations';
import LocationEditPage from '../pages/provider/Locations/[id]';
import AddLocationPage from '../pages/provider/AddLocation';
import ProfilePage from '../pages/provider/Profile';
import OrdersPage from '../pages/provider/Orders';
import OrderDetailPage from '../pages/provider/Orders/[id]';
import ProviderLayout from '../layouts/ProviderLayout/ProviderLayout';

// Admin imports
import { AdminLayout } from '../layouts/AdminLayout';
import { AdminDashboard } from '../pages/admin/Dashboard';
import { UserManagement } from '../pages/admin/UserManagement';
import { AddUser } from '../pages/admin/AddUser';
import { UserDetail } from '../pages/admin/UserDetail';
import { LocationManagement } from '../pages/admin/LocationManagement';
import { AddLocation } from '../pages/admin/AddLocation';
import { LocationDetail } from '../pages/admin/LocationDetail';
import { ReviewManagement } from '../pages/admin/ReviewManagement';
import { ReviewDetail } from '../pages/admin/ReviewDetail';
import { ItineraryReviewDetail } from '../pages/admin/ItineraryReviewDetail';
import { AlgorithmSettings } from '../pages/admin/AlgorithmSettings';

const AppRoutes: React.FC = () => {
  return (
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
      </Route>

      {/* Default Redirect */}
      <Route path="/" element={<Navigate to="/login" replace />} />
    </Routes>
  );
};

export default AppRoutes;
