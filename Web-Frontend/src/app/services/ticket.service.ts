import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { timeout } from 'rxjs/operators';
import { TicketDto, PurchaseTicketDto, TicketCheckDto } from '../models/models';
import { environment } from '../../environments/environment';

const API_TIMEOUT = 10_000;

@Injectable({ providedIn: 'root' })
export class TicketService {
  private readonly apiUrl = `${environment.apiUrl}/api/Tickets`;

  constructor(private http: HttpClient) {}

  getMyTickets(): Observable<TicketDto[]>               { return this.http.get<TicketDto[]>(`${this.apiUrl}/my-tickets`).pipe(timeout(API_TIMEOUT)); }
  getById(id: string): Observable<TicketDto>            { return this.http.get<TicketDto>(`${this.apiUrl}/${id}`).pipe(timeout(API_TIMEOUT)); }
  purchase(dto: PurchaseTicketDto): Observable<TicketDto>{ return this.http.post<TicketDto>(`${this.apiUrl}/purchase`, dto).pipe(timeout(API_TIMEOUT)); }
  checkTicket(eventId: string): Observable<TicketCheckDto>{ return this.http.get<TicketCheckDto>(`${this.apiUrl}/check/${eventId}`).pipe(timeout(API_TIMEOUT)); }
  markAsUsed(id: string): Observable<void>              { return this.http.post<void>(`${this.apiUrl}/${id}/use`, {}).pipe(timeout(API_TIMEOUT)); }
}
