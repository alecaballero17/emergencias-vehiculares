import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { WorkshopService } from '../../services/workshop.service';
import { Workshop } from '../../models/interfaces';

@Component({
  selector: 'app-layout',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './layout.html',
  styleUrl: './layout.scss'
})
export class LayoutComponent implements OnInit {
  workshop: Workshop | null = null;
  sidebarOpen = true;
  unreadCount = 0;

  menuItems = [
    { icon: '📊', label: 'Dashboard', route: '/dashboard' },
    { icon: '🆘', label: 'Disponibles', route: '/available' },
    { icon: '📋', label: 'Mis Incidentes', route: '/incidents' },
    { icon: '👨‍🔧', label: 'Técnicos', route: '/technicians' },
    { icon: '🔔', label: 'Notificaciones', route: '/notifications' },
    { icon: '⚙️', label: 'Perfil', route: '/profile' },
  ];

  constructor(private auth: AuthService, private ws: WorkshopService) {}

  ngOnInit(): void {
    this.ws.getProfile().subscribe(w => this.workshop = w);
    this.ws.getNotifications(true).subscribe(n => this.unreadCount = n.length);
  }

  logout(): void {
    this.auth.logout();
  }

  toggleSidebar(): void {
    this.sidebarOpen = !this.sidebarOpen;
  }
}
