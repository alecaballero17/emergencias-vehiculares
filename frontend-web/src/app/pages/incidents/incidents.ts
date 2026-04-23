import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { WorkshopService } from '../../services/workshop.service';
import { Incident } from '../../models/interfaces';

@Component({
  selector: 'app-incidents',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
  templateUrl: './incidents.html',
  styleUrl: './incidents.scss'
})
export class IncidentsComponent implements OnInit {
  incidents: Incident[] = [];
  loading = false;
  statusFilter = '';

  constructor(private ws: WorkshopService, private cd: ChangeDetectorRef) {}

  ngOnInit(): void {
    setTimeout(() => { 
      if (this.loading) {
        this.loading = false;
        this.cd.detectChanges();
      }
    }, 4000);
    this.loadIncidents();
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
}
