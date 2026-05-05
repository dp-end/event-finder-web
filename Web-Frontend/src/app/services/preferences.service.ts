import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

export type AppLanguage = 'tr' | 'en';
export type ProfileVisibility = 'public' | 'members' | 'private';

export interface PrivacyPreferences {
  profileVisibility: ProfileVisibility;
  showEmail: boolean;
  showUniversity: boolean;
  showDepartment: boolean;
}

const DARK_MODE_KEY = 'eventFinder.darkMode';
const LANGUAGE_KEY = 'eventFinder.language';
const PRIVACY_KEY = 'eventFinder.privacy';

const DEFAULT_PRIVACY: PrivacyPreferences = {
  profileVisibility: 'public',
  showEmail: true,
  showUniversity: true,
  showDepartment: true
};

@Injectable({ providedIn: 'root' })
export class PreferencesService {
  private darkModeSubject = new BehaviorSubject<boolean>(this.readDarkMode());
  private languageSubject = new BehaviorSubject<AppLanguage>(this.readLanguage());
  private privacySubject = new BehaviorSubject<PrivacyPreferences>(this.readPrivacy());

  darkMode$ = this.darkModeSubject.asObservable();
  language$ = this.languageSubject.asObservable();
  privacy$ = this.privacySubject.asObservable();

  constructor() {
    this.applyTheme(this.darkModeSubject.value);
    this.applyLanguage(this.languageSubject.value);
  }

  get isDarkMode(): boolean {
    return this.darkModeSubject.value;
  }

  get language(): AppLanguage {
    return this.languageSubject.value;
  }

  get locale(): string {
    return this.language === 'en' ? 'en-US' : 'tr-TR';
  }

  get privacy(): PrivacyPreferences {
    return { ...this.privacySubject.value };
  }

  setDarkMode(enabled: boolean): void {
    this.writeStorage(DARK_MODE_KEY, enabled ? 'true' : 'false');
    this.darkModeSubject.next(enabled);
    this.applyTheme(enabled);
  }

  setLanguage(language: AppLanguage): void {
    this.writeStorage(LANGUAGE_KEY, language);
    this.languageSubject.next(language);
    this.applyLanguage(language);
  }

  setPrivacy(preferences: PrivacyPreferences): void {
    const next = { ...DEFAULT_PRIVACY, ...preferences };
    this.writeStorage(PRIVACY_KEY, JSON.stringify(next));
    this.privacySubject.next(next);
  }

  private readDarkMode(): boolean {
    return this.readStorage(DARK_MODE_KEY) === 'true';
  }

  private readLanguage(): AppLanguage {
    return this.readStorage(LANGUAGE_KEY) === 'en' ? 'en' : 'tr';
  }

  private readPrivacy(): PrivacyPreferences {
    const stored = this.readStorage(PRIVACY_KEY);
    if (!stored) return { ...DEFAULT_PRIVACY };

    try {
      const parsed = JSON.parse(stored) as Partial<PrivacyPreferences>;
      const profileVisibility = parsed.profileVisibility === 'members' || parsed.profileVisibility === 'private'
        ? parsed.profileVisibility
        : 'public';

      return {
        profileVisibility,
        showEmail: parsed.showEmail ?? DEFAULT_PRIVACY.showEmail,
        showUniversity: parsed.showUniversity ?? DEFAULT_PRIVACY.showUniversity,
        showDepartment: parsed.showDepartment ?? DEFAULT_PRIVACY.showDepartment
      };
    } catch {
      return { ...DEFAULT_PRIVACY };
    }
  }

  private applyTheme(enabled: boolean): void {
    if (typeof document === 'undefined') return;
    document.body.classList.toggle('dark-theme', enabled);
    document.documentElement.setAttribute('data-theme', enabled ? 'dark' : 'light');
  }

  private applyLanguage(language: AppLanguage): void {
    if (typeof document === 'undefined') return;
    document.documentElement.lang = language;
  }

  private readStorage(key: string): string | null {
    if (typeof localStorage === 'undefined') return null;
    try { return localStorage.getItem(key); } catch { return null; }
  }

  private writeStorage(key: string, value: string): void {
    if (typeof localStorage === 'undefined') return;
    try { localStorage.setItem(key, value); } catch {}
  }
}
