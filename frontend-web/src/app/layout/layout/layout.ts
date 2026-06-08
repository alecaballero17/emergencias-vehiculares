import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { WorkshopService } from '../../services/workshop.service';
import { Workshop } from '../../models/interfaces';
import { WebSocketService } from '../../services/websocket.service';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-layout',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './layout.html',
  styleUrl: './layout.scss'
})
export class LayoutComponent implements OnInit, OnDestroy {
  workshop: Workshop | null = null;
  sidebarOpen = true;
  unreadCount = 0;
  isAdmin = false;
  menuItems: any[] = [];
  wsConnected = false;
  private wsSubscription: Subscription | null = null;
  private statusSubscription: Subscription | null = null;

  constructor(
    private auth: AuthService, 
    private ws: WorkshopService,
    private wsService: WebSocketService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    const role = localStorage.getItem('role');
    this.isAdmin = role === 'admin';

    this.menuItems = [
      { icon: '📊', label: 'Dashboard', route: '/dashboard' },
    ];

    if (this.isAdmin) {
      this.menuItems.push(
        { icon: '🏢', label: 'Tenants', route: '/tenants' },
        { icon: '🆘', label: 'Disponibles', route: '/available' },
        { icon: '📋', label: 'Mis Incidentes', route: '/incidents' },
        { icon: '📈', label: 'Analíticas', route: '/analytics' },
        { icon: '👨‍🔧', label: 'Técnicos', route: '/technicians' },
        { icon: '🔔', label: 'Notificaciones', route: '/notifications' },
        { icon: '💰', label: 'Finanzas', route: '/finance' },
        { icon: '💾', label: 'Base de Datos', route: '/backup' },
        { icon: '🗣️', label: 'Asistente de Voz', route: '/voice-assistant' }
      );
    } else {
      this.menuItems.push(
        { icon: '🆘', label: 'Disponibles', route: '/available' },
        { icon: '📋', label: 'Mis Incidentes', route: '/incidents' },
        { icon: '📈', label: 'Analíticas', route: '/analytics' },
        { icon: '👨‍🔧', label: 'Técnicos', route: '/technicians' },
        { icon: '🔔', label: 'Notificaciones', route: '/notifications' },
        { icon: '💰', label: 'Finanzas', route: '/finance' },
        { icon: '🗣️', label: 'Asistente de Voz', route: '/voice-assistant' }
      );
    }
    this.menuItems.push({ icon: '⚙️', label: 'Perfil', route: '/profile' });

    this.ws.getProfile().subscribe({
      next: w => this.workshop = w,
      error: () => this.workshop = null
    });
    this.ws.getNotifications(true).subscribe({
      next: n => this.unreadCount = n.length,
      error: () => this.unreadCount = 0
    });

    // Conectar WebSocket y configurar notificaciones en tiempo real
    this.wsService.connect();

    this.statusSubscription = this.wsService.status$.subscribe(status => {
      console.log('[Layout] WS connection status changed:', status);
      this.wsConnected = status;
      this.cdr.detectChanges();
    });

    if ('Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission();
    }

    this.wsSubscription = this.wsService.messages$.subscribe(msg => {
      console.log('[Layout WS] Message received:', msg);
      if (msg.type === 'new_incident_alert') {
        this.unreadCount++;
        this.showDesktopNotification(
          '🚨 Nueva Emergencia SOS',
          `Tipo: ${this.getTypeLabel(msg.incident_type)}. Dirección: ${msg.address || 'No especificada'}.`
        );
      } else if (msg.type === 'notification') {
        this.showDesktopNotification(
          msg.title || 'Nueva Notificación',
          msg.message || ''
        );
        // Recargar el conteo de notificaciones no leídas
        this.ws.getNotifications(true).subscribe({
          next: n => this.unreadCount = n.length
        });
      }
    });
  }

  ngOnDestroy(): void {
    if (this.wsSubscription) {
      this.wsSubscription.unsubscribe();
    }
    if (this.statusSubscription) {
      this.statusSubscription.unsubscribe();
    }
    this.wsService.disconnect();
  }

  showDesktopNotification(title: string, body: string): void {
    if ('Notification' in window && Notification.permission === 'granted') {
      try {
        new Notification(title, {
          body: body,
          icon: '/favicon.ico'
        });
      } catch (err) {
        console.error('Error creating Notification:', err);
      }
    }
  }

  getTypeLabel(type: string): string {
    const map: Record<string, string> = {
      battery: 'Batería', tire: 'Llanta', crash: 'Accidente',
      engine: 'Motor', keys_lost: 'Llave perdida', keys_locked: 'Llave en vehículo',
      overheating: 'Sobrecalentamiento', other: 'Otro'
    };
    return map[type] || type;
  }

  logout(): void {
    this.auth.logout();
  }

  toggleSidebar(): void {
    this.sidebarOpen = !this.sidebarOpen;
  }
}
