import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
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
export class IncidentDetailComponent implements OnInit, OnDestroy {
  incident: IncidentDetail | null = null;
  technicians: Technician[] = [];
  loading = true;
  error = '';
  
  private pollingInterval: any;

  // Formulario aceptar
  selectedTechId: number | null = null;

  // Formulario completar
  finalCost: number | null = null;
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
    battery: ['baterías', 'eléctrico', 'electricidad', 'batería', 'corriente', 'alternador'],
    tire: ['llantas', 'neumáticos', 'llanta', 'neumático', 'pinchazo', 'auxilio', 'gomería'],
    crash: ['carrocería', 'chasis', 'colisión', 'remolque', 'chapería', 'pintura'],
    engine: ['motor', 'mecánica', 'mecánico', 'general', 'frenos', 'suspensión'],
    keys_lost: ['cerrajería', 'llaves', 'cerrajero', 'chapa'],
    keys_locked: ['cerrajería', 'llaves', 'cerrajero', 'apertura'],
    overheating: ['motor', 'radiador', 'refrigeración', 'mecánica', 'agua', 'ventilador'],
    other: ['general', 'mecánica', 'auxilio']
  };

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private ws: WorkshopService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    this.loadIncident(id);
    this.ws.getTechnicians().subscribe(t => {
      this.technicians = t.filter(x => x.is_available);
      this.cdr.detectChanges();
    });

    // POLLING en tiempo real
    this.pollingInterval = setInterval(() => {
      this.refreshIncidentSilently(id);
    }, 5000);
  }

  ngOnDestroy(): void {
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval);
    }
  }

  loadIncident(id: number): void {
    this.loading = true;
    this.ws.getIncidentDetail(id).subscribe({
      next: (data) => { 
        this.incident = data; 
        this.loading = false; 
        this.cdr.detectChanges();
      },
      error: (err) => { 
        this.error = 'No se pudo cargar el incidente'; 
        this.loading = false; 
        this.cdr.detectChanges();
      }
    });
  }

  refreshIncidentSilently(id: number): void {
    // Actualiza sin mostrar pantalla de carga
    this.ws.getIncidentDetail(id).subscribe({
      next: (data) => { 
        this.incident = data; 
        this.cdr.detectChanges();
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

  getImageUrl(url: string): string {
    if (url.startsWith('http')) return url;
    return `${this.apiBase}/${url}`;
  }

  parseAISummary(summary: string): {icon: string, title: string, content: string, type: string}[] {
    const sections: {icon: string, title: string, content: string, type: string}[] = [];
    
    // Patrones para extraer secciones del texto generado por Gemini
    const patterns = [
      { regex: /(?:🚨\s*)?SITUACI[OÓ]N:\s*(.*?)(?=(?:🛠️|🧰|DIAGN[OÓ]STICO|RECOMENDACI[OÓ]N)|$)/si, icon: '🚨', title: 'Situación', type: 'situacion' },
      { regex: /(?:🛠️\s*)?DIAGN[OÓ]STICO:\s*(.*?)(?=(?:🧰|RECOMENDACI[OÓ]N)|$)/si, icon: '🛠️', title: 'Diagnóstico', type: 'diagnostico' },
      { regex: /(?:🧰\s*)?RECOMENDACI[OÓ]N:\s*(.*?)$/si, icon: '🧰', title: 'Recomendación', type: 'recomendacion' },
    ];

    for (const p of patterns) {
      const match = summary.match(p.regex);
      if (match && match[1]) {
        sections.push({ icon: p.icon, title: p.title, content: match[1].trim(), type: p.type });
      }
    }

    // Si no se pudo parsear (formato diferente), mostrar todo como una sola sección
    if (sections.length === 0) {
      sections.push({ icon: '🤖', title: 'Análisis', content: summary, type: 'general' });
    }

    return sections;
  }

  getPaymentStatusLabel(status: string): string {
    const map: Record<string, string> = {
      'pending': 'PENDIENTE',
      'completed': 'PAGADO',
      'failed': 'FALLIDO',
      'refunded': 'REEMBOLSADO',
    };
    return map[status] || status.toUpperCase();
  }

  getPaymentMethodLabel(method: string): string {
    const map: Record<string, string> = {
      'mobile_payment': '📱 QR / Billetera Móvil',
      'cash': '💵 Efectivo',
      'credit_card': '💳 Tarjeta de Crédito',
      'debit_card': '🏦 Transferencia Bancaria',
    };
    return map[method] || method;
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
    if (!this.incident || !tech.specialties || tech.specialties.length === 0) return 10; // Base 10% for any professional
    
    const relevant = this.typeSpecialtyMap[this.incident.incident_type] || [];
    if (relevant.length === 0) return 50;

    const techSpecs = tech.specialties.map(s => s.toLowerCase().trim());
    
    // Fuzzy matching: check if any tech specialty contains or is contained by a relevant keyword
    const matchedRelevant = relevant.filter(r => 
      techSpecs.some(ts => ts.includes(r) || r.includes(ts))
    );

    if (matchedRelevant.length === 0) return 15; // Base 15% if no direct match but has specialties

    // Calculation: 40% base for any match + proportional part
    const score = 40 + (matchedRelevant.length / relevant.length) * 60;
    return Math.min(Math.round(score), 100);
  }

  /** Check if technician is a recommended match */
  isRecommended(tech: Technician): boolean {
    const score = this.getMatchScore(tech);
    return score >= 60;
  }

  /** Check if this technician is the absolute best match in the list */
  isBestMatch(tech: Technician): boolean {
    if (this.technicians.length === 0) return false;
    const scores = this.technicians.map(t => this.getMatchScore(t));
    const maxScore = Math.max(...scores);
    return maxScore > 20 && this.getMatchScore(tech) === maxScore;
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
    if (!this.incident || this.finalCost === null) return;
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
