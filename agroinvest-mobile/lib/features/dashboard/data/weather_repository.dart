import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

/// Current conditions + short forecast for the home dashboard's weather card.
/// Open-Meteo is keyless and free, so this talks to it directly instead of
/// proxying through the backend. Location is best-effort GPS with a Tashkent
/// fallback so the card always renders.
class WeatherRepository {
  // Plain Dio: DioClient points at the AgroInvest API and attaches JWTs,
  // neither of which applies to a third-party weather host.
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  static const _tashkentLat = 41.3111;
  static const _tashkentLng = 69.2797;

  Future<WeatherData> fetchWeather() async {
    double lat = _tashkentLat;
    double lng = _tashkentLng;
    bool usedFallback = true;

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
        final position = await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
            ).timeout(const Duration(seconds: 8));
        lat = position.latitude;
        lng = position.longitude;
        usedFallback = false;
      }
    } catch (_) {
      // GPS is optional - Tashkent fallback keeps the card useful.
    }

    final response = await _dio.get(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': lat,
        'longitude': lng,
        'current': 'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
        'timezone': 'auto',
        'forecast_days': 4,
      },
    );

    final data = Map<String, dynamic>.from(response.data);
    final current = Map<String, dynamic>.from(data['current']);
    final daily = Map<String, dynamic>.from(data['daily']);

    final days = <DailyForecast>[];
    final times = List<String>.from(daily['time']);
    for (var i = 1; i < times.length; i++) {
      days.add(DailyForecast(
        date: DateTime.parse(times[i]),
        weatherCode: (daily['weather_code'][i] as num).toInt(),
        maxTemp: (daily['temperature_2m_max'][i] as num).toDouble(),
        minTemp: (daily['temperature_2m_min'][i] as num).toDouble(),
      ));
    }

    return WeatherData(
      temperature: (current['temperature_2m'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      weatherCode: (current['weather_code'] as num).toInt(),
      isFallbackLocation: usedFallback,
      forecast: days,
    );
  }
}

class WeatherData {
  final double temperature;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final bool isFallbackLocation;
  final List<DailyForecast> forecast;

  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.isFallbackLocation,
    required this.forecast,
  });
}

class DailyForecast {
  final DateTime date;
  final int weatherCode;
  final double maxTemp;
  final double minTemp;

  const DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.maxTemp,
    required this.minTemp,
  });
}
