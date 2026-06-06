import { useCallback } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAppSelector } from './index';

/**
 * Returns a function that wraps any protected action.
 * If the user is not authenticated, navigates to /login
 * with a `redirect` state so we can return after login.
 *
 * Usage:
 *   const requireAuth = useRequireAuth();
 *   const handleAddToCart = requireAuth(() => dispatch(addToCart(...)));
 */
export const useRequireAuth = () => {
    const navigate = useNavigate();
    const location = useLocation();
    const isAuthenticated = useAppSelector((state) => state.auth.isAuthenticated);

    const requireAuth = useCallback(
        (action: () => void) => {
            return () => {
                if (!isAuthenticated) {
                    navigate('/login', { state: { redirect: location.pathname } });
                    return;
                }
                action();
            };
        },
        [isAuthenticated, navigate, location.pathname]
    );

    return requireAuth;
};
