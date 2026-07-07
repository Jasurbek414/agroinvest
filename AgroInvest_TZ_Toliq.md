# AgroInvest — To'liq Texnik Spetsifikatsiya (TZ)
**Versiya:** 2.0 (Java · React · Flutter · PostgreSQL)
**Tayyorlangan:** 2026-yil iyul
**Asosiy hujjat:** AgroInvest_Texnik_Qollanma.pdf v1.0 + Implementation Plan v2.0

---

## MUNDARIJA

1. [Loyihaning mohiyati va biznes modeli](#1-loyihaning-mohiyati-va-biznes-modeli)
2. [Foydalanuvchi rollari va User Flows](#2-foydalanuvchi-rollari-va-user-flows)
3. [Funksional talablar (to'liq ro'yxat)](#3-funksional-talablar)
4. [Tizim arxitekturasi va texnologik stack](#4-tizim-arxitekturasi-va-texnologik-stack)
5. [Ma'lumotlar bazasi sxemasi (PostgreSQL)](#5-malumotlar-bazasi-sxemasi)
6. [API arxitekturasi — barcha endpointlar](#6-api-arxitekturasi)
7. [To'lov va moliyaviy oqim mexanizmi](#7-tolov-va-moliyaviy-oqim-mexanizmi)
8. [Ishonch, nazorat va xavfsizlik tizimi](#8-ishonch-nazorat-va-xavfsizlik)
9. [Huquqiy va me'yoriy jihatlar](#9-huquqiy-jihatlar)
10. [Papka tuzilmasi — Backend, Web, Mobile](#10-papka-tuzilmasi)
11. [Backend — pom.xml dependencies](#11-backend-dependencies)
12. [Mobile — pubspec.yaml packages](#12-mobile-packages)
13. [Muhit o'zgaruvchilari (.env)](#13-muhit-ozgaruvchilari)
14. [Docker Compose va Deployment](#14-docker-va-deployment)
15. [MVP bosqichlari — Sprint rejasi](#15-sprint-rejasi)
16. [Byudjet taqsimoti](#16-byudjet)
17. [Risklar tahlili](#17-risklar)
18. [Muvaffaqiyat metrikalari (KPI)](#18-kpi)

---

## 1. LOYIHANING MOHIYATI VA BIZNES MODELI

### 1.1 Muammo
O'zbekistonda qishloq xo'jaligi bilan shug'ullanuvchi minglab fermer va dehqonlar mavjud bo'lib, ularning katta qismi ishlab chiqarishni kengaytirish uchun zarur sarmoyaga ega emas. Bank kreditlari yuqori foiz stavkalari, garov talabi va byurokratik to'siqlar tufayli ko'plab kichik fermerlar uchun amalda erishib bo'lmaydigan holatda qoladi. Shu bilan bir vaqtda, shaharlarda yashovchi minglab odamlar qishloq xo'jaligiga investitsiya qilishni xohlaydi, ammo ularda na yer, na vaqt, na tajriba bor.

### 1.2 Yechim
**AgroInvest** — investorlar va fermerlarni to'g'ridan-to'g'ri bog'laydigan raqamli platforma.

**Asosiy tamoyil:** Platforma hech qachon o'zi qishloq xo'jaligi faoliyati bilan shug'ullanmaydi. U faqat texnologik vositachi — ishonchni ta'minlovchi, hisob-kitobni avtomatlashtiruvchi va tomonlarni bog'lovchi qatlam sifatida ishlaydi.

### 1.3 Qiymat zanjiri (Value Chain)

| Bosqich | Ishtirokchi | Harakat |
|---------|-------------|---------|
| 1. Taklif yaratish | Fermer | Aktiv turi, kerakli summa, muddat, kutilayotgan daromad |
| 2. Tekshiruv | Admin | Fermer va loyihani vetting, hujjatlarni tasdiqlash |
| 3. Sarmoya yig'ish | Investor(lar) | Ulush xarid qilish — to'liq yig'ilguncha |
| 4. Parvarish | Fermer | Aktivni yetishtirish, davriy hisobot berish |
| 5. Monitoring | Platforma | Foto/video, geolokatsiya, verifikator tashrifi |
| 6. Sotish | Fermer / Platforma | Tayyor mahsulotni bozorga yoki xaridorga sotish |
| 7. Hisob-kitob | Platforma | Komissiya ushlash, qolganini taqsimlash |

### 1.4 Daromad modeli
- **Muvaffaqiyat komissiyasi** (asosiy): yakuniy daromaddan **8–15%**
- **Fermerdan boshlang'ich xizmat haqi**: (MVP da ixtiyoriy)
- **Sug'urta xizmat haqi ustama**: sug'urta hamkorligi orqali
- **Premium investor xizmatlari**: (kelajak)

### 1.5 Daromad taqsimlash formulasi
```
umumiy_tushum         = mahsulot_sotilgan_narxi
platforma_komissiyasi  = umumiy_tushum × komissiya_foizi   (8–15%)
sof_daromad           = umumiy_tushum − boshlang'ich_investitsiya − platforma_komissiyasi
investor_ulushi        = sof_daromad × investor_foizi       (masalan, 70%)
fermer_ulushi          = sof_daromad × fermer_foizi         (masalan, 30%)
investorga_qaytariladigan = boshlang'ich_investitsiya + investor_ulushi
```

**Misol:** Investor 10,000,000 so'm tikadi → 13,000,000 so'mga sotiladi.
- Platforma: 1,300,000 so'm (10%) · Investor: 11,190,000 so'm · Fermer: 510,000 so'm

---

## 2. FOYDALANUVCHI ROLLARI VA USER FLOWS

### 2.1 Rollar tizimi (6 ta rol)

| Rol | Kod | Tavsif | Asosiy vakolat |
|-----|-----|--------|----------------|
| Super Admin | `SUPERADMIN` | Platforma egasi/texnik rahbar | Hamma narsa: tizim sozlamalari, admin boshqarish, audit log, emergency freeze |
| Admin | `ADMIN` | Platforma xodimi | Fermer vetting, loyiha tasdiqlash, moliyaviy monitoring, nizo hal qilish |
| Moderator | `MODERATOR` | Kontent moderatori | Hisobotlarni tekshirish, shikoyatlar, yengil boshqaruv |
| Verifikator | `VERIFIER` | Vet/Agronom, shartnoma asosida | Dala tashrifi natijalarini kiritish |
| Investor | `INVESTOR` | Sarmoyador | Loyiha ko'rish, investitsiya, daromad olish |
| Fermer | `FARMER` | Fermer/ishlab chiqaruvchi | Loyiha yaratish, hisobot yuklash |

### 2.2 SuperAdmin maxsus vakolatlari
- ✅ Admin, Moderator, Verifikator akkountlarini **yaratish / bloklash / o'chirish**
- ✅ Platforma sozlamalarini boshqarish: komissiya %, minimal investitsiya, hisobot chastotasi
- ✅ Barcha moliyaviy tranzaksiyalarni ko'rish va **CSV/Excel eksport**
- ✅ **Audit log** — kim, qachon, nima qildi (to'liq, o'zgartirib bo'lmaydigan)
- ✅ **Emergency freeze** — istalgan loyihani, hisobni yoki tranzaksiyani muzlatish
- ✅ Platforma umumiy statistikasi: GMV, MAU, revenue, konversiya

### 2.3 Rol ierarxiyasi
```
SUPERADMIN
    │
    ├── ADMIN
    │     └── MODERATOR
    │               └── VERIFIER
    │
    ├── INVESTOR
    └── FARMER
```

### 2.4 Investor User Flow
```
[Ro'yxatdan o'tish: telefon + SMS OTP]
         ↓
[KYC: pasport ma'lumotlari + foto]
         ↓
[Admin KYC tasdiqlash → xabarnoma]
         ↓
[Faol loyihalar ro'yxati: filter/qidiruv]
         ↓
[Loyiha profili: fermer reytingi, hujjatlar, tarix]
         ↓
[Ulush miqdori kiritish + to'lov: Payme/Click]
         ↓
[Elektron shartnomani imzolash (PDF auto-generatsiya)]
         ↓
[Monitoring: foto/video timeline, hisobotlar]
         ↓
[Mahsulot sotilgach → avtomatik xabarnoma]
         ↓
[Hamyonga daromad → yechib olish yoki qayta investitsiya]
```

### 2.5 Fermer User Flow
```
[Ro'yxatdan o'tish: telefon + SMS OTP]
         ↓
[Hujjatlar: pasport, yer huquqi, tajriba sertifikatlari]
         ↓
[Admin vetting — MAJBURIY (1-2 ish kuni)]
         ↓
[Yangi loyiha arizasi: aktiv, summa, muddat, xavf darajasi]
         ↓
[Admin loyihani tasdiqlaydi → Funding bosqichiga]
         ↓
[Summa yig'ilgach → 50% boshida, 50% yarimida fermerga]
         ↓
[Har 14 kunda foto/video hisobot yuklash (GPS bilan)]
         ↓
[Favqulodda holat → bir tugma bilan signal → adminga]
         ↓
[Sotish → tushum → avtomatik hisob-kitob → ulushni olish]
```

### 2.6 Admin User Flow
```
[Dashboard: KPI ko'rsatkichlar]
    ├── Fermer arizalari → vetting → tasdiqlash/rad etish
    ├── Loyiha arizalari → tekshirish → tasdiqlash/rad etish
    ├── Hisobotlarni ko'rish → shubhalilarni belgilash
    ├── Nizolar → ticket tizimi → hal qilish
    ├── Pul yechish so'rovlari → tasdiqlash
    └── Moliyaviy monitoring → komissiya, to'lovlar
```

### 2.7 SuperAdmin User Flow
```
[SuperAdmin Dashboard: platforma umumiy statistikasi]
    ├── Akkountlar boshqaruvi: admin/moderator yaratish, bloklash
    ├── Audit log: barcha harakatlar tarixi (filter + eksport)
    ├── Platform sozlamalari: komissiya, limitlar, chastota
    ├── Emergency: loyiha/hisob freeze qilish
    └── Statistika eksport: CSV/Excel
```

---

## 3. FUNKSIONAL TALABLAR

### 3.1 Foydalanuvchi boshqaruvi (Auth Module)

| # | Funksiya | Prioritet | Tavsif |
|---|----------|-----------|--------|
| F-1.1 | SMS OTP yuborish | P0 (MVP) | Eskiz.uz orqali |
| F-1.2 | OTP tasdiqlash | P0 | 6 raqam, 5 daqiqa amal qiladi |
| F-1.3 | Ro'yxatdan o'tish | P0 | Telefon + rol tanlash (investor/farmer) |
| F-1.4 | Kirish (Login) | P0 | Telefon + OTP yoki parol |
| F-1.5 | Token yangilash | P0 | JWT refresh token (Redis da) |
| F-1.6 | Chiqish (Logout) | P0 | Refresh token bekor qilish |
| F-1.7 | KYC hujjatlar yuklash | P0 | Pasport + rasm → S3 |
| F-1.8 | 2FA moliyaviy amallar | P1 | OTP orqali tasdiqlash |
| F-1.9 | Profilni tahrirlash | P1 | Ism, avatar |
| F-1.10 | Hisobni bloklash | P0 | Admin/SuperAdmin tomonidan |

### 3.2 Loyihalar (Projects) Moduli

| # | Funksiya | Prioritet | Tavsif |
|---|----------|-----------|--------|
| F-2.1 | Loyiha yaratish | P0 | Faqat VERIFIED FARMER |
| F-2.2 | Loyiha holatlari | P0 | PENDING→APPROVED→FUNDING→ACTIVE→COMPLETED/CANCELLED |
| F-2.3 | Loyiha detail sahifasi | P0 | Rasm, parametrlar, fermer profili, progress |
| F-2.4 | Filtrlash/qidiruv | P0 | Aktiv turi, hudud, muddat, daromad %, xavf |
| F-2.5 | Real-vaqt progress bar | P0 | Yig'ilgan summa / Maqsad summa |
| F-2.6 | Rasm/video yuklash | P0 | Multipart → S3 |
| F-2.7 | Admin tasdiqlash | P0 | Status o'zgartirish + xabarnoma |
| F-2.8 | Loyiha tarixi | P1 | Fermerning oldingi natijalari |

### 3.3 Investitsiya va Ulush Moduli

| # | Funksiya | Prioritet | Tavsif |
|---|----------|-----------|--------|
| F-3.1 | Ulush xarid qilish | P0 | To'liq yoki qisman |
| F-3.2 | To'lovga yo'naltirish | P0 | Payme / Click |
| F-3.3 | Webhook qayta ishlash | P0 | To'lov statusini yangilash |
| F-3.4 | Shartnoma PDF auto-generatsiya | P0 | Har investitsiya uchun avtomatik |
| F-3.5 | Elektron imzo | P1 | Raqamli imzolash |
| F-3.6 | Bekor qilish oynasi | P0 | 24 soat ichida (loyiha to'liq yig'ilmagan bo'lsa) |
| F-3.7 | Investitsiyalar tarixi | P0 | Barcha faol va yakunlangan |
| F-3.8 | Limit tekshiruvi | P0 | Min/Max summa |
| F-3.9 | Idempotency key | P0 | Ikki marta to'lovning oldini olish |
| F-3.10 | Escrow mexanizmi | P0 | Muzlatish → tasdiqlash → fermerga |

### 3.4 Monitoring va Hisobot Moduli

| # | Funksiya | Prioritet | Tavsif |
|---|----------|-----------|--------|
| F-4.1 | Foto/video yuklash | P0 | Majburiy jadval (har 14 kun) |
| F-4.2 | Timestamp | P0 | Yuklash vaqti avtomatik |
| F-4.3 | Geolokatsiya (GPS) | P0 | Koordinatalar bilan solishtirish |
| F-4.4 | Verifikator xulosasi | P1 | Dala tashrifi natijasi |
| F-4.5 | Favqulodda signal | P0 | Emergency → adminga darhol bildirishnoma |
| F-4.6 | Investor timeline | P0 | Xronologik hisobotlar lentasi |
| F-4.7 | Kechikkan hisobot ogohlantirishi | P1 | 2 kun o'tsa → SMS/Telegram |

### 3.5 Moliyaviy Modul

| # | Funksiya | Prioritet | Tavsif |
|---|----------|-----------|--------|
| F-5.1 | Payme integratsiyasi | P0 | CheckPerformTransaction protokoli |
| F-5.2 | Click integratsiyasi | P0 | Prepare + Complete protokoli |
| F-5.3 | Ichki hamyon (Wallet) | P0 | balance, frozen, total_earned |
| F-5.4 | Komissiya hisoblash | P0 | Platform sozlamalaridan olinadi |
| F-5.5 | Daromad taqsimlash | P0 | Loyiha yakunida avtomatik |
| F-5.6 | Pul yechish so'rovi | P0 | Foydalanuvchi → Admin tasdiqlash |
| F-5.7 | Moliyaviy tarix | P0 | Immutable tranzaksiyalar |
| F-5.8 | Audit log | P0 | Kim/qachon/nima — o'zgartirib bo'lmaydi |

### 3.6 Bildirishnomalar Moduli

| # | Funksiya | Prioritet | Tavsif |
|---|----------|-----------|--------|
| F-6.1 | SMS (Eskiz.uz) | P0 | OTP, to'lov, muhim voqealar |
| F-6.2 | Telegram Bot | P0 | Hisobot, muddat, bildirishnoma |
| F-6.3 | Push (Firebase FCM) | P1 | Flutter mobil uchun |
| F-6.4 | In-App bildirishnoma | P0 | Web va mobil ichida |
| F-6.5 | Email xulosalar | P2 | Haftalik/oylik hisobot |

### 3.7 Admin Panel Moduli

| # | Funksiya | Prioritet | Tavsif |
|---|----------|-----------|--------|
| F-7.1 | Fermer arizalarini tasdiqlash | P0 | Ko'rish + approve/reject |
| F-7.2 | Loyiha arizalarini tasdiqlash | P0 | Ko'rish + approve/reject |
| F-7.3 | KYC tasdiqlash | P0 | Pasport + rasm tekshiruv |
| F-7.4 | Foydalanuvchilar boshqaruvi | P0 | Bloklash, faollashtirish |
| F-7.5 | Tranzaksiyalar monitoringi | P0 | Barcha moliyaviy harakatlar |
| F-7.6 | Nizolar tizimi | P1 | Ticket-based |
| F-7.7 | Statistik dashboard | P0 | KPI ko'rsatkichlari + Recharts |
| F-7.8 | Pul yechishni tasdiqlash | P0 | Withdrawal approval |
| F-7.9 | Hisobot tekshiruv | P1 | Foto/video tasdiqlash |

### 3.8 SuperAdmin Panel Moduli

| # | Funksiya | Prioritet | Tavsif |
|---|----------|-----------|--------|
| F-8.1 | Admin akkount yaratish | P0 | Yangi admin/moderator/verifier |
| F-8.2 | Akkount bloklash/o'chirish | P0 | SuperAdmin tomonidan |
| F-8.3 | Audit log ko'rish | P0 | Filter + paginate + eksport |
| F-8.4 | Platform sozlamalari | P0 | Komissiya %, limitlar, chastota |
| F-8.5 | Emergency freeze | P0 | Loyiha/hisob/tranzaksiya muzlatish |
| F-8.6 | Statistika eksport | P0 | CSV/Excel formati |
| F-8.7 | Umumiy tizim statistikasi | P0 | GMV, MAU, revenue, konversiya |

### 3.9 Baholash va Obro' Tizimi

| # | Funksiya | Prioritet | Tavsif |
|---|----------|-----------|--------|
| F-9.1 | Fermer reytingi | P1 | Muvaffaqiyat, daromadlilik, intizom |
| F-9.2 | Sharh qoldirish | P1 | Investor → Fermergа |
| F-9.3 | "Verified" belgi | P1 | Shaffof va muntazam fermerlar |

---

## 4. TIZIM ARXITEKTURASI VA TEXNOLOGIK STACK

### 4.1 Yuqori darajadagi arxitektura
```
┌──────────────────────────────────────────────────────────────┐
│                     CLIENT QATLAMLARI                        │
│                                                              │
│  ┌──────────────────┐     ┌──────────────────────────────┐  │
│  │  Flutter Mobil   │     │  React + Tailwind (Web SPA)  │  │
│  │  Android / iOS   │     │  Investor · Farmer · Admin   │  │
│  │  Provider state  │     │  Zustand state management    │  │
│  └────────┬─────────┘     └───────────────┬──────────────┘  │
└───────────┼───────────────────────────────┼─────────────────┘
            │                               │
            ▼                               ▼
┌──────────────────────────────────────────────────────────────┐
│             Java Spring Boot REST API  (:8080)               │
│   Spring Security · JWT · RBAC (6 rol) · Flyway migrations  │
│                                                              │
│  Auth  │  Users  │  Projects  │  Investments  │  Payments   │
│  Reports  │  Wallets  │  Transactions  │  Notifications      │
│  Disputes  │  Withdrawals  │  Admin  │  SuperAdmin           │
└────────────────────────┬─────────────────────────────────────┘
                         │
         ┌───────────────┼──────────────────┐
         ▼               ▼                  ▼
   PostgreSQL 16      Redis 7          Cloudflare R2
   (asosiy DB)      (JWT cache,        (rasm, video,
   Flyway mig.       OTP kodlar,        hujjatlar)
   ACID kafolat)     rate limiting)
                         │
         ┌───────────────┴──────────────────┐
         ▼                                  ▼
   Eskiz.uz (SMS)              Telegram Bot API
   OTP, bildirishnoma          Push xabarlar
```

### 4.2 Texnologik Stack (Tasdiqlangan)

| Qatlam | Texnologiya | Versiya | Maqsad |
|--------|-------------|---------|--------|
| **Backend** | Java Spring Boot | 3.3+ (Java 17) | REST API, biznes logika |
| **Security** | Spring Security + JJWT | — | Auth, RBAC, 2FA |
| **ORM** | Spring Data JPA + Hibernate | — | DB bilan ishlash |
| **DB Migration** | Flyway | 10+ | Schema versiyalash |
| **Validation** | Jakarta Validation | — | DTO validatsiya |
| **Mapping** | MapStruct | 1.6 | Entity↔DTO konversiya |
| **HTTP Client** | Spring WebFlux (WebClient) | — | Payme/Click/SMS so'rovlari |
| **API Docs** | Springdoc OpenAPI 3 | 2.6 | Swagger UI `/api/docs` |
| **Build** | Maven | 3.9+ | Dependency management |
| **Database** | PostgreSQL | 16 | Asosiy ma'lumotlar bazasi |
| **Cache** | Redis | 7 | OTP, JWT refresh, rate limiting |
| **File Storage** | Cloudflare R2 (AWS S3 API) | — | Rasm, video, hujjatlar |
| **Web Frontend** | React | 18 | SPA web ilova |
| **JS** | JavaScript (ES2022+) | — | JSX, modern JS |
| **CSS Framework** | Tailwind CSS | 3.4 | Utility-first styling |
| **State** | Zustand | 4+ | Global state management |
| **HTTP** | Axios | 1.7+ | API so'rovlar, interceptors |
| **Router** | React Router | v6 | Sahifalar navigatsiyasi |
| **Charts** | Recharts | 2.12 | Dashboard grafiklari |
| **Forms** | React Hook Form + Zod | — | Forma va validatsiya |
| **Mobile** | Flutter | 3.22+ | iOS va Android |
| **State (Flutter)** | Provider | 6.1 | State management |
| **HTTP (Flutter)** | Dio | 5.7 | API so'rovlar |
| **Push** | Firebase FCM | — | Flutter push bildirishnoma |
| **SMS** | Eskiz.uz API | — | O'zbekiston SMS gateway |
| **Telegram** | Bot API | — | Bildirishnoma kanali |
| **To'lov** | Payme API + Click API | — | O'zbekiston to'lov tizimlari |
| **Container** | Docker + Docker Compose | — | Local + Production |
| **CI/CD** | GitHub Actions | — | Avtomatik test va deploy |
| **Monitoring** | Sentry | — | Xato kuzatish |
| **Linter** | Checkstyle (Java), ESLint (React) | — | Kod sifati |
| **Test (Java)** | JUnit 5 + Mockito + Testcontainers | — | Unit + Integration |
| **Test (React)** | Jest + React Testing Library | — | Component testing |

### 4.3 Xavfsizlik arxitekturasi
- Barcha API: **HTTPS (TLS 1.3)**
- Parollar: **bcrypt** (cost factor 12)
- JWT: Access token **15 daqiqa** + Refresh token **30 kun** (Redis da)
- **RBAC**: `@PreAuthorize("hasRole('ADMIN')")` Spring Security annotatsiyalari
- **Audit log**: Immutable — kim, qachon, nima, eski/yangi qiymat
- Pasport ma'lumotlari: **AES-256** shifrlash (at-rest)
- **Rate limiting**: OTP uchun 5/daqiqa, API uchun 100/daqiqa
- **CORS**: Faqat ruxsat etilgan domainlar
- **SQL injection**: JPA parametrlangan so'rovlar
- **XSS**: Input sanitizatsiya, `Content-Security-Policy` headers
- **Idempotency**: Moliyaviy so'rovlar uchun `X-Idempotency-Key` header

---

## 5. MA'LUMOTLAR BAZASI SXEMASI (PostgreSQL 16)

### Migratsiya fayllari ketma-ketligi
```
db/migration/
├── V1__init_enums_and_tables.sql     ← Barcha ENUM va asosiy jadvallar
├── V2__indexes.sql                   ← Indekslar
├── V3__superadmin_and_settings.sql   ← SuperAdmin jadvallar
├── V4__seed_superadmin.sql           ← Default SuperAdmin va sozlamalar
└── V5__platform_constraints.sql      ← Qo'shimcha check constraint'lar
```

### V1 — ENUM Tiplar
```sql
CREATE TYPE user_role    AS ENUM ('SUPERADMIN','ADMIN','MODERATOR','VERIFIER','INVESTOR','FARMER');
CREATE TYPE kyc_status   AS ENUM ('PENDING','VERIFIED','REJECTED');
CREATE TYPE asset_type   AS ENUM ('LIVESTOCK','CROP','GREENHOUSE','POULTRY','BEEKEEPING','OTHER');
CREATE TYPE risk_level   AS ENUM ('LOW','MEDIUM','HIGH');
CREATE TYPE proj_status  AS ENUM ('PENDING','APPROVED','FUNDING','ACTIVE','COMPLETED','CANCELLED');
CREATE TYPE inv_status   AS ENUM ('RESERVED','CONFIRMED','ACTIVE','PAID_OUT','REFUNDED','CANCELLED');
CREATE TYPE txn_type     AS ENUM ('DEPOSIT','PAYOUT','COMMISSION','WITHDRAWAL','REFUND','FARMER_PAYOUT');
CREATE TYPE txn_status   AS ENUM ('PENDING','COMPLETED','FAILED','CANCELLED');
CREATE TYPE pay_provider AS ENUM ('PAYME','CLICK','MANUAL','INTERNAL');
CREATE TYPE wd_status    AS ENUM ('PENDING','APPROVED','PROCESSED','REJECTED');
CREATE TYPE disp_status  AS ENUM ('OPEN','INVESTIGATING','RESOLVED','CLOSED');
CREATE TYPE rep_type     AS ENUM ('ROUTINE','EMERGENCY','VERIFICATION','FINAL','COMPLETION');
CREATE TYPE notif_ch     AS ENUM ('IN_APP','SMS','TELEGRAM','EMAIL');
```

### Jadval 1: `users`
```sql
CREATE TABLE users (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  role                user_role   NOT NULL DEFAULT 'INVESTOR',
  full_name           VARCHAR(255) NOT NULL,
  phone_number        VARCHAR(20)  UNIQUE NOT NULL,
  email               VARCHAR(255) UNIQUE,
  password_hash       VARCHAR(255),
  avatar_url          VARCHAR(500),
  passport_data       TEXT,                        -- AES-256 shifrlangan JSONB
  kyc_status          kyc_status  DEFAULT 'PENDING',
  kyc_rejected_reason VARCHAR(500),
  kyc_verified_at     TIMESTAMP,
  kyc_verified_by     UUID REFERENCES users(id),
  rating              DECIMAL(3,2) DEFAULT 0.00,   -- 0.00–5.00 (fermerlar uchun)
  total_projects      INTEGER     DEFAULT 0,
  is_active           BOOLEAN     DEFAULT true,
  is_blocked          BOOLEAN     DEFAULT false,
  blocked_reason      VARCHAR(500),
  blocked_at          TIMESTAMP,
  blocked_by          UUID REFERENCES users(id),
  telegram_chat_id    BIGINT,
  fcm_token           VARCHAR(500),                -- Firebase Cloud Messaging
  created_at          TIMESTAMP   DEFAULT now(),
  updated_at          TIMESTAMP   DEFAULT now()
);
```

### Jadval 2: `wallets`
```sql
CREATE TABLE wallets (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID        UNIQUE NOT NULL REFERENCES users(id),
  balance          DECIMAL(18,2) DEFAULT 0,
  frozen           DECIMAL(18,2) DEFAULT 0,        -- muzlatilgan (faol investitsiyalar)
  total_earned     DECIMAL(18,2) DEFAULT 0,
  total_withdrawn  DECIMAL(18,2) DEFAULT 0,
  updated_at       TIMESTAMP   DEFAULT now()
);
```

### Jadval 3: `projects`
```sql
CREATE TABLE projects (
  id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id             UUID        NOT NULL REFERENCES users(id),
  asset_type            asset_type  NOT NULL,
  title                 VARCHAR(255) NOT NULL,
  description           TEXT        NOT NULL,
  region                VARCHAR(100),
  location_details      VARCHAR(500),
  target_amount         DECIMAL(18,2) NOT NULL,
  raised_amount         DECIMAL(18,2) DEFAULT 0,
  min_investment        DECIMAL(18,2) DEFAULT 100000,
  max_investment        DECIMAL(18,2),
  expected_return_pct   DECIMAL(5,2)  NOT NULL,
  commission_pct        DECIMAL(5,2)  DEFAULT 10,
  investor_share_pct    DECIMAL(5,2)  DEFAULT 70,
  farmer_share_pct      DECIMAL(5,2)  DEFAULT 30,
  duration_days         INTEGER      NOT NULL,
  start_date            DATE,
  end_date              DATE,
  risk_level            risk_level   NOT NULL,
  status                proj_status  DEFAULT 'PENDING',
  rejection_reason      VARCHAR(500),
  media_urls            JSONB        DEFAULT '[]',
  total_investors       INTEGER      DEFAULT 0,
  report_frequency_days INTEGER      DEFAULT 14,
  admin_notes           TEXT,
  approved_by           UUID REFERENCES users(id),
  approved_at           TIMESTAMP,
  completed_at          TIMESTAMP,
  final_amount          DECIMAL(18,2),
  created_at            TIMESTAMP    DEFAULT now(),
  updated_at            TIMESTAMP    DEFAULT now()
);
```

### Jadval 4: `investments`
```sql
CREATE TABLE investments (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id        UUID        NOT NULL REFERENCES projects(id),
  investor_id       UUID        NOT NULL REFERENCES users(id),
  amount            DECIMAL(18,2) NOT NULL,
  share_pct         DECIMAL(10,6) NOT NULL,
  idempotency_key   VARCHAR(255)  UNIQUE,
  contract_url      VARCHAR(500),
  contract_signed_at TIMESTAMP,
  status            inv_status   DEFAULT 'RESERVED',
  payout_amount     DECIMAL(18,2),
  payout_date       TIMESTAMP,
  cancelled_at      TIMESTAMP,
  cancel_reason     VARCHAR(500),
  created_at        TIMESTAMP    DEFAULT now(),
  updated_at        TIMESTAMP    DEFAULT now()
);
```

### Jadval 5: `transactions` ⚠️ IMMUTABLE
```sql
-- DIQQAT: Bu jadvalga UPDATE va DELETE MUMKIN EMAS!
-- Faqat INSERT — moliyaviy audit uchun
CREATE TABLE transactions (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID        NOT NULL REFERENCES users(id),
  project_id          UUID        REFERENCES projects(id),
  investment_id       UUID        REFERENCES investments(id),
  type                txn_type    NOT NULL,
  amount              DECIMAL(18,2) NOT NULL,
  currency            VARCHAR(3)   DEFAULT 'UZS',
  payment_provider    pay_provider,
  external_payment_id VARCHAR(255),
  idempotency_key     VARCHAR(255) UNIQUE,
  status              txn_status   DEFAULT 'PENDING',
  metadata            JSONB        DEFAULT '{}',
  created_at          TIMESTAMP    DEFAULT now()
  -- updated_at YO'Q — intentional!
);
```

### Jadval 6: `reports`
```sql
CREATE TABLE reports (
  id            UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id    UUID      NOT NULL REFERENCES projects(id),
  submitted_by  UUID      NOT NULL REFERENCES users(id),
  report_type   rep_type  NOT NULL,
  media_urls    JSONB     DEFAULT '[]',
  geo_lat       DECIMAL(10,7),
  geo_lng       DECIMAL(10,7),
  geo_accuracy  FLOAT,
  notes         TEXT,
  is_verified   BOOLEAN   DEFAULT false,
  verified_by   UUID REFERENCES users(id),
  verified_at   TIMESTAMP,
  admin_comment TEXT,
  created_at    TIMESTAMP DEFAULT now()
);
```

### Jadval 7: `withdrawal_requests`
```sql
CREATE TABLE withdrawal_requests (
  id              UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID      NOT NULL REFERENCES users(id),
  amount          DECIMAL(18,2) NOT NULL,
  status          wd_status DEFAULT 'PENDING',
  bank_name       VARCHAR(100),
  card_number     VARCHAR(20),
  payment_details JSONB,
  admin_comment   VARCHAR(500),
  processed_by    UUID REFERENCES users(id),
  processed_at    TIMESTAMP,
  created_at      TIMESTAMP DEFAULT now()
);
```

### Jadval 8: `disputes`
```sql
CREATE TABLE disputes (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id    UUID        NOT NULL REFERENCES projects(id),
  filed_by      UUID        NOT NULL REFERENCES users(id),
  against_user  UUID        NOT NULL REFERENCES users(id),
  dispute_type  VARCHAR(100),
  description   TEXT        NOT NULL,
  status        disp_status DEFAULT 'OPEN',
  resolution    TEXT,
  resolved_by   UUID REFERENCES users(id),
  resolved_at   TIMESTAMP,
  created_at    TIMESTAMP   DEFAULT now(),
  updated_at    TIMESTAMP   DEFAULT now()
);
```

### Jadval 9: `notifications`
```sql
CREATE TABLE notifications (
  id          UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID      NOT NULL REFERENCES users(id),
  type        VARCHAR(100) NOT NULL,
  title       VARCHAR(255) NOT NULL,
  message     TEXT      NOT NULL,
  is_read     BOOLEAN   DEFAULT false,
  channel     notif_ch  DEFAULT 'IN_APP',
  sent_at     TIMESTAMP,
  created_at  TIMESTAMP DEFAULT now()
);
```

### Jadval 10: `otp_codes`
```sql
CREATE TABLE otp_codes (
  id           UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number VARCHAR(20) NOT NULL,
  code         VARCHAR(6)  NOT NULL,
  purpose      VARCHAR(50),       -- login | register | 2fa | reset
  expires_at   TIMESTAMP  NOT NULL,
  is_used      BOOLEAN    DEFAULT false,
  attempts     INTEGER    DEFAULT 0,
  created_at   TIMESTAMP  DEFAULT now()
);
```

### Jadval 11: `platform_settings` (SuperAdmin uchun)
```sql
CREATE TABLE platform_settings (
  id            UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
  setting_key   VARCHAR(100) UNIQUE NOT NULL,
  setting_value TEXT      NOT NULL,
  description   VARCHAR(500),
  updated_by    UUID REFERENCES users(id),
  updated_at    TIMESTAMP DEFAULT now()
);
```

### Jadval 12: `audit_logs` (SuperAdmin uchun — IMMUTABLE)
```sql
CREATE TABLE audit_logs (
  id          UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID      NOT NULL REFERENCES users(id),
  action      VARCHAR(100) NOT NULL,   -- CREATE_USER, UPDATE_SETTINGS, BLOCK_USER ...
  entity_type VARCHAR(100),            -- User, Project, Investment ...
  entity_id   VARCHAR(100),
  old_value   JSONB,
  new_value   JSONB,
  ip_address  VARCHAR(45),
  user_agent  VARCHAR(500),
  created_at  TIMESTAMP DEFAULT now()
  -- updated_at YO'Q — immutable!
);
```

### Munosabatlar (ERD qisqacha)
```
users (1) ──── (N) projects         [farmer_id]
users (1) ──── (N) investments      [investor_id]
users (1) ──── (1) wallets          [user_id]
users (1) ──── (N) transactions     [user_id]
users (1) ──── (N) notifications    [user_id]
users (1) ──── (N) withdrawal_requests [user_id]
users (1) ──── (N) audit_logs       [user_id]
projects (1) ── (N) investments     [project_id]
projects (1) ── (N) reports         [project_id]
projects (1) ── (N) transactions    [project_id]
projects (1) ── (N) disputes        [project_id]
```

### Indekslar (V2__indexes.sql)
```sql
CREATE INDEX idx_users_role         ON users(role);
CREATE INDEX idx_users_phone        ON users(phone_number);
CREATE INDEX idx_users_kyc          ON users(kyc_status);
CREATE INDEX idx_projects_status    ON projects(status);
CREATE INDEX idx_projects_farmer    ON projects(farmer_id);
CREATE INDEX idx_projects_asset     ON projects(asset_type);
CREATE INDEX idx_investments_inv    ON investments(investor_id);
CREATE INDEX idx_investments_proj   ON investments(project_id);
CREATE INDEX idx_investments_status ON investments(status);
CREATE INDEX idx_transactions_user  ON transactions(user_id);
CREATE INDEX idx_transactions_type  ON transactions(type);
CREATE INDEX idx_transactions_date  ON transactions(created_at DESC);
CREATE INDEX idx_reports_project    ON reports(project_id);
CREATE INDEX idx_reports_type       ON reports(report_type);
CREATE INDEX idx_notifications_user ON notifications(user_id, is_read);
CREATE INDEX idx_audit_logs_user    ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_date    ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_entity  ON audit_logs(entity_type, entity_id);
```

### Default ma'lumotlar (V4__seed_superadmin.sql)
```sql
-- SuperAdmin (parol: changeme123 — birinchi kirishda o'zgartirish SHART)
INSERT INTO users (role, full_name, phone_number, password_hash, kyc_status, is_active)
VALUES ('SUPERADMIN', 'Super Admin', '+998901234567',
        '$2a$12$HASHED_PASSWORD_HERE', 'VERIFIED', true);

-- Default platform sozlamalari
INSERT INTO platform_settings (setting_key, setting_value, description) VALUES
  ('default_commission_pct',        '10',     'Default platforma komissiyasi (%)'),
  ('min_investment_amount',         '100000', 'Minimal investitsiya summasi (so''m)'),
  ('max_investment_cancel_hours',   '24',     'Bekor qilish oynasi (soat)'),
  ('report_frequency_days',         '14',     'Hisobot chastotasi (kun)'),
  ('default_investor_share_pct',    '70',     'Investorga sof daromaddan (%)'),
  ('default_farmer_share_pct',      '30',     'Fermergа sof daromaddan (%)'),
  ('otp_expiry_minutes',            '5',      'OTP amal qilish muddati (daqiqa)'),
  ('max_otp_attempts',              '3',      'OTP urinishlar soni'),
  ('jwt_access_expiry_seconds',     '900',    'Access token muddati (sekund = 15 daq)'),
  ('jwt_refresh_expiry_days',       '30',     'Refresh token muddati (kun)');
```

---

## 6. API ARXITEKTURASI — BARCHA ENDPOINTLAR

### Umumiy qoidalar
- **Base URL:** `/api/v1`
- **Auth Header:** `Authorization: Bearer <access_token>`
- **Idempotency Header:** `X-Idempotency-Key: <uuid>` (moliyaviy so'rovlar uchun MAJBURIY)
- **Content-Type:** `application/json`
- **Versiyalash:** URL asosida (`/api/v1/`, `/api/v2/` — kelajakda)

**Muvaffaqiyatli javob formati:**
```json
{
  "success": true,
  "data": { ... },
  "meta": { "page": 1, "size": 20, "total": 150, "totalPages": 8 }
}
```

**Xatolik formati:**
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Telefon raqami noto'g'ri formatda",
    "details": [{ "field": "phoneNumber", "message": "..." }]
  }
}
```

### Auth Endpointlar `/api/v1/auth`

| Metod | Endpoint | Rol | Tavsif |
|-------|----------|-----|--------|
| `POST` | `/send-otp` | Public | SMS OTP yuborish |
| `POST` | `/verify-otp` | Public | OTP tasdiqlash |
| `POST` | `/register` | Public | Ro'yxatdan o'tish |
| `POST` | `/login` | Public | Kirish (token olish) |
| `POST` | `/refresh` | Auth | Access tokenni yangilash |
| `POST` | `/logout` | Auth | Chiqish |
| `POST` | `/2fa/send` | Auth | 2FA SMS yuborish |
| `POST` | `/2fa/verify` | Auth | 2FA tasdiqlash |

### Foydalanuvchi Endpointlari `/api/v1/users`

| Metod | Endpoint | Rol | Tavsif |
|-------|----------|-----|--------|
| `GET` | `/me` | Auth | O'z profili |
| `PATCH` | `/me` | Auth | Profilni tahrirlash |
| `POST` | `/me/kyc` | Auth | KYC hujjatlarini yuklash |
| `GET` | `/{id}/public` | Auth | Fermer publik profili |
| `GET` | `/` | ADMIN+ | Barcha foydalanuvchilar (filter + paginate) |
| `GET` | `/{id}` | ADMIN+ | Bitta foydalanuvchi detail |
| `PATCH` | `/{id}/block` | ADMIN+ | Bloklash / faollashtirish |
| `PATCH` | `/{id}/kyc` | ADMIN+ | KYC statusini yangilash |

### Loyiha Endpointlari `/api/v1/projects`

| Metod | Endpoint | Rol | Tavsif |
|-------|----------|-----|--------|
| `GET` | `/` | Public | Loyihalar ro'yxati (filter + paginate) |
| `GET` | `/{id}` | Public | Bitta loyiha to'liq |
| `POST` | `/` | FARMER | Yangi loyiha yaratish |
| `PATCH` | `/{id}` | FARMER | Tahrirlash (faqat PENDING da) |
| `DELETE` | `/{id}` | FARMER | Bekor qilish (faqat PENDING da) |
| `GET` | `/my` | FARMER | Fermerning o'z loyihalari |
| `POST` | `/{id}/media` | FARMER | Rasm/video yuklash |
| `DELETE` | `/{id}/media/{mediaId}` | FARMER | Media o'chirish |
| `PATCH` | `/{id}/status` | ADMIN+ | Holat o'zgartirish |
| `GET` | `/pending` | ADMIN+ | Tasdiqlash kutayotganlar |

**Namuna — Loyiha yaratish:**
```http
POST /api/v1/projects
Authorization: Bearer <token>
Content-Type: application/json

{
  "assetType": "LIVESTOCK",
  "title": "50 ta boquv qo'zisi — Qashqadaryo",
  "description": "3 oylik boquv davri, Qurbon hayit mavsumiga mo'ljallangan",
  "region": "Qashqadaryo",
  "targetAmount": 15000000,
  "minInvestment": 500000,
  "expectedReturnPct": 22.0,
  "durationDays": 90,
  "riskLevel": "MEDIUM"
}

// 201 Created
{
  "success": true,
  "data": {
    "id": "b3f1a2c3-...",
    "status": "PENDING",
    "createdAt": "2026-07-06T03:00:00Z"
  }
}
```

### Investitsiya Endpointlari `/api/v1/investments`

| Metod | Endpoint | Rol | Tavsif |
|-------|----------|-----|--------|
| `POST` | `/` | INVESTOR | Yangi investitsiya yaratish |
| `GET` | `/my` | INVESTOR | O'z investitsiyalari |
| `GET` | `/{id}` | Auth | Bitta investitsiya |
| `POST` | `/{id}/cancel` | INVESTOR | Bekor qilish (24 soat ichida) |
| `GET` | `/{id}/contract` | Auth | Shartnoma PDF yuklab olish |
| `GET` | `/project/{projectId}` | ADMIN+ | Loyihaning investitsiyalari |

### Hisobot Endpointlari `/api/v1/reports`

| Metod | Endpoint | Rol | Tavsif |
|-------|----------|-----|--------|
| `POST` | `/project/{id}` | FARMER/VERIFIER | Yangi hisobot (multipart) |
| `GET` | `/project/{id}` | Auth | Loyiha hisobotlari |
| `GET` | `/{id}` | Auth | Bitta hisobot |
| `POST` | `/project/{id}/emergency` | FARMER | Favqulodda signal |
| `PATCH` | `/{id}/verify` | ADMIN+ | Tasdiqlash |
| `GET` | `/unverified` | ADMIN+ | Tasdiqlanmagan hisobotlar |

### Hamyon Endpointlari `/api/v1/wallet`

| Metod | Endpoint | Rol | Tavsif |
|-------|----------|-----|--------|
| `GET` | `/` | Auth | Hamyon holati |
| `GET` | `/transactions` | Auth | Tranzaksiyalar tarixi (paginate) |

### To'lov Endpointlari `/api/v1/payments`

| Metod | Endpoint | Rol | Tavsif |
|-------|----------|-----|--------|
| `POST` | `/payme/webhook` | System | Payme webhook (CheckPerformTransaction) |
| `POST` | `/click/prepare` | System | Click Prepare endpoint |
| `POST` | `/click/complete` | System | Click Complete endpoint |

### Pul Yechish Endpointlari `/api/v1/withdrawals`

| Metod | Endpoint | Rol | Tavsif |
|-------|----------|-----|--------|
| `POST` | `/` | Auth | Yangi so'rov |
| `GET` | `/my` | Auth | O'z so'rovlari |
| `GET` | `/` | ADMIN+ | Barcha so'rovlar |
| `PATCH` | `/{id}` | ADMIN+ | Tasdiqlash / rad etish |

### Daromad Taqsimlash `/api/v1/payouts`

| Metod | Endpoint | Rol | Tavsif |
|-------|----------|-----|--------|
| `POST` | `/distribute/{projectId}` | ADMIN+ | Daromadni taqsimlash |

### Nizolar Endpointlari `/api/v1/disputes`

| Metod | Endpoint | Rol | Tavsif |
|-------|----------|-----|--------|
| `POST` | `/` | Auth | Nizo ochish |
| `GET` | `/` | ADMIN+ | Barcha nizolar |
| `GET` | `/{id}` | Auth | Bitta nizo |
| `PATCH` | `/{id}` | ADMIN+ | Hal qilish |

### Bildirishnoma Endpointlari `/api/v1/notifications`

| Metod | Endpoint | Rol | Tavsif |
|-------|----------|-----|--------|
| `GET` | `/` | Auth | O'z bildirishnomalari |
| `PATCH` | `/{id}/read` | Auth | O'qilgan |
| `PATCH` | `/read-all` | Auth | Hammasini o'qilgan |

### Admin Endpointlari `/api/v1/admin`

| Metod | Endpoint | Rol | Tavsif |
|-------|----------|-----|--------|
| `GET` | `/dashboard` | ADMIN+ | KPI statistikasi |
| `GET` | `/farmers/pending` | ADMIN+ | Vetting kutayotganlar |
| `GET` | `/projects/pending` | ADMIN+ | Tasdiqlash kutayotganlar |
| `GET` | `/transactions` | ADMIN+ | Barcha tranzaksiyalar |
| `GET` | `/reports/unverified` | ADMIN+ | Tasdiqlanmagan hisobotlar |

### SuperAdmin Endpointlari `/api/v1/superadmin`

| Metod | Endpoint | Rol | Tavsif |
|-------|----------|-----|--------|
| `GET` | `/dashboard` | SUPERADMIN | To'liq tizim statistikasi (GMV, MAU, Revenue) |
| `GET` | `/accounts` | SUPERADMIN | Barcha admin/moderator/verifier akkountlar |
| `POST` | `/accounts` | SUPERADMIN | Yangi admin/moderator/verifier yaratish |
| `GET` | `/accounts/{id}` | SUPERADMIN | Akkount detail |
| `PATCH` | `/accounts/{id}` | SUPERADMIN | Akkountni tahrirlash |
| `DELETE` | `/accounts/{id}` | SUPERADMIN | Akkountni o'chirish |
| `PATCH` | `/accounts/{id}/block` | SUPERADMIN | Bloklash / aktivlashtirish |
| `GET` | `/audit-logs` | SUPERADMIN | Audit log (filter: user, action, date + paginate) |
| `GET` | `/audit-logs/export` | SUPERADMIN | Audit log CSV eksport |
| `GET` | `/settings` | SUPERADMIN | Platform sozlamalari |
| `PATCH` | `/settings` | SUPERADMIN | Sozlamalarni yangilash |
| `POST` | `/emergency/freeze` | SUPERADMIN | Loyiha/hisob/tranzaksiya freeze |
| `GET` | `/stats/export` | SUPERADMIN | To'liq statistika CSV/Excel eksport |

---

## 7. TO'LOV VA MOLIYAVIY OQİM MEXANİZMI

### 7.1 Pul oqimi bosqichlari
```
1. KIRISH:     Investor → Payme/Click → Platforma hisob
2. ESCROW:     wallets.balance → wallets.frozen (loyiha to'liq yig'ilgunga qadar)
3. FERMERGA:   50% yig'ilgach → bosqich 1 | 100% yig'ilgach → bosqich 2
4. SOTISH:     Tushum → Platforma hisobiga
5. TAQSIMLASH: Komissiya (8-15%) → investor ulushi → fermer ulushi
6. YECHISH:    Foydalanuvchi so'rovi → Admin tasdiqlash → Bank/Karta
```

### 7.2 Payme integratsiyasi (3 bosqichli protokol)
```
POST /api/v1/payments/payme/webhook

Metodlar:
- CheckPerformTransaction → loyiha mavjudligini tekshirish
- CreateTransaction        → tranzaksiya yaratish (PENDING)
- PerformTransaction       → tasdiqlash (COMPLETED)
- CancelTransaction        → bekor qilish (CANCELLED)
- CheckTransaction         → holat tekshirish
- GetStatement             → davriy hisobot
```

### 7.3 Click integratsiyasi (2 bosqichli protokol)
```
POST /api/v1/payments/click/prepare  → amount va order tekshirish
POST /api/v1/payments/click/complete → to'lovni yakunlash
```

### 7.4 Escrow mantig'i (Spring @Transactional)
```java
@Transactional
public void confirmInvestment(UUID investmentId) {
    Investment investment = findById(investmentId);
    Wallet wallet = walletRepo.findByUserId(investment.getInvestorId());

    // 1. Hamyondan yechish
    wallet.setBalance(wallet.getBalance().subtract(investment.getAmount()));
    wallet.setFrozen(wallet.getFrozen().add(investment.getAmount()));

    // 2. Loyihaga qo'shish
    project.setRaisedAmount(project.getRaisedAmount().add(investment.getAmount()));

    // 3. Immutable tranzaksiya yozish
    transactionRepo.save(Transaction.builder()
        .userId(investment.getInvestorId())
        .projectId(investment.getProjectId())
        .investmentId(investment.getId())
        .type(TransactionType.DEPOSIT)
        .amount(investment.getAmount())
        .status(TransactionStatus.COMPLETED)
        .build());
}
```

---

## 8. ISHONCH, NAZORAT VA XAVFSIZLIK

### 8.1 Fermerni tekshirish (Vetting) jarayoni
**Majburiy hujjatlar:**
1. Pasport (skaneri yoki foto)
2. STIR (agar mavjud)
3. Yer/mulk huquqi yoki ijara shartnomasi
4. Oldingi tajriba (foto, guvohnomalar)
5. Birinchi 10-20 fermer uchun: admin/verifikator shaxsan tashrifi

**Vetting holat mashinalari:**
```
[FARMER ro'yxatdan o'tadi] → [kyc_status = PENDING]
         ↓
[Admin hujjatlarni ko'radi (1-2 ish kuni)]
         ↓
[Tasdiqlash]  → kyc_status = VERIFIED → Loyiha yarata oladi
[Rad etish]   → kyc_status = REJECTED + sabab → Qayta yuklash
```

### 8.2 Monitoring mexanizmlari

| Mexanizm | Ishlash | Bosqich |
|----------|---------|---------|
| Davriy foto/video | Har 14 kunda majburiy (GPS bilan) | ✅ MVP |
| Geolokatsiya tekshiruv | GPS koordinatalar solishtirish | ✅ MVP |
| Kechikkan hisobot ogohlantirish | 2 kun o'tsa → SMS + Telegram | ✅ MVP |
| Tasodifiy dala tashrifi | Verifikator kutilmagan tashrif | 2-bosqich |
| Video-qo'ng'iroq | Jonli ko'rish | 2-bosqich |
| IoT sensorlar | GPS-teg, harorat sensori | 3-bosqich |

### 8.3 Halokat siyosati
Har bir loyiha sahifasida **MAJBURIY** ko'rsatiladi:
- Xavf darajasi (LOW / MEDIUM / HIGH) va uning ma'nosi
- `"Kafolatlangan daromad yo'q — bu KUTILAYOTGAN daromad"` xabardorligi
- Halokat holatida nima bo'lishi: veterinar xulosasi → foto-dalil → zaxira fond → investor xabardor qilish

### 8.4 Texnik xavfsizlik (Spring Security)
```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {
  // HTTPS majburiy (TLS 1.3)
  // Parollar: BCryptPasswordEncoder (strength=12)
  // JWT: access=15 daqiqa, refresh=30 kun (Redis da)
  // RBAC: @PreAuthorize("hasRole('ADMIN')")
  // Rate limiting: Bucket4j + Redis
  // CORS: faqat ruxsat etilgan domainlar
  // Audit log: barcha muvaffaqiyatli va muvaffaqiyatsiz amallar
}
```

---

## 9. HUQUQIY JIHATLAR

> ⚠️ Bu bo'lim umumiy yo'nalish beradi. Loyihani ishga tushirishdan oldin O'zbekiston qonunlari bo'yicha ixtisoslashgan yurist bilan maslahatlashing.

### 9.1 Shartnoma turlari
1. **Investor–Platforma shartnomasi** — xizmat shartlari, foydalanuvchi qoidalari
2. **Fermer–Platforma shartnomasi** — vetting, hisobot majburiyatlari, komissiya
3. **Investor–Fermer investitsiya shartnomasi** — har bir investitsiya uchun avtomatik PDF generatsiya

### 9.2 Tavsiyalar
- IT Park rezidenti sifatida ro'yxatdan o'tish (soliq imtiyozlari)
- "Kutilayotgan"/"tarixiy" daromad — hech qachon "kafolatlangan" emas
- Kichik, tanish doiradagi investorlar bilan boshlash
- Chet el investorlari: alohida huquqiy tekshiruv

---

## 10. PAPKA TUZILMASI

### Backend (Java Spring Boot)
```
agroinvest-backend/
├── pom.xml
├── Dockerfile
├── .env.example
└── src/
    ├── main/
    │   ├── java/uz/agroinvest/
    │   │   ├── AgroInvestApplication.java
    │   │   ├── config/
    │   │   │   ├── SecurityConfig.java
    │   │   │   ├── JwtConfig.java
    │   │   │   ├── RedisConfig.java
    │   │   │   ├── S3Config.java
    │   │   │   ├── CorsConfig.java
    │   │   │   └── SwaggerConfig.java
    │   │   ├── security/
    │   │   │   ├── JwtTokenProvider.java
    │   │   │   ├── JwtAuthFilter.java
    │   │   │   ├── UserPrincipal.java
    │   │   │   └── CustomUserDetailsService.java
    │   │   ├── module/
    │   │   │   ├── auth/
    │   │   │   │   ├── AuthController.java
    │   │   │   │   ├── AuthService.java
    │   │   │   │   ├── OtpService.java
    │   │   │   │   └── dto/
    │   │   │   │       ├── SendOtpRequest.java
    │   │   │   │       ├── VerifyOtpRequest.java
    │   │   │   │       ├── RegisterRequest.java
    │   │   │   │       ├── LoginRequest.java
    │   │   │   │       └── AuthResponse.java
    │   │   │   ├── user/
    │   │   │   │   ├── UserController.java
    │   │   │   │   ├── UserService.java
    │   │   │   │   ├── UserRepository.java
    │   │   │   │   ├── entity/User.java
    │   │   │   │   └── dto/
    │   │   │   │       ├── UserDto.java
    │   │   │   │       ├── UpdateProfileRequest.java
    │   │   │   │       └── KycRequest.java
    │   │   │   ├── project/
    │   │   │   │   ├── ProjectController.java
    │   │   │   │   ├── ProjectService.java
    │   │   │   │   ├── ProjectRepository.java
    │   │   │   │   ├── entity/Project.java
    │   │   │   │   └── dto/
    │   │   │   │       ├── ProjectDto.java
    │   │   │   │       ├── CreateProjectRequest.java
    │   │   │   │       ├── UpdateProjectRequest.java
    │   │   │   │       └── ProjectFilterRequest.java
    │   │   │   ├── investment/
    │   │   │   │   ├── InvestmentController.java
    │   │   │   │   ├── InvestmentService.java
    │   │   │   │   ├── InvestmentRepository.java
    │   │   │   │   ├── entity/Investment.java
    │   │   │   │   └── dto/
    │   │   │   │       ├── InvestmentDto.java
    │   │   │   │       └── CreateInvestmentRequest.java
    │   │   │   ├── payment/
    │   │   │   │   ├── PaymentController.java
    │   │   │   │   ├── PaymentService.java
    │   │   │   │   ├── PaymeService.java
    │   │   │   │   ├── ClickService.java
    │   │   │   │   └── dto/
    │   │   │   │       ├── PaymeWebhookRequest.java
    │   │   │   │       ├── ClickPrepareRequest.java
    │   │   │   │       └── ClickCompleteRequest.java
    │   │   │   ├── report/
    │   │   │   │   ├── ReportController.java
    │   │   │   │   ├── ReportService.java
    │   │   │   │   ├── ReportRepository.java
    │   │   │   │   ├── entity/Report.java
    │   │   │   │   └── dto/
    │   │   │   │       ├── ReportDto.java
    │   │   │   │       └── CreateReportRequest.java
    │   │   │   ├── wallet/
    │   │   │   │   ├── WalletController.java
    │   │   │   │   ├── WalletService.java
    │   │   │   │   ├── WalletRepository.java
    │   │   │   │   └── entity/Wallet.java
    │   │   │   ├── transaction/
    │   │   │   │   ├── TransactionController.java
    │   │   │   │   ├── TransactionService.java
    │   │   │   │   ├── TransactionRepository.java
    │   │   │   │   └── entity/Transaction.java
    │   │   │   ├── withdrawal/
    │   │   │   │   ├── WithdrawalController.java
    │   │   │   │   ├── WithdrawalService.java
    │   │   │   │   ├── WithdrawalRepository.java
    │   │   │   │   └── entity/WithdrawalRequest.java
    │   │   │   ├── notification/
    │   │   │   │   ├── NotificationController.java
    │   │   │   │   ├── NotificationService.java
    │   │   │   │   ├── TelegramService.java
    │   │   │   │   ├── SmsService.java
    │   │   │   │   └── entity/Notification.java
    │   │   │   ├── dispute/
    │   │   │   │   ├── DisputeController.java
    │   │   │   │   ├── DisputeService.java
    │   │   │   │   ├── DisputeRepository.java
    │   │   │   │   └── entity/Dispute.java
    │   │   │   ├── admin/
    │   │   │   │   ├── AdminController.java
    │   │   │   │   ├── AdminService.java
    │   │   │   │   └── dto/DashboardStatsDto.java
    │   │   │   └── superadmin/
    │   │   │       ├── SuperAdminController.java
    │   │   │       ├── SuperAdminService.java
    │   │   │       ├── AuditLogRepository.java
    │   │   │       ├── PlatformSettingsRepository.java
    │   │   │       └── entity/
    │   │   │           ├── AuditLog.java
    │   │   │           └── PlatformSettings.java
    │   │   ├── common/
    │   │   │   ├── exception/
    │   │   │   │   ├── GlobalExceptionHandler.java
    │   │   │   │   ├── ApiException.java
    │   │   │   │   └── ErrorCode.java
    │   │   │   ├── response/
    │   │   │   │   ├── ApiResponse.java
    │   │   │   │   └── PageResponse.java
    │   │   │   ├── enums/
    │   │   │   │   ├── UserRole.java
    │   │   │   │   ├── ProjectStatus.java
    │   │   │   │   ├── KycStatus.java
    │   │   │   │   ├── InvestmentStatus.java
    │   │   │   │   ├── TransactionType.java
    │   │   │   │   └── AssetType.java
    │   │   │   └── util/
    │   │   │       ├── EncryptionUtil.java    ← AES-256
    │   │   │       ├── CalculationUtil.java   ← Daromad formula
    │   │   │       └── FileUploadUtil.java    ← S3 yuklaish
    │   │   └── integration/
    │   │       ├── s3/S3Service.java
    │   │       ├── payme/PaymeClient.java
    │   │       ├── click/ClickClient.java
    │   │       ├── sms/SmsClient.java
    │   │       └── telegram/TelegramClient.java
    │   └── resources/
    │       ├── application.yml
    │       ├── application-dev.yml
    │       ├── application-prod.yml
    │       └── db/migration/
    │           ├── V1__init_enums_and_tables.sql
    │           ├── V2__indexes.sql
    │           ├── V3__superadmin_and_settings.sql
    │           ├── V4__seed_superadmin.sql
    │           └── V5__platform_constraints.sql
    └── test/
        └── java/uz/agroinvest/
            ├── auth/AuthControllerTest.java
            ├── project/ProjectServiceTest.java
            └── payment/PaymentServiceTest.java
```

### Web Frontend (React + JS + Tailwind)
```
agroinvest-web/
├── public/index.html
├── src/
│   ├── index.js
│   ├── App.jsx
│   ├── api/
│   │   ├── axios.js              ← Base instance + interceptors
│   │   ├── auth.api.js
│   │   ├── projects.api.js
│   │   ├── investments.api.js
│   │   ├── reports.api.js
│   │   ├── wallet.api.js
│   │   ├── admin.api.js
│   │   └── superadmin.api.js
│   ├── store/
│   │   ├── auth.store.js         ← Zustand
│   │   └── notification.store.js
│   ├── hooks/
│   │   ├── useAuth.js
│   │   ├── useProjects.js
│   │   └── useDebounce.js
│   ├── pages/
│   │   ├── public/
│   │   │   ├── LandingPage.jsx
│   │   │   ├── ProjectsPage.jsx
│   │   │   └── ProjectDetailPage.jsx
│   │   ├── auth/
│   │   │   ├── LoginPage.jsx
│   │   │   └── RegisterPage.jsx
│   │   ├── investor/
│   │   │   ├── InvestorDashboard.jsx
│   │   │   ├── MyInvestments.jsx
│   │   │   ├── WalletPage.jsx
│   │   │   └── ProfilePage.jsx
│   │   ├── farmer/
│   │   │   ├── FarmerDashboard.jsx
│   │   │   ├── MyProjects.jsx
│   │   │   ├── CreateProject.jsx
│   │   │   └── UploadReport.jsx
│   │   ├── admin/
│   │   │   ├── AdminDashboard.jsx
│   │   │   ├── FarmerVerification.jsx
│   │   │   ├── ProjectApproval.jsx
│   │   │   ├── TransactionsPage.jsx
│   │   │   ├── DisputesPage.jsx
│   │   │   └── WithdrawalApproval.jsx
│   │   └── superadmin/
│   │       ├── SuperAdminDashboard.jsx
│   │       ├── AccountsManagement.jsx
│   │       ├── AuditLog.jsx
│   │       ├── PlatformSettings.jsx
│   │       └── SystemStats.jsx
│   ├── components/
│   │   ├── ui/
│   │   │   ├── Button.jsx
│   │   │   ├── Input.jsx
│   │   │   ├── Select.jsx
│   │   │   ├── Modal.jsx
│   │   │   ├── Badge.jsx
│   │   │   ├── Table.jsx
│   │   │   ├── Pagination.jsx
│   │   │   ├── Spinner.jsx
│   │   │   ├── Alert.jsx
│   │   │   ├── Card.jsx
│   │   │   └── ProgressBar.jsx
│   │   ├── auth/
│   │   │   ├── OTPInput.jsx
│   │   │   ├── KYCForm.jsx
│   │   │   └── ProtectedRoute.jsx
│   │   ├── layout/
│   │   │   ├── Navbar.jsx
│   │   │   ├── Sidebar.jsx
│   │   │   ├── Footer.jsx
│   │   │   ├── DashboardLayout.jsx
│   │   │   └── PublicLayout.jsx
│   │   ├── projects/
│   │   │   ├── ProjectCard.jsx
│   │   │   ├── ProjectFilters.jsx
│   │   │   ├── ProjectTimeline.jsx
│   │   │   └── InvestmentModal.jsx
│   │   ├── charts/
│   │   │   ├── RevenueChart.jsx     ← Recharts
│   │   │   ├── InvestmentChart.jsx
│   │   │   └── StatsCards.jsx
│   │   └── notifications/
│   │       └── NotificationBell.jsx
│   ├── utils/
│   │   ├── formatters.js            ← So'm formatlash, sana
│   │   ├── validators.js
│   │   └── constants.js
│   └── styles/
│       └── index.css                ← Tailwind @tailwind directives
├── tailwind.config.js
├── postcss.config.js
├── .env
├── .env.example
└── package.json
```

### Mobile (Flutter)
```
agroinvest-mobile/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_text_styles.dart
│   │   │   └── api_constants.dart
│   │   ├── network/
│   │   │   ├── dio_client.dart
│   │   │   └── interceptors/auth_interceptor.dart
│   │   ├── storage/
│   │   │   └── secure_storage.dart
│   │   └── utils/
│   │       ├── formatters.dart
│   │       └── validators.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── auth_repository.dart
│   │   │   │   └── models/
│   │   │   │       ├── auth_response.dart
│   │   │   │       └── user_model.dart
│   │   │   └── presentation/
│   │   │       ├── pages/
│   │   │       │   ├── splash_page.dart
│   │   │       │   ├── onboarding_page.dart
│   │   │       │   ├── login_page.dart
│   │   │       │   ├── register_page.dart
│   │   │       │   └── otp_page.dart
│   │   │       └── providers/auth_provider.dart
│   │   ├── projects/
│   │   │   ├── data/
│   │   │   │   ├── project_repository.dart
│   │   │   │   └── models/project_model.dart
│   │   │   └── presentation/
│   │   │       ├── pages/
│   │   │       │   ├── projects_list_page.dart
│   │   │       │   ├── project_detail_page.dart
│   │   │       │   └── create_project_page.dart
│   │   │       └── providers/projects_provider.dart
│   │   ├── investments/
│   │   │   ├── data/investment_repository.dart
│   │   │   └── presentation/
│   │   │       ├── pages/
│   │   │       │   ├── my_investments_page.dart
│   │   │       │   └── invest_page.dart
│   │   │       └── providers/investment_provider.dart
│   │   ├── reports/
│   │   │   ├── data/report_repository.dart
│   │   │   └── presentation/
│   │   │       ├── pages/
│   │   │       │   ├── reports_timeline_page.dart
│   │   │       │   └── upload_report_page.dart
│   │   │       └── providers/reports_provider.dart
│   │   ├── wallet/
│   │   │   └── presentation/
│   │   │       ├── pages/wallet_page.dart
│   │   │       └── providers/wallet_provider.dart
│   │   ├── profile/
│   │   │   └── presentation/
│   │   │       └── pages/profile_page.dart
│   │   └── notifications/
│   │       └── presentation/
│   │           └── pages/notifications_page.dart
│   └── shared/
│       ├── widgets/
│       │   ├── custom_button.dart
│       │   ├── custom_text_field.dart
│       │   ├── loading_widget.dart
│       │   ├── project_card.dart
│       │   ├── progress_bar_widget.dart
│       │   ├── stat_card.dart
│       │   └── bottom_nav_bar.dart
│       └── providers/app_provider.dart
└── android/ ios/ (Flutter defaults)
```

---

## 11. BACKEND DEPENDENCIES (pom.xml)

```xml
<project>
  <groupId>uz.agroinvest</groupId>
  <artifactId>agroinvest-backend</artifactId>
  <version>1.0.0</version>
  <packaging>jar</packaging>

  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.3.5</version>
  </parent>

  <properties>
    <java.version>17</java.version>
    <mapstruct.version>1.6.0</mapstruct.version>
    <jjwt.version>0.12.6</jjwt.version>
    <aws.version>2.26.0</aws.version>
  </properties>

  <dependencies>
    <!-- Spring Boot Core -->
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-redis</artifactId>
    </dependency>
    <!-- WebClient (Payme/Click/SMS HTTP) -->
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-webflux</artifactId>
    </dependency>

    <!-- PostgreSQL -->
    <dependency>
      <groupId>org.postgresql</groupId>
      <artifactId>postgresql</artifactId>
      <scope>runtime</scope>
    </dependency>

    <!-- Flyway -->
    <dependency>
      <groupId>org.flywaydb</groupId>
      <artifactId>flyway-core</artifactId>
    </dependency>
    <dependency>
      <groupId>org.flywaydb</groupId>
      <artifactId>flyway-database-postgresql</artifactId>
    </dependency>

    <!-- JWT (JJWT) -->
    <dependency>
      <groupId>io.jsonwebtoken</groupId>
      <artifactId>jjwt-api</artifactId>
      <version>${jjwt.version}</version>
    </dependency>
    <dependency>
      <groupId>io.jsonwebtoken</groupId>
      <artifactId>jjwt-impl</artifactId>
      <version>${jjwt.version}</version>
      <scope>runtime</scope>
    </dependency>
    <dependency>
      <groupId>io.jsonwebtoken</groupId>
      <artifactId>jjwt-jackson</artifactId>
      <version>${jjwt.version}</version>
      <scope>runtime</scope>
    </dependency>

    <!-- AWS S3 SDK (Cloudflare R2) -->
    <dependency>
      <groupId>software.amazon.awssdk</groupId>
      <artifactId>s3</artifactId>
      <version>${aws.version}</version>
    </dependency>

    <!-- OpenAPI / Swagger -->
    <dependency>
      <groupId>org.springdoc</groupId>
      <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
      <version>2.6.0</version>
    </dependency>

    <!-- Lombok -->
    <dependency>
      <groupId>org.projectlombok</groupId>
      <artifactId>lombok</artifactId>
      <optional>true</optional>
    </dependency>

    <!-- MapStruct -->
    <dependency>
      <groupId>org.mapstruct</groupId>
      <artifactId>mapstruct</artifactId>
      <version>${mapstruct.version}</version>
    </dependency>
    <dependency>
      <groupId>org.mapstruct</groupId>
      <artifactId>mapstruct-processor</artifactId>
      <version>${mapstruct.version}</version>
      <scope>provided</scope>
    </dependency>

    <!-- Rate Limiting -->
    <dependency>
      <groupId>com.bucket4j</groupId>
      <artifactId>bucket4j-redis</artifactId>
      <version>8.14.0</version>
    </dependency>

    <!-- PDF Generation (shartnoma) -->
    <dependency>
      <groupId>com.itextpdf</groupId>
      <artifactId>itext7-core</artifactId>
      <version>8.0.5</version>
      <type>pom</type>
    </dependency>

    <!-- Sentry -->
    <dependency>
      <groupId>io.sentry</groupId>
      <artifactId>sentry-spring-boot-starter-jakarta</artifactId>
      <version>7.16.0</version>
    </dependency>

    <!-- Test -->
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-test</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.springframework.security</groupId>
      <artifactId>spring-security-test</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.testcontainers</groupId>
      <artifactId>postgresql</artifactId>
      <scope>test</scope>
    </dependency>
  </dependencies>
</project>
```

---

## 12. MOBILE PACKAGES (pubspec.yaml)

```yaml
name: agroinvest
description: AgroInvest — Fermer va investor bog'lovchi platforma
version: 1.0.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

  # State management
  provider: ^6.1.2

  # HTTP
  dio: ^5.7.0

  # Secure token saqlash
  flutter_secure_storage: ^9.2.2

  # Navigation
  go_router: ^14.2.7

  # Image picker (foto yuklash)
  image_picker: ^1.1.2

  # File picker (hujjat yuklash)
  file_picker: ^8.1.2

  # Kamera (to'g'ridan-to'g'ri suratga olish)
  camera: ^0.11.0+2

  # GPS / Geolokatsiya
  geolocator: ^13.0.1
  geocoding: ^3.0.0

  # Firebase (push notifications)
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3

  # Local notifications
  flutter_local_notifications: ^17.2.4

  # Image cache
  cached_network_image: ^3.4.1

  # Video player
  video_player: ^2.9.1

  # Grafik/charts
  fl_chart: ^0.69.0

  # Shimmer skeleton loading
  shimmer: ^3.0.0

  # Toast xabarlari
  fluttertoast: ^8.2.8

  # URL ochish
  url_launcher: ^6.3.1

  # Env
  flutter_dotenv: ^5.2.1

  # Sana/vaqt formatlash
  intl: ^0.19.0

  # Internet holati
  connectivity_plus: ^6.0.5

  # Lottie animatsiyalar
  lottie: ^3.1.2

  # WebView (Payme/Click to'lov sahifasi)
  webview_flutter: ^4.10.0

  # Pinch-to-zoom rasmlar uchun
  photo_view: ^0.15.0

  # Shared preferences
  shared_preferences: ^2.3.2

  # OTP input widget
  pin_code_fields: ^8.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.12
```

---

## 13. MUHIT O'ZGARUVCHILARI (.env)

### Backend `application.yml`
```yaml
server:
  port: 8080
  servlet:
    context-path: /

spring:
  application:
    name: agroinvest-backend
  datasource:
    url: jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:agroinvest_db}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
    driver-class-name: org.postgresql.Driver
    hikari:
      maximum-pool-size: 10
      minimum-idle: 5
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
    open-in-view: false
  flyway:
    enabled: true
    locations: classpath:db/migration
    baseline-on-migrate: true
  redis:
    host: ${REDIS_HOST:localhost}
    port: ${REDIS_PORT:6379}
    password: ${REDIS_PASSWORD:}
    timeout: 2000ms
  servlet:
    multipart:
      max-file-size: 50MB
      max-request-size: 100MB

jwt:
  secret: ${JWT_SECRET}
  access-expiry-seconds: 900
  refresh-expiry-seconds: 2592000

encryption:
  key: ${ENCRYPTION_KEY}

s3:
  endpoint: ${S3_ENDPOINT}
  access-key: ${S3_ACCESS_KEY}
  secret-key: ${S3_SECRET_KEY}
  bucket: ${S3_BUCKET_NAME}
  public-url: ${S3_PUBLIC_URL}

payme:
  merchant-id: ${PAYME_MERCHANT_ID}
  secret-key: ${PAYME_SECRET_KEY}
  test-secret-key: ${PAYME_TEST_SECRET_KEY}
  test-mode: ${PAYME_TEST_MODE:true}

click:
  merchant-id: ${CLICK_MERCHANT_ID}
  service-id: ${CLICK_SERVICE_ID}
  secret-key: ${CLICK_SECRET_KEY}

sms:
  base-url: https://notify.eskiz.uz
  email: ${SMS_EMAIL}
  password: ${SMS_PASSWORD}
  from: ${SMS_FROM:4546}

telegram:
  bot-token: ${TELEGRAM_BOT_TOKEN}
  bot-username: ${TELEGRAM_BOT_USERNAME}

sentry:
  dsn: ${SENTRY_DSN:}
  environment: ${SPRING_PROFILES_ACTIVE:dev}

springdoc:
  api-docs:
    path: /api/docs
  swagger-ui:
    path: /swagger-ui.html
```

### Backend `.env.example`
```env
# PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_NAME=agroinvest_db
DB_USERNAME=agroinvest_user
DB_PASSWORD=strong_password_here

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT (minimum 32 ta belgi)
JWT_SECRET=your_super_secret_jwt_key_minimum_32_chars!!

# AES-256 shifrlash (pasport ma'lumotlari uchun — ANIQ 32 ta belgi)
ENCRYPTION_KEY=32_char_aes256_key_must_be_here!

# Cloudflare R2 (yoki AWS S3)
S3_ENDPOINT=https://xxx.r2.cloudflarestorage.com
S3_ACCESS_KEY=your_r2_access_key
S3_SECRET_KEY=your_r2_secret_key
S3_BUCKET_NAME=agroinvest-files
S3_PUBLIC_URL=https://files.agroinvest.uz

# Payme
PAYME_MERCHANT_ID=your_payme_merchant_id
PAYME_SECRET_KEY=your_payme_secret_key
PAYME_TEST_SECRET_KEY=your_payme_test_key
PAYME_TEST_MODE=true

# Click
CLICK_MERCHANT_ID=your_click_merchant_id
CLICK_SERVICE_ID=your_click_service_id
CLICK_SECRET_KEY=your_click_secret_key

# SMS (Eskiz.uz)
SMS_EMAIL=your@email.com
SMS_PASSWORD=your_eskiz_password
SMS_FROM=4546

# Telegram Bot
TELEGRAM_BOT_TOKEN=1234567890:ABCDefGhIjKlMnOpQrStUvWxYz
TELEGRAM_BOT_USERNAME=AgroInvestBot

# Sentry (ixtiyoriy)
SENTRY_DSN=https://xxx@sentry.io/xxx
```

### Web Frontend `.env`
```env
REACT_APP_API_URL=http://localhost:8080/api/v1
REACT_APP_APP_NAME=AgroInvest
REACT_APP_PAYME_MERCHANT_ID=your_merchant_id
REACT_APP_CLICK_MERCHANT_ID=your_merchant_id
```

### Flutter `.env`
```env
API_BASE_URL=http://localhost:8080/api/v1
APP_NAME=AgroInvest
```

---

## 14. DOCKER VA DEPLOYMENT

### `docker-compose.yml` (Local development)
```yaml
version: '3.9'

services:
  postgres:
    image: postgres:16-alpine
    container_name: agroinvest_postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: agroinvest_db
      POSTGRES_USER: agroinvest_user
      POSTGRES_PASSWORD: strong_password_here
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U agroinvest_user -d agroinvest_db"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: agroinvest_redis
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD:-}
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  backend:
    build:
      context: ./agroinvest-backend
      dockerfile: Dockerfile
    container_name: agroinvest_backend
    restart: unless-stopped
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    env_file:
      - ./agroinvest-backend/.env
    volumes:
      - ./logs:/app/logs

  frontend:
    build:
      context: ./agroinvest-web
      dockerfile: Dockerfile
    container_name: agroinvest_frontend
    restart: unless-stopped
    ports:
      - "3000:80"
    depends_on:
      - backend

volumes:
  postgres_data:
  redis_data:
```

### Backend `Dockerfile`
```dockerfile
FROM eclipse-temurin:17-jdk-alpine AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN ./mvnw clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### GitHub Actions CI/CD (`.github/workflows/ci.yml`)
```yaml
name: CI/CD Pipeline
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
      - name: Run tests
        run: cd agroinvest-backend && ./mvnw test

  test-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: cd agroinvest-web && npm ci && npm test -- --watchAll=false

  deploy:
    needs: [test-backend, test-frontend]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to VPS
        run: |
          ssh deploy@${{ secrets.VPS_HOST }} "cd /app && git pull && docker-compose up -d --build"
```

---

## 15. SPRINT REJASI (MVP — 10 Hafta)

### Sprint 1 — Foundation (1-2 hafta)
- [ ] Mono-repo tuzilmasi: `agroinvest-backend/`, `agroinvest-web/`, `agroinvest-mobile/`
- [ ] Docker Compose (PostgreSQL 16 + Redis 7) ishga tushirish
- [ ] Backend: Spring Boot loyiha, `pom.xml` sozlash, papka tuzilmasi
- [ ] DB: Flyway migratsiyalar V1-V4 yozish va ishga tushirish
- [ ] Backend: `Auth` moduli — SMS OTP, register, login, JWT, refresh, logout
- [ ] Backend: `User` moduli — profil, KYC yuklash
- [ ] Backend: `SecurityConfig` — 6 rol RBAC, filter chain
- [ ] Web: React loyiha yaratish (`create-react-app` yoki Vite), Tailwind sozlash
- [ ] Web: Axios instance + JWT interceptors + 401 redirect
- [ ] Web: `LoginPage`, `RegisterPage` (OTP flow)

### Sprint 2 — Core Modules (3-4 hafta)
- [ ] Backend: `Project` moduli — CRUD, status mashinasi (PENDING→COMPLETED)
- [ ] Backend: `Investment` moduli — ulush, escrow, idempotency
- [ ] Backend: `Wallet` + `Transaction` modullari (immutable transactions)
- [ ] Backend: `Payme` integratsiyasi (sandbox) — webhook handler
- [ ] Backend: `Click` integratsiyasi (sandbox) — prepare + complete
- [ ] Web: Bosh sahifa — loyihalar ro'yxati + filter + progress bar
- [ ] Web: Loyiha detail sahifasi — to'liq info + InvestmentModal
- [ ] Web: Investor dashboard — investitsiyalarim, hamyon

### Sprint 3 — Admin + SuperAdmin + Monitoring (5-6 hafta)
- [ ] Backend: `Report` moduli — foto/video + GPS + emergency
- [ ] Backend: `Notification` moduli — SMS (Eskiz.uz) + Telegram Bot
- [ ] Backend: `Dispute` moduli — ticket tizimi
- [ ] Backend: `Withdrawal` moduli — so'rov + admin tasdiqlash
- [ ] Backend: `Admin` moduli — dashboard statistikasi
- [ ] Backend: `SuperAdmin` moduli — akkount boshqarish, audit log, settings, emergency freeze
- [ ] Web: Admin panel (6 sahifa: dashboard, vetting, loyihalar, tranzaksiyalar, nizolar, yechish)
- [ ] Web: SuperAdmin panel (5 sahifa: dashboard, akkountlar, audit, settings, stats)
- [ ] Web: Farmer dashboard + hisobot yuklash formasi

### Sprint 4 — Flutter Mobile (7-8 hafta)
- [ ] Flutter: Loyiha arxitekturasi + Provider + Dio setup
- [ ] Flutter: Splash, Onboarding, Login (OTP flow), Register
- [ ] Flutter: Investor: Projects list, Project detail, Invest screen
- [ ] Flutter: Farmer: Farmer dashboard, Create project (ko'p bosqichli), Upload report (GPS + kamera)
- [ ] Flutter: Emergency signal ekrani
- [ ] Flutter: Wallet screen
- [ ] Flutter: Profile + KYC
- [ ] Flutter: Firebase FCM push notifications
- [ ] Flutter: Bottom navigation bar (rol asosida)

### Sprint 5 — Polish + Deploy (9-10 hafta)
- [ ] Backend: PDF shartnoma auto-generatsiya (iText7)
- [ ] Backend: Payout distribution algoritmi (loyiha yakunida)
- [ ] Backend: Kechikkan hisobot uchun Scheduled task
- [ ] Web: Recharts grafiklari (revenue, investment trend)
- [ ] Flutter: Shimmer skeleton loading, Lottie animatsiyalar
- [ ] Testing: JUnit + Mockito + Testcontainers (backend)
- [ ] Testing: Jest + RTL (frontend)
- [ ] Deployment: VPS + Docker + Nginx reverse proxy + SSL (Let's Encrypt)
- [ ] Monitoring: Sentry (backend + frontend + flutter)
- [ ] Swagger UI tekshirish va hujjatlashtirish

---

## 16. BYUDJET TAQSIMOTI ($5,000)

| Yo'nalish | Summa ($) | Izoh |
|-----------|-----------|------|
| Huquqiy maslahat va shartnoma | 600–900 | Eng muhim — qisqartirib bo'lmaydi |
| Server/xosting/domen (12 oy) | 200–350 | VPS (Ubuntu 22.04) + domen + SSL |
| To'lov tizimi integratsiyasi | 0–300 | Payme/Click (ba'zan komissiya asosida) |
| Dizayn (UI/UX) | 300–600 | Figma mockup yoki shablon moslashtirish |
| Pilot zaxira fond | 1000–1500 | Halokat holatida qisman qoplama |
| Marketing | 400–700 | Ijtimoiy tarmoq, kontent, uchrashuvlar |
| Uchinchi tomon xizmatlari | 100–200 | Eskiz.uz, Cloudflare R2, Firebase |
| Kutilmagan xarajatlar | 500–800 | 15-20% zaxira |
| **Jami** | **~3,100–5,350** | |

**Dasturlash xarajati:** Founder o'zi qurayotgani sababli alohida ko'rsatilmagan. Qo'shimcha dasturchi kerak bo'lsa: +$1,000–2,000.

---

## 17. RISKLAR TAHLILI

| Xavf | Ta'siri | Kamaytirish strategiyasi |
|------|---------|--------------------------|
| Fermer yolg'on ma'lumot berishi | Yuqori | Qattiq vetting, shaxsan tashrif, GPS, reyting |
| Hayvon/ekin halokati | Yuqori | Sug'urta, zaxira fond, xavf oldindan ko'rsatish |
| Investor nizo | O'rta | Aniq shartnoma, bekor qilish qoidalari |
| Huquqiy muammolar | Yuqori | Yurist, to'g'ridan-to'g'ri shartnoma modeli |
| Yetarli investor topa olmaslik | O'rta | Kichik miqyosdan boshlash |
| Texnik nosozlik (to'lov xatosi) | O'rta | Idempotency, immutable transactions, backup |
| Scaling qiyinligi | O'rta | Modulli monolit → mikroservislar (kelajak) |
| Raqobatchilar | Past-O'rta | Birinchi bo'lib kirish, kuchli hamjamiyat |
| **Eng katta xavf** | **Kritik** | **Ishonch yo'qolishi** — har bir muammoni oshkora va tez hal qilish |

---

## 18. MUVAFFAQIYAT METRIKALARI (KPI)

### Pilot bosqichi (birinchi 3 oy)

| Metrika | Maqsad |
|---------|--------|
| Ro'yxatdan o'tgan fermerlar | 10-15 |
| Vetting o'tgan fermerlar | 5-8 |
| Ro'yxatdan o'tgan investorlar | 50-100 |
| Yakunlangan loyihalar (to'liq tsikl) | 3-5 |
| O'rtacha investitsiya summasi | 500,000–2,000,000 so'm |
| Qayta investitsiya darajasi | 30%+ |
| O'z vaqtida hisobot yuklash (%) | 90%+ |
| Halokat/yo'qotish darajasi | <5% |

### Uzoq muddatli ko'rsatkichlar
- **MAU** — Oylik faol foydalanuvchilar
- **GMV** — Umumiy investitsiya aylanmasi
- **Revenue** — Platforma komissiyasidan daromad
- **Retention (Farmer)** — Fermerning qayta loyiha ochish darajasi
- **Retention (Investor)** — Investorning qayta investitsiya darajasi
- **CAC / LTV** — Mijozni jalb qilish xarajati / Umr bo'yi qiymati nisbati
- **NPS** — Net Promoter Score (foydalanuvchi qoniqishi)

---

## XULOSA — ENG MUHIM TAMOYILLAR

| Tamoyil | Tafsilot |
|---------|----------|
| 🔒 **Ishonch** | Qat'iy vetting, shaffof monitoring, real-vaqt hisobotlar |
| 📊 **Shaffoflik** | Har bir tranzaksiya immutable, audit log to'liq |
| 🛡️ **Xavfsizlik** | AES-256, bcrypt, JWT+Redis, RBAC, rate limiting |
| ⚖️ **Huquqiy tozalik** | Yurist bilan ishlash, to'g'ridan-to'g'ri shartnoma |
| 🚀 **MVP birinchi** | Avval qo'lda sinash, keyin to'liq platforma |
| 👑 **SuperAdmin nazorati** | Barcha akkountlar va tizim sozlamalari nazorat ostida |

**Stack yakuniy tanlov:**
```
Backend:  Java 17 + Spring Boot 3.3 + PostgreSQL 16 + Redis 7
Web:      React 18 + JavaScript + Tailwind CSS 3.4
Mobile:   Flutter 3.22 (Android + iOS)
Files:    Cloudflare R2 (S3-mos)
Payment:  Payme API + Click API
SMS:      Eskiz.uz
Push:     Telegram Bot + Firebase FCM
Deploy:   Docker + Nginx + VPS + GitHub Actions
```
