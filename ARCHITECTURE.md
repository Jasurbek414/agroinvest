# Arxitektura

## Umumiy ko'rinish

```
                    ┌─────────────────┐
                    │   Cloudflare     │
                    │   Tunnel (edge)  │
                    └────────┬─────────┘
                             │
              ┌──────────────┴──────────────┐
              │                              │
      ┌───────▼────────┐            ┌────────▼────────┐
      │  agroinvest-web │            │ agroinvest-mobile│
      │  (nginx, :3001) │            │ (Android/iOS)    │
      └───────┬────────┘            └────────┬─────────┘
              │         REST + JWT            │
              └──────────────┬────────────────┘
                              │
                    ┌─────────▼──────────┐
                    │ agroinvest-backend  │
                    │ Spring Boot (:8080) │
                    └──────┬───────┬──────┘
                           │       │
                 ┌─────────▼──┐ ┌──▼──────┐
                 │ PostgreSQL │ │  Redis   │
                 │  (:5436)   │ │ (:6379)  │
                 └────────────┘ └──────────┘
```

Barcha xizmatlar bitta `docker-compose.yml` orqali boshqariladi (postgres, redis, backend, frontend). Mobil ilova alohida build qilinib, do'kon/APK orqali tarqatiladi va backend'ga to'g'ridan-to'g'ri HTTPS orqali ulanadi.

## Backend (`agroinvest-backend`)

- **Modulli tuzilma**: `src/main/java/uz/agroinvest/module/<domen>` — har bir domen (auth, project, investment, wallet, withdrawal, deposit, review, dispute, expense, vet, report, banner, permission, category, superadmin, ...) o'z entity/repository/service/controller/dto to'plamiga ega.
- **Autentifikatsiya**: JWT (access 15 daqiqa, refresh 30 kun), `JwtAuthFilter` + `RestAuthenticationEntryPoint` (autentifikatsiya yo'q → 401, ruxsat yo'q → 403 — ikkalasi ham `ApiResponse` formatida).
- **Ruxsat tizimi**: ikki qatlamli — eski `hasRole()`/`hasAnyRole()` (aksariyat endpointlar) va yangi `@authz.has('modul.amal')` (Redis'da 6 soatga keshlangan, `PermissionService`) — SuperAdmin panelidan dinamik boshqariladi.
- **Migratsiyalar**: Flyway, `src/main/resources/db/migration/V*.sql` — hech qachon tahrirlanmaydi, faqat qo'shiladi.
- **Fayl saqlash**: S3-mos obyekt xotira (`FileStorageService`), kategoriya bo'yicha (`kyc`, `project`, `report`, `expense`, `vet`, `deposit`, `banner`, `general`).

## Web (`agroinvest-web`)

- **Marshrutlash**: `src/App.jsx` — rol asosida himoyalangan (`ProtectedRoute`), ommaviy (`/`, `/projects`, `/projects/:id`) va autentifikatsiya (`/login`, `/register`) yo'llari.
- **Holat**: Zustand (`store/auth.store.js`, `store/theme.store.js`) — global holat uchun; sahifa-darajasidagi ma'lumotlar uchun `useState`+API chaqiruvlari.
- **Dizayn tizimi**: Tailwind CSS v4 (CSS-first, `src/index.css`dagi `@theme`), umumiy komponentlar `src/components/ui/` (Badge, Button, DataTable, Card, ...), dark mode `class` strategiyasi bilan.
- **SuperAdmin paneli** (`pages/superadmin/SuperAdminDashboard.jsx`) — barcha operatsion navbatlar (yechish/to'lov so'rovlari, KYC, loyihalar, hisobotlar, harajatlar, vet, shikoyatlar) + boshqaruv vositalari (ruxsatlar, kategoriyalar, reklamalar, sozlamalar, audit, hisoblar) bitta `?tab=` asosidagi sahifada.

## Mobil (`agroinvest-mobile`)

- **Marshrutlash**: `go_router` (`lib/app.dart`), `StatefulShellRoute` bilan pastki navigatsiya (Bosh sahifa/Loyihalar/Market/Profil).
- **Holat boshqaruvi**: `provider` paketi, har bir feature o'z `ChangeNotifier` providerига ega (`lib/features/<feature>/presentation/providers/`).
- **Rol qamrovi**: faqat INVESTOR va FARMER uchun — admin/superadmin funksiyalari web-only (qasddan qaror).
- **Dark mode**: `AppTheme.dark()` + `ThemeProvider` (`shared_preferences`da saqlanadi) — Material-standart vidjetlarni (Scaffold, AppBar, TextField, Button, Card) qamrab oladi; qattiq kodlangan `AppColors.*` ishlatuvchi ekranlar hali to'liq moslashmagan (i18n kabi "mexanizm, to'liq qamrov emas").
- **Push-bildirishnoma**: `PushNotificationService` ulangan (login/sessiya tiklashda chaqiriladi), lekin haqiqiy Firebase loyihasi (`google-services.json`/`GoogleService-Info.plist`) ulanmaguncha jim ishlamay turadi.

## Ma'lumotlar oqimi misoli: To'ldirish (deposit) so'rovi

Haqiqiy Payme/Click integratsiyasi hozircha ulanmagan (`PaymentService`/`PaymentController` kodda bor, lekin merchant hisob ma'lumotlari yo'q). Buning o'rniga:

1. Investor/fermer summani va (ixtiyoriy) to'lov chekini kiritib so'rov yuboradi (`POST /api/v1/deposit-requests`) — hamyonga hali tegilmaydi.
2. Admin/SuperAdmin "To'lov so'rovlari" navbatida ko'rib, tasdiqlaydi yoki rad etadi (`PATCH /api/v1/deposit-requests/{id}`).
3. Tasdiqlansa — `WalletRepository.findByUserIdForUpdate` orqali pessimistik lock bilan balans oshiriladi, `Transaction(type=DEPOSIT, provider=MANUAL)` yoziladi, audit logga tushadi.

## Ruxsatlar (permission) tizimi

- Bazaviy 6 rol (`UserRole` enum) — o'zgarmas.
- `permissions` jadvali — `modul.amal` formatidagi kodlar (masalan `deposit.review`, `category.manage`, `banner.manage`).
- `role_permissions` — qaysi rolga qaysi ruxsat berilgan (SuperAdmin panelidan matritsa ko'rinishida boshqariladi).
- `custom_roles`/`custom_role_permissions`/`user_custom_roles` — bazaviy rol ustiga qo'shimcha ruxsatlar to'plamini istalgan foydalanuvchiga biriktirish imkonini beradi.
- **Muhim**: yangi migratsiya orqali `role_permissions`ga to'g'ridan-to'g'ri SQL bilan yozilgan grant'lar Redis keshini bilmaydi — shuning uchun `PermissionService` har backend ishga tushganda (`ApplicationRunner`) barcha `role_permissions:*` kesh yozuvlarini avtomatik tozalaydi.
