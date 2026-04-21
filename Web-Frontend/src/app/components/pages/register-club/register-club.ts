import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterModule, Router } from '@angular/router';
import { AuthService } from '../../../services/auth';

@Component({
  selector: 'app-register-club',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule, RouterModule],
  templateUrl: './register-club.html',
  styleUrl: './register-club.css',
})
export class RegisterClub {
  clubForm: FormGroup;
  showPassword = false;
  isSubmitting = false;
  errorMessage = '';
  successMessage = '';

  universities = [
    'Akdeniz Üniversitesi', 'İstanbul Teknik Üniversitesi',
    'ODTÜ', 'Boğaziçi Üniversitesi', 'Hacettepe Üniversitesi',
    'Ege Üniversitesi', 'Ankara Üniversitesi'
  ];

  constructor(
    private fb: FormBuilder,
    private router: Router,
    private authService: AuthService
  ) {
    this.clubForm = this.fb.group({
      clubName: ['', [Validators.required, Validators.minLength(3)]],
      clubEmail: ['', [Validators.required, Validators.email]],
      advisorName: ['', Validators.required],
      phoneNumber: ['', [Validators.required, Validators.pattern(/^[0-9]{10,11}$/)]],
      referenceNumber: ['', Validators.required],
      university: ['', Validators.required],
      password: ['', [
        Validators.required,
        Validators.minLength(8),
        Validators.pattern(/^(?=.*[A-Z])(?=.*[!@#$%^&*()_+{}\[\]:;<>,.?~\\/-]).+$/)
      ]]
    });
  }

  togglePassword(): void {
    this.showPassword = !this.showPassword;
  }

  onSubmit(): void {
    if (this.clubForm.invalid || this.isSubmitting) return;

    this.isSubmitting = true;
    this.errorMessage = '';
    this.successMessage = '';

    const v = this.clubForm.value;

    const payload = {
      firstName: v.clubName,
      lastName: '',
      email: v.clubEmail,
      userName: v.clubEmail.split('@')[0],
      password: v.password,
      confirmPassword: v.password,
      userType: 'club',
      clubName: v.clubName,
      advisorName: v.advisorName,
      phoneNumber: v.phoneNumber,
      referenceNumber: v.referenceNumber,
      university: v.university,
    };

    this.authService.register(payload).subscribe({
      next: () => {
        this.successMessage = 'Kulüp kaydınız başarıyla oluşturuldu! Giriş yapabilirsiniz.';
        this.isSubmitting = false;
        setTimeout(() => this.router.navigate(['/login-club']), 2000);
      },
      error: (err) => {
        this.errorMessage = err.error?.message || err.error?.Message || 'Kayıt sırasında bir hata oluştu.';
        this.isSubmitting = false;
      }
    });
  }

  goBack(): void {
    window.history.back();
  }
}
