import React, { useEffect, useRef, useState } from 'react';
import { Bell } from 'lucide-react';
import { getMyNotifications, getUnreadCount, markAsRead, markAllAsRead } from '../../api/notifications.api';
import { formatDate } from '../../utils/format';

const POLL_INTERVAL_MS = 30000;

const NotificationBell = () => {
  const [open, setOpen] = useState(false);
  const [unreadCount, setUnreadCount] = useState(0);
  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(false);
  const containerRef = useRef(null);

  const fetchUnreadCount = async () => {
    try {
      const res = await getUnreadCount();
      setUnreadCount(res.data || 0);
    } catch {
      // silent - the bell simply won't show a badge if this fails
    }
  };

  useEffect(() => {
    fetchUnreadCount();
    const interval = setInterval(fetchUnreadCount, POLL_INTERVAL_MS);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (containerRef.current && !containerRef.current.contains(e.target)) {
        setOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const toggleOpen = async () => {
    const next = !open;
    setOpen(next);
    if (next) {
      setLoading(true);
      try {
        const res = await getMyNotifications();
        setNotifications(res.data.content || []);
      } finally {
        setLoading(false);
      }
    }
  };

  const handleItemClick = async (notification) => {
    if (!notification.isRead) {
      try {
        await markAsRead(notification.id);
        setNotifications((prev) => prev.map((n) => (n.id === notification.id ? { ...n, isRead: true } : n)));
        setUnreadCount((c) => Math.max(0, c - 1));
      } catch {
        // non-critical - leave it unread visually if the request failed
      }
    }
  };

  const handleMarkAll = async () => {
    try {
      await markAllAsRead();
      setNotifications((prev) => prev.map((n) => ({ ...n, isRead: true })));
      setUnreadCount(0);
    } catch {
      // non-critical
    }
  };

  return (
    <div className="relative" ref={containerRef}>
      <button
        onClick={toggleOpen}
        aria-label="Bildirishnomalar"
        className="relative p-2 rounded-xl hover:bg-gray-100 transition text-gray-600"
      >
        <Bell size={20} />
        {unreadCount > 0 && (
          <span className="absolute -top-0.5 -right-0.5 min-w-[18px] h-[18px] px-1 rounded-full bg-red-500 text-white text-[10px] font-bold flex items-center justify-center">
            {unreadCount > 9 ? '9+' : unreadCount}
          </span>
        )}
      </button>

      {open && (
        <div className="absolute right-0 mt-2 w-80 bg-white rounded-2xl border border-gray-100 shadow-xl z-50 overflow-hidden">
          <div className="flex items-center justify-between px-4 py-3 border-b border-gray-100">
            <span className="text-sm font-bold text-gray-900">Bildirishnomalar</span>
            {unreadCount > 0 && (
              <button onClick={handleMarkAll} className="text-xs font-semibold text-green-600 hover:text-green-700">
                Barchasini o'qilgan deb belgilash
              </button>
            )}
          </div>
          <div className="max-h-96 overflow-y-auto">
            {loading ? (
              <p className="p-6 text-center text-sm text-gray-400 animate-pulse">Yuklanmoqda...</p>
            ) : notifications.length === 0 ? (
              <p className="p-6 text-center text-sm text-gray-400">Bildirishnomalar yo'q</p>
            ) : (
              notifications.map((n) => (
                <button
                  key={n.id}
                  onClick={() => handleItemClick(n)}
                  className={`w-full text-left px-4 py-3 border-b border-gray-50 last:border-0 hover:bg-gray-50 transition ${
                    !n.isRead ? 'bg-green-50/40' : ''
                  }`}
                >
                  <div className="flex items-start gap-2">
                    {!n.isRead && <span className="mt-1.5 w-1.5 h-1.5 rounded-full bg-green-600 shrink-0" />}
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold text-gray-800 truncate">{n.title}</p>
                      <p className="text-xs text-gray-500 mt-0.5 line-clamp-2">{n.message}</p>
                      <p className="text-[10px] text-gray-400 mt-1">{formatDate(n.createdAt)}</p>
                    </div>
                  </div>
                </button>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default NotificationBell;
