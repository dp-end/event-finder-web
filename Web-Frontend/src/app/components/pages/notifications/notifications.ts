import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';
import { NotificationService } from '../../../services/notification.service';
import { PreferencesService } from '../../../services/preferences.service';
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
    private preferencesService: PreferencesService,
    private router: Router,
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

  openNotification(notification: NotificationDto): void {
    const navigate = () => this.navigateNotification(notification);

    if (notification.isRead) {
      navigate();
      return;
    }

    this.notificationService.markAsRead(notification.id).pipe(takeUntil(this.destroy$)).subscribe({
      next: () => {
        notification.isRead = true;
        this.cdr.detectChanges();
        navigate();
      },
      error: () => navigate()
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

    const isEnglish = this.preferencesService.language === 'en';
    if (diffMin < 1)   return isEnglish ? 'Just now' : 'Az önce';
    if (diffMin < 60)  return isEnglish ? `${diffMin} min ago` : `${diffMin} dk önce`;
    if (diffHour < 24) return isEnglish ? `${diffHour} h ago` : `${diffHour} saat önce`;
    if (diffDay < 7)   return isEnglish ? `${diffDay} days ago` : `${diffDay} gün önce`;
    return date.toLocaleDateString(this.preferencesService.locale, { day: 'numeric', month: 'long' });
  }

  private navigateNotification(notification: NotificationDto): void {
    const type = Number(notification.type);
    const eventId = notification.relatedEventId
      || (this.isEventNotification(type) ? notification.relatedEntityId : undefined);
    const clubId = notification.relatedClubId
      || (type === NotificationType.ClubFollowed ? notification.relatedEntityId : undefined);

    if (eventId) {
      this.router.navigate(['/event', eventId]);
      return;
    }

    if (clubId) {
      this.router.navigate(['/club', clubId]);
    }
  }

  private isEventNotification(type: number): boolean {
    return [
      NotificationType.NewEvent,
      NotificationType.TicketPurchased,
      NotificationType.EventReminder,
      NotificationType.EventCancelled,
      NotificationType.ClubNewEvent,
      NotificationType.EventCommented,
      NotificationType.EventLiked
    ].includes(type);
  }
}
