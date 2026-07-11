const links = [
  { to: '/projects', label: 'Loyihalar' },
  { to: '/superadmin/dashboard?tab=withdrawals', label: "Yechish so'rovlari" },
  { to: '/superadmin/dashboard?tab=deposits', label: "To'lov so'rovlari" },
  { to: '/superadmin/dashboard?tab=kyc', label: 'KYC Vetting' }
];

function test(pathname, search) {
  console.log(`\nTesting with pathname: "${pathname}", search: "${search}"`);
  
  // Mock activeTab extraction
  const params = new URLSearchParams(search);
  const activeTab = params.get('tab');
  
  links.forEach(({ to, label }) => {
    const isLinkActive = (() => {
      if (to.includes('?tab=')) {
        const targetTab = to.split('tab=')[1]?.split('&')[0];
        const currentTabValue = activeTab || 'withdrawals';
        return pathname === to.split('?')[0] && currentTabValue === targetTab;
      }
      return pathname === to;
    })();
    
    console.log(`  - [${isLinkActive ? 'ACTIVE' : '      '}] ${label} (to: ${to})`);
  });
}

test('/superadmin/dashboard', '');
test('/superadmin/dashboard', '?tab=deposits');
test('/superadmin/dashboard', '?tab=kyc');
test('/projects', '');
