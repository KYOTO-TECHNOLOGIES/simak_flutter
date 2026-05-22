import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAppSelector } from '../hooks';
import { Loader2 } from 'lucide-react';

interface Props {
  roles?: ('admin' | 'user')[];
}

export const PrivateRoute = ({ roles }: Props) => {
  const { user, isAuthenticated, checkingAuth } = useAppSelector((state) => state.auth);
  const location = useLocation();

  // While the app is checking session, show a spinner (prevents flash of login redirect)
  if (checkingAuth) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-white">
        <Loader2 size={36} className="animate-spin text-red-600" />
      </div>
    );
  }

  if (!isAuthenticated) {
    // Save the route they tried to visit so we can redirect back after login
    return <Navigate to="/login" state={{ redirect: location.pathname }} replace />;
  }

  if (roles && user && !roles.includes(user.role)) {
    return <Navigate to="/unauthorized" replace />;
  }

  return <Outlet />;
};