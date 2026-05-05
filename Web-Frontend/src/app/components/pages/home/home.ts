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
import { PreferencesService } from '../../../services/preferences.service';
import { EventListDto, ClubListDto, CategoryDto } from '../../../models/models';
import { environment } from '../../../../environments/environment';

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
  activeEventType = 'Tümü';
  searchText = '';
  freeOnly = false;
  maxPrice = 200;
  readonly minFilterPrice = 10;
  readonly maxFilterPrice = 500;
  isFilterOpen = false;
  draftFreeOnly = false;
  draftMaxPrice = 200;
  draftTimePeriod = 'Tümü';
  ownerIdFilter: string | null = null;

  timePeriods  = ['Tümü', 'Bugün', 'Bu Hafta', 'Bu Ay'];
  eventTypes   = ['Tümü', 'Kulüp Etkinlikleri', 'Bireysel Etkinlikler'];

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
    private route: ActivatedRoute,
    private preferencesService: PreferencesService
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
    if (!this.freeOnly && this.maxPrice < this.maxFilterPrice) filters.maxPrice = this.maxPrice;
    if (this.activeTimePeriod !== 'Tümü') filters.timePeriod = this.activeTimePeriod;
    if (this.ownerIdFilter) filters.ownerId = this.ownerIdFilter;
    if (this.activeEventType !== 'Tümü') {
      filters.eventType = this.activeEventType === 'Kulüp Etkinlikleri' ? 'club' : 'individual';
    }

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

  get hasAdvancedFilters(): boolean {
    return this.freeOnly || this.maxPrice < this.maxFilterPrice || this.activeTimePeriod !== 'Tümü';
  }

  openFilterPanel(): void {
    this.draftFreeOnly = this.freeOnly;
    this.draftMaxPrice = this.maxPrice;
    this.draftTimePeriod = this.activeTimePeriod;
    this.isFilterOpen = true;
  }

  closeFilterPanel(): void {
    this.isFilterOpen = false;
  }

  setDraftTimePeriod(period: string): void {
    this.draftTimePeriod = period;
  }

  selectDraftPaid(): void {
    this.draftFreeOnly = false;
    if (this.draftMaxPrice >= this.maxFilterPrice) this.draftMaxPrice = 200;
  }

  applyAdvancedFilters(): void {
    this.freeOnly = this.draftFreeOnly;
    this.maxPrice = this.draftMaxPrice;
    this.activeTimePeriod = this.draftTimePeriod;
    this.isFilterOpen = false;
    this.loadEvents();
  }

  selectCategory(category: string): void {
    this.activeCategory = category;
    this.loadEvents();
  }

  selectTimePeriod(period: string): void {
    this.activeTimePeriod = period;
    this.loadEvents();
  }

  selectEventType(type: string): void {
    this.activeEventType = type;
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
    return price === 0
      ? (this.preferencesService.language === 'en' ? 'Free' : 'Ücretsiz')
      : `₺${price}`;
  }

  resolveImageUrl(url?: string): string {
    if (!url) return '';
    return url.startsWith('/') ? `${environment.apiUrl}${url}` : url;
  }
}
