import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { Subject, debounceTime, distinctUntilChanged, takeUntil } from 'rxjs';
import { ClubService } from '../../../services/club.service';
import { ClubListDto } from '../../../models/models';

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

  constructor(private clubService: ClubService, private router: Router) {}

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
    this.clubService.getAll().pipe(takeUntil(this.destroy$)).subscribe({
      next: (clubs) => {
        this.clubs = clubs;
        this.filteredClubs = clubs;
        this.isLoading = false;
      },
      error: (err) => {
        this.error = err.message || 'Kulüpler yüklenemedi.';
        this.isLoading = false;
      }
    });
  }

  onSearchInput() {
    this.searchSubject.next(this.searchText);
  }

  filterClubs() {
    const q = this.searchText.toLowerCase().trim();
    if (!q) {
      this.filteredClubs = this.clubs;
    } else {
      this.filteredClubs = this.clubs.filter(c =>
        c.name.toLowerCase().includes(q) ||
        (c.category && c.category.toLowerCase().includes(q))
      );
    }
  }

  goToClub(clubId: string) {
    this.router.navigate(['/club', clubId]);
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
