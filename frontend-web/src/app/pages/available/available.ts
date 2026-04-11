import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { WorkshopService } from '../../services/workshop.service';
import { Incident } from '../../models/interfaces';

@Component({
  selector: 'app-available',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './available.html',
  styleUrl: './available.scss'
})
export class AvailableComponent implements OnInit {
  incidents: Incident[] = [];
  loading = true;

  constructor(private ws: WorkshopService) {}

  ngOnInit(): void {
    this.loadIncidents();
  }

  loadIncidents(): void {
    this.loading = true;
    this.ws.getAvailableIncidents().subscribe({
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

  getPriorityClass(p: string): string {
    return `priority-${p}`;
  }

  timeAgo(date: string): string {
    const diff = Date.now() - new Date(date).getTime();
    const min = Math.floor(diff / 60000);
    if (min < 60) return `hace ${min} min`;
    const hrs = Math.floor(min / 60);
    if (hrs < 24) return `hace ${hrs}h`;
    return `hace ${Math.floor(hrs / 24)}d`;
  }
}
