import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { WorkshopService } from '../../services/workshop.service';
import { IncidentDetail, Technician } from '../../models/interfaces';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-incident-detail',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './incident-detail.html',
  styleUrl: './incident-detail.scss'
})
export class IncidentDetailComponent implements OnInit {
  incident: IncidentDetail | null = null;
  technicians: Technician[] = [];
  loading = true;
  error = '';

  // Formulario aceptar
  selectedTechId: number | null = null;

  // Formulario completar
  finalCost: number = 0;
  completionNotes: string = '';

  // Formulario rechazar
  rejectReason: string = '';

  showAcceptModal = false;
  showCompleteModal = false;
  showRejectModal = false;
  actionLoading = false;

  readonly apiBase = environment.apiUrl.replace('/api', '');

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private ws: WorkshopService
  ) {}

  ngOnInit(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    this.loadIncident(id);
    this.ws.getTechnicians().subscribe(t => this.technicians = t.filter(x => x.is_available));
  }

  loadIncident(id: number): void {
    this.ws.getIncidentDetail(id).subscribe({
      next: (data) => { this.incident = data; this.loading = false; },
      error: (err) => { this.error = 'No se pudo cargar el incidente'; this.loading = false; }
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

  getImageUrl(url: string): string {
    if (url.startsWith('http')) return url;
    return `${this.apiBase}/${url}`;
  }

  // === Acciones ===
  acceptIncident(): void {
    if (!this.incident || !this.selectedTechId) return;
    this.actionLoading = true;
    this.ws.acceptIncident(this.incident.id, this.selectedTechId).subscribe({
      next: () => {
        this.showAcceptModal = false;
        this.actionLoading = false;
        this.loadIncident(this.incident!.id);
      },
      error: (err) => {
        this.error = err.error?.detail || 'Error al aceptar';
        this.actionLoading = false;
      }
    });
  }

  rejectIncident(): void {
    if (!this.incident) return;
    this.actionLoading = true;
    this.ws.rejectIncident(this.incident.id, this.rejectReason).subscribe({
      next: () => {
        this.showRejectModal = false;
        this.actionLoading = false;
        this.router.navigate(['/available']);
      },
      error: (err) => {
        this.error = err.error?.detail || 'Error al rechazar';
        this.actionLoading = false;
      }
    });
  }

  completeIncident(): void {
    if (!this.incident) return;
    this.actionLoading = true;
    this.ws.completeIncident(this.incident.id, this.finalCost, this.completionNotes).subscribe({
      next: () => {
        this.showCompleteModal = false;
        this.actionLoading = false;
        this.loadIncident(this.incident!.id);
      },
      error: (err) => {
        this.error = err.error?.detail || 'Error al completar';
        this.actionLoading = false;
      }
    });
  }
}
