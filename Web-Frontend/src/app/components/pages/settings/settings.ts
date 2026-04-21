import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-settings',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './settings.html',
  styleUrl: './settings.css'
})
export class Settings {

  // Ayar durumlarını tutan değişkenler
  isDarkMode: boolean = false;
  appLanguage: string = 'tr';
  pushNotifications: boolean = true;
  emailNotifications: boolean = false;

  // Tema değiştirme fonksiyonu (İleride buraya gerçek tema değiştirme kodları eklenebilir)
  toggleTheme() {
    this.isDarkMode = !this.isDarkMode;
    console.log('Karanlık tema durumu:', this.isDarkMode);
  }

  // Dil değiştirme fonksiyonu
  changeLanguage(event: any) {
    this.appLanguage = event.target.value;
    console.log('Seçilen dil:', this.appLanguage);
  }
}
