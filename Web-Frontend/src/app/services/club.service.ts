import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { timeout } from 'rxjs/operators';
import { ClubDto, ClubListDto, CreateClubDto } from '../models/models';
import { environment } from '../../environments/environment';

const API_TIMEOUT = 10_000;

@Injectable({ providedIn: 'root' })
export class ClubService {
  private readonly apiUrl = `${environment.apiUrl}/api/Clubs`;

  constructor(private http: HttpClient) {}

  getAll(): Observable<ClubListDto[]>             { return this.http.get<ClubListDto[]>(this.apiUrl).pipe(timeout(API_TIMEOUT)); }
  getPopular(count = 5): Observable<ClubListDto[]>{ return this.http.get<ClubListDto[]>(`${this.apiUrl}/popular?count=${count}`).pipe(timeout(API_TIMEOUT)); }
  getById(id: string): Observable<ClubDto>        { return this.http.get<ClubDto>(`${this.apiUrl}/${id}`).pipe(timeout(API_TIMEOUT)); }
  create(dto: CreateClubDto): Observable<ClubDto> { return this.http.post<ClubDto>(this.apiUrl, dto).pipe(timeout(API_TIMEOUT)); }
  update(id: string, dto: Partial<CreateClubDto>): Observable<ClubDto> { return this.http.put<ClubDto>(`${this.apiUrl}/${id}`, dto).pipe(timeout(API_TIMEOUT)); }
  delete(id: string): Observable<void>            { return this.http.delete<void>(`${this.apiUrl}/${id}`).pipe(timeout(API_TIMEOUT)); }

  toggleFollow(id: string): Observable<{ isFollowing: boolean; followerCount: number }> {
    return this.http.post<{ isFollowing: boolean; followerCount: number }>(`${this.apiUrl}/${id}/follow`, {}).pipe(timeout(API_TIMEOUT));
  }
}
