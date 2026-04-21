import { Component } from '@angular/core';
import { RouterOutlet, Router, NavigationEnd } from '@angular/router';
import { SidebarComponent } from './components/sidebar/sidebar';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, SidebarComponent, CommonModule],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  showSidebar = false;

  // Sidebar gösterilmeyecek prefix'ler (auth sayfaları)
  private hiddenRoutes = [
    '/login',
    '/register',
    '/register-student',
    '/register-club',
  ];

  constructor(private router: Router) {
    this.router.events.subscribe(event => {
      if (event instanceof NavigationEnd) {
        const url = event.urlAfterRedirects || event.url;
        this.showSidebar = !this.hiddenRoutes.some(r => url.startsWith(r));
      }
    });
  }
}
