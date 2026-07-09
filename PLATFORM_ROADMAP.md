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

## Phase 6 — Asosiy tuzatishlar, SuperAdmin konsolidatsiyasi va qo'lda to'lov tizimi (BAJARILDI)

Foydalanuvchi so'rovi bo'yicha to'liq platforma auditi (TZ + roadmap + web/mobil kod strukturasi) o'tkazildi; natijalar va to'liq keyingi fazalar rejasi (C–J, hali boshlanmagan) `.claude/plans/silly-napping-candy.md`da saqlangan.

- [x] 6.1 VERIFIER "o'lik uchi" tuzatildi: `/verifier/dashboard` (yangi sahifa, ACTIVE/FUNDING loyihalar ro'yxati + `ReportUploadModal` orqali `VERIFICATION` hisobot kiritish). Backend: `ReportController.submitReport`ning `hasAnyRole('FARMER','VERIFIER')`si `@authz.has('report.submit')`ga o'tkazildi — Phase 1'ning "yangi/tegilgan endpointlarni hasPermission() bilan belgilash" bandi bo'yicha birinchi real pilot.
- [x] 6.2 SuperAdmin konsolidatsiyasi: `SuperAdminDashboard.jsx` barcha 7 admin tab (withdrawals/kyc/projects/reports/expenses/vetInspections/disputes) + yangi deposits/permissions/categories + mavjud settings/audit/accounts'ni bitta `?tab=` asosidagi sahifaga birlashtirdi; `/admin/dashboard` ADMIN/MODERATOR uchun o'zgarishsiz qoldi.
- [x] 6.3 Rol/Ruxsat boshqaruv UI (Phase 2 bandi): `PermissionsPanel` (rol×ruxsat matritsasi + maxsus rollar CRUD + foydalanuvchiga biriktirish). Backend'ga `GET /superadmin/permissions/roles/{role}` qo'shildi (avval faqat grant/revoke bor edi).
- [x] 6.4 Kategoriya boshqaruv UI (Phase 2 bandi): `AssetCategoryController`ga `POST`/`PATCH` qo'shildi (`category.manage` ruxsati, V21), `CategoriesPanel` + rekursiv daraxt UI.
- [x] 6.5 CSV eksport + bulk actions (Phase 1 bandi, qisman): `DataTable.jsx`ga `onExport` qo'shildi; `KycTab`/`WithdrawalsTab`ga eksport, `KycTab` (bulk bloklash) va `ProjectsTab`ga (bulk tasdiqlash) bulk actions ulandi — namunaviy 2-3 tab, qolganlari xuddi shu patternni takrorlaydi.
- [x] 6.6 Qo'lda to'ldirish (deposit) tasdiqlash tizimi — haqiqiy Payme/Click hozircha ulanmagan, buning o'rniga investor/fermer chek bilan so'rov yuboradi, admin/superadmin tasdiqlagach hamyonga tushadi: yangi `deposit_requests` jadvali (V22) + `deposit.review` ruxsati (V23), to'liq backend moduli, web (`DepositRequestsTab`, yangilangan `TopUpForm`), mobil (`DepositBottomSheet`, `testDeposit()` olib tashlandi). `PaymentService`/`PaymentController` (Payme/Click) kodga tegilmadi — kelajakda qayta yoqish uchun saqlanadi.
- [x] 6.7 Kod sifati: `CreateProjectForm.jsx` (382 qator) 5 ta kichik komponentga bo'lindi; takrorlangan `ReceiptChips`/`DocumentChips` yagona `ui/DocumentChips.jsx`ga; `wallet_page.dart` (564 qator) 3 ta widgetga bo'lindi; `AdminDashboard`/`SuperAdminDashboard`ning takroriy stats/chart kodi umumiy `AdminStatsAndCharts.jsx`ga chiqarildi.
- [x] 6.8 **Real ishlab chiqarishda topilgan kritik xato**: `PermissionService.getRolePermissions()` Redis keshiga `List.copyOf(...)` (JDK ichki immutable turi) yozar edi — bu `@authz.has(...)` mexanizmining birinchi haqiqiy chaqiruvchilari (6.1, 6.4, 6.6 pilotlari) paytida JVM qayta ishga tushgach Jackson deserializatsiyasi butunlay portlashiga sabab bo'ldi (500 xato, "Could not resolve type id"). Bu **avvaldan mavjud, hech qachon sinovdan o'tmagan xato** edi — chunki `@authz.has(...)`ning ilgari birorta ham jonli chaqiruvchisi yo'q edi. Tuzatildi: `ArrayList` yozish + o'qishda deserializatsiya xatosini keshdan o'tkazib yubormasdan qayta hisoblashga tushadigan himoya qo'shildi. Jonli konteynerlarga qarshi to'liq depozit-tasdiqlash oqimi (yaratish→tasdiqlash→hamyon balansi oshishi) qayta tekshirilib, ishlashi tasdiqlandi.

**Kelajakdagi fazalar (C–J, hali boshlanmagan)** — to'liq tavsif `.claude/plans/silly-napping-candy.md`da:
- Faza C — Reklama/E'lonlar (Banner) mini-CMS, mobil "Market" tabini almashtiradi
- Faza D — Ommaviy Landing Page (investor+fermer teng balansda)
- Faza E — Dizayn tizimini birlashtirish (investor/fermer/public/auth sahifalari)
- Faza F — TZ'dagi yetishmayotgan funksiyalar (reyting/sharh UI, xavf-ogohlantirish bloki, fermer tarixi)
- Faza G — Mobil: dark mode, push-bildirishnoma ulash, qolgan katta fayllarni bo'lish
- Faza H — Demo/test ma'lumot qo'shish
- Faza I — Hujjatlar (texnik + biznes/yuridik)
- Faza J — Yakuniy sifat nazorati (QA)

---

## Faza 7 — C, D, E, F, G, I fazalari (BAJARILDI, H ataylab qoldirilgan)

**Yangilanish (keyingi sessiya)**: Faza G'da qoldirilgan 4 ta katta mobil fayl endi to'liq bo'lindi — pastdagi 7.1-bandga qarang.

Foydalanuvchi so'rovi: "professional darajada davom et, yetishmayotgan harqanday qismni qo'sh, maksimal darajada ideal bo'lsin". Quyidagi fazalar shu sessiyada bajarildi va jonli serverga joylashtirildi.

- [x] **Faza C — Reklama/E'lonlar (Banner) mini-CMS**: `banners` jadvali (V24) + `banner.manage` ruxsati, to'liq backend CRUD (`BannerController`/`Service`/`Repository`, auditoriya bo'yicha filtrlash — ALL/INVESTOR/FARMER + sana oralig'i), Web SuperAdmin "Reklamalar" tabi. Mobil "Market" tabidagi **butunlay soxta marketplace** (qattiq kodlangan 8 ta "xizmat") olib tashlandi — endi haqiqiy `GET /banners`ga ulanadi, foydalanuvchi rolига mos e'lonlarni ko'rsatadi, bosilganda havolaga o'tadi.
- [x] **Faza D — Ommaviy Landing Page**: avval `/` umuman mavjud emas edi (hammasi `/login`ga otilib ketardi). Endi: hero (investor+fermer teng balans), jonli statistika (yangi **public** `GET /settings/public-stats` endpoint — investorlar/fermerlar soni, moliyalashtirilgan loyihalar, jami sarmoya), "qanday ishlaydi" bo'limi, tanlangan faol loyihalar, ishonch/xavf bloki. Faqat kirgan foydalanuvchi o'z dashboardiga yo'naltiriladi, mehmon endi haqiqiy landing page'ni ko'radi.
- [x] **Faza E — Dizayn tizimini birlashtirish**: ~30 ta fayl (`ProjectCard`, barcha farmer formalari/modallari, `LoginPage`/`RegisterPage`, `WalletPage`, `FarmerDashboard`, `ProjectDetailPage`, `DisputesPage`, `ProjectsPage`, `KycPage`, umumiy `ImageUploadPicker` va h.k.) dark-mode va `primary-*` token'larga o'tkazildi — avval faqat admin/superadmin qismi dizayn jihatidan tugallangan edi.
- [x] **Faza F — TZ'dagi yetishmayotgan funksiyalar**: `RiskDisclosure` komponenti (TZ §8.3 — xavf darajasi izohi + "kafolat yo'q" matni, avval umuman yo'q edi) ProjectDetailPage'ga qo'shildi. Reyting/sharh (F-9.2) — avval webda **umuman UI yo'q edi**, mobilda faqat investitsiyalar ichiga ko'milgan bottom-sheet edi: endi web'da `FarmerReviewsList`/`ReviewFormModal` (MyInvestments'dagi PAID_OUT investitsiyalarga "Sharh qoldirish" tugmasi + ProjectDetailPage'da fermer sharhlari bo'limi), mobilda alohida `FarmerReviewsPage` (`/farmers/:id/reviews`, loyiha sahifasidagi yulduzcha reytingdan bosib kirish orqali).
- [x] **Faza G — Mobil imkoniyatlari**: `AppTheme.dark()` + `ThemeProvider` (`shared_preferences`da saqlanadi, profil sahifasida "Ko'rinish" menyusi) — Material-standart vidjetlarni qamraydi, i18n kabi "mexanizm, to'liq qamrov emas". `PushNotificationService().initialize()` login va sessiya tiklashda chaqiriladigan qilindi (avval hech qachon chaqirilmagan edi) — haqiqiy Firebase loyihasi ulanmaguncha jim ishlaydi, xato bermaydi.
- [x] **7.1 — 4 ta eng katta mobil fayl komponentlarga bo'lindi** (keyingi sessiyada yakunlandi): har birida xatti-harakat 1:1 saqlangan, faqat UI mustaqil vidjetlarga ajratilgan; har bosqichdan keyin `flutter analyze` toza (yangi warning/error yo'q, faqat oldindan mavjud 16 ta info-darajali lint).
  - `project_detail_page.dart`: 746 → ~140 qator + 6 ta yangi vidjet (`ProjectHeaderCard`, `ProjectFinancialsSection`, `ProjectLinksSection`, `ProjectBottomActionsBar`, `investment_bottom_sheet.dart`, `project_investors_sheet.dart`).
  - `create_project_page.dart`: 695 → ~270 qator + `widgets/create_project/` papkasida 6 ta vidjet (`ProjectBasicInfoSection`, `AssetTypePicker`, `FundingModeSection`, `ProfitShareSlider`, `ExpensePolicySection`, `ReportFrequencyAndTargetsSection`) — webdagi `CreateProjectForm.jsx` bo'linishi bilan bir xil naqsh.
  - `dashboard_page.dart`: 537 → ~80 qator + 4 ta vidjet (`DashboardGreeting`, `InvestorDashboard`, `FarmerDashboard`, `GuestDashboard`).
  - `register_page.dart`: 509 → ~215 qator + 3 ta vidjet (`PhoneVerificationStep`, `ProfileDetailsStep`, `RolePickerCards`). Yo'l-yo'lakay aniqlangan dizayn-nomuvofiqlik tuzatildi: sahifa mavjud umumiy `AppTextField` vidjetidan (login/KYC formalarida ishlatiladigan) foydalanmay, 4 ta maydonni qo'lda ~150 qator takrorlangan `InputDecoration` bilan yozgan edi — endi qolgan formalar kabi `AppTextField`dan foydalanadi.
- [x] **Faza H — Demo ma'lumot** (keyingi sessiyada, foydalanuvchining aniq roziligi bilan bosqichma-bosqich bajarildi): haqiqiy `POST /auth/register`/`/projects`/`/investments`/`/reports`/`/payout`/`/reviews`/`/superadmin/banners` endpointlari orqali (to'g'ridan-to'g'ri SQL emas) 6 ta demo foydalanuvchi (`[DEMO]` prefiksi bilan, telefon `+998900000001`–`06`, parol har birida bir xil — `Demo12345`, oson topish/tozalash uchun), 3 ta demo loyiha (PENDING/FUNDING/ACTIVE→COMPLETED holatlarida — admin navbati, qisman moliyalashtirilgan va to'liq yakunlangan loyiha namunalari), to'liq loyiha hayot sikli (sarmoya→hisobot→to'lov→sharh) bitta loyihada oxirigacha ishlatib ko'rildi, va 4 ta banner (SVG data-URI rasm bilan, real fayl yuklashsiz) qo'shildi. Demo investorlar hamyoniga ~60 mln so'm depozit-so'rov+tasdiqlash orqali (haqiqiy oqim bilan bir xil mexanizm) kiritildi — bu qadam alohida aniq tasdiq bilan bajarildi.
- [x] **7.2 — Real production xavfsizlik teshigi topildi va tuzatildi** (Faza H tayyorgarligi paytida): `docker-compose.yml`da `SPRING_PROFILES_ACTIVE` umuman o'rnatilmagan edi → backend standart `dev` profilida ishlayotgan edi. Bu ikkita muammoni fosh qildi: (1) `DevPaymentController`/`POST /payments/test-deposit` — istalgan autentifikatsiyalangan foydalanuvchi o'ziga bepul pul qo'sha olardi (`@Profile({"dev","test"})` production'da ham faol edi) — **butunlay o'chirildi va joylashtirildi** (endi bu funksiya superadmin-tasdiqlovchi deposit-so'rov oqimi bilan almashtirilgan, kerak emas edi). (2) `SMS_EMAIL`/`SMS_PASSWORD` sozlanmagani sababli OTP doim `123456` qiymatini qabul qiladi (`OtpService`dagi mock-kod, profildan qat'iy nazar) — **hali ham shu holatda qoladi**, chunki haqiqiy SMS-provayder (Eskiz.uz va h.k.) hisob ma'lumotlari yo'q; bu ma'lum va qabul qilingan vaqtinchalik cheklov sifatida qayd etiladi, haqiqiy hisob mavjud bo'lganda `.env`ga `SMS_EMAIL`/`SMS_PASSWORD` qo'shish kifoya. Yo'l-yo'lakay: yagona SUPERADMIN hisobining paroli unutilgani sababli (foydalanuvchi so'rovi bilan, aniq ruxsat olingach) to'g'ridan-to'g'ri bazada bcrypt xesh orqali tiklandi — **foydalanuvchiga xabar berilgan, darhol o'zgartirish tavsiya etiladi**.
- [x] **Faza I — Hujjatlar**: texnik — root `README.md`, `ARCHITECTURE.md`, `DEPLOYMENT.md`, har uch ilova uchun `README.md`, `.env.example` fayllar. Biznes/yuridik — `legal/` papkasida Foydalanish shartlari, Maxfiylik siyosati va 3 shartnoma uchun talablar ro'yxati, **barchasi aniq "QORALAMA — yurist ko'rib chiqmasdan ishlatilmasin" deb belgilangan** (men yurist emasman).

**Real production xatosi (Faza C/D ishi paytida topildi va tuzatildi)**: `SecurityConfig`dagi `/api/v1/categories` uchun permitAll matcher HTTP metodidan qat'iy nazar ishlaydi (Spring Security xususiyati) — bu xavfsizlik teshigi emasligi alohida tekshirildi, chunki `@PreAuthorize`/`@authz.has(...)` metod darajasida baribir bloklaydi (jonli tizimda `curl` bilan tasdiqlandi: rasm yuklamagan/ruxsatsiz so'rovlar hali ham to'g'ri rad etiladi).

---

## Tekshirish mezonlari

| Bosqich | Qanday tekshiriladi |
|---|---|
| Phase 0 | `mvn test` yashil; migratsiyalar toza + haqiqiy bazada; Swagger orqali `hasPermission()` qo'lda; mavjud `hasRole()` regressiyasi |
| Phase 1 | Har bir admin tab qo'lda: eksport CSV, bulk faqat tanlangan qatorlarga, filtrlar to'g'ri |
| Phase 2 | SuperAdmin permission yaratadi→rolga bog'laydi→foydalanuvchi huquqi qayta deploysiz o'zgaradi |
| Phase 3 | Til almashtirish restart'siz; dark mode tizim+qo'lda; WebSocket polling'siz yetib boradi |
| Phase 4 | Chat xabari real vaqtda yetib boradi; AI indikatori ko'rinadi |
| Phase 6 | Deposit so'rov yaratish→admin tasdiqlaydi→hamyon balansi oshadi (haqiqiy Postgres+Redis'ga qarshi tekshirildi); VERIFIER login→`/verifier/dashboard`→hisobot kiritadi; SuperAdmin barcha tablarni bitta sahifada ko'radi |
| Faza 7 | Landing page mehmon uchun `/`da ochiladi; bannerlar mobil "Market" tabida haqiqiy `GET /banners`dan keladi; reyting/sharh web+mobilda ishlaydi; 4 ta bo'lingan mobil sahifada `flutter analyze` toza va oqim (loyiha ko'rish→ro'yxatdan o'tish→dashboard→sarmoya kiritish) qo'lda o'zgarishsiz ishlaydi |
