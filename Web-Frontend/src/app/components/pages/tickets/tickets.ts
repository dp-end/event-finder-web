import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';
import { TicketService } from '../../../services/ticket.service';
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
  error: string | null = null;

  ngOnInit(): void {
    this.loadTickets();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  constructor(private ticketService: TicketService, private cdr: ChangeDetectorRef) {}

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
    return new Date(dateStr).toLocaleString('tr-TR', {
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
}
