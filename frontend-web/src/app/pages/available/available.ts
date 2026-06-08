import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { WorkshopService } from '../../services/workshop.service';
import { Incident } from '../../models/interfaces';
import { WebSocketService } from '../../services/websocket.service';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-available',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './available.html',
  styleUrl: './available.scss'
})
export class AvailableComponent implements OnInit, OnDestroy {
  incidents: Incident[] = [];
  loading = true;
  private pollingInterval: any;
  private wsSubscription: Subscription | null = null;

  constructor(
    private ws: WorkshopService, 
    private cd: ChangeDetectorRef,
    private wsService: WebSocketService
  ) {}

  ngOnInit(): void {
    this.loadIncidents();
    this.pollingInterval = setInterval(() => {
      this.refreshIncidentsSilently();
    }, 5000);

    // Escuchar alertas de nuevos incidentes para recargar al instante
    this.wsSubscription = this.wsService.messages$.subscribe(msg => {
      if (msg.type === 'new_incident_alert') {
        console.log('[Available SOS] Recibida nueva emergencia via WebSocket. Refrescando...');
        this.refreshIncidentsSilently();
      }
    });
  }

  ngOnDestroy(): void {
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval);
    }
    if (this.wsSubscription) {
      this.wsSubscription.unsubscribe();
    }
  }

  loadIncidents(): void {
    this.loading = true;
    this.ws.getAvailableIncidents().subscribe({
      next: (data) => { 
        this.incidents = data || []; 
        this.loading = false; 
        this.cd.detectChanges();
      },
      error: () => { 
        this.incidents = [];
        this.loading = false; 
        this.cd.detectChanges();
      }
    });
  }

  refreshIncidentsSilently(): void {
    this.ws.getAvailableIncidents().subscribe({
      next: (data) => { 
        this.incidents = data || []; 
        this.cd.detectChanges();
      }
    });
  }

  getCriticalCount(): number {
    return this.incidents.filter(i => i.priority === 'critical').length;
  }

  getHighCount(): number {
    return this.incidents.filter(i => i.priority === 'high').length;
  }

  getTypeLabel(type: string): string {
    const map: Record<string, string> = {
      battery: '🔋 Batería', tire: '🛞 Llanta', crash: '💥 Accidente',
      engine: '🔧 Motor', keys_lost: '🔑 Llave perdida', keys_locked: '🔐 Llave en vehículo',
      overheating: '🌡️ Sobrecalentamiento', other: '❓ Otro'
    };
    return map[type] || type;
  }

  getPriorityLabel(p: string): string {
    const map: Record<string, string> = {
      critical: 'CRÍTICO', high: 'ALTA', medium: 'MEDIA', low: 'BAJA'
    };
    return map[p] || p.toUpperCase();
  }

  getPriorityIcon(p: string): string {
    const map: Record<string, string> = {
      critical: '🚨', high: '⚠️', medium: '🔶', low: '🟢'
    };
    return map[p] || '🔶';
  }

  getPriorityClass(p: string): string {
    return `priority-${p}`;
  }

  timeAgo(date: string): string {
    const diff = Date.now() - new Date(date).getTime();
    const min = Math.floor(diff / 60000);
    if (min < 1) return 'Ahora';
    if (min < 60) return `hace ${min} min`;
    const hrs = Math.floor(min / 60);
    if (hrs < 24) return `hace ${hrs}h`;
    return `hace ${Math.floor(hrs / 24)}d`;
  }
}
