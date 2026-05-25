import { Routes } from '@angular/router';
import { authGuard } from './guards/auth.guard';
import { LayoutComponent } from './layout/layout/layout';

export const routes: Routes = [
  { path: 'login', loadComponent: () => import('./pages/login/login').then(m => m.LoginComponent) },
  { path: 'register', loadComponent: () => import('./pages/register/register').then(m => m.RegisterComponent) },
  {
    path: '',
    component: LayoutComponent,
    canActivate: [authGuard],
    children: [
      { path: 'dashboard', loadComponent: () => import('./pages/dashboard/dashboard').then(m => m.DashboardComponent) },
      { path: 'available', loadComponent: () => import('./pages/available/available').then(m => m.AvailableComponent) },
      { path: 'incidents', loadComponent: () => import('./pages/incidents/incidents').then(m => m.IncidentsComponent) },
      { path: 'incidents/:id', loadComponent: () => import('./pages/incident-detail/incident-detail').then(m => m.IncidentDetailComponent) },
      { path: 'technicians', loadComponent: () => import('./pages/technicians/technicians').then(m => m.TechniciansComponent) },
      { path: 'notifications', loadComponent: () => import('./pages/notifications/notifications').then(m => m.NotificationsComponent) },
      { path: 'profile', loadComponent: () => import('./pages/profile/profile').then(m => m.ProfileComponent) },
      { path: 'vehicles', loadComponent: () => import('./pages/vehicles/vehicles').then(m => m.VehiclesComponent) },
      { path: 'finance', loadComponent: () => import('./pages/finance/finance').then(m => m.FinanceComponent) },
      { path: 'analytics', loadComponent: () => import('./pages/analytics/analytics').then(m => m.AnalyticsComponent) },
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' }
    ]
  },
  { path: '**', redirectTo: 'login' }
];
