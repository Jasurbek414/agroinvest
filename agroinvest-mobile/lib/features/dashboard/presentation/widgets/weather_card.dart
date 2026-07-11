import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/weather_repository.dart';

/// WMO weather code -> (uz label, icon, accent color).
(String, IconData, Color) weatherCodeMeta(int code) {
  if (code == 0) return ('Ochiq havo', Icons.wb_sunny_rounded, const Color(0xFFF59E0B));
  if (code <= 2) return ('Qisman bulutli', Icons.wb_cloudy_rounded, const Color(0xFF60A5FA));
  if (code == 3) return ('Bulutli', Icons.cloud_rounded, const Color(0xFF94A3B8));
  if (code == 45 || code == 48) return ('Tuman', Icons.foggy, const Color(0xFF94A3B8));
  if (code <= 57) return ("Yengil yomg'ir", Icons.grain_rounded, const Color(0xFF60A5FA));
  if (code <= 67) return ("Yomg'ir", Icons.water_drop_rounded, const Color(0xFF3B82F6));
  if (code <= 77) return ('Qor', Icons.ac_unit_rounded, const Color(0xFF93C5FD));
  if (code <= 82) return ('Jala', Icons.water_drop_rounded, const Color(0xFF3B82F6));
  if (code >= 95) return ('Momaqaldiroq', Icons.thunderstorm_rounded, const Color(0xFF8B5CF6));
  return ('Bulutli', Icons.cloud_rounded, const Color(0xFF94A3B8));
}

const _weekdaysUz = ['Dush', 'Sesh', 'Chor', 'Pay', 'Jum', 'Shan', 'Yak'];

/// Compact weather strip for the home dashboard: current conditions plus a
/// 3-day forecast. Farmers plan feeding/grazing around it; investors get
/// context for the daily reports they read.
class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  final _repository = WeatherRepository();
  WeatherData? _weather;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repository.fetchWeather();
      if (mounted) setState(() => _weather = data);
    } catch (_) {
      // Weather is a nice-to-have - on failure the card just disappears.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 92,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: const Center(
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
        ),
      );
    }

    final weather = _weather;
    if (weather == null) return const SizedBox.shrink();

    final meta = weatherCodeMeta(weather.weatherCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: meta.$3.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(meta.$2, color: meta.$3, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${weather.temperature.round()}°',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textDark, letterSpacing: -0.5, height: 1),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(meta.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 2),
                        Text(
                          weather.isFallbackLocation ? 'Toshkent' : 'Joylashuvingiz',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _InfoChip(icon: Icons.air_rounded, label: '${weather.windSpeed.round()} km/soat'),
                  const SizedBox(height: 4),
                  _InfoChip(icon: Icons.water_drop_outlined, label: '${weather.humidity}%'),
                ],
              ),
            ],
          ),
          if (weather.forecast.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final day in weather.forecast.take(3)) _ForecastDay(forecast: day),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
      ],
    );
  }
}

class _ForecastDay extends StatelessWidget {
  final DailyForecast forecast;

  const _ForecastDay({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final meta = weatherCodeMeta(forecast.weatherCode);
    return Column(
      children: [
        Text(
          _weekdaysUz[forecast.date.weekday - 1],
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.textMuted),
        ),
        const SizedBox(height: 5),
        Icon(meta.$2, color: meta.$3, size: 18),
        const SizedBox(height: 5),
        Text(
          '${forecast.maxTemp.round()}° / ${forecast.minTemp.round()}°',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textDark),
        ),
      ],
    );
  }
}
