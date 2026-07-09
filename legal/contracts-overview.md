# Shartnoma shablonlari — talablar ro'yxati va yurist uchun tekshirish checklisti

> **To'liq matn qoralamalari endi mavjud**: [`contracts/investor-platform-agreement.md`](./contracts/investor-platform-agreement.md), [`contracts/farmer-platform-agreement.md`](./contracts/farmer-platform-agreement.md), [`contracts/investor-farmer-agreement.md`](./contracts/investor-farmer-agreement.md). Bu fayl endi ularni **tekshirish ro'yxati (checklist)** sifatida xizmat qiladi — yurist matnlarni ko'rib chiqayotganda har bir band haqiqatan ham kiritilganini shu ro'yxat bo'yicha tasdiqlashi mumkin. TZ §9'da uchta shartnoma nomlangan: Investor–Platforma, Fermer–Platforma, Investor–Fermer. Bular real pul oqimini tartibga soluvchi moliyaviy shartnomalar bo'lgani uchun, **yakuniy matnni albatta litsenziyalangan yurist tasdiqlashi shart** — quyidagi ro'yxat kod bazasida allaqachon mavjud mexanizmlarga tayangan holda tuzilgan.

## 1. Investor–Platforma shartnomasi

Investor ro'yxatdan o'tganda yoki birinchi sarmoya kiritishda qabul qiladi.

- Platformaning vositachilik roli va javobgarlik chegarasi (Foydalanish shartlari §2, §9 bilan mos kelishi kerak).
- Xavf ogohlantirishi — "kafolatlangan daromad yo'q" bandi (Foydalanish shartlari §5 bilan bir xil til).
- Komissiya/xizmat haqi miqdori va undirish tartibi (`PlatformSettingsService.getCommissionPct()` orqali boshqariladigan qiymatga mos).
- Sarmoyani bekor qilish shartlari — 24 soatlik oyna, faqat loyiha hali to'liq moliyalashtirilmagan bo'lsa (`InvestmentService` mantig'iga mos).
- KYC talabi va uni bajarmasa xizmatdan foydalana olmasligi.
- Nizolarni hal qilish tartibi (Platforma ichidagi Shikoyatlar tizimi → sud).

## 2. Fermer–Platforma shartnomasi

Fermer birinchi loyihasini yaratishda qabul qiladi.

- Loyiha ma'lumotlarining haqiqiyligi uchun Fermerning shaxsiy javobgarligi.
- Hisobot berish majburiyati — chastota (`reportFrequencyDays`, loyiha yaratishda belgilanadi) va favqulodda holat haqida darhol xabar berish (F-4.5).
- Mablag'ni sarflash tartibi — `expensePolicy` (INVESTOR_BUDGET / FARMER_REIMBURSED / MIXED) shartlariga mos moddalar.
- Foyda taqsimoti formulasi — `proposedInvestorSharePct`/fermer ulushi, `PayoutService` hisoblash mantig'iga mos til bilan.
- Noto'g'ri/soxta ma'lumot berish oqibatlari (hisobni bloklash, moliyaviy javobgarlik).
- Fermerning o'z hissasi (`farmerContributionValue`, agar mavjud bo'lsa) qanday hisobga olinishi.

## 3. Investor–Fermer shartnomasi (avtomatik generatsiya qilinadigan)

Har bir tasdiqlangan investitsiya uchun avtomatik PDF sifatida yaratiladi (F-3.4).

- Taraflar (Investor, Fermer) va Platformaning bu shartnomadagi roli (vositachi, taraf emas).
- Sarmoya summasi, sana, loyihadagi ulush foizi (`sharePct`).
- Kutilayotgan foyda foizi va muddat — **"kutilayotgan, kafolatlanmagan"** deb aniq ko'rsatilishi shart.
- Yo'qotish yuzaga kelgan taqdirda taraflarning huquq va majburiyatlari (Foydalanish shartlari §5.4 jarayoniga havola).
- Loyiha yakunlanganda hisob-kitob qilish tartibi.
- Elektron imzo/tasdiqlash usuli (hozircha kodda amalga oshirilmagan — F-3.5, kelajakdagi ish).

## Texnik eslatma

Amalga oshirish holati:
1. ✅ **Statik matn** — `legal/contracts/` papkasida uchta to'liq matn qoralamasi mavjud.
2. ✅ **Investor–Fermer shartnomasi uchun PDF generatsiya** — `AgreementService.java` (`generateInvestmentAgreementPdf`) allaqachon mavjud edi; bu sessiyada uning §5 (yakuniy qoidalar) bandi tuzatildi, chunki u faqat "loyiha moliyalashtirilmasa — to'liq qaytariladi" holatini tasvirlab, ancha muhimroq "loyiha moliyalashtirilib, past narxda sotilsa" (zarar) holatini umuman yoritmagan edi — endi ikkala holat ham aniq yozilgan.
3. ⬜ **"Men shartlarga roziman" checkbox'ini majburiy qilish** — ro'yxatdan o'tish/loyiha yaratish/sarmoya kiritish oqimida hali kodda majburiy checkbox sifatida amalga oshirilmagan (mobil sarmoya kiritish formasida shunga o'xshash "kafolatlanmagan daromadni tushunaman" checkbox bor, lekin u to'liq shartnoma matniga havola qilmaydi). Bu — alohida, kelajakdagi dasturlash vazifasi.
4. ⬜ **Elektron imzo (EDS)** — hali amalga oshirilmagan (F-3.5).
