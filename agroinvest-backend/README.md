# AgroInvest — Backend

Java 17 + Spring Boot 3.3 + PostgreSQL + Redis + Flyway asosidagi REST API.

To'liq loyiha va arxitektura haqida: [../README.md](../README.md), [../ARCHITECTURE.md](../ARCHITECTURE.md).

## Ishga tushirish (dev)

Eng oson yo'l — root papkadagi Docker Compose orqali (Postgres/Redis bilan birga): [../DEPLOYMENT.md](../DEPLOYMENT.md)ga qarang.

Lokal Postgres/Redis'ga to'g'ridan-to'g'ri ulanib ishga tushirish uchun:

```bash
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

`src/main/resources/application-dev.yml` standart lokal ulanish sozlamalarini o'z ichiga oladi.

## Build

```bash
mvn package -DskipTests
java -jar target/agroinvest-backend-*.jar
```

## API hujjatlari

Ishga tushgandan so'ng: `http://localhost:8080/swagger-ui.html` (OpenAPI: `/api/docs`).

## Tuzilma

`src/main/java/uz/agroinvest/module/<domen>/` — har bir domen o'z ichida `entity/`, `dto/`, `*Repository`, `*Service`, `*Controller`ga ega. Umumiy narsalar: `common/` (xatolar, javob formati, enum'lar), `security/` (JWT, ruxsat tizimi), `config/` (Spring konfiguratsiyalari).

## Migratsiyalar

`src/main/resources/db/migration/V<raqam>__<nom>.sql` — Flyway orqali avtomatik qo'llaniladi. **Hech qachon mavjud migratsiyani tahrirlamang** — faqat yangisini qo'shing (keyingi raqam bilan).
