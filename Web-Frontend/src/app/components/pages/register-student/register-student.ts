import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators, AbstractControl } from '@angular/forms';
import { RouterModule, Router } from '@angular/router';
import { AuthService } from '../../../services/auth';

@Component({
  selector: 'app-register-student',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule, RouterModule],
  templateUrl: './register-student.html',
  styleUrl: './register-student.css',
})
export class RegisterStudent {
  studentForm: FormGroup;
  errorMessage = '';
  successMessage = '';
  isLoading = false;
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
    this.studentForm = this.fb.group(
      {
        firstName:       ['', Validators.required],
        lastName:        ['', Validators.required],
        userName:        ['', [Validators.required, Validators.minLength(3)]],
        email:           ['', [Validators.required, Validators.email]],
        university:      [''],
        department:      [''],
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

  onSubmit() {
    this.errorMessage  = '';
    this.successMessage = '';

    if (this.studentForm.invalid) {
      this.studentForm.markAllAsTouched();
      return;
    }

    this.isLoading = true;
    const v = this.studentForm.value;

    const payload = {
      firstName:       v.firstName,
      lastName:        v.lastName,
      email:           v.email,
      userName:        v.userName,
      password:        v.password,
      confirmPassword: v.confirmPassword,
      userType:        'student',
      university:      v.university || '',
      department:      v.department || '',
    };

    this.authService.register(payload).subscribe({
      next: () => {
        this.isLoading = false;
        this.successMessage = 'Kayıt başarılı! Giriş sayfasına yönlendiriliyorsunuz...';
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

  goBack() { window.history.back(); }
}
