-- Adds the PUSH value needed for FCM push-notification infrastructure
-- (NotificationService now dispatches NotificationChannel.PUSH to
-- FcmPushService, and users.fcm_token already existed but had no consumer).
ALTER TYPE notif_ch ADD VALUE IF NOT EXISTS 'PUSH';
