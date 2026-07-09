# AgroInvest — Mobile

Flutter (Dio + go_router + Provider) asosidagi mobil ilova — Investor va Fermer rollari uchun (admin/superadmin funksiyalari faqat veb-ilovada).

To'liq loyiha va arxitektura haqida: [../README.md](../README.md), [../ARCHITECTURE.md](../ARCHITECTURE.md).

## Ishga tushirish (dev)

```bash
flutter pub get
cp .env.example .env   # API_BASE_URL ni to'g'rilang
flutter run
```

Android emulyatordan lokal backend'ga ulanish uchun `API_BASE_URL=http://10.0.2.2:8080/api/v1` (emulyator xost mashinaning localhost'iga shu manzil orqali murojaat qiladi).

## Build (release)

```bash
flutter build apk --release   # Android
flutter build ios --release   # iOS (macOS + Xcode talab qiladi)
```

## Tuzilma

Har bir funksional blok `lib/features/<nom>/` ostida uch qatlamli: `data/` (repository, backend bilan aloqa), `presentation/providers/` (holat, `ChangeNotifier`), `presentation/pages/` va `presentation/widgets/` (UI). Umumiy infratuzilma `lib/core/` da (`network/dio_client.dart` — token yangilash bilan, `theme/`, `storage/`, `widgets/`).

## Hozircha mexanizm darajasida (to'liq qamrov emas)

- **Dark mode** (`core/theme/`) — Material-standart vidjetlarni qamraydi (Scaffold, AppBar, Button, TextField, Card); qattiq kodlangan `AppColors.*`dan foydalanuvchi ekranlar hali moslashtirilmagan.
- **Til tanlash** (`easy_localization`) — faqat o'zbek tili to'liq, mexanizm ru/en uchun tayyor.
- **Push-bildirishnoma** (`core/notifications/push_notification_service.dart`) — kod tayyor va ulangan, lekin haqiqiy Firebase loyihasi (`google-services.json`/`GoogleService-Info.plist`) qo'shilmaguncha jim ishlamay turadi.
