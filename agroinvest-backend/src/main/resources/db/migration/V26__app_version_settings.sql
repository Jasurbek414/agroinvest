INSERT INTO platform_settings (id, setting_key, setting_value, description)
VALUES 
  (gen_random_uuid(), 'app_version_code', '1', 'Mobil ilova versiya kodi (versionCode)'),
  (gen_random_uuid(), 'app_version_name', '1.0.0', 'Mobil ilova versiya nomi (versionName)'),
  (gen_random_uuid(), 'app_download_url', '/agroinvest.apk', 'Mobil ilovani yuklab olish manzili (downloadUrl)'),
  (gen_random_uuid(), 'app_force_update', 'false', 'Mobil ilovani yangilashni majburlash (forceUpdate)')
ON CONFLICT (setting_key) DO NOTHING;
