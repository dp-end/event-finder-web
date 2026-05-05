import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';
import { AuthService } from '../../../services/auth';
import {
  AppLanguage,
  PreferencesService,
  PrivacyPreferences,
  ProfileVisibility
} from '../../../services/preferences.service';
import { ProfileDto, UpdateProfileRequest } from '../../../models/models';

type SettingsDialog = 'profile' | 'password' | 'privacy' | null;

interface ProfileForm {
  userType: string;
  firstName: string;
  lastName: string;
  university: string;
  department: string;
  profileImageUrl: string;
  clubName: string;
  clubDescription: string;
  clubCoverImageUrl: string;
  clubInstagramHandle: string;
}

interface PasswordForm {
  currentPassword: string;
  newPassword: string;
  confirmPassword: string;
}

const SETTINGS_COPY = {
  tr: {
    settings: 'Ayarlar',
    account: 'Hesap',
    preferences: 'Tercihler',
    editProfile: 'Profili Düzenle',
    editProfileHint: 'Ad, biyografi, profil fotoğrafı',
    changePassword: 'Şifre Değiştir',
    changePasswordHint: 'Hesap güvenliğini yönetin',
    privacy: 'Gizlilik',
    privacyHint: 'Profilini kimler görebilir',
    darkTheme: 'Karanlık Tema',
    darkThemeHint: 'Aydınlık / Karanlık mod',
    language: 'Dil',
    languageHint: 'Uygulama dilini değiştir',
    logout: 'Hesaptan Çıkış Yap',
    save: 'Kaydet',
    cancel: 'İptal',
    close: 'Kapat',
    retry: 'Tekrar dene',
    profileUpdated: 'Profil güncellendi.',
    privacyUpdated: 'Gizlilik tercihleri kaydedildi.',
    passwordUpdated: 'Şifreniz başarıyla değiştirildi.',
    loginRequired: 'Bu işlem için giriş yapmalısınız.',
    fillRequired: 'Lütfen zorunlu alanları doldurun.',
    passwordMismatch: 'Yeni şifreler eşleşmiyor.',
    passwordMin: 'Yeni şifre en az 6 karakter olmalıdır.',
    currentPassword: 'Mevcut Şifre',
    newPassword: 'Yeni Şifre',
    confirmPassword: 'Yeni Şifre Tekrar',
    firstName: 'Ad',
    lastName: 'Soyad',
    university: 'Üniversite',
    department: 'Bölüm',
    profileImageUrl: 'Profil Fotoğraf URL',
    clubName: 'Kulüp Adı',
    clubDescription: 'Kulüp Açıklaması',
    clubCoverImageUrl: 'Kapak Fotoğraf URL',
    clubInstagramHandle: 'Instagram',
    publicProfile: 'Herkese açık',
    membersProfile: 'Sadece giriş yapanlar',
    privateProfile: 'Gizli',
    profileVisibility: 'Profil görünürlüğü',
    showEmail: 'E-posta profilimde görünsün',
    showUniversity: 'Üniversite profilimde görünsün',
    showDepartment: 'Bölüm profilimde görünsün',
    selectedPrivacy: 'Seçili gizlilik'
  },
  en: {
    settings: 'Settings',
    account: 'Account',
    preferences: 'Preferences',
    editProfile: 'Edit Profile',
    editProfileHint: 'Name, biography, profile photo',
    changePassword: 'Change Password',
    changePasswordHint: 'Manage account security',
    privacy: 'Privacy',
    privacyHint: 'Control who can see your profile',
    darkTheme: 'Dark Theme',
    darkThemeHint: 'Light / Dark mode',
    language: 'Language',
    languageHint: 'Change application language',
    logout: 'Log Out',
    save: 'Save',
    cancel: 'Cancel',
    close: 'Close',
    retry: 'Try again',
    profileUpdated: 'Profile updated.',
    privacyUpdated: 'Privacy preferences saved.',
    passwordUpdated: 'Your password has been changed.',
    loginRequired: 'You need to sign in for this action.',
    fillRequired: 'Please fill in the required fields.',
    passwordMismatch: 'New passwords do not match.',
    passwordMin: 'New password must be at least 6 characters.',
    currentPassword: 'Current Password',
    newPassword: 'New Password',
    confirmPassword: 'Confirm New Password',
    firstName: 'First Name',
    lastName: 'Last Name',
    university: 'University',
    department: 'Department',
    profileImageUrl: 'Profile Photo URL',
    clubName: 'Club Name',
    clubDescription: 'Club Description',
    clubCoverImageUrl: 'Cover Photo URL',
    clubInstagramHandle: 'Instagram',
    publicProfile: 'Public',
    membersProfile: 'Signed-in users only',
    privateProfile: 'Private',
    profileVisibility: 'Profile visibility',
    showEmail: 'Show email on my profile',
    showUniversity: 'Show university on my profile',
    showDepartment: 'Show department on my profile',
    selectedPrivacy: 'Selected privacy'
  }
} as const;

type CopyKey = keyof typeof SETTINGS_COPY.tr;

@Component({
  selector: 'app-settings',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './settings.html',
  styleUrl: './settings.css'
})
export class Settings implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  isDarkMode = false;
  appLanguage: AppLanguage = 'tr';
  activeDialog: SettingsDialog = null;

  privacyPreferences: PrivacyPreferences = {
    profileVisibility: 'public',
    showEmail: true,
    showUniversity: true,
    showDepartment: true
  };
  privacyDraft: PrivacyPreferences = {
    profileVisibility: 'public',
    showEmail: true,
    showUniversity: true,
    showDepartment: true
  };

  profileForm: ProfileForm = this.emptyProfileForm();
  passwordForm: PasswordForm = this.emptyPasswordForm();

  isProfileLoading = false;
  isSavingProfile = false;
  isSavingPassword = false;

  profileError: string | null = null;
  profileMessage: string | null = null;
  passwordError: string | null = null;
  passwordMessage: string | null = null;
  settingsMessage: string | null = null;

  constructor(
    private authService: AuthService,
    private preferencesService: PreferencesService,
    private router: Router,
    private route: ActivatedRoute
  ) {
    this.privacyPreferences = this.preferencesService.privacy;
    this.privacyDraft = this.preferencesService.privacy;
  }

  ngOnInit(): void {
    this.preferencesService.darkMode$
      .pipe(takeUntil(this.destroy$))
      .subscribe(value => this.isDarkMode = value);

    this.preferencesService.language$
      .pipe(takeUntil(this.destroy$))
      .subscribe(value => this.appLanguage = value);

    this.preferencesService.privacy$
      .pipe(takeUntil(this.destroy$))
      .subscribe(value => this.privacyPreferences = value);

    this.route.queryParamMap
      .pipe(takeUntil(this.destroy$))
      .subscribe(params => {
        const panel = params.get('panel') ?? params.get('section');
        if (panel === 'profile') this.openProfileDialog();
        if (panel === 'password') this.openPasswordDialog();
        if (panel === 'privacy') this.openPrivacyDialog();
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  t(key: CopyKey): string {
    return SETTINGS_COPY[this.appLanguage][key];
  }

  get isClubProfile(): boolean {
    return this.profileForm.userType === 'club';
  }

  get privacySummary(): string {
    return this.visibilityLabel(this.privacyPreferences.profileVisibility);
  }

  toggleTheme(event: Event): void {
    const input = event.target as HTMLInputElement;
    this.preferencesService.setDarkMode(input.checked);
  }

  changeLanguage(event: Event): void {
    const select = event.target as HTMLSelectElement;
    const language: AppLanguage = select.value === 'en' ? 'en' : 'tr';
    this.preferencesService.setLanguage(language);
  }

  openProfileDialog(): void {
    this.settingsMessage = null;
    if (!this.authService.isLoggedIn()) {
      this.router.navigate(['/login']);
      return;
    }

    this.activeDialog = 'profile';
    this.profileMessage = null;
    const cachedProfile = this.authService.getCurrentProfileSnapshot();
    if (cachedProfile) this.patchProfileForm(cachedProfile);
    this.loadProfile();
  }

  openPasswordDialog(): void {
    this.settingsMessage = null;
    if (!this.authService.isLoggedIn()) {
      this.router.navigate(['/login']);
      return;
    }

    this.activeDialog = 'password';
    this.passwordForm = this.emptyPasswordForm();
    this.passwordError = null;
    this.passwordMessage = null;
  }

  openPrivacyDialog(): void {
    this.settingsMessage = null;
    this.activeDialog = 'privacy';
    this.privacyDraft = { ...this.privacyPreferences };
  }

  closeDialog(): void {
    if (this.isSavingProfile || this.isSavingPassword) return;
    this.activeDialog = null;
  }

  saveProfile(): void {
    if (this.isSavingProfile) return;

    const requiredFilled = this.isClubProfile
      ? this.profileForm.clubName.trim().length > 0
      : this.profileForm.firstName.trim().length > 0 && this.profileForm.lastName.trim().length > 0;

    if (!requiredFilled) {
      this.profileError = this.t('fillRequired');
      return;
    }

    const payload: UpdateProfileRequest = this.isClubProfile
      ? {
          clubName: this.profileForm.clubName.trim(),
          clubDescription: this.profileForm.clubDescription.trim(),
          clubCoverImageUrl: this.profileForm.clubCoverImageUrl.trim(),
          clubInstagramHandle: this.profileForm.clubInstagramHandle.trim(),
          university: this.profileForm.university.trim(),
          department: this.profileForm.department.trim(),
          profileImageUrl: this.profileForm.profileImageUrl.trim()
        }
      : {
          firstName: this.profileForm.firstName.trim(),
          lastName: this.profileForm.lastName.trim(),
          university: this.profileForm.university.trim(),
          department: this.profileForm.department.trim(),
          profileImageUrl: this.profileForm.profileImageUrl.trim()
        };

    this.isSavingProfile = true;
    this.profileError = null;
    this.profileMessage = null;

    this.authService.updateProfile(payload)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: profile => {
          this.patchProfileForm(profile);
          this.isSavingProfile = false;
          this.profileMessage = this.t('profileUpdated');
        },
        error: error => {
          this.profileError = this.extractError(error, this.t('fillRequired'));
          this.isSavingProfile = false;
        }
      });
  }

  savePassword(): void {
    if (this.isSavingPassword) return;

    this.passwordError = null;
    this.passwordMessage = null;

    if (!this.passwordForm.currentPassword || !this.passwordForm.newPassword || !this.passwordForm.confirmPassword) {
      this.passwordError = this.t('fillRequired');
      return;
    }

    if (this.passwordForm.newPassword.length < 6) {
      this.passwordError = this.t('passwordMin');
      return;
    }

    if (this.passwordForm.newPassword !== this.passwordForm.confirmPassword) {
      this.passwordError = this.t('passwordMismatch');
      return;
    }

    this.isSavingPassword = true;

    this.authService.changePassword({
      currentPassword: this.passwordForm.currentPassword,
      newPassword: this.passwordForm.newPassword
    }).pipe(takeUntil(this.destroy$)).subscribe({
      next: response => {
        this.passwordForm = this.emptyPasswordForm();
        this.passwordMessage = response.message || this.t('passwordUpdated');
        this.isSavingPassword = false;
      },
      error: error => {
        this.passwordError = this.extractError(error, this.t('fillRequired'));
        this.isSavingPassword = false;
      }
    });
  }

  savePrivacy(): void {
    this.preferencesService.setPrivacy(this.privacyDraft);
    this.settingsMessage = this.t('privacyUpdated');
    this.activeDialog = null;
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }

  visibilityLabel(value: ProfileVisibility): string {
    if (value === 'members') return this.t('membersProfile');
    if (value === 'private') return this.t('privateProfile');
    return this.t('publicProfile');
  }

  private loadProfile(): void {
    this.isProfileLoading = true;
    this.profileError = null;
    const cachedProfile = this.authService.getCurrentProfileSnapshot();
    if (cachedProfile) {
      this.patchProfileForm(cachedProfile);
      this.isProfileLoading = false;
    }

    this.authService.getMe()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: profile => {
          this.patchProfileForm(profile);
          this.isProfileLoading = false;
        },
        error: error => {
          if (!cachedProfile) {
            this.profileError = this.extractError(error, this.t('loginRequired'));
          }
          this.isProfileLoading = false;
        }
      });
  }

  private patchProfileForm(profile: ProfileDto): void {
    this.profileForm = {
      userType: profile.userType ?? 'student',
      firstName: profile.firstName ?? '',
      lastName: profile.lastName ?? '',
      university: profile.university ?? '',
      department: profile.department ?? '',
      profileImageUrl: profile.profileImageUrl ?? '',
      clubName: profile.clubName ?? profile.firstName ?? '',
      clubDescription: profile.clubDescription ?? '',
      clubCoverImageUrl: profile.clubCoverImageUrl ?? '',
      clubInstagramHandle: profile.clubInstagramHandle ?? ''
    };
  }

  private emptyProfileForm(): ProfileForm {
    return {
      userType: 'student',
      firstName: '',
      lastName: '',
      university: '',
      department: '',
      profileImageUrl: '',
      clubName: '',
      clubDescription: '',
      clubCoverImageUrl: '',
      clubInstagramHandle: ''
    };
  }

  private emptyPasswordForm(): PasswordForm {
    return {
      currentPassword: '',
      newPassword: '',
      confirmPassword: ''
    };
  }

  private extractError(error: unknown, fallback: string): string {
    if (typeof error === 'object' && error !== null) {
      const maybeHttpError = error as { error?: unknown; message?: unknown };
      const body = maybeHttpError.error;

      if (typeof body === 'string') return body;
      if (typeof body === 'object' && body !== null) {
        const message = (body as { message?: unknown }).message;
        if (typeof message === 'string' && message.trim()) return message;
      }

      if (typeof maybeHttpError.message === 'string' && maybeHttpError.message.trim()) {
        return maybeHttpError.message;
      }
    }

    return fallback;
  }
}
