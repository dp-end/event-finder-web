import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule, ActivatedRoute } from '@angular/router';
import { Subject, debounceTime, distinctUntilChanged, takeUntil } from 'rxjs';
import { EventCard } from '../../event-card/event-card';
import { SidebarService } from '../../../services/sidebar';
import { EventService, EventFilterParams } from '../../../services/event.service';
import { ClubService } from '../../../services/club.service';
import { CategoryService } from '../../../services/category.service';
import { EventListDto, ClubListDto, CategoryDto } from '../../../models/models';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, FormsModule, EventCard, RouterModule],
  templateUrl: './home.html',
  styleUrl: './home.css'
})
export class Home implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  private searchSubject = new Subject<string>();

  categories: CategoryDto[] = [];
  activeCategory = 'Tümü';
  activeTimePeriod = 'Tümü';
  searchText = '';
  freeOnly = false;
  ownerIdFilter: string | null = null;

  timePeriods = ['Tümü', 'Bugün', 'Bu Hafta', 'Bu Ay'];

  events: EventListDto[] = [];
  topClubs: ClubListDto[] = [];

  isLoading = true;
  isLoadingClubs = true;
  error: string | null = null;

  constructor(
    private sidebarService: SidebarService,
    private eventService: EventService,
    private clubService: ClubService,
    private categoryService: CategoryService,
    private cdr: ChangeDetectorRef,
    private route: ActivatedRoute
  ) {}

  ngOnInit(): void {
    this.loadCategories();
    this.loadTopClubs();

    this.route.queryParamMap.pipe(takeUntil(this.destroy$)).subscribe(params => {
      this.ownerIdFilter = params.get('ownerId');
      this.loadEvents();
    });

    this.searchSubject.pipe(
      debounceTime(300),
      distinctUntilChanged(),
      takeUntil(this.destroy$)
    ).subscribe(() => this.loadEvents());
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private loadCategories(): void {
    this.categoryService.getAll().pipe(takeUntil(this.destroy$)).subscribe({
      next: cats => {
        this.categories = cats;
        this.cdr.detectChanges();
      },
      error: () => {}
    });
  }

  loadEvents(): void {
    this.isLoading = true;
    this.error = null;
    this.cdr.detectChanges();

    const filters: EventFilterParams = {};
    if (this.searchText) filters.query = this.searchText;
    if (this.activeCategory !== 'Tümü') filters.category = this.activeCategory;
    if (this.freeOnly) filters.freeOnly = true;
    if (this.activeTimePeriod !== 'Tümü') filters.timePeriod = this.activeTimePeriod;
    if (this.ownerIdFilter) filters.ownerId = this.ownerIdFilter;

    this.eventService.getAll(filters).pipe(takeUntil(this.destroy$)).subscribe({
      next: events => {
        this.events = events;
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'Etkinlikler yüklenemedi. Sunucu bağlantısını kontrol edin.';
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  private loadTopClubs(): void {
    this.clubService.getPopular(5).pipe(takeUntil(this.destroy$)).subscribe({
      next: clubs => {
        this.topClubs = clubs;
        this.isLoadingClubs = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.isLoadingClubs = false;
        this.cdr.detectChanges();
      }
    });
  }

  openMenu(): void { this.sidebarService.toggleSidebar(); }

  selectCategory(category: string): void {
    this.activeCategory = category;
    this.loadEvents();
  }

  selectTimePeriod(period: string): void {
    this.activeTimePeriod = period;
    this.loadEvents();
  }

  onSearchInput(): void {
    this.searchSubject.next(this.searchText);
  }

  toggleFreeOnly(): void {
    this.freeOnly = !this.freeOnly;
    this.loadEvents();
  }

  formatPrice(price: number): string {
    return price === 0 ? 'Ücretsiz' : `₺${price}`;
  }
}
