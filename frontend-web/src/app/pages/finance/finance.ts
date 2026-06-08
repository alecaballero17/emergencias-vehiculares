import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { WorkshopService } from '../../services/workshop.service';
import { Incident } from '../../models/interfaces';
import { ExportUtil } from '../../utils/export-util';

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

  constructor(private ws: WorkshopService, private cd: ChangeDetectorRef) {}

  ngOnInit(): void {
    setTimeout(() => { 
      if (this.loading) {
        this.loading = false; 
        this.cd.detectChanges();
      }
    }, 4000);

    this.ws.getAssignedIncidents().subscribe({
      next: (incidents) => {
        this.processFinanceData(incidents || []);
        this.loading = false;
        this.cd.detectChanges();
      },
      error: () => { 
        this.records = [];
        this.loading = false; 
        this.cd.detectChanges();
      }
    });
  }

  private processFinanceData(incidents: Incident[]): void {
    const completed = incidents.filter(i => i.status === 'finalizado' && i.final_cost);
    const pending = incidents.filter(i => i.status === 'en_camino' || i.status === 'en_atencion' || i.status === 'taller_asignado');

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

  exportPdf(): void {
    const html = this.compileReportHtml();
    ExportUtil.exportToPdf('Reporte Financiero', html);
  }

  exportHtml(): void {
    const html = this.compileReportHtml();
    ExportUtil.exportToHtml('reporte_financiero', 'Reporte Financiero', html);
  }

  exportExcel(): void {
    const headers = ['Nro. Servicio', 'Tipo de Incidente', 'Fecha', 'Cobrado (Bs.)', 'Comisión (10% - Bs.)', 'Neto (Bs.)', 'Estado'];
    const rows = this.records.map(r => [
      `#${r.incidentId}`,
      this.getTypeLabel(r.incidentType),
      new Date(r.date).toLocaleDateString('es-ES'),
      r.amount,
      r.commission,
      r.net,
      'Pagado'
    ]);
    ExportUtil.exportToExcel('reporte_financiero', headers, rows);
  }

  compileReportHtml(): string {
    let rowsHtml = '';
    this.records.forEach(r => {
      rowsHtml += `
        <tr>
          <td>#${r.incidentId}</td>
          <td>${this.getTypeLabel(r.incidentType)}</td>
          <td>${new Date(r.date).toLocaleDateString('es-ES')}</td>
          <td class="money">Bs. ${r.amount.toFixed(2)}</td>
          <td class="money" style="color: #ef4444;">- Bs. ${r.commission.toFixed(2)}</td>
          <td class="money" style="color: #10b981;">Bs. ${r.net.toFixed(2)}</td>
          <td><span class="badge badge-success">Pagado</span></td>
        </tr>
      `;
    });

    return `
      <div style="margin-bottom: 25px;">
        <h3>Resumen Financiero</h3>
        <table style="width: 100%; margin-bottom: 25px;">
          <thead>
            <tr>
              <th>Ingresos Totales</th>
              <th>Comisión Plataforma (10%)</th>
              <th>Ganancia Neta</th>
              <th>Servicios Completados</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td class="money">Bs. ${this.summary.totalRevenue.toFixed(2)}</td>
              <td class="money" style="color: #ef4444;">- Bs. ${this.summary.totalCommission.toFixed(2)}</td>
              <td class="money" style="color: #10b981;">Bs. ${this.summary.netEarnings.toFixed(2)}</td>
              <td>${this.summary.completedServices}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <h3>Detalle de Transacciones</h3>
      <table>
        <thead>
          <tr>
            <th>Servicio</th>
            <th>Tipo</th>
            <th>Fecha</th>
            <th>Cobrado</th>
            <th>Comisión (10%)</th>
            <th>Neto</th>
            <th>Estado</th>
          </tr>
        </thead>
        <tbody>
          ${rowsHtml}
        </tbody>
      </table>
    `;
  }
}
