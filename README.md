# 📍 EventFinder Web & API

Modern etkinlik yönetim sistemi. Bu proje, ölçeklenebilir bir backend mimarisi ve modern bir frontend arayüzünün nasıl birleştirileceğini gösteren uçtan uca bir çözümdür.

---

## 🏗️ Mimari Yapı (Backend)
Proje **Clean Architecture** prensipleri üzerine inşa edilmiştir:
- **Domain:** Entity'ler ve temel kurallar.
- **Application:** MediatR ile CQRS deseni, FluentValidation ve DTO'lar.
- **Infrastructure:** Entity Framework Core (MySQL/PostgreSQL), Identity ve JWT servisleri.
- **WebApi:** RESTful API endpoint'leri ve merkezi hata yönetimi (Middleware).

## 🧪 Test Stratejisi
- **Unit Tests:** İş mantığının (Business Logic) doğrulanması.
- **Infrastructure Tests:** Veritabanı ve dış servis entegrasyonlarının testi.
- *Test Coverage:* XUnit, Moq ve AutoFixture kullanılarak sağlanmıştır.

## ⚡ Teknolojiler
- **Backend:** .NET 8/9, Entity Framework Core, MediatR, Automapper.
- **Frontend:** Angular 19, Standalone Components, RxJS, Tailwind/CSS.
- **Database:** MySql (Pomelo).

---

## 🚀 Başlangıç
1. `Backend` klasörüne gidin ve `dotnet restore` yapın.
2. `appsettings.json` içindeki bağlantı dizesini güncelleyin.
3. `dotnet ef database update` komutuyla migration'ları uygulayın.
4. `Frontend` klasöründe `npm install` ve `ng serve` komutlarını çalıştırın.


---

## 📱 Ekosistem ve Mobil Entegrasyon

Bu proje, uçtan uca bir etkinlik yönetim ekosisteminin parçasıdır. Sistemle tam entegre çalışan, **Flutter** ile geliştirilmiş mobil uygulamaya aşağıdaki bağlantıdan ulaşabilirsiniz:

🔗 **[EventFinder Mobile App (Flutter)](https://github.com/dp-end/event-finder-mobile)**

---
