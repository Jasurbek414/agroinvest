# AgroInvest — Platforma yo'l xaritasi

> Bu fayl "konstitutsiya" talablari (2026-07-08) bo'yicha ko'p bosqichli, ko'p sessiyali ish rejasi. Har sessiyada shu fayldan davom etiladi — bajarilgan bandlar `[x]` bilan belgilanadi, izoh qo'shiladi.

## Muhim arxitektura qarorlari

1. **Dinamik rollar** = qattiq 6 baza rol (`UserRole` enum, o'zgarmaydi) ustiga qo'shiladigan `custom_roles`/`custom_role_permissions`/`user_custom_roles`. Eski `hasRole()` endpointlar custom-rol ruxsatlarini ko'rmaydi, toki `hasPermission()`ga ko'chirilmaguncha.
2. **Audit log** — mavjud aniq-chaqiruv patternini (`AuditLogService.log()`) davom ettiramiz, AOP qo'shmaymiz.
3. **FROZEN** — `ProjectStatus` enum qiymati emas, `projects.is_frozen` orthogonal bayrog'i (xuddi `users.is_blocked` kabi).
4. **Kategoriya taksonomiyasi** — additive: yangi `asset_categories` + `projects.category_id` (nullable), eski `asset_type`/`animal_type` va ularga tayanuvchi kod Phase 5gacha tegilmaydi.
5. **ProjectStatus kengaytirish** — `ALTER TYPE proj_status ADD VALUE` faqat DDL, alohida migratsiyada, o'sha migratsiyada foydalanilmaydi (V8/V13 pattern).

Tasdiqlangan kategoriya tuzilmasi — pastda 0.4 bo'limida.

---

## Phase 0 — Poydevor

- [x] 0.0 Xavfsizlik: prompt-injection topilmasi tekshirildi (repo bo'ylab qidiruv — zararli fayl topilmadi; ehtimol sub-agent haqiqiy system-reminder tegini noto'g'ri talqin qilgan)
- [x] 0.1 Ruxsatlar tizimi
  - [x] Flyway: `permissions`, `role_permissions` (baza 6 rol uchun joriy huquqlar bilan seed — V14/V15), `custom_roles`, `custom_role_permissions`, `user_custom_roles`
  - [x] `hasPermission(String code)` SpEL bean-reference expression (`@authz.has(...)`, `AuthorizationBean`)
  - [x] Rol→ruxsat Redis kesh (`PermissionService.getRolePermissions`, 6 soat TTL)
  - [x] SuperAdmin: permission yaratish/rolga bog'lash/custom-rol foydalanuvchiga biriktirish endpointlari (`PermissionController`)
  - [x] **Reja tashqarisidagi xavfsizlik tuzatishi** (0.1 sinovi paytida topildi): `POST .../custom-roles` javobida to'liq `User` obyekti (bcrypt `passwordHash`, shifrlangan `passportData`) xom holda JSON'ga chiqib ketayotgan edi — bu **oldindan mavjud** kamchilik, `SuperAdminController.getAuditLogs()`/`getSettings()` xam xuddi shu tarzda xom `AuditLog`/`PlatformSettings` entitylarni (`User` bog'lanishi bilan) qaytarardi. Ikkalasi ustida ham `open-in-view: false` sababli `LazyInitializationException` xavfi bor edi (`AuditLog.user` — `nullable=false`, ya'ni har bir qatorda kafolatlangan portlash). Tuzatildi: `User.passwordHash`/`passportData`ga global `@JsonIgnore` (himoya qatlami) + yangi `AuditLogDto`/`PlatformSettingsDto`/`PermissionDto`/`CustomRoleDto` + ikkala repozitoriyaga `@EntityGraph(attributePaths={"user"|"updatedBy"})` `findAll(Pageable)` override. Haqiqiy throwaway bazada qo'lda tekshirildi (login→audit-log yozuv yaratish→ro'yxatni olish — portlashsiz, `passwordHash` chiqmaydi).
- [x] 0.2 Audit log to'ldirish
  - [x] `AuditLogService.log()` — ipAddress/userAgent avtomatik `RequestContextHolder` orqali (X-Forwarded-For → getRemoteAddr fallback) — controller/service signaturelarini o'zgartirmasdan, chunki barcha chaqiruvlar faqat HTTP so'rov threadida ishlaydi (ReportMonitoringScheduler kabi background joblardan hech qachon chaqirilmaydi)
  - [x] `ProjectService.changeStatus` (`PROJECT_STATUS_<status>`), `InvestmentService` (`CREATE_INVESTMENT`/`CANCEL_INVESTMENT`), `PayoutService.distributePayout` (`DISTRIBUTE_PAYOUT` — endi `UserPrincipal` qabul qiladi), `ExpenseService.reviewExpense` (`APPROVE_EXPENSE`/`REJECT_EXPENSE`), `ReportService.verifyReport` (`VERIFY_REPORT`/`REJECT_REPORT`), `VetInspectionService.verifyInspection` (`VERIFY_VET_INSPECTION`/`REJECT_VET_INSPECTION`) — audit chaqiruvlari qo'shildi. Throwaway bazada tekshirildi: `ipAddress`/`userAgent` to'g'ri yoziladi (masalan `0:0:0:0:0:0:0:1` + maxsus User-Agent).
- [x] 0.3 ProjectStatus + FROZEN
  - [x] `ALTER TYPE proj_status ADD VALUE 'DRAFT','MONITORING'` (V16, faqat DDL) + `projects.is_frozen/frozen_reason/frozen_at/frozen_by` (V17 — `frozen_from_status` amalda keraksiz bo'lib chiqdi va olib tashlandi: status muzlatish paytida umuman o'zgarmagani uchun "qaytarish" uchun eslab qolish shart emas)
  - [x] `ProjectService.changeStatus`: MONITORING (faqat ACTIVE'dan) qo'shildi; **shu yerda topilgan qo'shimcha xato**: 0.2'da qo'shilgan audit-log chaqiruvi if/else-if zanjiridagi HECH BIR shartga mos kelmagan holatda ham (masalan noto'g'ri status=PENDING yuborilsa) ishga tushib, sodir bo'lmagan o'zgarishni yolg'on qayd etardi — tuzatildi: tanilmagan target uchun aniq `BAD_REQUEST`
  - [x] `PayoutService.distributePayout`: ACTIVE tekshiruvi ACTIVE||MONITORING'ga kengaytirildi + `is_frozen` tekshiruvi qo'shildi
  - [x] `PATCH /projects/{id}/freeze` (admin/superadmin) + `POST /projects/{id}/submit` (fermerning "e'lon qilish" tugmasi, DRAFT→PENDING) + `InvestmentService.createInvestment`'ga `is_frozen` tekshiruvi. **Rejadan chetlanish**: withdrawal `is_frozen`ni tekshirmaydi — `WithdrawalRequest` hech qanday loyihaga bog'lanmagan (faqat hamyon balansidan), shuning uchun bitta loyihani muzlatish umumiy pul yechishni bloklashi mantiqan noto'g'ri va texnik jihatdan amalga oshirib bo'lmaydi
  - [x] **Qo'shimcha xavfsizlik tuzatishi** (DRAFT qo'shish jarayonida topilgan): `GET /projects` va `GET /projects/{id}` ikkalasi ham `permitAll()` — DRAFT loyiha (fermerning hali yubormagan qoralamasi) tasodifan UUID orqali yoki filtrsiz ro'yxatda hamma uchun ochiq bo'lib qolar edi. Tuzatildi: `ProjectRepository.search()` DRAFT'ni har doim (status filtridan qat'iy nazar) chiqarib tashlaydi; `getProjectById` faqat egasi/xodimga DRAFT ko'rsatadi, boshqalarga 404 (mavjudligini oshkor qilmaslik uchun)
- [x] 0.4 Kategoriya taksonomiyasi (poydevor)
  - [x] `asset_categories` jadvali (V18) + seed (V19, pastdagi tuzilma bo'yicha, 42 qator, kod-asosli parent lookup) + `projects.category_id` nullable FK (V20) — `asset_type`/`animal_type` va ularga tayanuvchi qidiruv/dashboard kodi tegilmadi
  - [x] `AssetCategoryService`/`Controller`: `GET /api/v1/categories` (public, `permitAll`) — to'liq daraxtni bitta so'rovda qaytaradi. Hozircha faqat o'qish uchun (boshqaruv UI — Phase 2; `category_id`ni loyiha yaratishda o'rnatish va qidiruvga ulash — Phase 5), lekin real endpoint sifatida ishlaydi (skelet emas)
  - [x] **Real bug, haqiqiy bazada topildi**: V18 dastlab `level`/`sort_order` ustunlarini `SMALLINT` deb e'lon qilgan edi, lekin entity `Integer` maydoni sifatida — Hibernate `ddl-auto: validate` bilan ishga tushishda `int2 != int4` deb qulab tushdi. Faqat haqiqiy Postgres'ga qarshi ishga tushirilganda aniqlandi (Mockito testlar buni hech qachon ushlamaydi). Tuzatildi: ikkalasi ham `INTEGER`
- [x] 0.5 i18n skeleton
  - [x] Mobil: `easy_localization` (+ transitiv `shared_preferences`) ulandi, `EasyLocalization` `main.dart`da `runApp`ni o'raydi, `MaterialApp.router`ga `localizationsDelegates`/`supportedLocales`/`locale` ulandi (`app.dart`), `assets/translations/uz.json` (pubspec'da ro'yxatga olingan)
  - [x] Veb: `react-i18next`+`i18next` o'rnatildi, `src/i18n/index.js` + `src/i18n/locales/uz.json`, `main.jsx`da import qilinadi
  - [x] Til tanlagich: veb — `UserMenu.jsx` dropdown'ida (`theme.store.js`dagi dark-mode toggle pattern bilan bir xil joyda); mobil — `ProfilePage`da "Til" menyu bandi → bottom sheet. Ikkalasida ham hozircha faqat "O'zbek" ko'rinadi, lekin `LANGUAGES`/`_availableLanguages` ro'yxatiga yangi til qo'shish yetarli (qayta ulash shart emas) — bu **mexanizm**, to'liq tarjima qamrovi emas (Phase 3)
  - [x] Ikkala tomonda ham kamida bitta real ekranga ulandi (skelet emas): veb `UserMenu`dagi "Kirish"/"Chiqish"/tungi-rejim matnlari endi `t(...)` orqali chiqadi
  - **Izoh**: `agroinvest-mobile/lib/app.dart` va `profile_page.dart`da ushbu sessiyaning oldingi (hali commit qilinmagan) "Market" tab ishi bilan bir xil fayllarga tegilgan edi — ikkalasi git indeksida alohida ajratildi (faqat i18n gunk'lari commit qilindi), "Market" ishi ishchi papkada tegilmagan holda qoldi, alohida ko'rib chiqilishi kerak

### Tasdiqlangan kategoriya tuzilmasi (0.4)

```
Chorvachilik
  Qoramolchilik        → Sut / Go'sht / Nasldor / Buqa semirtirish
  Qo'ychilik           → Go'sht / Jun / Nasldor
  Echkichilik          → Sut / Go'sht / Nasldor
  Quyonchilik
  Parrandachilik       → Tovuq / Bedana / Kurka / O'rdak / G'oz / Tuyaqush
  Otxonachilik
  Tuyachilik
Dehqonchilik           → G'alla / Sabzavot / Poliz / Dukkakli / Moyli ekinlar / Dorivor o'simliklar
Bog'dorchilik          → Urug'li mevalar / Danakli mevalar / Yong'oqli daraxtlar / Sitrus mevalar
Uzumchilik
Issiqxona
O'rmon plantatsiyalari
Asalarichilik
Baliqchilik
Boshqa
```

---

## Phase 1 — Mavjud modullarni to'liq checklistga moslashtirish

- [ ] Qidiruv/filtr kengaytirish (summa oralig'i, muddat, foiz, xavf, reyting) — `ProjectRepository.search`
- [ ] CSV eksport — har bir admin ro'yxat endpointi + `DataTable.jsx` "Eksport" tugmasi
- [ ] Bulk actions — mavjud `DataTable.jsx` `bulkActions` propini har bir admin tab'ga ulash
- [ ] CSV import — past-xavfli amallardan boshlab (masalan bulk KYC ro'yxati)
- [ ] Yangi/tegilgan endpointlarni `hasPermission()` bilan belgilash
- [ ] Draft/autosave — loyiha yaratish + kunlik hisobot formalari

## Phase 2 — SuperAdmin ilg'or vositalari

- [ ] Rol/permission boshqaruv UI
- [ ] Kategoriya boshqaruv UI
- [ ] `feature_flags` jadvali (modul yoqish/o'chirish)
- [ ] Bannerlar/reklama/hamkorlar mini-CMS
- [ ] Actuator + Micrometer (SuperAdmin-only health/metrics)
- [ ] Backup siyosati hujjatlashtirish (infra/DevOps, UI feature emas)

## Phase 3 — Tizim talablarini yakunlash

- [ ] To'liq tarjima qamrovi (uz + ru + en)
- [ ] Mobil dark mode (`AppTheme.dark()` + `darkTheme:`/`themeMode:`)
- [ ] WebSocket/STOMP real-time (bildirishnoma poll→push)

## Phase 4 — Chat + AI markazi

- [ ] Chat: `Conversation`/`Message`, WebSocket orqali, investor↔fermer/fermer↔admin/investor↔admin
- [ ] AI (a): DAILY hisobot metrikalaridan o'sish/xarajat trendi (yangi AI kerak emas — birinchi qilinadi)
- [ ] AI (b): hisobot fotosidan kasallik aniqlash (tashqi vision API)
- [ ] AI (c): LLM-asosli tavsiya matni
- [ ] AI (d): AI yordamchi chat

## Phase 5 — Taksonomiya migratsiyasini yakunlash

- [ ] `ProjectRepository`/`DashboardService`ni `category_id`ga ko'chirish
- [ ] Eski loyihalarni backfill qilish (ko'rib chiqilgan xaritalash)
- [ ] Eski `asset_type`/`animal_type` ustunlarini eskirgan deb belgilash (o'chirilmaydi)

---

## Tekshirish mezonlari

| Bosqich | Qanday tekshiriladi |
|---|---|
| Phase 0 | `mvn test` yashil; migratsiyalar toza + haqiqiy bazada; Swagger orqali `hasPermission()` qo'lda; mavjud `hasRole()` regressiyasi |
| Phase 1 | Har bir admin tab qo'lda: eksport CSV, bulk faqat tanlangan qatorlarga, filtrlar to'g'ri |
| Phase 2 | SuperAdmin permission yaratadi→rolga bog'laydi→foydalanuvchi huquqi qayta deploysiz o'zgaradi |
| Phase 3 | Til almashtirish restart'siz; dark mode tizim+qo'lda; WebSocket polling'siz yetib boradi |
| Phase 4 | Chat xabari real vaqtda yetib boradi; AI indikatori ko'rinadi |
