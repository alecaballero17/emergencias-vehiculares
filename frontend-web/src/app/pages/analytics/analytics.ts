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

  private map: any = null;

  constructor(
    private analyticsService: AnalyticsService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadAllData();
  }

  ngOnDestroy(): void {
    if (this.map) {
      try {
        this.map.remove();
      } catch (err) {
        console.error('Error removing map on destroy:', err);
      }
      this.map = null;
    }
  }

  loadAllData(): void {
    this.loading = true;
    this.analyticsService.getDashboardStats().subscribe({
      next: (res: any) => {
        try {
          this.summary = res?.summary || {};
          this.assignmentTime = res?.assignment || {};
          this.arrivalTime = res?.arrival || {};
          this.incidentsByType = res?.types?.data || [];
          this.pieTotal = res?.types?.total || 0;
          this.topWorkshops = res?.workshops?.data || [];
          this.heatmapPoints = res?.heatmap?.points || [];
          this.cancelledCases = res?.cancelled || {};
          this.slaCompliance = res?.sla || {};
        } catch (e) {
          console.error('Error parsing dashboard stats:', e);
        } finally {
          this.loading = false;
          this.cdr.detectChanges();
          
          setTimeout(() => {
            this.initMap();
          }, 100);
        }
      },
      error: (err) => {
        console.error('Error loading analytics:', err);
        this.loading = false;
        this.cdr.detectChanges();
      }
    });
  }

  initMap(retries = 0): void {
    const L = (window as any).L;
    if (!L) {
      if (retries < 20) {
        setTimeout(() => this.initMap(retries + 1), 200);
      } else {
        console.error('Leaflet library (L) could not be loaded.');
      }
      return;
    }

    const container = document.getElementById('heatmap-container');
    if (!container) {
      if (retries < 20) {
        setTimeout(() => this.initMap(retries + 1), 200);
      }
      return;
    }

    // Limpiar mapa anterior si existe para evitar "Map container is already initialized"
    if (this.map) {
      try {
        this.map.remove();
      } catch (e) {
        console.warn('Error removing map before re-initialization:', e);
      }
      this.map = null;
    }

    if ((container as any)._leaflet_id) {
      (container as any)._leaflet_id = null;
    }

    try {
      this.map = L.map('heatmap-container').setView([-17.7833, -63.1822], 13);

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap'
      }).addTo(this.map);

      if (this.heatmapPoints && this.heatmapPoints.length > 0) {
        this.heatmapPoints.forEach((p: any) => {
          if (p.lat && p.lng) {
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
            }).addTo(this.map).bindPopup(`Incidente: ${p.type}`);
          }
        });
      }

      // Invalidar el tamaño del mapa para asegurar el renderizado correcto de los tiles
      setTimeout(() => {
        if (this.map) {
          this.map.invalidateSize();
        }
      }, 100);

    } catch (err) {
      console.error('Error during Leaflet map initialization:', err);
    }
  }

  getIncPercentage(count: number): number {
    return this.pieTotal > 0 ? (count / this.pieTotal) * 100 : 0;
  }
}
