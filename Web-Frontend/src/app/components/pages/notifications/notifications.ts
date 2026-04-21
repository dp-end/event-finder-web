import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';
import { NotificationService } from '../../../services/notification.service';
import { NotificationDto, NotificationType } from '../../../models/models';

@Component({
  selector: 'app-notifications',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './notifications.html',
  styleUrl: './notifications.css'
})
export class Notifications implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  notifications: NotificationDto[] = [];
  isLoading = true;
  error: string | null = null;

  get unreadCount(): number {
    return this.notifications.filter(n => !n.isRead).length;
  }

  constructor(
    private notificationService: NotificationService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void { this.loadNotifications(); }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadNotifications(): void {
    this.isLoading = true;
    this.error = null;
    this.notificationService.getAll().pipe(takeUntil(this.destroy$)).subscribe({
      next: notifications => {
        this.notifications = notifications;
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'Bildirimler yüklenemedi.';
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  markAsRead(notification: NotificationDto): void {
    if (notification.isRead) return;
    this.notificationService.markAsRead(notification.id).pipe(takeUntil(this.destroy$)).subscribe({
      next: () => { notification.isRead = true; this.cdr.detectChanges(); }
    });
  }

  markAllAsRead(): void {
    this.notificationService.markAllAsRead().pipe(takeUntil(this.destroy$)).subscribe({
      next: () => {
        this.notifications.forEach(n => n.isRead = true);
        this.cdr.detectChanges();
      }
    });
  }

  getTypeIcon(type: NotificationType): string {
    switch (type) {
      case NotificationType.NewEvent:        return '📅';
      case NotificationType.TicketPurchased: return '🎫';
      case NotificationType.EventReminder:   return '⏰';
      case NotificationType.EventCancelled:  return '❌';
      case NotificationType.ClubNewEvent:    return '🏛️';
      default:                               return '🔔';
    }
  }

  formatDate(dateStr: string): string {
    const date = new Date(dateStr);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMin  = Math.floor(diffMs / 60000);
    const diffHour = Math.floor(diffMin / 60);
    const diffDay  = Math.floor(diffHour / 24);

    if (diffMin < 1)   return 'Az önce';
    if (diffMin < 60)  return `${diffMin} dk önce`;
    if (diffHour < 24) return `${diffHour} saat önce`;
    if (diffDay < 7)   return `${diffDay} gün önce`;
    return date.toLocaleDateString('tr-TR', { day: 'numeric', month: 'long' });
  }
}
