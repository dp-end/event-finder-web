import { Routes } from '@angular/router';

// MEVCUT COMPONENTLER
import { Login } from './components/pages/login/login';
import { LoginClub } from './components/pages/login-club/login-club';
import { RegisterSelection } from './components/pages/register-selection/register-selection';
import { RegisterStudent } from './components/pages/register-student/register-student';
import { RegisterClub } from './components/pages/register-club/register-club';
import { Home } from './components/pages/home/home';
import { EventDetail } from './components/pages/event-detail/event-detail';

// YENİ EKLENEN SİDEBAR COMPONENTLERİ
import { Notifications } from './components/pages/notifications/notifications';
import { Tickets } from './components/pages/tickets/tickets';
import { Profile } from './components/pages/profile/profile';
import { Settings } from './components/pages/settings/settings';
import { CreateEvent } from './components/pages/create-event/create-event';
import { ClupDetails } from './components/pages/clup-details/clup-details';

export const routes: Routes = [
  // 1. UYGULAMA İLK AÇILDIĞINDA (Boş URL) -> Login'e yönlendir
  { path: '', redirectTo: 'login', pathMatch: 'full' },

  // 2. SAYFALARIMIZIN ROTALARI
  { path: 'login', component: Login },
  { path: 'login-club', component: LoginClub },
  { path: 'register', component: RegisterSelection },
  { path: 'register-student', component: RegisterStudent },
  { path: 'register-club', component: RegisterClub },
  { path: 'home', component: Home },
  { path: 'event/:id', component: EventDetail},

  // 3. YENİ SİDEBAR ROTALARI
  { path: 'notifications', component: Notifications },
  { path: 'tickets', component: Tickets },
  { path: 'profile', component: Profile },
  { path: 'settings', component: Settings },
  { path: 'create-event', component: CreateEvent },
  { path: 'club/:id', component: ClupDetails },

  // 4. YANLIŞ URL GİRİLİRSE (Catch-all) -> Güvenlik için Login'e atılır
  { path: '**', redirectTo: 'login' }
];
