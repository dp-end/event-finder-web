import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, tap, timeout } from 'rxjs';
import { AuthResponse, LoginRequest, RegisterStudentRequest, RegisterClubRequest } from '../models/models';
import { environment } from '../../environments/environment';

const API_TIMEOUT = 10_000;

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly apiUrl = `${environment.apiUrl}/api/Account`;

  private tokenSubject = new BehaviorSubject<string | null>(localStorage.getItem('token'));
  private userSubject  = new BehaviorSubject<AuthResponse | null>(this.loadUser());

  token$ = this.tokenSubject.asObservable();
  user$  = this.userSubject.asObservable();

  constructor(private http: HttpClient) {}

  login(credentials: LoginRequest, loginType: 'student' | 'club' = 'student'): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.apiUrl}/authenticate`, { ...credentials, loginType }).pipe(
      timeout(API_TIMEOUT),
      tap(response => this.storeSession(response))
    );
  }

  loginClub(credentials: LoginRequest): Observable<AuthResponse> {
    return this.login(credentials, 'club');
  }

  register(userData: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/register`, userData, { responseType: 'text' }).pipe(
      timeout(API_TIMEOUT)
    );
  }

  registerStudent(data: RegisterStudentRequest): Observable<string> {
    return this.http.post(`${this.apiUrl}/register`, data, { responseType: 'text' }).pipe(
      timeout(API_TIMEOUT)
    );
  }

  registerClub(data: RegisterClubRequest): Observable<string> {
    return this.http.post(`${this.apiUrl}/register`, data, { responseType: 'text' }).pipe(
      timeout(API_TIMEOUT)
    );
  }

  forgotPassword(email: string): Observable<string> {
    return this.http.post(`${this.apiUrl}/forgot-password`, { email }, { responseType: 'text' }).pipe(
      timeout(API_TIMEOUT)
    );
  }

  logout(): void {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    localStorage.removeItem('userName');
    this.tokenSubject.next(null);
    this.userSubject.next(null);
  }

  getToken(): string | null   { return this.tokenSubject.value; }
  getCurrentUser(): AuthResponse | null { return this.userSubject.value; }
  getCurrentUserName(): string | null   { return this.getCurrentUser()?.userName ?? localStorage.getItem('userName') ?? null; }
  isLoggedIn(): boolean  { return !!this.getToken(); }
  isClubUser(): boolean  { const u = this.getCurrentUser(); return u?.userType === 'club' || u?.roles?.includes('Club') === true; }
  isAdmin(): boolean     { const u = this.getCurrentUser(); return u?.roles?.includes('SuperAdmin') === true || u?.roles?.includes('Admin') === true; }

  // Eski uyumluluk
  setToken(token: string): void    { localStorage.setItem('token', token); this.tokenSubject.next(token); }
  setUserName(name: string | null): void { name ? localStorage.setItem('userName', name) : localStorage.removeItem('userName'); }
  get userName$() { return new BehaviorSubject<string | null>(this.getCurrentUser()?.userName ?? null).asObservable(); }

  private storeSession(response: AuthResponse): void {
    localStorage.setItem('token', response.jwToken);
    localStorage.setItem('user', JSON.stringify(response));
    localStorage.setItem('userName', response.userName);
    this.tokenSubject.next(response.jwToken);
    this.userSubject.next(response);
  }

  private loadUser(): AuthResponse | null {
    const stored = localStorage.getItem('user');
    if (!stored) return null;
    try { return JSON.parse(stored) as AuthResponse; } catch { return null; }
  }
}
