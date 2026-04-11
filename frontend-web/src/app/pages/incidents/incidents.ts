import { Component, OnInit } from '@angular/core';
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
  loading = true;
  statusFilter = '';

  constructor(private ws: WorkshopService) {}

  ngOnInit(): void {
    this.loadIncidents();
  }

  loadIncidents(): void {
    this.loading = true;
    this.ws.getAssignedIncidents(this.statusFilter || undefined).subscribe({
      next: (data) => { this.incidents = data; this.loading = false; },
      error: () => { this.loading = false; }
    });
  }

  getTypeLabel(type: string): string {
    const map: Record<string, string> = {
      battery: '🔋 Batería', tire: '🛞 Llanta', engine: '🔧 Motor',
      collision: '💥 Choque', lockout: '🔑 Llaves', fuel: '⛽ Combustible',
      towing: '🚛 Remolque', other: '❓ Otro'
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
}
