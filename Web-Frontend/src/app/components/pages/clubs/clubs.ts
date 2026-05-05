import { Component, OnInit, OnDestroy, ChangeDetectorRef, ChangeDetectionStrategy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { Subject, debounceTime, distinctUntilChanged, takeUntil } from 'rxjs';
import { ClubService } from '../../../services/club.service';
import { ClubListDto } from '../../../models/models';
import { environment } from '../../../../environments/environment';

@Component({
  selector: 'app-clubs',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
  templateUrl: './clubs.html',
  styleUrl: './clubs.css'
})
export class Clubs implements OnInit, OnDestroy {
  clubs: ClubListDto[] = [];
  filteredClubs: ClubListDto[] = [];
  isLoading = true;
  error = '';
  searchText = '';

  private destroy$ = new Subject<void>();
  private searchSubject = new Subject<string>();

  constructor(
    private clubService: ClubService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit() {
    this.loadClubs();
    this.searchSubject.pipe(
      debounceTime(300),
      distinctUntilChanged(),
      takeUntil(this.destroy$)
    ).subscribe(() => this.filterClubs());
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadClubs() {
    this.isLoading = true;
    this.error = '';
    this.cdr.detectChanges();

    this.clubService.getAll().pipe(takeUntil(this.destroy$)).subscribe({
      next: (clubs) => {
        this.clubs        = Array.isArray(clubs) ? clubs : [];
        this.filteredClubs = this.clubs;
        this.isLoading    = false;
        this.error        = '';
        this.cdr.detectChanges();
      },
      error: (err) => {
        console.error('Kulüpler yüklenemedi:', err);
        this.error     = 'Kulüpler yüklenemedi. Lütfen tekrar deneyin.';
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      complete: () => {
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  onSearchInput() {
    this.searchSubject.next(this.searchText);
  }

  filterClubs() {
    const q = this.searchText.toLowerCase().trim();
    this.filteredClubs = q
      ? this.clubs.filter(c =>
          c.name.toLowerCase().includes(q) ||
          (c.category && c.category.toLowerCase().includes(q))
        )
      : this.clubs;
    this.cdr.detectChanges();
  }

  goToClub(clubId: string) {
    this.router.navigate(['/club', clubId]);
  }

  resolveImageUrl(url?: string): string {
    if (!url) return '';
    return url.startsWith('/') ? `${environment.apiUrl}${url}` : url;
  }

  toggleFollow(event: Event, club: ClubListDto) {
    event.stopPropagation();
    this.clubService.toggleFollow(club.id).pipe(takeUntil(this.destroy$)).subscribe({
      next: (res) => {
        club.isFollowedByCurrentUser = res.isFollowing;
        club.followerCount = res.followerCount;
      },
      error: () => {}
    });
  }
}
