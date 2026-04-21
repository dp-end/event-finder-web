import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { timeout } from 'rxjs/operators';
import { CategoryDto } from '../models/models';
import { environment } from '../../environments/environment';

const API_TIMEOUT = 10_000;

@Injectable({ providedIn: 'root' })
export class CategoryService {
  private readonly apiUrl = `${environment.apiUrl}/api/Categories`;

  constructor(private http: HttpClient) {}

  getAll(): Observable<CategoryDto[]>          { return this.http.get<CategoryDto[]>(this.apiUrl).pipe(timeout(API_TIMEOUT)); }
  getById(id: string): Observable<CategoryDto> { return this.http.get<CategoryDto>(`${this.apiUrl}/${id}`).pipe(timeout(API_TIMEOUT)); }
}
