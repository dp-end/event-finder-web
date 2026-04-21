import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule, Router } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';
import { EventService } from '../../../services/event.service';
import { CategoryService } from '../../../services/category.service';
import { AuthService } from '../../../services/auth';
import { CategoryDto } from '../../../models/models';

@Component({
  selector: 'app-create-event',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './create-event.html',
  styleUrl: './create-event.css'
})
export class CreateEvent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  categories: CategoryDto[] = [];
  isLoadingCategories = true;
  isSubmitting = false;
  isUploadingImage = false;
  successMessage: string | null = null;
  errorMessage: string | null = null;

  selectedFileName: string | null = null;
  imagePreviewUrl: string | null = null;
  selectedImageFile: File | null = null;

  form = {
    title: '',
    description: '',
    date: '',
    location: '',
    address: '',
    price: 0,
    quota: 0,
    imageUrl: '',
    categoryId: '',
  };

  constructor(
    private eventService: EventService,
    private categoryService: CategoryService,
    private authService: AuthService,
    private router: Router
  ) {}

  ngOnInit(): void {
    if (!this.authService.isLoggedIn()) {
      this.router.navigate(['/login']);
      return;
    }
    this.loadCategories();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private loadCategories(): void {
    this.categoryService.getAll().pipe(takeUntil(this.destroy$)).subscribe({
      next: cats => {
        this.categories = cats;
        this.isLoadingCategories = false;
      },
      error: () => { this.isLoadingCategories = false; }
    });
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (!input.files?.length) return;

    const file = input.files[0];
    this.selectedImageFile = file;
    this.selectedFileName = file.name;
    this.imagePreviewUrl = null;
    this.errorMessage = null;

    // Önizleme göster
    const reader = new FileReader();
    reader.onload = (e) => { this.imagePreviewUrl = e.target?.result as string; };
    reader.readAsDataURL(file);
  }

  onSubmit(): void {
    if (this.isSubmitting || this.isUploadingImage) return;
    this.successMessage = null;
    this.errorMessage = null;

    const payload = new FormData();
    payload.append('title', this.form.title.trim());
    payload.append('description', this.form.description.trim());
    payload.append('date', new Date(this.form.date).toISOString());
    payload.append('location', this.form.location.trim());
    payload.append('address', this.form.address.trim());
    payload.append('price', Number(this.form.price).toString());
    payload.append('quota', Number(this.form.quota).toString());

    if (this.selectedImageFile) {
      payload.append('imageFile', this.selectedImageFile);
    } else if (this.form.imageUrl.trim()) {
      payload.append('imageUrl', this.form.imageUrl.trim());
    }

    if (this.form.categoryId) payload.append('categoryId', this.form.categoryId);

    const user = this.authService.getCurrentUser();
    if (user?.clubId) payload.append('clubId', user.clubId);

    this.isSubmitting = true;
    this.eventService.create(payload).pipe(takeUntil(this.destroy$)).subscribe({
      next: event => {
        this.successMessage = 'Etkinlik başarıyla oluşturuldu!';
        this.isSubmitting = false;
        setTimeout(() => this.router.navigate(['/event', event.id]), 1500);
      },
      error: err => {
        this.errorMessage = err.error?.message || err.error?.Message || 'Etkinlik oluşturulurken bir hata oluştu.';
        this.isSubmitting = false;
      }
    });
  }
}
