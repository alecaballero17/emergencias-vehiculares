import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { WorkshopService } from '../../services/workshop.service';
import { WebSocketService } from '../../services/websocket.service';
import { IncidentDetail, Technician } from '../../models/interfaces';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-incident-detail',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './incident-detail.html',
  styleUrl: './incident-detail.scss'
})
export class IncidentDetailComponent implements OnInit, OnDestroy {
  incident: IncidentDetail | null = null;
  technicians: Technician[] = [];
  loading = true;
  error = '';
  
  private pollingInterval: any;

  // Mapa y Simulación GPS
  private map: any;
  private userMarker: any;
  private mechanicMarker: any;
  private simulationInterval: any;
  private simulationProgress = 0.0;
  
  mechanicLat: number | null = null;
  mechanicLng: number | null = null;

  // Formulario aceptar
  selectedTechId: number | null = null;

  // Formulario completar
  finalCost: number | null = null;
  completionNotes: string = '';

  // Formulario rechazar
  rejectReason: string = '';

  // Formulario cotizar
  quoteAmount: number | null = null;
  quoteArrivalHours: number | null = null;
  quoteRepairHours: number | null = null;
  quoteDescription: string = '';

  showAcceptModal = false;
  showCompleteModal = false;
  showRejectModal = false;
  showQuoteModal = false;
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
    private wsService: WebSocketService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    this.loadIncident(id);
    
    // Conectar WebSocket y suscribirse
    this.wsService.connect();
    this.wsService.subscribeIncident(id);
    
    this.wsService.messages$.subscribe(msg => {
      if (this.incident && msg.incident_id === this.incident.id) {
        if (msg.type === 'location_update') {
          this.mechanicLat = msg.latitude;
          this.mechanicLng = msg.longitude;
          this.updateMapMarkers();
        } else if (msg.type === 'status_change' || msg.type === 'payment_confirmed') {
          this.refreshIncidentSilently(this.incident.id);
        }
      }
    });

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
    this.wsService.disconnect();
    this.stopSimulation();
  }

  loadIncident(id: number): void {
    this.loading = true;
    this.ws.getIncidentDetail(id).subscribe({
      next: (data) => { 
        this.incident = data; 
        this.loading = false; 
        this.cdr.detectChanges();

        setTimeout(() => {
          this.loadLeaflet();
        }, 150);

        if (this.incident.status === 'en_camino') {
          this.startSimulation();
        } else {
          this.stopSimulation();
        }
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
        
        // Intentar inicializar el mapa si el contenedor no estaba listo en la carga inicial
        if (!this.map) {
          this.loadLeaflet();
        }

        if (this.incident.status === 'en_camino') {
          this.startSimulation();
        } else {
          this.stopSimulation();
        }
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
      pendiente: 'Pendiente',
      buscando_taller: 'Buscando Cotizaciones',
      taller_asignado: 'Taller Asignado',
      en_camino: 'En Camino',
      en_atencion: 'En Atención',
      finalizado: 'Completado',
      cancelado: 'Cancelado'
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

  sendQuotation(): void {
    if (!this.incident || this.quoteAmount === null || this.quoteArrivalHours === null || this.quoteRepairHours === null) return;
    this.actionLoading = true;
    this.ws.sendQuotation(
      this.incident.id, 
      this.quoteAmount, 
      this.quoteArrivalHours, 
      this.quoteRepairHours, 
      this.quoteDescription
    ).subscribe({
      next: () => {
        this.showQuoteModal = false;
        this.actionLoading = false;
        this.quoteAmount = null;
        this.quoteArrivalHours = null;
        this.quoteRepairHours = null;
        this.quoteDescription = '';
        this.loadIncident(this.incident!.id);
      },
      error: (err) => {
        this.error = err.error?.detail || 'Error al enviar cotización';
        this.actionLoading = false;
      }
    });
  }

  markEnRoute(): void {
    if (!this.incident) return;
    this.actionLoading = true;
    this.ws.markEnRoute(this.incident.id).subscribe({
      next: () => {
        this.actionLoading = false;
        this.loadIncident(this.incident!.id);
      },
      error: (err) => {
        this.error = err.error?.detail || 'Error al iniciar viaje';
        this.actionLoading = false;
      }
    });
  }

  markArrived(): void {
    if (!this.incident) return;
    this.actionLoading = true;
    this.ws.markArrived(this.incident.id).subscribe({
      next: () => {
        this.actionLoading = false;
        this.loadIncident(this.incident!.id);
      },
      error: (err) => {
        this.error = err.error?.detail || 'Error al reportar llegada';
        this.actionLoading = false;
      }
    });
  }

  // --- Leaflet Map & Simulation ---
  loadLeaflet(): void {
    if ((window as any).L) {
      this.initMap();
      return;
    }
    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
    document.head.appendChild(link);

    const script = document.createElement('script');
    script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
    script.onload = () => this.initMap();
    document.body.appendChild(script);
  }

  initMap(): void {
    const L = (window as any).L;
    if (!L || !this.incident) return;

    const container = document.getElementById('web-map-container');
    if (!container) return;

    if ((container as any)._leaflet_id) {
      return;
    }

    this.map = L.map('web-map-container').setView([this.incident.latitude, this.incident.longitude], 15);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap'
    }).addTo(this.map);

    // Icono azul para el incidente
    const blueIcon = L.icon({
      iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-blue.png',
      shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
      iconSize: [25, 41],
      iconAnchor: [12, 41],
      popupAnchor: [1, -34],
      shadowSize: [41, 41]
    });

    this.userMarker = L.marker([this.incident.latitude, this.incident.longitude], { icon: blueIcon })
      .addTo(this.map)
      .bindPopup('Ubicación de la Emergencia')
      .openPopup();

    this.updateMapMarkers();
  }

  updateMapMarkers(): void {
    const L = (window as any).L;
    if (!L || !this.map) return;

    if (this.mechanicLat && this.mechanicLng) {
      const orangeIcon = L.icon({
        iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-orange.png',
        shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
        iconSize: [25, 41],
        iconAnchor: [12, 41],
        popupAnchor: [1, -34],
        shadowSize: [41, 41]
      });

      if (this.mechanicMarker) {
        this.mechanicMarker.setLatLng([this.mechanicLat, this.mechanicLng]);
      } else {
        this.mechanicMarker = L.marker([this.mechanicLat, this.mechanicLng], { icon: orangeIcon })
          .addTo(this.map)
          .bindPopup('Mecánico en Camino');
      }

      // Auto-centrar mostrando ambos marcadores
      const bounds = L.latLngBounds([
        [this.incident!.latitude, this.incident!.longitude],
        [this.mechanicLat, this.mechanicLng]
      ]);
      this.map.fitBounds(bounds, { padding: [50, 50] });
    } else if (this.mechanicMarker) {
      this.map.removeLayer(this.mechanicMarker);
      this.mechanicMarker = null;
    }
  }

  startSimulation(): void {
    if (this.simulationInterval || !this.incident) return;
    this.simulationProgress = 0.0;

    // Partir de un offset de ~1.5 km
    const startLat = this.incident.latitude + 0.008;
    const startLng = this.incident.longitude + 0.008;

    this.mechanicLat = startLat;
    this.mechanicLng = startLng;

    setTimeout(() => {
      this.loadLeaflet();
    }, 200);

    // Mover el marcador de mecánico en la web y emitir actualización via WebSocket
    this.simulationInterval = setInterval(() => {
      if (!this.incident || this.incident.status !== 'en_camino') {
        this.stopSimulation();
        return;
      }

      this.simulationProgress += 0.05; // 20 pasos de 4s (total 80s)
      if (this.simulationProgress >= 1.0) {
        this.simulationProgress = 1.0;
        this.stopSimulation();
      }

      const currentLat = startLat + (this.incident.latitude - startLat) * this.simulationProgress;
      const currentLng = startLng + (this.incident.longitude - startLng) * this.simulationProgress;

      this.mechanicLat = currentLat;
      this.mechanicLng = currentLng;
      this.updateMapMarkers();

      // Emitir al backend a través del WebSocket
      const eta = Math.round(10 * (1.0 - this.simulationProgress));
      this.wsService.sendLocationUpdate(this.incident.id, currentLat, currentLng, eta > 0 ? eta : 1);
    }, 4000);
  }

  stopSimulation(): void {
    if (this.simulationInterval) {
      clearInterval(this.simulationInterval);
      this.simulationInterval = null;
    }
  }
}
