import { Sprout, LayoutDashboard, Wallet, MessageSquareWarning, FileCheck2, ShieldCheck, Crown } from 'lucide-react';

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
  ADMIN: [
    { to: '/projects', label: 'Loyihalar', icon: Sprout },
    { to: '/admin/dashboard', label: 'Admin paneli', icon: ShieldCheck },
  ],
  MODERATOR: [
    { to: '/projects', label: 'Loyihalar', icon: Sprout },
    { to: '/admin/dashboard', label: 'Admin paneli', icon: ShieldCheck },
  ],
  SUPERADMIN: [
    { to: '/projects', label: 'Loyihalar', icon: Sprout },
    { to: '/superadmin/dashboard', label: 'SuperAdmin paneli', icon: Crown },
  ],
};

export const getNavLinks = (role) => NAV_LINKS_BY_ROLE[role] || [{ to: '/projects', label: 'Loyihalar', icon: Sprout }];
