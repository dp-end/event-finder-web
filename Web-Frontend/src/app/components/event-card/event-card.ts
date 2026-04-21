import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { EventListDto } from '../../models/models';
import { EventService } from '../../services/event.service';
import { AuthService } from '../../services/auth';
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
    private authService: AuthService
  ) {}

  goToDetail(): void {
    if (this.event?.id) {
      this.router.navigate(['/event', this.event.id]);
    }
  }

  filterByOrganizer(e: Event): void {
    e.stopPropagation();
    if (!this.event?.ownerId) return;
    this.router.navigate(['/home'], { queryParams: { ownerId: this.event.ownerId } });
  }

  toggleLike(e: Event): void {
    e.stopPropagation();
    if (!this.event?.id || this.isLiking) return;
    if (!this.authService.isLoggedIn()) {
      this.router.navigate(['/login']);
      return;
    }

    this.isLiking = true;
    this.eventService.toggleLike(this.event.id).subscribe({
      next: result => {
        this.event.isLikedByCurrentUser = result.isLiked;
        this.event.likeCount = result.likeCount;
        this.isLiking = false;
      },
      error: () => { this.isLiking = false; }
    });
  }

  resolveImageUrl(url?: string): string {
    if (!url) return '';
    return url.startsWith('/') ? `${environment.apiUrl}${url}` : url;
  }

  formatPrice(price: number): string {
    return price === 0 ? 'Ücretsiz' : `₺${price}`;
  }

  formatDate(dateStr: string): string {
    const date = new Date(dateStr);
    return date.toLocaleString('tr-TR', {
      day: 'numeric', month: 'long', year: 'numeric',
      hour: '2-digit', minute: '2-digit'
    });
  }
}
