import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AnalyticsService } from '../../services/analytics.service';

@Component({
  selector: 'app-analytics',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './analytics.html',
  styleUrl: './analytics.scss'
})
export class AnalyticsComponent implements OnInit, OnDestroy {
  loading = true;
  summary: any = {};
  assignmentTime: any = {};
  arrivalTime: any = {};
  incidentsByType: any[] = [];
  topWorkshops: any[] = [];
  heatmapPoints: any[] = [];
  cancelledCases: any = {};
  slaCompliance: any = {};
  
  pieTotal = 0;
  pieColors: { [key: string]: string } = {
    'battery': '#6366f1',
    'tire': '#06b6d4',
    'crash': '#ef4444',
    'engine': '#f59e0b',
    'other': '#10b981'
  };

  constructor(
    private analyticsService: AnalyticsService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadAllData();
  }

  ngOnDestroy(): void {
    // Limpieza
  }

  loadAllData(): void {
    this.loading = true;
    this.analyticsService.getDashboardStats().subscribe({
      next: (res: any) => {
        this.summary = res.summary;
        this.assignmentTime = res.assignment;
        this.arrivalTime = res.arrival;
        this.incidentsByType = res.types.data || [];
        this.pieTotal = res.types.total || 0;
        this.topWorkshops = res.workshops.data || [];
        this.heatmapPoints = res.heatmap.points || [];
        this.cancelledCases = res.cancelled;
        this.slaCompliance = res.sla;

        this.loading = false;
        this.cdr.detectChanges();
        
        setTimeout(() => {
          this.loadLeaflet();
        }, 100);
      },
      error: (err) => {
        console.error('Error loading analytics:', err);
        this.loading = false;
        this.cdr.detectChanges();
      }
    });
  }

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
    if (!L || !this.heatmapPoints.length) return;

    const container = document.getElementById('heatmap-container');
    if (!container) return;

    if ((container as any)._leaflet_id) {
      return;
    }

    const map = L.map('heatmap-container').setView([-17.7833, -63.1822], 13);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap'
    }).addTo(map);

    this.heatmapPoints.forEach((p: any) => {
      let color = '#ef4444';
      if (p.type === 'battery') color = '#6366f1';
      if (p.type === 'tire') color = '#06b6d4';
      if (p.type === 'engine') color = '#f59e0b';
      if (p.type === 'other') color = '#10b981';

      L.circle([p.lat, p.lng], {
        color: color,
        fillColor: color,
        fillOpacity: 0.4,
        radius: 350
      }).addTo(map).bindPopup(`Incidente: ${p.type}`);
    });
  }

  getIncPercentage(count: number): number {
    return this.pieTotal > 0 ? (count / this.pieTotal) * 100 : 0;
  }
}
