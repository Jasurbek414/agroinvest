# Joylashtirish (Deployment)

## Talab qilinadigan narsalar

- Docker + Docker Compose
- `.env` fayli (root papkada) — quyidagi qiymatlar bilan:

```env
DB_PASSWORD=<kuchli parol>
REDIS_PASSWORD=<kuchli parol>
JWT_SECRET=<kamida 32 belgili tasodifiy satr>
ENCRYPTION_KEY=<32 belgili tasodifiy satr — passport/karta ma'lumotlarini shifrlash uchun>
APP_CORS_ALLOWED_ORIGINS=https://sizning-domeningiz.uz,http://localhost:3001,http://localhost:5173
```

`ENCRYPTION_KEY`ni **hech qachon** o'zgartirmang, agar bazada allaqachon shifrlangan ma'lumot (pasport, karta raqami) bo'lsa — kalit almashsa, mavjud yozuvlar deshifrlanmay qoladi.

## Ishga tushirish

```bash
docker compose up -d --build
```

Bu quyidagilarni ko'taradi:

| Xizmat | Port | Tavsif |
|---|---|---|
| `agroinvest_postgres` | 5436→5432 | Ma'lumotlar bazasi |
| `agroinvest_redis` | 6379 | Kesh (ruxsatlar, login urinishlari) |
| `agroinvest_backend` | 8080 | Spring Boot API |
| `agroinvest_frontend` | 3001→80 | nginx orqali xizmat ko'rsatiladigan veb-ilova (build qilingan static + `/api/` reverse-proxy) |

Backend birinchi marta ishga tushganda Flyway barcha migratsiyalarni avtomatik qo'llaydi (`V1`dan joriy versiyagacha) — qo'lda hech narsa bajarish shart emas.

## Faqat backend yoki frontend'ni qayta qurish/joylashtirish

Kod o'zgarishidan keyin, ma'lumotlar bazasi/Redis'ga tegmasdan faqat kerakli xizmatni yangilash:

```bash
docker compose build backend frontend      # yoki faqat bittasi
docker compose up -d --no-deps backend frontend
```

`--no-deps` muhim — aks holda Compose bog'liq xizmatlarni (postgres/redis) ham qayta ishga tushirishga urinishi mumkin.

## Tashqi kirish (Cloudflare Tunnel)

Production'da `cloudflared` konteyneri (`docker-compose.prod.yml`) orqali domen bog'lanadi — bu loyihada alohida sozlangan, `.env`dagi kalitlarga bog'liq emas. Agar tunnel uzilib-ulanib tursa (Redis/Postgres loglarida emas, `docker logs <cloudflared-konteyner-nomi>`da ko'rinadi), bu tarmoq/Cloudflare tomonidagi masala — backend/frontend konteynerlariga aloqasi yo'q.

## Log va holatni tekshirish

```bash
docker ps --filter "name=agroinvest"
docker logs agroinvest_backend --since 30m | grep -iE "error|exception"
docker logs agroinvest_frontend --since 30m
```

## Standart SuperAdmin hisobi

`V4__seed_superadmin.sql` orqali quyidagi hisob avtomatik yaratiladi:

- Telefon: `+998901234567`
- Boshlang'ich parol: `changeme123`

**Birinchi kirishdan so'ng albatta parolni almashtiring** — bu haqiqiy production hisob bo'lsa, standart parol xavfsizlik zaifligidir.

## Mobil ilovani build qilish

```bash
cd agroinvest-mobile
flutter pub get
flutter build apk --release   # Android
# yoki: flutter build ios --release
```

`.env` faylida `API_BASE_URL` production backend manziliga (masalan `https://api.sizning-domeningiz.uz/api/v1`) ko'rsatilishi kerak.
