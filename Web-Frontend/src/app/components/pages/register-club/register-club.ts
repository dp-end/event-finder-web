import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators, AbstractControl } from '@angular/forms';
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
  isLoading = false;
  errorMessage = '';
  successMessage = '';
  showPassword = false;
  showConfirm = false;

  universities = [
    'Akdeniz Üniversitesi',
    'İstanbul Teknik Üniversitesi',
    'ODTÜ',
    'Boğaziçi Üniversitesi',
    'Hacettepe Üniversitesi',
    'Ege Üniversitesi',
    'Ankara Üniversitesi',
    'Diğer',
  ];

  constructor(
    private fb: FormBuilder,
    private router: Router,
    private authService: AuthService
  ) {
    this.clubForm = this.fb.group(
      {
        clubName:        ['', [Validators.required, Validators.minLength(2)]],
        userName:        ['', [Validators.required, Validators.minLength(3)]],
        clubEmail:       ['', [Validators.required, Validators.email]],
        advisorName:     [''],
        phoneNumber:     [''],
        referenceNumber: [''],
        university:      [''],
        password:        ['', [Validators.required, Validators.minLength(6)]],
        confirmPassword: ['', Validators.required],
      },
      { validators: this.passwordMatchValidator }
    );
  }

  passwordMatchValidator(control: AbstractControl) {
    const pw = control.get('password')?.value;
    const cp = control.get('confirmPassword')?.value;
    if (pw !== cp) {
      control.get('confirmPassword')?.setErrors({ mismatch: true });
      return { mismatch: true };
    }
    return null;
  }

  togglePassword() { this.showPassword = !this.showPassword; }
  toggleConfirm()  { this.showConfirm  = !this.showConfirm;  }

  onSubmit(): void {
    if (this.clubForm.invalid || this.isLoading) return;

    this.isLoading = true;
    this.errorMessage = '';
    this.successMessage = '';

    const v = this.clubForm.value;

    const payload = {
      firstName:       v.clubName,
      lastName:        '',
      email:           v.clubEmail,
      userName:        v.userName,
      password:        v.password,
      confirmPassword: v.confirmPassword,
      userType:        'club',
      clubName:        v.clubName,
      advisorName:     v.advisorName  || '',
      phoneNumber:     v.phoneNumber  || '',
      referenceNumber: v.referenceNumber || '',
      university:      v.university   || '',
    };

    this.authService.register(payload).subscribe({
      next: () => {
        this.isLoading = false;
        this.successMessage = 'Kulüp kaydı başarılı! Giriş yapabilirsiniz.';
        setTimeout(() => this.router.navigate(['/login']), 2000);
      },
      error: (err) => {
        this.isLoading = false;
        let msg = 'Kayıt sırasında bir hata oluştu.';
        if (typeof err.error === 'string' && err.error.length > 0) {
          try { msg = JSON.parse(err.error)?.Message || err.error; } catch { msg = err.error; }
        } else if (err.error?.message) {
          msg = err.error.message;
        } else if (err.error?.Message) {
          msg = err.error.Message;
        } else if (err.error?.errors) {
          msg = Object.values(err.error.errors).flat().join(' ');
        }
        this.errorMessage = msg;
      }
    });
  }

  goBack(): void { window.history.back(); }
}
