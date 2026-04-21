import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { timeout } from 'rxjs/operators';
import { EventDto, EventListDto, CreateEventDto } from '../models/models';
import { environment } from '../../environments/environment';

export interface EventFilterParams {
  query?: string;
  category?: string;
  freeOnly?: boolean;
  maxPrice?: number;
  timePeriod?: string;
  ownerId?: string;
}

const API_TIMEOUT = 10_000;

@Injectable({ providedIn: 'root' })
export class EventService {
  private readonly apiUrl = `${environment.apiUrl}/api/Events`;

  constructor(private http: HttpClient) {}

  getAll(filters?: EventFilterParams): Observable<EventListDto[]> {
    let params = new HttpParams();
    if (filters?.query)      params = params.set('query', filters.query);
    if (filters?.category)   params = params.set('category', filters.category);
    if (filters?.freeOnly)   params = params.set('freeOnly', 'true');
    if (filters?.maxPrice !== undefined) params = params.set('maxPrice', filters.maxPrice.toString());
    if (filters?.timePeriod) params = params.set('timePeriod', filters.timePeriod);
    if (filters?.ownerId)    params = params.set('ownerId', filters.ownerId);
    return this.http.get<EventListDto[]>(this.apiUrl, { params }).pipe(timeout(API_TIMEOUT));
  }

  uploadImage(file: File): Observable<{ imageUrl: string }> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.post<{ imageUrl: string }>(`${this.apiUrl}/upload-image`, formData).pipe(timeout(30_000));
  }

  getById(id: string): Observable<EventDto> {
    return this.http.get<EventDto>(`${this.apiUrl}/${id}`).pipe(timeout(API_TIMEOUT));
  }

  getByClub(clubId: string): Observable<EventListDto[]> {
    return this.http.get<EventListDto[]>(`${this.apiUrl}/club/${clubId}`).pipe(timeout(API_TIMEOUT));
  }

  create(dto: CreateEventDto | FormData): Observable<EventDto> {
    return this.http.post<EventDto>(this.apiUrl, dto).pipe(timeout(API_TIMEOUT));
  }

  update(id: string, dto: Partial<CreateEventDto>): Observable<EventDto> {
    return this.http.put<EventDto>(`${this.apiUrl}/${id}`, dto).pipe(timeout(API_TIMEOUT));
  }

  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`).pipe(timeout(API_TIMEOUT));
  }

  toggleLike(id: string): Observable<{ isLiked: boolean; likeCount: number }> {
    return this.http.post<{ isLiked: boolean; likeCount: number }>(`${this.apiUrl}/${id}/like`, {}).pipe(timeout(API_TIMEOUT));
  }
}
