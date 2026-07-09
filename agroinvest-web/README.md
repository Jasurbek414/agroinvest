# AgroInvest — Web

React 19 + Vite + Tailwind CSS v4 + Zustand asosidagi veb-ilova: ommaviy landing page, loyihalar katalogi, investor/fermer/admin/superadmin panellari.

To'liq loyiha va arxitektura haqida: [../README.md](../README.md), [../ARCHITECTURE.md](../ARCHITECTURE.md).

## Ishga tushirish (dev)

```bash
npm install
cp .env.example .env.development   # VITE_API_URL ni backend manzilingizga moslang
npm run dev
```

`VITE_API_URL` — backend API manzili (standart: `http://localhost:8080/api/v1`).

## Build

```bash
npm run build   # dist/ papkasiga
npm run preview # build natijasini lokal ko'rish
```

## Tuzilma

- `src/pages/` — marshrut darajasidagi sahifalar (rol bo'yicha papkalangan: `public/`, `auth/`, `investor/`, `farmer/`, `admin/`, `superadmin/`, `profile/`, `disputes/`, `verifier/`).
- `src/components/` — qayta ishlatiladigan komponentlar; `ui/` — umumiy dizayn tizimi (Badge, Button, DataTable, Card, ...), qolganlari domen bo'yicha (`projects/`, `farmer/`, `superadmin/`, `landing/`, `reviews/`, ...).
- `src/api/` — har bir backend moduliga mos `*.api.js` fayllar (axios asosida, `src/api/axios.js`da markazlashgan token/refresh mantiqi).
- `src/store/` — Zustand global holatlari (`auth.store.js`, `theme.store.js`).

## Kod uslubi

- Yangi funksiya qo'shishda mavjud `ui/` komponentlaridan foydalaning (masalan status ko'rsatish uchun har doim `Badge`, o'zingizning rang-mantig'ingizni yozmang).
- Dark mode har doim `dark:` prefiksi bilan, `primary-*` rang tokenlaridan foydalaning (`green-*`/`red-*` kabi qattiq kodlangan Tailwind ranglarini emas).
- 300+ qatorli komponentlar kichik qism-komponentlarga bo'linadi (masalan `components/farmer/create-project/`).
