import { Component, OnInit, OnDestroy, ChangeDetectorRef, ElementRef, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule, ActivatedRoute, Router } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';
import { EventService } from '../../../services/event.service';
import { TicketService } from '../../../services/ticket.service';
import { CommentService } from '../../../services/comment.service';
import { AuthService } from '../../../services/auth';
import { PreferencesService } from '../../../services/preferences.service';
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
  @ViewChild('commentsSection') commentsSection?: ElementRef<HTMLElement>;
  @ViewChild('commentComposer') commentComposer?: ElementRef<HTMLTextAreaElement>;

  event: EventDto | null = null;
  comments: CommentDto[] = [];
  newComment: string = '';
  replyingTo: CommentDto | null = null;

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

  get organizerName(): string {
    return this.event?.organizerName || this.event?.clubName || this.event?.ownerName || 'Organizatör';
  }

  get organizerInitials(): string {
    return this.event?.organizerInitials || this.event?.clubInitials || this.event?.ownerInitials || '?';
  }

  get organizerProfileImageUrl(): string | undefined {
    return this.event?.organizerProfileImageUrl || this.event?.clubProfileImageUrl || this.event?.ownerProfileImageUrl;
  }

  get organizerLabel(): string {
    return this.event?.clubId ? 'Düzenleyen Topluluk' : 'Düzenleyen Kişi';
  }

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private eventService: EventService,
    private ticketService: TicketService,
    private commentService: CommentService,
    public authService: AuthService,
    private preferencesService: PreferencesService,
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

    this.route.queryParamMap.pipe(takeUntil(this.destroy$)).subscribe(params => {
      if (params.get('focus') === 'comments') this.requestCommentsFocus(true);
    });

    this.route.fragment.pipe(takeUntil(this.destroy$)).subscribe(fragment => {
      if (fragment === 'comments') this.requestCommentsFocus(true);
    });
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
    const wasLiked = this.event.isLikedByCurrentUser;
    const previousCount = this.event.likeCount ?? 0;
    this.eventService.toggleLike(this.event.id).pipe(takeUntil(this.destroy$)).subscribe({
      next: result => {
        this.event!.isLikedByCurrentUser = result.liked;
        const delta = result.liked === wasLiked ? 0 : (result.liked ? 1 : -1);
        this.event!.likeCount = Math.max(0, previousCount + delta);
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

    const content = this.newComment.trim();
    const parentCommentId = this.replyingTo?.parentCommentId || this.replyingTo?.id;
    this.isPostingComment = true;
    this.commentService.create({ eventId: this.event.id, content, parentCommentId })
      .pipe(takeUntil(this.destroy$)).subscribe({
        next: comment => {
          if (parentCommentId) {
            this.comments = this.addReplyToParent(this.comments, parentCommentId, comment);
          } else {
            this.comments = [comment, ...this.comments];
          }
          this.event!.commentCount++;
          this.newComment = '';
          this.replyingTo = null;
          this.isPostingComment = false;
          this.cdr.detectChanges();
        },
        error: () => { this.isPostingComment = false; this.cdr.detectChanges(); }
      });
  }

  deleteComment(commentId: string): void {
    this.commentService.delete(commentId).pipe(takeUntil(this.destroy$)).subscribe({
      next: () => {
        const result = this.removeCommentFromList(this.comments, commentId);
        this.comments = result.comments;
        if (this.event) this.event.commentCount = Math.max(0, this.event.commentCount - result.removedCount);
        if (this.replyingTo?.id === commentId) this.replyingTo = null;
        this.cdr.detectChanges();
      }
    });
  }

  goToOrganizerProfile(): void {
    if (!this.event) return;

    if (this.event.clubId) {
      this.router.navigate(['/club', this.event.clubId]);
      return;
    }

    if (this.event.ownerId) {
      this.router.navigate(['/profile', this.event.ownerId]);
    }
  }

  goToCommentOwner(comment: CommentDto): void {
    if (comment.applicationUserId) {
      this.router.navigate(['/profile', comment.applicationUserId]);
    }
  }

  replyTo(comment: CommentDto): void {
    if (!this.isLoggedIn) {
      this.router.navigate(['/login']);
      return;
    }
    this.replyingTo = comment;
    this.requestCommentsFocus(true);
    this.cdr.detectChanges();
  }

  cancelReply(): void {
    this.replyingTo = null;
  }

  scrollToComments(focusComposer = false): void {
    this.commentsSection?.nativeElement.scrollIntoView({ behavior: 'smooth', block: 'start' });
    if (focusComposer && this.isLoggedIn) {
      window.setTimeout(() => this.commentComposer?.nativeElement.focus(), 320);
    }
  }

  commentAuthorImageUrl(comment: CommentDto): string | undefined {
    return comment.userProfileImageUrl;
  }

  private requestCommentsFocus(focusComposer = false): void {
    window.setTimeout(() => this.scrollToComments(focusComposer), 120);
    window.setTimeout(() => this.scrollToComments(focusComposer), 520);
  }

  private addReplyToParent(comments: CommentDto[], parentId: string, reply: CommentDto): CommentDto[] {
    return comments.map(comment => {
      if (comment.id === parentId) {
        return { ...comment, replies: [...(comment.replies ?? []), reply] };
      }

      if (comment.replies?.length) {
        return { ...comment, replies: this.addReplyToParent(comment.replies, parentId, reply) };
      }

      return comment;
    });
  }

  private removeCommentFromList(comments: CommentDto[], commentId: string): { comments: CommentDto[]; removedCount: number } {
    let removedCount = 0;
    const next: CommentDto[] = [];

    for (const comment of comments) {
      if (comment.id === commentId) {
        removedCount += this.countCommentThread(comment);
        continue;
      }

      if (comment.replies?.length) {
        const result = this.removeCommentFromList(comment.replies, commentId);
        removedCount += result.removedCount;
        next.push({ ...comment, replies: result.comments });
      } else {
        next.push(comment);
      }
    }

    return { comments: next, removedCount };
  }

  private countCommentThread(comment: CommentDto): number {
    return 1 + (comment.replies ?? []).reduce((total, reply) => total + this.countCommentThread(reply), 0);
  }

  formatDate(dateStr: string): string {
    return new Date(dateStr).toLocaleString(this.preferencesService.locale, {
      day: 'numeric', month: 'long', year: 'numeric',
      hour: '2-digit', minute: '2-digit'
    });
  }

  formatPrice(price: number): string {
    return price === 0
      ? (this.preferencesService.language === 'en' ? 'Free' : 'Ücretsiz')
      : `₺${price}`;
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
