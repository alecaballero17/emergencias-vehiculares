import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { WorkshopService } from '../../services/workshop.service';
import { Notification } from '../../models/interfaces';
import { Router } from '@angular/router';
import { ChangeDetectorRef } from '@angular/core';
import { WebSocketService } from '../../services/websocket.service';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-notifications',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './notifications.html',
  styleUrl: './notifications.scss'
})
export class NotificationsComponent implements OnInit, OnDestroy {
  notifications: Notification[] = [];
  loading = false;
  private idRegex = /#(\d+)/;
  private wsSubscription: Subscription | null = null;

  constructor(
    private ws: WorkshopService, 
    private router: Router,
    private cdr: ChangeDetectorRef,
    private wsService: WebSocketService
  ) {}

  ngOnInit(): void {
    this.loadNotifications();
    
    // Escuchar notificaciones en tiempo real para recargar la lista
    this.wsSubscription = this.wsService.messages$.subscribe(msg => {
      if (msg.type === 'notification') {
        console.log('[Notifications Component] Recibida notificación vía WebSocket. Recargando...');
        this.loadNotifications();
      }
    });
  }

  ngOnDestroy(): void {
    if (this.wsSubscription) {
      this.wsSubscription.unsubscribe();
    }
  }

  loadNotifications(): void {
    this.loading = true;
    this.ws.getNotifications().subscribe({
      next: (data) => { 
        this.notifications = data; 
        this.loading = false;
        this.cdr.detectChanges(); // Forzar actualización de la UI
      },
      error: () => { 
        this.loading = false;
        this.cdr.detectChanges();
      }
    });
  }

  markRead(n: Notification): void {
    if (n.is_read) {
      this.goToIncident(n);
      return;
    }
    this.ws.markNotificationRead(n.id).subscribe(() => {
      n.is_read = true;
      this.goToIncident(n);
    });
  }

  goToIncident(n: Notification): void {
    const match = n.message.match(this.idRegex);
    if (match && match[1]) {
      const incidentId = match[1];
      console.log('Navegando al incidente:', incidentId);
      this.router.navigate(['/incidents', incidentId]);
    }
  }
}
