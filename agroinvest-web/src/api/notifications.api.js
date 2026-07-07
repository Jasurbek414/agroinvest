import api from './axios';

export const getMyNotifications = (page = 0, size = 10) => {
  return api.get('/notifications', { params: { page, size } });
};

export const getUnreadCount = () => {
  return api.get('/notifications/unread-count');
};

export const markAsRead = (id) => {
  return api.patch(`/notifications/${id}/read`);
};

export const markAllAsRead = () => {
  return api.patch('/notifications/read-all');
};
