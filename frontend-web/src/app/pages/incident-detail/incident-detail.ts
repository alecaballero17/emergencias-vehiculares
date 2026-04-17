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

  // Mapeo de tipo de incidente → especialidades relevantes
  private readonly typeSpecialtyMap: Record<string, string[]> = {
    battery: ['baterías', 'eléctrico', 'electricidad', 'batería'],
    tire: ['llantas', 'neumáticos', 'llanta', 'neumático'],
    crash: ['carrocería', 'chasis', 'colisión', 'remolque'],
    engine: ['motor', 'mecánica', 'mecánico', 'general'],
    keys_lost: ['cerrajería', 'llaves', 'cerrajero'],
    keys_locked: ['cerrajería', 'llaves', 'cerrajero'],
    overheating: ['motor', 'radiador', 'refrigeración', 'mecánica'],
    other: ['general', 'mecánica']
  };

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private ws: WorkshopService
  ) {}

  ngOnInit(): void {
    setTimeout(() => { this.loading = false; }, 3000);
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

  /** Returns sorted technicians: best match first */
  get sortedTechnicians(): Technician[] {
    if (!this.incident) return this.technicians;
    return [...this.technicians].sort((a, b) => {
      return this.getMatchScore(b) - this.getMatchScore(a);
    });
  }

  /** Score 0-100 for how well a technician matches the incident type */
  getMatchScore(tech: Technician): number {
    if (!this.incident || !tech.specialties || tech.specialties.length === 0) return 0;
    const relevant = this.typeSpecialtyMap[this.incident.incident_type] || [];
    if (relevant.length === 0) return 50;
    const techSpecs = tech.specialties.map(s => s.toLowerCase().trim());
    const matchCount = relevant.filter(r => techSpecs.some(ts => ts.includes(r) || r.includes(ts))).length;
    return Math.round((matchCount / relevant.length) * 100);
  }

  /** Check if technician is a recommended match */
  isRecommended(tech: Technician): boolean {
    return this.getMatchScore(tech) >= 50;
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
