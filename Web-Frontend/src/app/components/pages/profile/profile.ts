import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';
import { AuthService } from '../../../services/auth';
import { EventService } from '../../../services/event.service';
import { PreferencesService, PrivacyPreferences } from '../../../services/preferences.service';
import { EventListDto, AuthResponse, ProfileDto } from '../../../models/models';
import { EventCard } from '../../event-card/event-card';
import { environment } from '../../../../environments/environment';

@Component({
  selector: 'app-profile',
  standalone: true,
  imports: [CommonModule, RouterModule, EventCard],
  templateUrl: './profile.html',
  styleUrl: './profile.css'
})
export class Profile implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  user: AuthResponse | null = null;
  profile: ProfileDto | null = null;
  privacyPreferences: PrivacyPreferences;
  myEvents: EventListDto[] = [];
  viewingProfileId: string | null = null;
  isLoadingProfile = true;
  isLoadingEvents = false;
  profileError: string | null = null;

  get initials(): string {
    const firstName = this.profile?.userType === 'club'
      ? (this.profile.clubName ?? this.profile.firstName)
      : (this.profile?.firstName ?? this.user?.firstName);
    const lastName = this.profile?.lastName ?? this.user?.lastName;
    const userName = this.profile?.userName ?? this.user?.userName;
    return ((firstName?.[0] ?? '') + (lastName?.[0] ?? '')).toUpperCase() || userName?.[0]?.toUpperCase() || '?';
  }

  get fullName(): string {
    if (this.profile?.userType === 'club') {
      return this.profile.clubName || this.profile.firstName || this.profile.userName;
    }
    if (this.profile) {
      return `${this.profile.firstName ?? ''} ${this.profile.lastName ?? ''}`.trim() || this.profile.userName;
    }
    if (!this.user) return '';
    return `${this.user.firstName ?? ''} ${this.user.lastName ?? ''}`.trim() || this.user.userName;
  }

  get profileImageUrl(): string | undefined {
    return this.profile?.profileImageUrl || (this.isViewingOwnProfile ? this.user?.profileImageUrl : undefined);
  }

  get coverImageUrl(): string | undefined {
    return this.isClubUser() ? this.profile?.clubCoverImageUrl : undefined;
  }

  get isViewingOwnProfile(): boolean {
    return !this.viewingProfileId || this.viewingProfileId === this.user?.id;
  }

  get canShowProfileDetails(): boolean {
    return !this.isViewingOwnProfile || this.privacyPreferences.profileVisibility !== 'private';
  }

  get eventsSectionTitle(): string {
    if (this.isViewingOwnProfile && this.isClubUser()) return 'Kulübümün Yüklediği Etkinlikler';
    if (this.isClubUser()) return 'Kulübün Yüklediği Etkinlikler';
    return this.isViewingOwnProfile ? 'Yüklediğim Etkinlikler' : 'Yüklediği Etkinlikler';
  }

  get eventsEmptyMessage(): string {
    if (this.isViewingOwnProfile && this.isClubUser()) return 'Henüz kulübünüz için etkinlik yüklemediniz.';
    if (this.isViewingOwnProfile) return 'Henüz etkinlik yüklemedin.';
    if (this.isClubUser()) return 'Bu kulübün aktif etkinliği yok.';
    return 'Bu kullanıcının yüklediği aktif etkinlik yok.';
  }

  get uploadedEventCount(): number {
    return this.myEvents.length || this.profile?.createdEventCount || 0;
  }

  get joinedEventCount(): number {
    return this.profile?.ticketCount ?? 0;
  }

  get followingClubCount(): number {
    return this.profile?.followingClubCount ?? 0;
  }

  get clubFollowerCount(): number {
    return this.profile?.clubFollowerCount ?? 0;
  }

  constructor(
    private authService: AuthService,
    private eventService: EventService,
    private preferencesService: PreferencesService,
    private route: ActivatedRoute,
    private cdr: ChangeDetectorRef
  ) {
    this.privacyPreferences = this.preferencesService.privacy;
  }

  ngOnInit(): void {
    this.user = this.authService.getCurrentUser();
    this.preferencesService.privacy$
      .pipe(takeUntil(this.destroy$))
      .subscribe(preferences => {
        this.privacyPreferences = preferences;
        this.cdr.detectChanges();
      });

    this.route.paramMap
      .pipe(takeUntil(this.destroy$))
      .subscribe(params => {
        this.viewingProfileId = params.get('id');
        this.loadProfile();
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  isClubUser(): boolean {
    return this.profile?.userType === 'club' || (this.isViewingOwnProfile && this.authService.isClubUser());
  }

  resolveImageUrl(url?: string): string {
    if (!url) return '';
    return url.startsWith('/') ? `${environment.apiUrl}${url}` : url;
  }

  private loadProfile(): void {
    this.user = this.authService.getCurrentUser();
    this.profile = null;
    this.myEvents = [];
    this.profileError = null;
    this.isLoadingProfile = true;
    this.isLoadingEvents = false;

    const publicProfileId = this.viewingProfileId && this.viewingProfileId !== this.user?.id
      ? this.viewingProfileId
      : null;

    if (publicProfileId) {
      this.authService.getPublicProfile(publicProfileId)
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: profile => {
            this.profile = profile;
            this.isLoadingProfile = false;
            this.cdr.detectChanges();
            this.loadProfileEvents(profile);
          },
          error: () => {
            this.profileError = 'Profil görüntülenemedi.';
            this.isLoadingProfile = false;
            this.cdr.detectChanges();
          }
        });
      return;
    }

    if (!this.user) {
      this.isLoadingProfile = false;
      this.cdr.detectChanges();
      return;
    }

    const cachedProfile = this.authService.getCurrentProfileSnapshot();
    if (cachedProfile) {
      this.profile = cachedProfile;
      this.isLoadingProfile = false;
      this.cdr.detectChanges();
      this.loadProfileEvents(cachedProfile);
    }

    this.authService.getMe()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: profile => {
          this.profile = profile;
          this.isLoadingProfile = false;
          this.cdr.detectChanges();
          if (!cachedProfile) this.loadProfileEvents(profile);
        },
        error: () => {
          if (!cachedProfile) this.profileError = 'Profil görüntülenemedi.';
          this.isLoadingProfile = false;
          this.cdr.detectChanges();
        }
      });
  }

  private loadProfileEvents(profile: ProfileDto): void {
    const events$ = profile.userType === 'club' && profile.clubId
      ? this.eventService.getByClub(profile.clubId)
      : this.isViewingOwnProfile
        ? this.eventService.getMine()
        : this.eventService.getByOwner(profile.id);

    this.isLoadingEvents = true;
    events$.pipe(takeUntil(this.destroy$)).subscribe({
      next: events => {
        this.myEvents = events;
        this.isLoadingEvents = false;
        this.cdr.detectChanges();
      },
      error: () => {
        if (this.isViewingOwnProfile && !(profile.userType === 'club' && profile.clubId)) {
          this.eventService.getByOwner(profile.id).pipe(takeUntil(this.destroy$)).subscribe({
            next: events => {
              this.myEvents = events;
              this.isLoadingEvents = false;
              this.cdr.detectChanges();
            },
            error: () => {
              this.isLoadingEvents = false;
              this.cdr.detectChanges();
            }
          });
          return;
        }

        this.isLoadingEvents = false;
        this.cdr.detectChanges();
      }
    });
  }
}
