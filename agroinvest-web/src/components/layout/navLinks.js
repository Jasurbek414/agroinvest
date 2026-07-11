import { Sprout, LayoutDashboard, Wallet, MessageSquareWarning, FileCheck2, ShieldCheck, Crown, FolderKanban, ClipboardList, Receipt, HeartPulse, Scale, Landmark, KeyRound, FolderTree, Users, Megaphone, ArrowLeftRight, Send, ShoppingBag, Info, BarChart3 } from 'lucide-react';

// Central role -> nav-link map used by both the desktop Sidebar and the mobile
// drawer, so the two never drift out of sync with each other.
const NAV_LINKS_BY_ROLE = {
  INVESTOR: [
    { to: '/projects', label: 'Loyihalar bozori', icon: Sprout },
    { to: '/coop-market', label: 'Investitsiya bozori', icon: BarChart3 },
    { to: '/investor/investments', label: 'Sarmoyalarim', icon: LayoutDashboard },
    { to: '/market', label: 'Market / Bozor', icon: ShoppingBag },
    { to: '/wallet', label: 'Hamyon', icon: Wallet },
    { to: '/disputes', label: 'Shikoyatlar', icon: MessageSquareWarning },
    { to: '/services', label: 'Qo\'shimcha xizmatlar', icon: Crown },
    { to: '/about', label: 'Platforma haqida', icon: Info },
    { to: '/settings', label: 'Profil sozlamalari', icon: KeyRound },
  ],
  FARMER: [
    { to: '/farmer/dashboard', label: 'Mening loyihalarim', icon: LayoutDashboard },
    { to: '/projects', label: 'Loyihalar bozori', icon: Sprout },
    { to: '/coop-market', label: 'Investitsiya bozori', icon: BarChart3 },
    { to: '/market', label: 'Market / Bozor', icon: ShoppingBag },
    { to: '/wallet', label: 'Hamyon', icon: Wallet },
    { to: '/disputes', label: 'Shikoyatlar', icon: MessageSquareWarning },
    { to: '/services', label: 'Qo\'shimcha xizmatlar', icon: Crown },
    { to: '/about', label: 'Platforma haqida', icon: Info },
    { to: '/settings', label: 'Profil sozlamalari', icon: KeyRound },
  ],
  VERIFIER: [
    { to: '/verifier/dashboard', label: 'Dala hisobotlari', icon: HeartPulse },
  ],
  ADMIN: [
    { to: '/projects', label: 'Loyihalar bozori', icon: Sprout },
    { to: '/admin/dashboard?tab=withdrawals', label: "Yechish so'rovlari", icon: Wallet },
    { to: '/admin/dashboard?tab=deposits', label: "To'lov so'rovlari", icon: Landmark },
    { to: '/admin/dashboard?tab=kyc', label: 'KYC Vetting', icon: ShieldCheck },
    { to: '/admin/dashboard?tab=projects', label: 'Kutilayotgan loyihalar', icon: FolderKanban },
    { to: '/admin/dashboard?tab=reports', label: 'Kutilayotgan hisobotlar', icon: ClipboardList },
    { to: '/admin/dashboard?tab=expenses', label: 'Harajatlar', icon: Receipt },
    { to: '/admin/dashboard?tab=vetInspections', label: 'Veterinar nazorati', icon: HeartPulse },
    { to: '/admin/dashboard?tab=disputes', label: 'Shikoyatlar', icon: Scale },
  ],
  MODERATOR: [
    { to: '/projects', label: 'Loyihalar bozori', icon: Sprout },
    { to: '/admin/dashboard?tab=withdrawals', label: "Yechish so'rovlari", icon: Wallet },
    { to: '/admin/dashboard?tab=deposits', label: "To'lov so'rovlari", icon: Landmark },
    { to: '/admin/dashboard?tab=kyc', label: 'KYC Vetting', icon: ShieldCheck },
    { to: '/admin/dashboard?tab=projects', label: 'Kutilayotgan loyihalar', icon: FolderKanban },
    { to: '/admin/dashboard?tab=reports', label: 'Kutilayotgan hisobotlar', icon: ClipboardList },
    { to: '/admin/dashboard?tab=expenses', label: 'Harajatlar', icon: Receipt },
    { to: '/admin/dashboard?tab=vetInspections', label: 'Veterinar nazorati', icon: HeartPulse },
    { to: '/admin/dashboard?tab=disputes', label: 'Shikoyatlar', icon: Scale },
  ],
  // SuperAdmin links carry an optional `section` label; Sidebar/MobileDrawer render
  // a small group header whenever it changes, so the long list stays scannable.
  SUPERADMIN: [
    { to: '/superadmin/dashboard?tab=overview', label: "Umumiy ko'rinish", icon: LayoutDashboard, section: 'Boshqaruv' },
    { to: '/projects', label: 'Loyihalar bozori', icon: Sprout, section: 'Boshqaruv' },
    { to: '/superadmin/dashboard?tab=coop', label: 'Investitsiya bozori', icon: BarChart3, section: 'Boshqaruv' },
    { to: '/superadmin/dashboard?tab=withdrawals', label: "Yechish so'rovlari", icon: Wallet, section: 'Operatsion navbatlar' },
    { to: '/superadmin/dashboard?tab=deposits', label: "To'lov so'rovlari", icon: Landmark, section: 'Operatsion navbatlar' },
    { to: '/superadmin/dashboard?tab=kyc', label: 'KYC Vetting', icon: ShieldCheck, section: 'Operatsion navbatlar' },
    { to: '/superadmin/dashboard?tab=projects', label: 'Kutilayotgan loyihalar', icon: FolderKanban, section: 'Operatsion navbatlar' },
    { to: '/superadmin/dashboard?tab=reports', label: 'Kutilayotgan hisobotlar', icon: ClipboardList, section: 'Operatsion navbatlar' },
    { to: '/superadmin/dashboard?tab=expenses', label: 'Harajatlar', icon: Receipt, section: 'Operatsion navbatlar' },
    { to: '/superadmin/dashboard?tab=vetInspections', label: 'Veterinar nazorati', icon: HeartPulse, section: 'Operatsion navbatlar' },
    { to: '/superadmin/dashboard?tab=disputes', label: 'Shikoyatlar', icon: Scale, section: 'Operatsion navbatlar' },
    { to: '/superadmin/dashboard?tab=transactions', label: 'Tranzaksiyalar', icon: ArrowLeftRight, section: 'Moliya' },
    { to: '/superadmin/dashboard?tab=broadcast', label: 'Xabarnoma yuborish', icon: Send, section: 'Kontent' },
    { to: '/superadmin/dashboard?tab=categories', label: 'Kategoriyalar', icon: FolderTree, section: 'Kontent' },
    { to: '/superadmin/dashboard?tab=banners', label: 'Reklamalar', icon: Megaphone, section: 'Kontent' },
    { to: '/superadmin/dashboard?tab=news', label: 'Yangiliklar', icon: ClipboardList, section: 'Kontent' },
    { to: '/superadmin/dashboard?tab=accounts', label: 'Hisoblar', icon: Users, section: 'Tizim' },
    { to: '/superadmin/dashboard?tab=permissions', label: 'Ruxsatlar', icon: KeyRound, section: 'Tizim' },
    { to: '/superadmin/dashboard?tab=settings', label: 'Tizim sozlamalari', icon: Crown, section: 'Tizim' },
  ],
};

export const getNavLinks = (role) => NAV_LINKS_BY_ROLE[role] || [{ to: '/projects', label: 'Loyihalar bozori', icon: Sprout }];
