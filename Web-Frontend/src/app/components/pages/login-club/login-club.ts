import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'app-login-club',
  standalone: true,
  imports: [],
  template: '',
})
export class LoginClub implements OnInit {
  constructor(private router: Router) {}
  ngOnInit() {
    this.router.navigate(['/login'], { replaceUrl: true });
  }
}
