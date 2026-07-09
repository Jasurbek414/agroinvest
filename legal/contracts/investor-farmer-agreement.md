# Investor–Fermer shartnomasi (avtomatik generatsiya qilinadigan) — QORALAMA

> **Bu hujjat qoralama holatida va litsenziyalangan yurist tomonidan ko'rib chiqilmasdan ishlatilmasligi kerak.** Sana: to'ldiring. Versiya: 0.2.
>
> **Texnik eslatma:** Ushbu matn — Platforma tomonidan har bir tasdiqlangan investitsiya uchun **avtomatik PDF sifatida generatsiya qilinadigan** shartnomaning kengaytirilgan, izohli matni. Haqiqiy PDF generatori: `agroinvest-backend/src/main/java/uz/agroinvest/module/agreement/AgreementService.java` (`generateInvestmentAgreementPdf`). Quyidagi bandlar shu kod bilan mos keladi — kod o'zgartirilsa, bu hujjat ham yangilanishi kerak (va aksincha).

---

## Tomonlar

- **Investor**: [`investment.getInvestor().getFullName()`] (Tel: [`investment.getInvestor().getPhoneNumber()`])
- **Fermer**: [`investment.getProject().getFarmer().getFullName()`]
- **Platformaning roli**: ushbu shartnomaning tarafi emas — faqat vositachi va hisob-kitob operatori (batafsil: [`investor-platform-agreement.md`](./investor-platform-agreement.md) §2).
- **Shartnoma raqami**: AI-[investitsiya ID'sining birinchi 8 belgisi]
- **Sana**: [investitsiya yaratilgan sana]

## 1. Shartnoma shartlari

1.1. Ushbu shartnoma AgroInvest platformasi orqali Investor va Fermer o'rtasidagi kelishuvni tartibga soladi.

1.2. Investor [`investment.getProject().getTitle()`] nomli loyihani moliyalashtirish uchun mablag' kiritadi. Fermer loyihani o'z vaqtida parvarish qilib, mahsulotni/chorvani sotish va yakuniy hisob-kitobni Platforma orqali amalga oshirish majburiyatini oladi.

## 2. Moliyaviy parametrlar

- **Sarmoya miqdori**: [`investment.getAmount()`] so'm
- **Loyiha muddati**: [`investment.getProject().getDurationDays()`] kun
- **Kutilayotgan foyda**: +[`investment.getProject().getExpectedReturnPct()`]% (**taxminiy, kafolatlanmagan** — §5ga qarang)
- **Investorning ushbu loyihadagi ulushi**: [`investment.getSharePct()`]%

## 3. Kelishilgan shartlar

3.1. **Sof foyda taqsimoti**: Investorlar jamoasi [`investorSharePct`]% / Fermer [`farmerSharePct`]% (Loyiha yaratilishida kelishilgan).

3.2. Agar Fermer o'z hissasi (hayvon/aktiv) bilan qatnashgan bo'lsa: uning qiymati [`farmerContributionValue`] so'm, [admin tomonidan tasdiqlangan/tasdiqlanmagan].

3.3. Joriy harajatlar siyosati: [Loyiha byudjetidan / Fermer to'laydi / Aralash] — batafsil: [`farmer-platform-agreement.md`](./farmer-platform-agreement.md) §7.

## 4. Hisob-kitob tartibi va muddatlar

4.1. Investor kiritgan mablag' Loyiha to'liq moliyalashtirilgunga qadar Platforma hamyonida **muzlatilgan (escrow)** holatda saqlanadi.

4.2. Agar Loyiha to'liq moliyalashtirilmasa yoki Platforma tomonidan hali faollashtirilmasdan (ACTIVE bosqichigacha) bekor qilinsa, ushbu shartnoma **avtomatik bekor hisoblanadi** va Investorning mablag'i to'liq, komissiyasiz balansiga qaytariladi.

4.3. Loyiha faollashtirilgandan (ACTIVE) so'ng, Fermer §6 (`farmer-platform-agreement.md`)da belgilangan hisobot berish majburiyatini bajaradi. Loyiha yakunlanganda (mahsulot/chorva sotilgach), Platforma admin jamoasi yakuniy sotuv summasini tizimga kiritadi va hisob-kitob avtomatik amalga oshiriladi (§5).

## 5. ZARARLAR VA YO'QOTISHLAR — TO'LIQ OGOHLANTIRISH

> **Bu shartnomaning eng muhim bandi. Investor sarmoya kiritishdan oldin uni to'liq o'qib chiqishi shart.**

5.1. **Ko'rsatilgan daromad — kutilayotgan (taxminiy) ko'rsatkich bo'lib, KAFOLATLANMAGAN.** Qishloq xo'jaligi faoliyati tabiiy risklarga (kasallik, ob-havo ofati) va bozor risklariga (narx tushishi) ega — sarmoyaning bir qismi yoki to'liqi yo'qotilishi mumkin.

5.2. **Agar loyiha hech qachon to'liq moliyalashtirilmasa yoki faollashtirilmasdan bekor qilinsa** (§4.2): Investorning mablag'i **to'liq va komissiyasiz** qaytariladi. Bu yagona holat bo'lib, unda Investor 100% qaytarimga kafolatlangan.

5.3. **Agar loyiha to'liq moliyalashtirilib faollashtirilgandan so'ng, yakuniy sotuv/tugatish summasi loyiha maqsad summasidan KAM bo'lsa** — bu asosiy zarar holati:
   - Yakuniy sotuv summasidan avval Platforma xizmat haqi, so'ng Fermerning tasdiqlangan xarajatlari ushlab qolinadi/qaytariladi;
   - Qolgan summa barcha Investorlar (va, agar mavjud bo'lsa, o'z hissasi bilan qatnashgan Fermer) o'rtasida ular kiritgan mablag'ga **to'g'ridan-to'g'ri proporsional** ravishda avtomatik taqsimlanadi;
   - Investor bu holda o'z sarmoyasining faqat bir qismini qaytarib olishi mumkin — **qaytariladigan summa nolgacha tushishi mumkin**;
   - **Investordan hech qachon qo'shimcha (kiritgan sarmoyasidan ortiq) to'lov talab qilinmaydi**, lekin **hech qanday minimal qaytarim ham kafolatlanmaydi**;
   - **Platformada bu yo'qotishni qisman yoki to'liq qoplaydigan alohida zaxira fond yoki sug'urta mexanizmi mavjud emas.**

5.4. **Misol (faqat tushuntirish uchun):** Agar Investor 10,000,000 so'm kiritgan bo'lsa va loyiha yakunida (barcha chegirmalardan keyin) umumiy taqsimlanadigan summa asl maqsad summaning 70%ini tashkil qilsa, Investor taxminan 7,000,000 so'm qaytarib oladi (o'z sarmoyasining 70%i) — 3,000,000 so'm yo'qotiladi.

5.5. **Nizo va shikoyat**: Agar Investor yakuniy hisob-kitob yoki Fermer harakatlari bilan rozi bo'lmasa, Platformaning "Shikoyatlar" tizimi orqali murojaat qilishi mumkin — biroq bu **avtomatik moliyaviy qoplashni kafolatlamaydi** (batafsil: [`investor-platform-agreement.md`](./investor-platform-agreement.md) §9).

## 6. Elektron tasdiqlash

6.1. Ushbu shartnoma Investor tomonidan Platformada sarmoya kiritish jarayonini yakunlash orqali **elektron shaklda tasdiqlangan** hisoblanadi.

6.2. **Hozircha alohida elektron imzo (raqamli imzo/EDS) mexanizmi kodda amalga oshirilmagan** — tasdiqlash shartnoma shartlarini o'qib chiqqanligini tasdiqlovchi belgini (checkbox) faollashtirish va sarmoya so'rovini yuborish orqali amalga oshiriladi. To'liq huquqiy kuchga ega elektron imzo tizimini joriy etish — kelajakdagi ish.

## 7. Yakuniy qoidalar

7.1. Ushbu shartnoma Platformaning [`investor-platform-agreement.md`](./investor-platform-agreement.md) va [`farmer-platform-agreement.md`](./farmer-platform-agreement.md) shartlariga qo'shimcha ravishda amal qiladi; ziddiyat yuzaga kelgan taqdirda ommaviy oferta shartlari ustuvor hisoblanadi.

7.2. Nizolar O'zbekiston Respublikasi qonunchiligiga muvofiq, avval Platforma ichidagi Shikoyatlar tizimi, so'ng zarur bo'lsa sud orqali hal qilinadi.
