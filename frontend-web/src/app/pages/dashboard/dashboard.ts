import { Component, OnInit } from '@angular/core';
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
  loading = true;

  constructor(private ws: WorkshopService) {}

  ngOnInit(): void {
    this.ws.getAvailableIncidents().subscribe(i => {
      this.availableCount = i.length;
    });
    this.ws.getAssignedIncidents().subscribe(incidents => {
      this.recentIncidents = incidents.slice(0, 5);
      this.activeCount = incidents.filter(i => i.status === 'in_progress' || i.status === 'assigned').length;
      this.completedCount = incidents.filter(i => i.status === 'completed').length;
      this.loading = false;
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

  getStatusLabel(status: string): string {
    const map: Record<string, string> = {
      pending: 'Pendiente',
      assigned: 'Asignado',
      in_progress: 'En Proceso',
      completed: 'Completado',
      cancelled: 'Cancelado'
    };
    return map[status] || status;
  }

  getTypeLabel(type: string): string {
    const map: Record<string, string> = {
      battery: '🔋 Batería',
      tire: '🛞 Llanta',
      engine: '🔧 Motor',
      collision: '💥 Choque',
      lockout: '🔑 Llaves',
      fuel: '⛽ Combustible',
      towing: '🚛 Remolque',
      other: '❓ Otro'
    };
    return map[type] || type;
  }
}
