import { Sprout, LayoutDashboard, Wallet, MessageSquareWarning, FileCheck2, ShieldCheck, Crown, FolderKanban, ClipboardList, Receipt, HeartPulse, Scale, Landmark, KeyRound, FolderTree, Users, Megaphone } from 'lucide-react';

// Central role -> nav-link map used by both the desktop Sidebar and the mobile
// drawer, so the two never drift out of sync with each other.
const NAV_LINKS_BY_ROLE = {
  INVESTOR: [
    { to: '/projects', label: 'Loyihalar', icon: Sprout },
    { to: '/investor/investments', label: 'Sarmoyalarim', icon: LayoutDashboard },
    { to: '/investor/wallet', label: 'Hamyon', icon: Wallet },
    { to: '/disputes', label: 'Shikoyatlar', icon: MessageSquareWarning },
    { to: '/profile/kyc', label: 'KYC', icon: FileCheck2 },
  ],
  FARMER: [
    { to: '/projects', label: 'Loyihalar', icon: Sprout },
    { to: '/farmer/dashboard', label: 'Fermer paneli', icon: LayoutDashboard },
    { to: '/disputes', label: 'Shikoyatlar', icon: MessageSquareWarning },
    { to: '/profile/kyc', label: 'KYC', icon: FileCheck2 },
  ],
  VERIFIER: [
    { to: '/verifier/dashboard', label: 'Dala hisobotlari', icon: HeartPulse },
  ],
  ADMIN: [
    { to: '/projects', label: 'Loyihalar', icon: Sprout },
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
    { to: '/projects', label: 'Loyihalar', icon: Sprout },
    { to: '/admin/dashboard?tab=withdrawals', label: "Yechish so'rovlari", icon: Wallet },
    { to: '/admin/dashboard?tab=deposits', label: "To'lov so'rovlari", icon: Landmark },
    { to: '/admin/dashboard?tab=kyc', label: 'KYC Vetting', icon: ShieldCheck },
    { to: '/admin/dashboard?tab=projects', label: 'Kutilayotgan loyihalar', icon: FolderKanban },
    { to: '/admin/dashboard?tab=reports', label: 'Kutilayotgan hisobotlar', icon: ClipboardList },
    { to: '/admin/dashboard?tab=expenses', label: 'Harajatlar', icon: Receipt },
    { to: '/admin/dashboard?tab=vetInspections', label: 'Veterinar nazorati', icon: HeartPulse },
    { to: '/admin/dashboard?tab=disputes', label: 'Shikoyatlar', icon: Scale },
  ],
  SUPERADMIN: [
    { to: '/projects', label: 'Loyihalar', icon: Sprout },
    { to: '/superadmin/dashboard?tab=withdrawals', label: "Yechish so'rovlari", icon: Wallet },
    { to: '/superadmin/dashboard?tab=deposits', label: "To'lov so'rovlari", icon: Landmark },
    { to: '/superadmin/dashboard?tab=kyc', label: 'KYC Vetting', icon: ShieldCheck },
    { to: '/superadmin/dashboard?tab=projects', label: 'Kutilayotgan loyihalar', icon: FolderKanban },
    { to: '/superadmin/dashboard?tab=reports', label: 'Kutilayotgan hisobotlar', icon: ClipboardList },
    { to: '/superadmin/dashboard?tab=expenses', label: 'Harajatlar', icon: Receipt },
    { to: '/superadmin/dashboard?tab=vetInspections', label: 'Veterinar nazorati', icon: HeartPulse },
    { to: '/superadmin/dashboard?tab=disputes', label: 'Shikoyatlar', icon: Scale },
    { to: '/superadmin/dashboard?tab=permissions', label: 'Ruxsatlar', icon: KeyRound },
    { to: '/superadmin/dashboard?tab=categories', label: 'Kategoriyalar', icon: FolderTree },
    { to: '/superadmin/dashboard?tab=banners', label: 'Reklamalar', icon: Megaphone },
    { to: '/superadmin/dashboard?tab=accounts', label: 'Hisoblar', icon: Users },
    { to: '/superadmin/dashboard?tab=settings', label: 'Tizim sozlamalari', icon: Crown },
  ],
};

export const getNavLinks = (role) => NAV_LINKS_BY_ROLE[role] || [{ to: '/projects', label: 'Loyihalar', icon: Sprout }];
