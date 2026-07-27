import React, { useState, useEffect, useRef } from 'react';
import { Bell, Check, Trash2, X } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { io, Socket } from 'socket.io-client';
import apiClient from '../../utils/apiClient';
import { getCurrentUser, getToken } from '../../utils/auth';
import './NotificationBell.css';
import { formatDistanceToNow } from 'date-fns';
import { vi } from 'date-fns/locale';
import { rememberOrderRoute } from '../../services/order.service';

interface Notification {
  id: string;
  title: string;
  content: string;
  is_read: boolean;
  type: string;
  action_type?: string;
  sent_at: string;
  metadata?: any;
}

export const NotificationBell: React.FC = () => {
  const navigate = useNavigate();
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const socketRef = useRef<Socket | null>(null);

  const fetchNotifications = async () => {
    try {
      const response = await apiClient.get('/notifications/me?limit=50');
      setNotifications(response.data.data);
      setUnreadCount(response.data.meta.unread_count);
    } catch (error) {
      console.error('Lỗi khi lấy thông báo:', error);
    }
  };

  useEffect(() => {
    fetchNotifications();

    const token = getToken();
    if (!token) return;

    socketRef.current = io(import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000', {
      auth: { token },
      transports: ['websocket'],
    });

    socketRef.current.on('connect', () => {
      console.log('Đã kết nối notification socket');
      const user = getCurrentUser();
      if (user && (user.id || user.sub)) {
        socketRef.current?.emit('join', { userId: user.id || user.sub });
      }
    });

    socketRef.current.on('new_notification', (data: any) => {
      console.log('Nhận thông báo mới:', data);
      
      const newNotif: Notification = {
        id: data.id,
        title: data.title,
        content: data.content,
        is_read: false,
        type: data.notification_type || data.type,
        action_type: data.action_type,
        sent_at: data.sent_at || new Date().toISOString(),
        metadata: data.metadata,
      };

      setNotifications((prev) => [newNotif, ...prev]);
      setUnreadCount((prev) => prev + 1);
    });

    return () => {
      if (socketRef.current) {
        socketRef.current.disconnect();
      }
    };
  }, []);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const markAsRead = async (id: string, e?: React.MouseEvent) => {
    if (e) {
      e.stopPropagation();
    }

    const previousNotifications = notifications;
    const previousUnreadCount = unreadCount;

    if (id === 'all') {
      setNotifications((prev) => prev.map((n) => ({ ...n, is_read: true })));
      setUnreadCount(0);
    } else {
      setNotifications((prev) =>
        prev.map((n) => (n.id === id ? { ...n, is_read: true } : n))
      );
      setUnreadCount((prev) => Math.max(0, prev - 1));
    }

    try {
      await apiClient.patch(`/notifications/me/${id}/read`);
    } catch (error) {
      console.error('Lỗi khi đánh dấu đã đọc:', error);
      setNotifications(previousNotifications);
      setUnreadCount(previousUnreadCount);
    }
  };

  const deleteNotification = async (id: string, e?: React.MouseEvent) => {
    if (e) {
      e.stopPropagation();
    }

    const previousNotifications = notifications;
    const target = notifications.find((n) => n.id === id);

    setNotifications((prev) => prev.filter((n) => n.id !== id));
    if (target && !target.is_read) {
      setUnreadCount((prev) => Math.max(0, prev - 1));
    }

    try {
      await apiClient.delete(`/notifications/me/${id}`);
    } catch (error) {
      console.error('Lỗi khi xóa thông báo:', error);
      setNotifications(previousNotifications);
      if (target && !target.is_read) {
        setUnreadCount((prev) => prev + 1);
      }
    }
  };

  const handleNotificationClick = (notif: Notification) => {
    if (!notif.is_read) {
      markAsRead(notif.id);
    }

    const meta = notif.metadata;
    if (meta) {
      switch (notif.action_type) {
        case 'place_registered':
        case 'place_updated':
          if (meta.place_id) navigate(`/admin/locations/${meta.place_id}`);
          break;
        case 'place_approved':
        case 'place_rejected':
          if (meta.place_id) navigate(`/locations/${meta.place_id}`);
          break;
        case 'new_order':
          if (meta.order_id) navigate(`/orders/${rememberOrderRoute(meta.order_id)}`);
          break;
      }
    }

    setIsOpen(false);
  };

  const getIconForType = (type: string) => {
    switch (type) {
      case 'success':
        return <div className="notif-icon success"><Check size={14} /></div>;
      case 'error':
        return <div className="notif-icon error"><X size={14} /></div>;
      default:
        return <div className="notif-icon info"><Bell size={14} /></div>;
    }
  };

  return (
    <div className="notification-wrapper" ref={dropdownRef}>
      <button 
        className="notification-bell-btn" 
        onClick={() => setIsOpen(!isOpen)}
        aria-label="Thông báo"
      >
        <Bell size={20} />
        {unreadCount > 0 && (
          <span className="notification-badge">
            {unreadCount > 99 ? '99+' : unreadCount}
          </span>
        )}
      </button>

      {isOpen && (
        <div className="notification-dropdown">
          <div className="notification-header">
            <h3>Thông báo</h3>
            {unreadCount > 0 && (
              <button
                className="mark-all-read"
                onClick={() => markAsRead('all')}
              >
                Đánh dấu tất cả đã đọc
              </button>
            )}
          </div>
          <div className="notification-list">
            {notifications.length === 0 ? (
              <div className="notification-empty">
                <p>Không có thông báo nào</p>
              </div>
            ) : (
              notifications.map((notif) => (
                <div
                  key={notif.id}
                  className={`notification-item ${!notif.is_read ? 'unread' : ''}`}
                  onClick={() => handleNotificationClick(notif)}
                >
                  <div className="notification-item-icon">
                    {getIconForType(notif.type)}
                  </div>
                  <div className="notification-item-content">
                    <h4>{notif.title}</h4>
                    <p>{notif.content}</p>
                    <span className="notification-time">
                      {formatDistanceToNow(new Date(notif.sent_at), { addSuffix: true, locale: vi })}
                    </span>
                  </div>
                  {!notif.is_read && (
                    <button
                      className="notification-item-read-btn"
                      onClick={(e) => markAsRead(notif.id, e)}
                      title="Đánh dấu đã đọc"
                    >
                      <Check size={14} />
                    </button>
                  )}
                  {notif.is_read && (
                    <button
                      className="notification-item-delete-btn"
                      onClick={(e) => deleteNotification(notif.id, e)}
                      title="Xóa thông báo"
                    >
                      <Trash2 size={14} />
                    </button>
                  )}
                </div>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
};
