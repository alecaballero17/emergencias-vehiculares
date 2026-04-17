import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { WorkshopService } from '../../services/workshop.service';
import { Incident } from '../../models/interfaces';

interface FinanceSummary {
  totalRevenue: number;
  totalCommission: number;
  netEarnings: number;
  completedServices: number;
  pendingPayments: number;
}

interface FinanceRecord {
  incidentId: number;
  incidentType: string;
  date: string;
  amount: number;
  commission: number;
  net: number;
  status: string;
}

@Component({
  selector: 'app-finance',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './finance.html',
  styleUrl: './finance.scss'
})
export class FinanceComponent implements OnInit {
  summary: FinanceSummary = {
    totalRevenue: 0,
    totalCommission: 0,
    netEarnings: 0,
    completedServices: 0,
    pendingPayments: 0
  };

  records: FinanceRecord[] = [];
  loading = true;
  readonly COMMISSION_RATE = 0.10;

  constructor(private ws: WorkshopService) {}

  ngOnInit(): void {
    setTimeout(() => { this.loading = false; }, 3000);

    this.ws.getAssignedIncidents().subscribe({
      next: (incidents) => {
        this.processFinanceData(incidents);
        this.loading = false;
      },
      error: () => { this.loading = false; }
    });
  }

  private processFinanceData(incidents: Incident[]): void {
    const completed = incidents.filter(i => i.status === 'completed' && i.final_cost);
    const pending = incidents.filter(i => i.status === 'in_progress' || i.status === 'assigned');

    this.records = completed.map(inc => {
      const amount = inc.final_cost || 0;
      const commission = Math.round(amount * this.COMMISSION_RATE * 100) / 100;
      return {
        incidentId: inc.id,
        incidentType: inc.incident_type,
        date: inc.completed_at || inc.updated_at,
        amount,
        commission,
        net: Math.round((amount - commission) * 100) / 100,
        status: 'paid'
      };
    });

    this.summary = {
      totalRevenue: this.records.reduce((sum, r) => sum + r.amount, 0),
      totalCommission: this.records.reduce((sum, r) => sum + r.commission, 0),
      netEarnings: this.records.reduce((sum, r) => sum + r.net, 0),
      completedServices: completed.length,
      pendingPayments: pending.length
    };
  }

  getTypeLabel(type: string): string {
    const map: Record<string, string> = {
      battery: '🔋 Batería', tire: '🛞 Llanta', crash: '💥 Accidente',
      engine: '🔧 Motor', keys_lost: '🔑 Llave perdida', keys_locked: '🔐 Llave en vehículo',
      overheating: '🌡️ Sobrecalentamiento', other: '❓ Otro'
    };
    return map[type] || type;
  }

  getTypeEmoji(type: string): string {
    const map: Record<string, string> = {
      battery: '🔋', tire: '🛞', crash: '💥', engine: '🔧',
      keys_lost: '🔑', keys_locked: '🔐', overheating: '🌡️', other: '❓'
    };
    return map[type] || '❓';
  }
}
