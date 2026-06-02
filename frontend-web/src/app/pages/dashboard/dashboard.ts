import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { WorkshopService } from '../../services/workshop.service';
import { Incident } from '../../models/interfaces';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.scss'
})
export class DashboardComponent implements OnInit {
  availableCount = 0;
  activeCount = 0;
  completedCount = 0;
  recentIncidents: Incident[] = [];
  loading = false;

  constructor(private ws: WorkshopService, private cd: ChangeDetectorRef) {}

  ngOnInit(): void {
    // Safety timeout: force loading off after 3 seconds no matter what
    setTimeout(() => {
      if (this.loading) {
        this.loading = false;
        this.cd.detectChanges();
      }
    }, 4000);

    this.ws.getAvailableIncidents().subscribe({
      next: (i) => {
        this.availableCount = (i || []).length;
        this.cd.detectChanges();
      },
      error: () => {}
    });

    this.ws.getAssignedIncidents().subscribe({
      next: (incidents) => {
        const safeInc = incidents || [];
        this.recentIncidents = safeInc.slice(0, 5);
        this.activeCount = safeInc.filter(i => i.status === 'taller_asignado' || i.status === 'en_camino' || i.status === 'en_atencion').length;
        this.completedCount = safeInc.filter(i => i.status === 'finalizado').length;
        this.loading = false;
        this.cd.detectChanges();
      },
      error: () => {
        this.loading = false;
        this.cd.detectChanges();
      }
    });
  }

  getPriorityClass(priority: string): string {
    const map: Record<string, string> = {
      critical: 'priority-critical',
      high: 'priority-high',
      medium: 'priority-medium',
      low: 'priority-low'
    };
    return map[priority] || '';
  }

  getPriorityLabel(p: string): string {
    const map: Record<string, string> = {
      low: 'BAJA', medium: 'MEDIA', high: 'ALTA', critical: 'CRÍTICA'
    };
    return map[p] || p;
  }

  getStatusLabel(status: string): string {
    const map: Record<string, string> = {
      pendiente: 'Pendiente',
      buscando_taller: 'Buscando Cotizaciones',
      taller_asignado: 'Taller Asignado',
      en_camino: 'En Camino',
      en_atencion: 'En Atención',
      finalizado: 'Completado',
      cancelado: 'Cancelado'
    };
    return map[status] || status;
  }

  getTypeLabel(type: string): string {
    const map: Record<string, string> = {
      battery: '🔋 Batería',
      tire: '🛞 Llanta',
      crash: '💥 Accidente',
      engine: '🔧 Motor',
      keys_lost: '🔑 Llave perdida',
      keys_locked: '🔐 Llave en vehículo',
      overheating: '🌡️ Sobrecalentamiento',
      other: '❓ Otro'
    };
    return map[type] || type;
  }

  getTypeEmoji(type: string): string {
    const map: Record<string, string> = {
      battery: '🔋', tire: '🛞', crash: '💥', engine: '🔧',
      keys_lost: '🔑', keys_locked: '🔐', overheating: '🌡️', other: '❓'
    };
    return map[type] || '❓';
  }
}
