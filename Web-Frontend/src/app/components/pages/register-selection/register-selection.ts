import { Component } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-register-selection',
  standalone: true,
  imports: [RouterLink, CommonModule],
  templateUrl: './register-selection.html',
  styleUrl: './register-selection.css',
})
export class RegisterSelection {
  constructor(private router: Router) {}

  selectRole(role: string) {
    if (role === 'Öğrenci') {
      this.router.navigate(['register-student']);
    } else if (role === 'Kulüp') {
      this.router.navigate(['register-club']);
    }
  }
}
