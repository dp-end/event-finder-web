import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { timeout } from 'rxjs/operators';
import { CommentDto, CreateCommentDto } from '../models/models';
import { environment } from '../../environments/environment';

const API_TIMEOUT = 10_000;

@Injectable({ providedIn: 'root' })
export class CommentService {
  private readonly apiUrl = `${environment.apiUrl}/api/Comments`;

  constructor(private http: HttpClient) {}

  getByEvent(eventId: string): Observable<CommentDto[]>   { return this.http.get<CommentDto[]>(`${this.apiUrl}/event/${eventId}`).pipe(timeout(API_TIMEOUT)); }
  create(dto: CreateCommentDto): Observable<CommentDto>    { return this.http.post<CommentDto>(this.apiUrl, dto).pipe(timeout(API_TIMEOUT)); }
  delete(id: string): Observable<void>                    { return this.http.delete<void>(`${this.apiUrl}/${id}`).pipe(timeout(API_TIMEOUT)); }
}
