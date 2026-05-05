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
    this.isSubmitting = true;

    if (this.selectedImageFile) {
      // Önce resmi yükle, sonra etkinliği oluştur
      this.isUploadingImage = true;
      this.eventService.uploadImage(this.selectedImageFile).pipe(takeUntil(this.destroy$)).subscribe({
        next: res => {
          this.isUploadingImage = false;
          this.form.imageUrl = res.imageUrl;
          this.submitJson();
        },
        error: () => {
          this.isUploadingImage = false;
          this.isSubmitting = false;
          this.errorMessage = 'Resim yüklenemedi. Lütfen tekrar deneyin.';
        }
      });
    } else {
      this.submitJson();
    }
  }

  private submitJson(): void {
    const user = this.authService.getCurrentUser();

    const dto = {
      title:       this.form.title.trim(),
      description: this.form.description.trim(),
      date:        new Date(this.form.date).toISOString(),
      location:    this.form.location.trim(),
      address:     this.form.address.trim(),
      price:       Number(this.form.price),
      quota:       Number(this.form.quota),
      imageUrl:    this.form.imageUrl.trim(),
      categoryId:  this.form.categoryId || undefined,
      clubId:      user?.clubId || undefined,
    };

    this.eventService.create(dto).pipe(takeUntil(this.destroy$)).subscribe({
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
