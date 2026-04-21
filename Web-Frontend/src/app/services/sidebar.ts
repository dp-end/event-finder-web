import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class SidebarService {
  // Menünün açık/kapalı durumunu hafızasında tutan değişken (Başlangıçta false yani kapalı)
  private isSidebarOpen = new BehaviorSubject<boolean>(false);

  // Diğer sayfaların bu durumu dinleyebilmesi için dışa açıyoruz
  isSidebarOpen$ = this.isSidebarOpen.asObservable();

  // Tıklandığında durumu tersine çeviren fonksiyon (Açıksa kapat, kapalıysa aç)
  toggleSidebar() {
    this.isSidebarOpen.next(!this.isSidebarOpen.value);
  }

  // Sadece kapatmak için (Linke tıklayınca veya dışarı tıklayınca kullanılır)
  closeSidebar() {
    this.isSidebarOpen.next(false);
  }
}
