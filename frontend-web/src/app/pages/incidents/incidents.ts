import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { WorkshopService } from '../../services/workshop.service';
import { RefreshService } from '../../services/refresh.service';
import { Incident } from '../../models/interfaces';
import { ExportUtil } from '../../utils/export-util';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-incidents',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
  templateUrl: './incidents.html',
  styleUrl: './incidents.scss'
})
export class IncidentsComponent implements OnInit, OnDestroy {
  incidents: Incident[] = [];
  loading = false;
  statusFilter = '';
  private pollingInterval: any;
  private refreshSubscription: Subscription | null = null;

  constructor(
    private ws: WorkshopService, 
    private refreshService: RefreshService,
    private cd: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadIncidents();
    this.pollingInterval = setInterval(() => {
      this.refreshIncidentsSilently();
    }, 5000);

    // Recargar automáticamente cuando se recupera la conexión a internet
    this.refreshSubscription = this.refreshService.refresh$.subscribe(() => {
      console.log('[IncidentsComponent] Conexión restablecida. Recargando incidentes...');
      this.loadIncidents();
    });
  }

  ngOnDestroy(): void {
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval);
    }
    if (this.refreshSubscription) {
      this.refreshSubscription.unsubscribe();
    }
  }

  loadIncidents(): void {
    this.loading = true;
    this.ws.getAssignedIncidents(this.statusFilter || undefined).subscribe({
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
    this.ws.getAssignedIncidents(this.statusFilter || undefined).subscribe({
      next: (data) => { 
        this.incidents = data || []; 
        this.cd.detectChanges();
      }
    });
  }

  getTypeLabel(type: string): string {
    const map: Record<string, string> = {
      battery: '🔋 Batería', tire: '🛞 Llanta', crash: '💥 Accidente',
      engine: '🔧 Motor', keys_lost: '🔑 Llave perdida', keys_locked: '🔐 Llave en vehículo',
      overheating: '🌡️ Sobrecalentamiento', other: '❓ Otro'
    };
    return map[type] || type;
  }

  getStatusLabel(s: string): string {
    const map: Record<string, string> = {
      pending: 'Pendiente', assigned: 'Asignado', in_progress: 'En Proceso',
      completed: 'Completado', cancelled: 'Cancelado'
    };
    return map[s] || s;
  }

  getPriorityLabel(p: string): string {
    const map: Record<string, string> = {
      low: 'BAJA', medium: 'MEDIA', high: 'ALTA', critical: 'CRÍTICA'
    };
    return map[p] || p;
  }

  exportPdf(): void {
    const html = this.compileIncidentsHtml();
    ExportUtil.exportToPdf('Reporte de Incidentes Asignados', html);
  }

  exportHtml(): void {
    const html = this.compileIncidentsHtml();
    ExportUtil.exportToHtml('reporte_incidentes', 'Reporte de Incidentes Asignados', html);
  }

  exportExcel(): void {
    const headers = ['ID', 'Tipo de Incidente', 'Prioridad', 'Estado', 'Fecha'];
    const rows = this.incidents.map(inc => [
      `#${inc.id}`,
      this.getTypeLabel(inc.incident_type),
      this.getPriorityLabel(inc.priority),
      this.getStatusLabel(inc.status),
      new Date(inc.created_at).toLocaleString('es-ES')
    ]);
    ExportUtil.exportToExcel('reporte_incidentes', headers, rows);
  }

  compileIncidentsHtml(): string {
    let rowsHtml = '';
    this.incidents.forEach(inc => {
      rowsHtml += `
        <tr>
          <td>#${inc.id}</td>
          <td>${this.getTypeLabel(inc.incident_type)}</td>
          <td>${this.getPriorityLabel(inc.priority)}</td>
          <td>${this.getStatusLabel(inc.status)}</td>
          <td>${new Date(inc.created_at).toLocaleString('es-ES')}</td>
        </tr>
      `;
    });

    return `
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Tipo de Incidente</th>
            <th>Prioridad</th>
            <th>Estado</th>
            <th>Fecha</th>
          </tr>
        </thead>
        <tbody>
          ${rowsHtml}
        </tbody>
      </table>
    `;
  }
}
