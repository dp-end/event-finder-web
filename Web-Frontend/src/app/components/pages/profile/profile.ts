import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { AuthService } from '../../../services/auth';
import { EventService } from '../../../services/event.service';
import { EventListDto, AuthResponse } from '../../../models/models';
import { EventCard } from '../../event-card/event-card';

@Component({
  selector: 'app-profile',
  standalone: true,
  imports: [CommonModule, RouterModule, EventCard],
  templateUrl: './profile.html',
  styleUrl: './profile.css'
})
export class Profile implements OnInit {
  user: AuthResponse | null = null;
  myEvents: EventListDto[] = [];
  isLoadingEvents = false;

  get initials(): string {
    if (!this.user) return '?';
    return ((this.user.firstName?.[0] ?? '') + (this.user.lastName?.[0] ?? '')).toUpperCase() || this.user.userName?.[0]?.toUpperCase() || '?';
  }

  get fullName(): string {
    if (!this.user) return '';
    return `${this.user.firstName ?? ''} ${this.user.lastName ?? ''}`.trim() || this.user.userName;
  }

  constructor(
    private authService: AuthService,
    private eventService: EventService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.user = this.authService.getCurrentUser();

    // Kulüp kullanıcısıysa kendi etkinliklerini yükle
    if (this.user && this.authService.isClubUser() && this.user.clubId) {
      this.isLoadingEvents = true;
      this.eventService.getByClub(this.user.clubId).subscribe({
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
    }
  }

  isClubUser(): boolean {
    return this.authService.isClubUser();
  }

  isAdmin(): boolean {
    return this.authService.isAdmin();
  }
}
