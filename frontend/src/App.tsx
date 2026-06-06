import { useEffect, useState } from "react";
import { BrowserRouter } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { checkAuth } from "./features/auth/authSlice";
import { AppRoutes } from "./routes/AppRoutes";
import ShrimpLoader from "./components/loader/preloader";

function App() {
  const dispatch = useDispatch();
  const { checkingAuth } = useSelector((state: any) => state.auth);
  const [minDelayDone, setMinDelayDone] = useState(false);

  useEffect(() => {
    dispatch(checkAuth() as any);
    // Minimum 5-second splash screen
    const timer = setTimeout(() => setMinDelayDone(true), 2000);
    return () => clearTimeout(timer);
  }, [dispatch]);

  if (checkingAuth || !minDelayDone) {
    return <ShrimpLoader label="Checking account..." />;
  }

  return (
    <BrowserRouter>
      <AppRoutes />
    </BrowserRouter>
  );
}

export default App;
