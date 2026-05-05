import { Component, Input, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { EventListDto } from '../../models/models';
import { EventService } from '../../services/event.service';
import { AuthService } from '../../services/auth';
import { PreferencesService } from '../../services/preferences.service';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-event-card',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './event-card.html',
  styleUrl: './event-card.css'
})
export class EventCard {
  @Input() event!: EventListDto;
  isLiking = false;

  constructor(
    private router: Router,
    private eventService: EventService,
    private authService: AuthService,
    private preferencesService: PreferencesService,
    private cdr: ChangeDetectorRef
  ) {}

  goToDetail(): void {
    if (this.event?.id) {
      this.router.navigate(['/event', this.event.id]);
    }
  }

  get isClubOrganizer(): boolean {
    return !!this.event?.clubId;
  }

  get organizerName(): string {
    return this.event?.organizerName || this.event?.clubName || this.event?.ownerName || 'Organizatör';
  }

  get organizerInitials(): string {
    return this.event?.organizerInitials || this.event?.clubInitials || this.event?.ownerInitials || '?';
  }

  get organizerProfileImageUrl(): string | undefined {
    return this.event?.organizerProfileImageUrl || this.event?.clubProfileImageUrl || this.event?.ownerProfileImageUrl;
  }

  goToOrganizer(e: Event): void {
    e.stopPropagation();
    if (this.event?.clubId) {
      this.router.navigate(['/club', this.event.clubId]);
      return;
    }

    if (this.event?.ownerId) {
      this.router.navigate(['/profile', this.event.ownerId]);
    }
  }

  toggleLike(e: Event): void {
    e.stopPropagation();
    if (!this.event?.id || this.isLiking) return;
    if (!this.authService.isLoggedIn()) {
      this.router.navigate(['/login']);
      return;
    }

    this.isLiking = true;
    const wasLiked = this.event.isLikedByCurrentUser;
    const previousCount = this.event.likeCount ?? 0;

    // Optimistic update — anlık yansıtma
    this.event.isLikedByCurrentUser = !wasLiked;
    this.event.likeCount = Math.max(0, previousCount + (wasLiked ? -1 : 1));
    this.cdr.detectChanges();

    this.eventService.toggleLike(this.event.id).subscribe({
      next: result => {
        this.event.isLikedByCurrentUser = result.liked;
        const delta = result.liked === wasLiked ? 0 : (result.liked ? 1 : -1);
        this.event.likeCount = Math.max(0, previousCount + delta);
        this.isLiking = false;
        this.cdr.detectChanges();
      },
      error: () => {
        // Hata olursa önceki duruma geri al
        this.event.isLikedByCurrentUser = wasLiked;
        this.event.likeCount = previousCount;
        this.isLiking = false;
        this.cdr.detectChanges();
      }
    });
  }

  goToComments(e: Event): void {
    e.stopPropagation();
    if (!this.event?.id) return;
    this.router.navigate(['/event', this.event.id], {
      queryParams: { focus: 'comments' },
      fragment: 'comments'
    });
  }

  resolveImageUrl(url?: string): string {
    if (!url) return '';
    return url.startsWith('/') ? `${environment.apiUrl}${url}` : url;
  }

  formatPrice(price: number): string {
    return price === 0
      ? (this.preferencesService.language === 'en' ? 'Free' : 'Ücretsiz')
      : `₺${price}`;
  }

  formatDate(dateStr: string): string {
    const date = new Date(dateStr);
    return date.toLocaleString(this.preferencesService.locale, {
      day: 'numeric', month: 'long', year: 'numeric',
      hour: '2-digit', minute: '2-digit'
    });
  }
}
