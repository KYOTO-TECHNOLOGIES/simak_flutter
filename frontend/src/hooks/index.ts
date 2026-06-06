import { useDispatch, useSelector, type TypedUseSelectorHook } from "react-redux";
import type { AppDispatch, RootState } from "../app/store";

/**
 * ✅ Pre-typed dispatch hook for Redux
 */
export const useAppDispatch = () => useDispatch<AppDispatch>();

/**
 * ✅ Pre-typed selector hook for Redux
 */
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;

export { useRequireAuth } from './useRequireAuth';

