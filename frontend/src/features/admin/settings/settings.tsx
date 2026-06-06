import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import {
  Store, Clock, MapPin, CreditCard, Truck, Receipt,
  ShoppingBag, Undo2, Bell, Users, Shield, Globe,
  Save, Plus, Trash2, AlertTriangle,
  FileUp, ChevronRight, Menu, Loader2,
} from "lucide-react";

import {
  settingsActions,
  selectSettingsStatus,
  selectActiveSection,
  selectIsDirty,
  selectStoreProfile,
  selectOperationalDays,
  selectDeliverySlots,
  selectServiceAreas,
  selectPaymentGatewayConnected,
  selectCodThresholds,
  selectReturnsConfig,
} from "./settingsSlice";
import type { SettingSection } from "./settingsSlice";

/* ── MAIN COMPONENT ── */
const SettingsPage: React.FC = () => {
  const dispatch = useDispatch();
  const activeTab = useSelector(selectActiveSection);
  const isDirty = useSelector(selectIsDirty);
  const status = useSelector(selectSettingsStatus);
  const [isSidebarOpen, setSidebarOpen] = useState(true);

  useEffect(() => {
    dispatch(settingsActions.fetchSettingsRequest());
  }, [dispatch]);

  const handleSave = () => dispatch(settingsActions.saveSettingsRequest());
  const handleDiscard = () => dispatch(settingsActions.discardChanges());
  const setSection = (id: SettingSection) =>
    dispatch(settingsActions.setActiveSection(id));

  return (
    <div className="min-h-screen bg-[#FBFBFA] flex text-[#18181B] animate-in fade-in duration-500">
      {/* --- LEFT SIDEBAR NAV --- */}
      <aside className={`bg-white border-r border-[#EEEEEE] transition-all duration-300 ${isSidebarOpen ? "w-72" : "w-20"} flex flex-col shrink-0`}>
        <div className="p-6 border-b flex items-center justify-between">
          <h2 className={`font-bold text-lg tracking-tight ${!isSidebarOpen && "hidden"}`}>Settings</h2>
          <button onClick={() => setSidebarOpen(!isSidebarOpen)} className="p-2 hover:bg-[#F4F4F5] rounded-lg">
            <Menu size={20} />
          </button>
        </div>

        <nav className="flex-1 overflow-y-auto p-4 space-y-1 custom-scrollbar">
          <NavGroup label="General" isOpen={isSidebarOpen}>
            <NavItem id="profile" icon={<Store size={18} />} label="Store Profile" active={activeTab} onClick={setSection} isOpen={isSidebarOpen} />
            <NavItem id="hours" icon={<Clock size={18} />} label="Hours & Slots" active={activeTab} onClick={setSection} isOpen={isSidebarOpen} />
            <NavItem id="service" icon={<MapPin size={18} />} label="Service Area" active={activeTab} onClick={setSection} isOpen={isSidebarOpen} />
          </NavGroup>

          <NavGroup label="Operations" isOpen={isSidebarOpen}>
            <NavItem id="payments" icon={<CreditCard size={18} />} label="Payments" active={activeTab} onClick={setSection} isOpen={isSidebarOpen} />
            <NavItem id="delivery" icon={<Truck size={18} />} label="Shipping Rules" active={activeTab} onClick={setSection} isOpen={isSidebarOpen} />
            <NavItem id="tax" icon={<Receipt size={18} />} label="Tax & Invoicing" active={activeTab} onClick={setSection} isOpen={isSidebarOpen} />
            <NavItem id="orders" icon={<ShoppingBag size={18} />} label="Order Workflow" active={activeTab} onClick={setSection} isOpen={isSidebarOpen} />
            <NavItem id="returns" icon={<Undo2 size={18} />} label="Return Policy" active={activeTab} onClick={setSection} isOpen={isSidebarOpen} />
          </NavGroup>

          <NavGroup label="System" isOpen={isSidebarOpen}>
            <NavItem id="notifications" icon={<Bell size={18} />} label="Notifications" active={activeTab} onClick={setSection} isOpen={isSidebarOpen} />
            <NavItem id="users" icon={<Users size={18} />} label="Team & Roles" active={activeTab} onClick={setSection} isOpen={isSidebarOpen} />
            <NavItem id="security" icon={<Shield size={18} />} label="Security" active={activeTab} onClick={setSection} isOpen={isSidebarOpen} />
            <NavItem id="seo" icon={<Globe size={18} />} label="SEO & App" active={activeTab} onClick={setSection} isOpen={isSidebarOpen} />
          </NavGroup>
        </nav>
      </aside>

      {/* --- MAIN CONTENT AREA --- */}
      <main className="flex-1 flex flex-col max-h-screen overflow-hidden">
        {/* Header */}
        <header className="h-20 bg-white border-b border-[#EEEEEE] flex items-center justify-between px-8 shrink-0">
          <div>
            <h1 className="text-xl font-bold capitalize">{activeTab.replace("-", " ")}</h1>
            <p className="text-xs text-[#71717A]">Manage your store's configuration and preferences.</p>
          </div>
          <div className="flex items-center gap-3">
            {isDirty && (
              <span className="text-[10px] font-bold text-amber-600 bg-amber-50 px-2 py-1 rounded-lg border border-amber-100 animate-in fade-in">
                Unsaved changes
              </span>
            )}
            <button
              onClick={handleDiscard}
              disabled={!isDirty}
              className="px-4 py-2 border border-[#EEEEEE] rounded-xl text-xs font-bold hover:bg-[#F4F4F5] disabled:opacity-40 disabled:cursor-not-allowed transition-all"
            >
              Discard Changes
            </button>
            <button
              onClick={handleSave}
              disabled={!isDirty || status === "saving"}
              className="px-4 py-2 bg-black text-white rounded-xl text-xs font-bold flex items-center gap-2 hover:bg-[#222] disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-md"
            >
              {status === "saving" ? (
                <Loader2 size={14} className="animate-spin" />
              ) : (
                <Save size={14} />
              )}
              {status === "saving" ? "Saving…" : "Save Changes"}
            </button>
          </div>
        </header>

        {/* Content Render */}
        <div className="flex-1 overflow-y-auto p-8">
          <div className="max-w-4xl mx-auto space-y-8 animate-in slide-in-from-bottom-2 duration-500">
            {activeTab === "profile" && <StoreProfileView />}
            {activeTab === "hours" && <HoursSlotsView />}
            {activeTab === "service" && <ServiceAreaView />}
            {activeTab === "payments" && <PaymentSettingsView />}
            {activeTab === "delivery" && <ShippingRulesView />}
            {activeTab === "tax" && <TaxView />}
            {activeTab === "orders" && <OrderWorkflowView />}
            {activeTab === "returns" && <ReturnsPolicyView />}
            {activeTab === "notifications" && <NotificationSettingsView />}
            {activeTab === "users" && <TeamRolesView />}
            {activeTab === "security" && <SecurityView />}
            {activeTab === "seo" && <SeoView />}
          </div>
        </div>
      </main>
    </div>
  );
};

/* ── 1. STORE PROFILE ── */
const StoreProfileView = () => {
  const dispatch = useDispatch();
  const profile = useSelector(selectStoreProfile);

  const update = (field: string, value: string) =>
    dispatch(settingsActions.updateStoreProfile({ [field]: value }));

  return (
    <div className="space-y-6">
      <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-6">
        <h3 className="text-sm font-bold">Store Information</h3>
        <div className="grid grid-cols-2 gap-4">
          <InputGroup label="Store Name" value={profile.storeName} onChange={(v) => update("storeName", v)} />
          <InputGroup label="Email" value={profile.storeEmail} onChange={(v) => update("storeEmail", v)} />
          <InputGroup label="Phone" value={profile.storePhone} onChange={(v) => update("storePhone", v)} />
          <InputGroup label="Currency" value={profile.currency} onChange={(v) => update("currency", v)} />
        </div>
        <InputGroup label="Address" value={profile.storeAddress} onChange={(v) => update("storeAddress", v)} />
      </section>

      <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-4">
        <h3 className="text-sm font-bold">Store Logo</h3>
        <div className="flex items-center gap-4">
          <div className="w-20 h-20 bg-[#F4F4F5] rounded-2xl flex items-center justify-center text-[#A1A1AA] border-2 border-dashed border-[#D4D4D8]">
            <Store size={28} />
          </div>
          <div>
            <button className="px-4 py-2 bg-black text-white rounded-xl text-xs font-bold flex items-center gap-2 shadow-md">
              <FileUp size={14} /> Upload Logo
            </button>
            <p className="text-[10px] text-[#A1A1AA] mt-2">PNG or JPG, max 2MB</p>
          </div>
        </div>
      </section>
    </div>
  );
};

/* ── 2. BUSINESS HOURS & SLOTS ── */
const HoursSlotsView = () => {
  const dispatch = useDispatch();
  const days = useSelector(selectOperationalDays);
  const slots = useSelector(selectDeliverySlots);

  return (
    <div className="space-y-8">
      <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm">
        <h3 className="text-sm font-bold mb-4">Operational Days</h3>
        <div className="grid grid-cols-7 gap-2">
          {["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map((day) => (
            <div key={day} className="flex flex-col items-center gap-2 p-3 border rounded-xl bg-[#FAFAFA]">
              <span className="text-[10px] font-bold text-[#A1A1AA]">{day}</span>
              <input
                type="checkbox"
                checked={days.includes(day)}
                onChange={() => dispatch(settingsActions.toggleOperationalDay(day))}
                className="w-4 h-4 accent-black"
              />
            </div>
          ))}
        </div>
      </section>

      <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-4">
        <div className="flex justify-between items-center">
          <h3 className="text-sm font-bold">Delivery Slots</h3>
          <button className="text-[10px] font-bold uppercase tracking-widest text-blue-600 flex items-center gap-1">
            <Plus size={12} /> Add Slot
          </button>
        </div>

        <div className="space-y-3">
          {slots.map((slot) => (
            <div key={slot.id} className="flex items-center justify-between p-4 border rounded-xl hover:border-black transition-all cursor-pointer group">
              <div className="flex items-center gap-4">
                <div className="w-10 h-10 bg-[#FAFAFA] rounded-full flex items-center justify-center text-[#71717A]">
                  <Clock size={16} />
                </div>
                <div>
                  <p className="text-xs font-bold">{slot.name}</p>
                  <p className="text-[10px] text-[#A1A1AA]">{slot.startTime} — {slot.endTime}</p>
                </div>
              </div>
              <div className="flex items-center gap-8">
                <div className="text-right">
                  <p className="text-[10px] font-bold text-[#71717A] uppercase">Cut-off</p>
                  <p className="text-[10px] font-mono">{slot.cutoffTime}</p>
                </div>
                <div className="text-right">
                  <p className="text-[10px] font-bold text-[#71717A] uppercase">Capacity</p>
                  <p className="text-[10px] font-mono font-bold">{slot.capacity} Orders</p>
                </div>
                <button
                  onClick={() => dispatch(settingsActions.removeDeliverySlot(slot.id))}
                  className="p-2 text-[#A1A1AA] hover:text-rose-500 opacity-0 group-hover:opacity-100 transition-all"
                >
                  <Trash2 size={16} />
                </button>
              </div>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
};

/* ── 3. SERVICE AREA ── */
const ServiceAreaView = () => {
  const areas = useSelector(selectServiceAreas);

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-end">
        <div>
          <h3 className="text-sm font-bold">Serviceable Pincodes</h3>
          <p className="text-xs text-[#A1A1AA]">Manage delivery fees and COD availability by zone.</p>
        </div>
        <button className="px-3 py-2 bg-[#F4F4F5] rounded-xl text-[10px] font-bold flex items-center gap-2">
          <FileUp size={14} /> Bulk CSV Import
        </button>
      </div>

      <div className="bg-white border border-[#EEEEEE] rounded-2xl overflow-hidden shadow-sm">
        <table className="w-full text-left text-sm">
          <thead className="bg-[#FAFAFA] border-b text-[10px] font-bold uppercase text-[#A1A1AA]">
            <tr>
              <th className="px-6 py-4">Pincode / Zone</th>
              <th className="px-6 py-4">Delivery Fee</th>
              <th className="px-6 py-4">Min. Order</th>
              <th className="px-6 py-4">COD</th>
              <th className="px-6 py-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#EEEEEE]">
            {areas.map((area) => (
              <tr key={area.id} className="hover:bg-[#FBFBFA]">
                <td className="px-6 py-4">
                  <p className="text-xs font-bold">{area.pincode}</p>
                  <p className="text-[10px] text-[#A1A1AA]">{area.zone}</p>
                </td>
                <td className="px-6 py-4 font-mono text-xs font-bold">{area.deliveryFee}</td>
                <td className="px-6 py-4 font-mono text-xs text-[#71717A]">{area.minOrder}</td>
                <td className="px-6 py-4">
                  <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${area.codAvailable ? "bg-emerald-50 text-emerald-600" : "bg-rose-50 text-rose-600"}`}>
                    {area.codAvailable ? "COD ON" : "PREPAID ONLY"}
                  </span>
                </td>
                <td className="px-6 py-4 text-right">
                  <button className="p-2 hover:bg-gray-100 rounded-lg"><ChevronRight size={14} /></button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

/* ── 4. PAYMENT SETTINGS ── */
const PaymentSettingsView = () => {
  const dispatch = useDispatch();
  const connected = useSelector(selectPaymentGatewayConnected);
  const cod = useSelector(selectCodThresholds);

  return (
    <div className="space-y-6">
      <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-6">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 bg-blue-50 text-blue-600 rounded-xl flex items-center justify-center">
            <CreditCard size={24} />
          </div>
          <div>
            <h3 className="text-sm font-bold">Razorpay Integration</h3>
            <p className="text-xs text-[#A1A1AA]">Primary gateway for UPI, Cards, and NetBanking.</p>
          </div>
          <div className="ml-auto flex items-center gap-2 px-2 py-1 rounded-lg border">
            {connected ? (
              <div className="flex items-center gap-2 bg-emerald-50 text-emerald-600 px-2 py-1 rounded-lg border-emerald-100">
                <div className="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-pulse" />
                <span className="text-[10px] font-bold uppercase">Connected</span>
              </div>
            ) : (
              <div className="flex items-center gap-2 bg-amber-50 text-amber-600 px-2 py-1 rounded-lg border-amber-100">
                <span className="text-[10px] font-bold uppercase">Not Connected</span>
              </div>
            )}
          </div>
        </div>

        <div className="space-y-4 pt-4 border-t">
          <div className="grid grid-cols-2 gap-4">
            <InputGroup label="Key ID" type="password" value="rzp_live_xxxxxxxxxx" />
            <InputGroup label="Key Secret" type="password" value="••••••••••••••••" />
          </div>
          <button className="text-xs font-bold text-blue-600 hover:underline">Test Webhook Connection</button>
        </div>
      </section>

      <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm">
        <h3 className="text-sm font-bold mb-4">COD Thresholds</h3>
        <div className="grid grid-cols-2 gap-4">
          <InputGroup
            label="Min COD Value"
            value={`AED ${cod.min}`}
            onChange={(v) => dispatch(settingsActions.setCodThresholds({ min: v.replace("AED ", ""), max: cod.max }))}
          />
          <InputGroup
            label="Max COD Value"
            value={`AED ${cod.max}`}
            onChange={(v) => dispatch(settingsActions.setCodThresholds({ min: cod.min, max: v.replace("AED ", "") }))}
          />
        </div>
      </section>
    </div>
  );
};

/* ── 5. SHIPPING RULES ── */
const ShippingRulesView = () => (
  <div className="space-y-6">
    <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-4">
      <h3 className="text-sm font-bold">Delivery Charges</h3>
      <div className="grid grid-cols-2 gap-4">
        <InputGroup label="Standard Delivery Fee" value="AED 49" />
        <InputGroup label="Free Delivery Above" value="AED 999" />
      </div>
    </section>
    <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-4">
      <h3 className="text-sm font-bold">Express Delivery</h3>
      <div className="grid grid-cols-2 gap-4">
        <InputGroup label="Express Fee" value="AED 99" />
        <InputGroup label="Delivery Window" value="2 Hours" />
      </div>
    </section>
  </div>
);

/* ── 6. TAX & INVOICING ── */
const TaxView = () => (
  <div className="space-y-6">
    <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-4">
      <h3 className="text-sm font-bold">GST Configuration</h3>
      <div className="grid grid-cols-2 gap-4">
        <InputGroup label="GSTIN" value="29ABCDE1234F1Z5" />
        <InputGroup label="Default Tax Rate (%)" value="5" />
      </div>
    </section>
    <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-4">
      <h3 className="text-sm font-bold">Invoice Settings</h3>
      <div className="grid grid-cols-2 gap-4">
        <InputGroup label="Invoice Prefix" value="FC-INV" />
        <InputGroup label="Starting Number" value="1001" />
      </div>
      <ToggleItem label="Auto-generate invoices on order confirmation" sub="Send PDF invoice via email/WhatsApp" defaultOn={true} />
    </section>
  </div>
);

/* ── 7. ORDER WORKFLOW ── */
const OrderWorkflowView = () => (
  <div className="space-y-6">
    <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-6">
      <h3 className="text-sm font-bold">Order Pipeline</h3>
      <div className="flex items-center gap-3 flex-wrap">
        {["Order Placed", "Processing", "Packed", "Out for Delivery", "Delivered"].map((stage, i) => (
          <React.Fragment key={stage}>
            <div className="px-4 py-2 bg-[#FAFAFA] border border-[#EEEEEE] rounded-xl text-xs font-bold flex items-center gap-2">
              <span className="w-5 h-5 bg-black text-white rounded-full flex items-center justify-center text-[10px] font-bold">{i + 1}</span>
              {stage}
            </div>
            {i < 4 && <ChevronRight size={16} className="text-[#D4D4D8]" />}
          </React.Fragment>
        ))}
      </div>
    </section>
    <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-4">
      <h3 className="text-sm font-bold">Auto-Cancel Settings</h3>
      <div className="grid grid-cols-2 gap-4">
        <InputGroup label="Auto-cancel pending orders after (hours)" value="24" />
        <InputGroup label="Auto-cancel unpaid orders after (hours)" value="4" />
      </div>
    </section>
  </div>
);

/* ── 8. RETURNS POLICY ── */
const ReturnsPolicyView = () => {
  const dispatch = useDispatch();
  const returns = useSelector(selectReturnsConfig);

  return (
    <div className="space-y-6">
      <div className="p-4 bg-amber-50 border border-amber-100 rounded-xl flex gap-3">
        <AlertTriangle className="text-amber-600 shrink-0" size={18} />
        <p className="text-xs text-amber-800 leading-relaxed">
          <strong>Warning:</strong> You are selling perishable goods (Fresh Fish). It is highly recommended to set a return window of less than 6 hours or "No Return" unless damaged.
        </p>
      </div>

      <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-6">
        <ToggleItem
          label="Enable Returns/Replacements"
          sub="Allow customers to request returns via the app"
          defaultOn={returns.enabled}
          onToggle={() => dispatch(settingsActions.setReturnsConfig({ enabled: !returns.enabled }))}
        />
        <div className="grid grid-cols-2 gap-4 pt-4 border-t">
          <InputGroup
            label="Return Window (Hours)"
            value={String(returns.windowHours)}
            onChange={(v) => dispatch(settingsActions.setReturnsConfig({ windowHours: parseInt(v) || 0 }))}
          />
          <div className="space-y-2">
            <label className="text-[10px] font-bold uppercase text-[#A1A1AA]">Proof Requirements</label>
            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={returns.photoProof}
                onChange={() => dispatch(settingsActions.setReturnsConfig({ photoProof: !returns.photoProof }))}
                className="accent-black"
              />
              <span className="text-xs">Photo of product required</span>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};

/* ── 9. NOTIFICATIONS ── */
const NotificationSettingsView = () => (
  <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-6">
    <h3 className="text-sm font-bold">Automated Alerts</h3>
    <div className="divide-y divide-[#EEEEEE]">
      <NotificationToggle label="Order Placed" channels={["SMS", "WhatsApp", "Email"]} />
      <NotificationToggle label="Out for Delivery" channels={["SMS", "WhatsApp"]} />
      <NotificationToggle label="Delivery Slot Reminder" channels={["WhatsApp"]} />
      <NotificationToggle label="Order Cancelled" channels={["SMS", "Email"]} />
    </div>
  </section>
);

/* ── 10. TEAM & ROLES ── */
const TeamRolesView = () => (
  <div className="space-y-6">
    <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-4">
      <div className="flex justify-between items-center">
        <h3 className="text-sm font-bold">Team Members</h3>
        <button className="px-3 py-2 bg-black text-white rounded-xl text-[10px] font-bold flex items-center gap-2 shadow-md">
          <Plus size={12} /> Invite
        </button>
      </div>
      <div className="space-y-3">
        <TeamRow name="Admin User" email="admin@freshcatch.in" role="Owner" />
        <TeamRow name="Store Manager" email="manager@freshcatch.in" role="Manager" />
        <TeamRow name="Support Agent" email="support@freshcatch.in" role="Support" />
      </div>
    </section>
  </div>
);

/* ── 11. SECURITY ── */
const SecurityView = () => (
  <div className="space-y-6">
    <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-6">
      <h3 className="text-sm font-bold">Authentication</h3>
      <ToggleItem label="Two-Factor Authentication (2FA)" sub="Require 2FA for admin access" defaultOn={false} />
      <ToggleItem label="Login Activity Alerts" sub="Get notified on new device logins" defaultOn={true} />
    </section>
    <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-4">
      <h3 className="text-sm font-bold">Password Policy</h3>
      <div className="grid grid-cols-2 gap-4">
        <InputGroup label="Min Password Length" value="8" />
        <InputGroup label="Require Password Change (days)" value="90" />
      </div>
    </section>
  </div>
);

/* ── 12. SEO ── */
const SeoView = () => (
  <div className="space-y-6">
    <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-4">
      <h3 className="text-sm font-bold">Meta Tags</h3>
      <InputGroup label="Site Title" value="FreshCatch Seafood - Fresh Fish Delivered" />
      <InputGroup label="Meta Description" value="Order fresh fish, prawns, and seafood online. Same-day delivery in select cities." />
    </section>
    <section className="bg-white border border-[#EEEEEE] rounded-2xl p-6 shadow-sm space-y-4">
      <h3 className="text-sm font-bold">Social & Sharing</h3>
      <div className="grid grid-cols-2 gap-4">
        <InputGroup label="OG Image URL" value="" placeholder="https://..." />
        <InputGroup label="Twitter Handle" value="@freshcatch_in" />
      </div>
    </section>
  </div>
);

/* ── HELPER COMPONENTS ── */
const NavGroup = ({ label, children, isOpen }: { label: string; children: React.ReactNode; isOpen: boolean }) => (
  <div className="py-4 space-y-2">
    {isOpen && <h4 className="px-4 text-[10px] font-bold uppercase text-[#A1A1AA] tracking-widest">{label}</h4>}
    {children}
  </div>
);

const NavItem = ({ id, icon, label, active, onClick, isOpen }: {
  id: string; icon: React.ReactNode; label: string; active: string; onClick: (id: any) => void; isOpen: boolean;
}) => (
  <button
    onClick={() => onClick(id)}
    title={label}
    className={`w-full flex items-center gap-3 px-4 py-2.5 rounded-xl transition-all ${active === id
      ? "bg-black text-white shadow-md"
      : "text-[#71717A] hover:bg-[#F4F4F5] hover:text-black"
      }`}
  >
    {icon}
    {isOpen && <span className="text-sm font-medium truncate">{label}</span>}
  </button>
);

const InputGroup = ({ label, onChange, ...props }: { label: string; onChange?: (v: string) => void;[key: string]: any }) => (
  <div className="space-y-1.5">
    <label className="text-[10px] font-bold uppercase text-[#A1A1AA] tracking-wider">{label}</label>
    <div className="relative">
      <input
        className="w-full px-4 py-2.5 bg-[#F9F9F9] border-none rounded-xl text-sm focus:ring-1 focus:ring-black outline-none transition-all"
        onChange={onChange ? (e) => onChange(e.target.value) : undefined}
        {...props}
      />
    </div>
  </div>
);

const ToggleItem = ({ label, sub, defaultOn, onToggle }: { label: string; sub: string; defaultOn: boolean; onToggle?: () => void }) => {
  const [isOn, setIsOn] = useState(defaultOn);
  const handleToggle = () => {
    setIsOn(!isOn);
    onToggle?.();
  };

  return (
    <div className="flex items-center justify-between">
      <div>
        <p className="text-sm font-bold">{label}</p>
        <p className="text-xs text-[#A1A1AA]">{sub}</p>
      </div>
      <button
        onClick={handleToggle}
        className={`w-12 h-6 rounded-full relative cursor-pointer transition-colors ${isOn ? "bg-black" : "bg-[#E5E5E5]"}`}
      >
        <div className={`absolute top-1 w-4 h-4 bg-white rounded-full transition-all shadow-sm ${isOn ? "left-7" : "left-1"}`} />
      </button>
    </div>
  );
};

const NotificationToggle = ({ label, channels }: { label: string; channels: string[] }) => (
  <div className="flex items-center justify-between py-4 first:pt-0 last:pb-0">
    <p className="text-xs font-medium">{label}</p>
    <div className="flex gap-2">
      {["SMS", "WhatsApp", "Email"].map((ch) => (
        <button
          key={ch}
          className={`px-3 py-1 rounded-lg text-[10px] font-bold border transition-all ${channels.includes(ch)
            ? "bg-black text-white border-black"
            : "text-[#A1A1AA] border-[#EEEEEE] hover:bg-gray-50"
            }`}
        >
          {ch}
        </button>
      ))}
    </div>
  </div>
);

const TeamRow = ({ name, email, role }: { name: string; email: string; role: string }) => (
  <div className="flex items-center justify-between p-4 border border-[#EEEEEE] rounded-xl hover:border-black transition-all">
    <div className="flex items-center gap-3">
      <div className="w-10 h-10 bg-[#F4F4F5] rounded-full flex items-center justify-center text-black font-bold text-sm">
        {name[0]}
      </div>
      <div>
        <p className="text-xs font-bold">{name}</p>
        <p className="text-[10px] text-[#A1A1AA]">{email}</p>
      </div>
    </div>
    <span className="text-[10px] font-bold uppercase px-3 py-1 bg-[#F4F4F5] rounded-lg">{role}</span>
  </div>
);

export default SettingsPage;