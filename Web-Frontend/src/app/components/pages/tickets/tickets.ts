import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';
import { TicketService } from '../../../services/ticket.service';
import { PreferencesService } from '../../../services/preferences.service';
import { TicketDto } from '../../../models/models';
import { environment } from '../../../../environments/environment';

@Component({
  selector: 'app-my-tickets',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './tickets.html',
  styleUrl: './tickets.css'
})
export class Tickets implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  tickets: TicketDto[] = [];
  selectedTicket: TicketDto | null = null;
  isLoading = true;
  isCancelling = false;
  cancelError: string | null = null;
  error: string | null = null;

  ngOnInit(): void {
    this.loadTickets();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  constructor(
    private ticketService: TicketService,
    private preferencesService: PreferencesService,
    private cdr: ChangeDetectorRef
  ) {}

  loadTickets(): void {
    this.isLoading = true;
    this.error = null;
    this.ticketService.getMyTickets().pipe(takeUntil(this.destroy$)).subscribe({
      next: tickets => {
        this.tickets = tickets;
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'Biletler yüklenemedi.';
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  openTicket(ticket: TicketDto): void {
    this.selectedTicket = ticket;
  }

  closeModal(): void {
    this.selectedTicket = null;
  }

  formatDate(dateStr: string): string {
    return new Date(dateStr).toLocaleString(this.preferencesService.locale, {
      day: 'numeric', month: 'long', year: 'numeric',
      hour: '2-digit', minute: '2-digit'
    });
  }

  resolveImageUrl(url?: string): string {
    if (!url) return '';
    return url.startsWith('/') ? `${environment.apiUrl}${url}` : url;
  }

  get activeTickets(): TicketDto[] {
    return this.tickets.filter(t => !t.isUsed);
  }

  get usedTickets(): TicketDto[] {
    return this.tickets.filter(t => t.isUsed);
  }

  cancelTicket(ticket: TicketDto): void {
    if (this.isCancelling) return;
    if (!confirm(`"${ticket.eventTitle}" etkinliği için aldığınız bileti iptal etmek istediğinize emin misiniz?`)) return;

    this.isCancelling = true;
    this.cancelError = null;
    this.ticketService.cancel(ticket.id).pipe(takeUntil(this.destroy$)).subscribe({
      next: () => {
        this.tickets = this.tickets.filter(t => t.id !== ticket.id);
        this.selectedTicket = null;
        this.isCancelling = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.cancelError = err?.error?.message ?? 'Bilet iptal edilemedi.';
        this.isCancelling = false;
        this.cdr.detectChanges();
      }
    });
  }
}
