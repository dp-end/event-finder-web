import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map, timeout } from 'rxjs/operators';
import { NotificationDto } from '../models/models';
import { environment } from '../../environments/environment';

const API_TIMEOUT = 10_000;

@Injectable({ providedIn: 'root' })
export class NotificationService {
  private readonly apiUrl = `${environment.apiUrl}/api/Notifications`;

  constructor(private http: HttpClient) {}

  getAll(): Observable<NotificationDto[]> { return this.http.get<NotificationDto[]>(this.apiUrl).pipe(timeout(API_TIMEOUT)); }
  getUnreadCount(): Observable<number>    {
    return this.http.get<{ unreadCount: number }>(`${this.apiUrl}/unread-count`).pipe(
      timeout(API_TIMEOUT),
      map(res => res.unreadCount)
    );
  }
  markAsRead(id: string): Observable<void>{ return this.http.put<void>(`${this.apiUrl}/${id}/read`, {}).pipe(timeout(API_TIMEOUT)); }
  markAllAsRead(): Observable<void>       { return this.http.put<void>(`${this.apiUrl}/read-all`, {}).pipe(timeout(API_TIMEOUT)); }
}
