# AgroInvest

Qishloq xo'jaligi investitsiya platformasi: investorlar fermerlarning chorvachilik/dehqonchilik loyihalarini moliyalashtiradi va foyda ulushi oladi, fermerlar esa loyihalariga tez va shaffof mablag' topadi.

## Loyiha tarkibi

| Papka | Texnologiya | Vazifasi |
|---|---|---|
| [`agroinvest-backend`](./agroinvest-backend) | Java 17, Spring Boot 3.3, PostgreSQL, Redis, Flyway | REST API, biznes-mantiq, autentifikatsiya, to'lovlar |
| [`agroinvest-web`](./agroinvest-web) | React 19, Vite, Tailwind CSS v4, Zustand | Veb-ilova: ommaviy landing/loyihalar, investor/fermer/admin/superadmin panellari |
| [`agroinvest-mobile`](./agroinvest-mobile) | Flutter, Dio, go_router, Provider | Investor va fermer uchun mobil ilova (Android/iOS) |

Batafsil: [ARCHITECTURE.md](./ARCHITECTURE.md) (tizim tuzilishi), [DEPLOYMENT.md](./DEPLOYMENT.md) (ishga tushirish/joylashtirish), [PLATFORM_ROADMAP.md](./PLATFORM_ROADMAP.md) (bosqichma-bosqich ish rejasi va bajarilgan/qolgan ishlar), [AgroInvest_TZ_Toliq.md](./AgroInvest_TZ_Toliq.md) (to'liq texnik topshiriq).

## Tezkor boshlash

Lokal muhitda barcha xizmatlarni (Postgres, Redis, backend, web) Docker orqali ishga tushirish:

```bash
cp .env.example .env   # DB_PASSWORD/REDIS_PASSWORD/JWT_SECRET/ENCRYPTION_KEY qiymatlarini kiriting
docker compose up -d --build
```

- Backend: http://localhost:8080/api/v1 (Swagger: `/swagger-ui.html`)
- Web: http://localhost:3001

Mobil ilovani ishga tushirish uchun [`agroinvest-mobile/README.md`](./agroinvest-mobile/README.md)ga qarang.

To'liq joylashtirish (production, Cloudflare Tunnel bilan) — [DEPLOYMENT.md](./DEPLOYMENT.md).

## Rollar

`SUPERADMIN`, `ADMIN`, `MODERATOR`, `VERIFIER`, `INVESTOR`, `FARMER` — har birining huquqlari va panellari haqida [ARCHITECTURE.md](./ARCHITECTURE.md)da.
