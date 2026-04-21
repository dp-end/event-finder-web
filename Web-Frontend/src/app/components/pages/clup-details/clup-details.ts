import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, ActivatedRoute, Router } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';
import { ClubService } from '../../../services/club.service';
import { EventService } from '../../../services/event.service';
import { AuthService } from '../../../services/auth';
import { ClubDto, EventListDto } from '../../../models/models';
import { EventCard } from '../../event-card/event-card';
import { environment } from '../../../../environments/environment';

@Component({
  selector: 'app-club-detail',
  standalone: true,
  imports: [CommonModule, RouterModule, EventCard],
  templateUrl: './clup-details.html',
  styleUrl: './clup-details.css'
})
export class ClupDetails implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  club: ClubDto | null = null;
  clubEvents: EventListDto[] = [];
  activeTab: 'events' | 'about' = 'events';
  isLoading = true;
  isLoadingEvents = false;
  isFollowing = false;
  error: string | null = null;

  get isLoggedIn(): boolean {
    return this.authService.isLoggedIn();
  }

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private clubService: ClubService,
    private eventService: EventService,
    private authService: AuthService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (!id) { this.router.navigate(['/home']); return; }
    this.loadClub(id);
    this.loadClubEvents(id);
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private loadClub(id: string): void {
    this.isLoading = true;
    this.clubService.getById(id).pipe(takeUntil(this.destroy$)).subscribe({
      next: club => {
        this.club = club;
        this.isFollowing = club.isFollowedByCurrentUser;
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'Kulüp bilgileri yüklenemedi.';
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  private loadClubEvents(clubId: string): void {
    this.isLoadingEvents = true;
    this.eventService.getByClub(clubId).pipe(takeUntil(this.destroy$)).subscribe({
      next: events => {
        this.clubEvents = events;
        this.isLoadingEvents = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.isLoadingEvents = false;
        this.cdr.detectChanges();
      }
    });
  }

  toggleFollow(): void {
    if (!this.club) return;
    if (!this.isLoggedIn) { this.router.navigate(['/login']); return; }

    this.clubService.toggleFollow(this.club.id).pipe(takeUntil(this.destroy$)).subscribe({
      next: result => {
        this.isFollowing = result.isFollowing;
        this.club!.followerCount = result.followerCount;
        this.club!.isFollowedByCurrentUser = result.isFollowing;
        this.cdr.detectChanges();
      }
    });
  }

  switchTab(tab: 'events' | 'about'): void {
    this.activeTab = tab;
  }

  resolveImageUrl(url?: string): string {
    if (!url) return '';
    return url.startsWith('/') ? `${environment.apiUrl}${url}` : url;
  }
}
