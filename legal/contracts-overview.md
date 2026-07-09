# Shartnoma shablonlari — talablar ro'yxati (matn emas)

> **Bu yerda tayyor shartnoma matni yo'q.** TZ §9'da uchta shartnoma nomlangan: Investor–Platforma, Fermer–Platforma, Investor–Fermer. Bular real pul oqimini tartibga soluvchi moliyaviy shartnomalar bo'lgani uchun, matnning o'zini litsenziyalangan yurist tayyorlashi shart. Quyida — har bir shartnomada **qanday band bo'lishi kerakligi** ro'yxati, kod bazasida allaqachon mavjud mexanizmlarga tayangan holda.

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

Barcha uchta shartnoma matni tayyor bo'lgach, ularni:
1. Statik matn sifatida (masalan `legal/templates/`) saqlash,
2. Investor-Fermer shartnomasi uchun `InvestmentService`ga PDF generatsiya qilishda shu shablondan foydalanish,
3. Ro'yxatdan o'tish/loyiha yaratish oqimida "Men shartlarga roziman" checkbox'ini majburiy qilish

kabi bosqichlar bilan kodga integratsiya qilish kerak bo'ladi — bu alohida dasturlash vazifasi.
