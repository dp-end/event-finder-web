import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';
import { SidebarService } from '../../services/sidebar';
import { AuthService } from '../../services/auth';
import { NotificationService } from '../../services/notification.service';
import { AuthResponse } from '../../models/models';

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './sidebar.html',
  styleUrl: './sidebar.css'
})
export class SidebarComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  isOpen = false;
  user: AuthResponse | null = null;
  unreadCount = 0;

  get initials(): string {
    if (!this.user) return 'U';
    return ((this.user.firstName?.[0] ?? '') + (this.user.lastName?.[0] ?? '')).toUpperCase()
      || this.user.userName?.[0]?.toUpperCase()
      || 'U';
  }

  get fullName(): string {
    if (!this.user) return 'Misafir';
    return `${this.user.firstName ?? ''} ${this.user.lastName ?? ''}`.trim() || this.user.userName;
  }

  get isClubUser(): boolean {
    return this.authService.isClubUser();
  }

  constructor(
    private sidebarService: SidebarService,
    private authService: AuthService,
    private notificationService: NotificationService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.sidebarService.isSidebarOpen$.pipe(takeUntil(this.destroy$)).subscribe(open => {
      this.isOpen = open;
    });

    this.authService.user$.pipe(takeUntil(this.destroy$)).subscribe(user => {
      this.user = user;
      this.cdr.detectChanges();
      if (user) this.loadUnreadCount();
    });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private loadUnreadCount(): void {
    this.notificationService.getUnreadCount().pipe(takeUntil(this.destroy$)).subscribe({
      next: count => { this.unreadCount = count; this.cdr.detectChanges(); },
      error: () => {}
    });
  }

  closeMenu(): void {
    this.sidebarService.closeSidebar();
  }

  logout(): void {
    this.authService.logout();
    this.closeMenu();
    this.router.navigate(['/login']);
  }
}
