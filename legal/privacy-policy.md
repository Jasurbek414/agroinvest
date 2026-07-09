# Maxfiylik siyosati — QORALAMA

> Ushbu hujjat qoralama holatida. Amalda ishlatishdan oldin litsenziyalangan yurist (O'zbekiston Respublikasining "Shaxsga doir ma'lumotlar to'g'risida"gi qonuniga muvofiqligini) tomonidan ko'rib chiqilishi shart. Sana: to'ldiring. Versiya: 0.1.

## 1. Ushbu siyosat nimani qamrab oladi

AgroInvest Platformasi (veb-sayt va mobil ilova) Foydalanuvchilardan qanday shaxsiy ma'lumot to'plashi, ulardan qanday foydalanishi, kim bilan almashishi va qanday himoya qilishini tushuntiradi.

## 2. To'planadigan ma'lumotlar

| Toifa | Misollar | Maqsad |
|---|---|---|
| Ro'yxatdan o'tish ma'lumotlari | F.I.SH, telefon raqami, email | Hisob yaratish, aloqa |
| KYC ma'lumotlari | Pasport seriya/raqami, JSHSHIR, pasport rasmi | Shaxsni tasdiqlash, firibgarlikning oldini olish (qonun talabi) |
| Moliyaviy ma'lumotlar | Karta raqami (yechish uchun), tranzaksiyalar tarixi | To'lovlarni amalga oshirish |
| Loyiha ma'lumotlari | Fermer yuklagan foto/video hisobotlar, geolokatsiya | Investorlarga shaffoflik ta'minlash |
| Texnik ma'lumotlar | IP-manzil, qurilma turi, ilova versiyasi | Xavfsizlik, nosozliklarni bartaraf etish |

## 3. Nozik (sensitiv) ma'lumotlar

3.1. Pasport ma'lumotlari va karta raqami bazada **shifrlangan holda** saqlanadi (AES-256).

3.2. Parol hech qachon ochiq matnda saqlanmaydi — faqat bir tomonlama xeshlangan (bcrypt) shaklda.

3.3. API javoblarida parol xeshi va shifrlangan pasport ma'lumotlari hech qachon qaytarilmaydi.

## 4. Ma'lumotlardan foydalanish maqsadlari

- Hisobni yaratish va boshqarish;
- KYC/AML (pul yuvishga qarshi) tekshiruvlari;
- To'lovlarni amalga oshirish va tasdiqlash;
- SMS/push-bildirishnomalar yuborish;
- Platforma xavfsizligini ta'minlash (firibgarlikni aniqlash);
- Qonuniy talablarga rioya qilish (soliq, moliyaviy monitoring organlari so'rovi bo'yicha).

## 5. Ma'lumotlarni uchinchi shaxslar bilan almashish

5.1. Ma'lumotlar quyidagi hollardan tashqari uchinchi shaxslarga berilmaydi:
   - Foydalanuvchining aniq roziligi bilan;
   - To'lov tizimlari (Payme, Click) — faqat to'lovni amalga oshirish uchun zarur ma'lumot;
   - SMS-xabar yuboruvchi provayder — faqat telefon raqami va kod;
   - Qonun talabiga ko'ra vakolatli davlat organlari so'rovi asosida.

5.2. Investorlar o'rtasida sherik-investorlar ro'yxati **maskalangan** (masalan "Jasurbek M.") ko'rinishda ko'rsatiladi — to'liq ism-familiya oshkor qilinmaydi.

## 6. Ma'lumotlarni saqlash muddati

6.1. Hisob faol bo'lgan davrda va O'zbekiston qonunchiligida belgilangan buxgalteriya/moliyaviy hujjatlarni saqlash muddati davomida (odatda 5 yilgacha) ma'lumotlar saqlanadi.

6.2. Hisob o'chirilgandan so'ng, qonuniy saqlash majburiyati bo'lmagan ma'lumotlar [muddat, to'ldiring] ichida o'chiriladi yoki anonimlashtiriladi.

## 7. Foydalanuvchi huquqlari

7.1. Foydalanuvchi o'z ma'lumotlarini ko'rish, tuzatish va (qonuniy cheklovlar doirasida) o'chirishni so'rash huquqiga ega.

7.2. Bunday so'rovlar [email/telefon — to'ldiring] orqali yuboriladi.

## 8. Xavfsizlik choralari

8.1. Ma'lumotlar uzatilishida HTTPS/TLS shifrlash ishlatiladi.

8.2. Kirish huquqlari rol asosida cheklangan (masalan, oddiy admin foydalanuvchining shifrlangan pasport ma'lumotini ko'ra olmaydi, faqat tasdiqlangan/rad etilgan holatni belgilaydi).

8.3. Barcha ma'muriy amallar (bloklash, tasdiqlash, sozlamalarni o'zgartirish) audit jurnalida qayd etiladi.

## 9. Bolalar maxfiyligi

9.1. Platforma 18 yoshdan kichik shaxslar uchun mo'ljallanmagan.

## 10. Siyosatga o'zgartirish kiritish

10.1. Ushbu siyosat vaqti-vaqti bilan yangilanishi mumkin, muhim o'zgarishlar haqida Foydalanuvchilarga xabar beriladi.

## 11. Aloqa

Maxfiylik bo'yicha savollar: [email/telefon — to'ldiring].
