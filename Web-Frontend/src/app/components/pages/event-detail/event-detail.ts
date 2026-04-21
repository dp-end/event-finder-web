import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule, ActivatedRoute, Router } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';
import { EventService } from '../../../services/event.service';
import { TicketService } from '../../../services/ticket.service';
import { CommentService } from '../../../services/comment.service';
import { AuthService } from '../../../services/auth';
import { EventDto, CommentDto } from '../../../models/models';
import { environment } from '../../../../environments/environment';

@Component({
  selector: 'app-event-detail',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './event-detail.html',
  styleUrl: './event-detail.css'
})
export class EventDetail implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  event: EventDto | null = null;
  comments: CommentDto[] = [];
  newComment: string = '';

  isLoading = true;
  isLoadingComments = false;
  isPurchasing = false;
  isLiking = false;
  isPostingComment = false;
  error: string | null = null;
  ticketMessage: string | null = null;
  ticketError: string | null = null;

  get isLoggedIn(): boolean {
    return this.authService.isLoggedIn();
  }

  get currentUserId(): string | undefined {
    return this.authService.getCurrentUser()?.id;
  }

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private eventService: EventService,
    private ticketService: TicketService,
    private commentService: CommentService,
    public authService: AuthService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (!id) {
      this.router.navigate(['/home']);
      return;
    }
    this.loadEvent(id);
    this.loadComments(id);
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private loadEvent(id: string): void {
    this.isLoading = true;
    this.eventService.getById(id).pipe(takeUntil(this.destroy$)).subscribe({
      next: ev => {
        this.event = ev;
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'Etkinlik yüklenemedi.';
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  private loadComments(eventId: string): void {
    this.isLoadingComments = true;
    this.commentService.getByEvent(eventId).pipe(takeUntil(this.destroy$)).subscribe({
      next: comments => {
        this.comments = comments;
        this.isLoadingComments = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.isLoadingComments = false;
        this.cdr.detectChanges();
      }
    });
  }

  toggleLike(): void {
    if (!this.event || this.isLiking) return;
    if (!this.isLoggedIn) { this.router.navigate(['/login']); return; }

    this.isLiking = true;
    this.eventService.toggleLike(this.event.id).pipe(takeUntil(this.destroy$)).subscribe({
      next: result => {
        this.event!.isLikedByCurrentUser = result.isLiked;
        this.event!.likeCount = result.likeCount;
        this.isLiking = false;
        this.cdr.detectChanges();
      },
      error: () => { this.isLiking = false; this.cdr.detectChanges(); }
    });
  }

  buyTicket(): void {
    if (!this.event) return;
    if (!this.isLoggedIn) { this.router.navigate(['/login']); return; }

    this.isPurchasing = true;
    this.ticketMessage = null;
    this.ticketError = null;

    this.ticketService.purchase({ eventId: this.event.id }).pipe(takeUntil(this.destroy$)).subscribe({
      next: () => {
        this.event!.hasTicket = true;
        this.event!.remainingQuota = Math.max(0, this.event!.remainingQuota - 1);
        this.ticketMessage = 'Biletiniz başarıyla alındı! Biletlerim sayfasından görüntüleyebilirsiniz.';
        this.isPurchasing = false;
        this.cdr.detectChanges();
      },
      error: err => {
        this.ticketError = err.error?.message || 'Bilet alınırken bir hata oluştu.';
        this.isPurchasing = false;
        this.cdr.detectChanges();
      }
    });
  }

  postComment(): void {
    if (!this.event || !this.newComment.trim() || this.isPostingComment) return;
    if (!this.isLoggedIn) { this.router.navigate(['/login']); return; }

    this.isPostingComment = true;
    this.commentService.create({ eventId: this.event.id, content: this.newComment.trim() })
      .pipe(takeUntil(this.destroy$)).subscribe({
        next: comment => {
          this.comments = [comment, ...this.comments];
          this.event!.commentCount++;
          this.newComment = '';
          this.isPostingComment = false;
          this.cdr.detectChanges();
        },
        error: () => { this.isPostingComment = false; this.cdr.detectChanges(); }
      });
  }

  deleteComment(commentId: string): void {
    this.commentService.delete(commentId).pipe(takeUntil(this.destroy$)).subscribe({
      next: () => {
        this.comments = this.comments.filter(c => c.id !== commentId);
        if (this.event) this.event.commentCount--;
        this.cdr.detectChanges();
      }
    });
  }

  formatDate(dateStr: string): string {
    return new Date(dateStr).toLocaleString('tr-TR', {
      day: 'numeric', month: 'long', year: 'numeric',
      hour: '2-digit', minute: '2-digit'
    });
  }

  formatPrice(price: number): string {
    return price === 0 ? 'Ücretsiz' : `₺${price}`;
  }

  resolveImageUrl(url?: string): string {
    if (!url) return '';
    return url.startsWith('/') ? `${environment.apiUrl}${url}` : url;
  }

  get quotaPercent(): number {
    if (!this.event || this.event.quota === 0) return 0;
    const used = this.event.quota - this.event.remainingQuota;
    return Math.min(100, Math.round((used / this.event.quota) * 100));
  }
}
