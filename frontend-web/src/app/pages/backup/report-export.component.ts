import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ReportService, ReportFormat } from '../../services/report.service';

/**
 * Componente para exportación de reportes
 * Permite descargar reportes en PDF, HTML y Excel
 */
@Component({
  selector: 'app-report-export',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="report-export-container">
      <h2>📊 Exportar Reportes</h2>

      <div class="report-section">
        <h3>Reportes de Incidentes</h3>
        <div class="controls">
          <label>
            Período (días):
            <input type="number" [(ngModel)]="daysIncidents" min="1" max="365" />
          </label>
          <div class="format-buttons">
            <button (click)="exportIncidentsPDF()" class="btn-pdf">📄 PDF</button>
            <button (click)="exportIncidentsHTML()" class="btn-html">🌐 HTML</button>
            <button (click)="exportIncidentsExcel()" class="btn-excel">📊 Excel</button>
          </div>
        </div>
      </div>

      <div class="report-section">
        <h3>Reportes Financieros</h3>
        <div class="controls">
          <label>
            Período (días):
            <input type="number" [(ngModel)]="daysFinancial" min="1" max="365" />
          </label>
          <div class="format-buttons">
            <button (click)="exportFinancialPDF()" class="btn-pdf">📄 PDF</button>
            <button (click)="exportFinancialHTML()" class="btn-html">🌐 HTML</button>
            <button (click)="exportFinancialExcel()" class="btn-excel">📊 Excel</button>
          </div>
        </div>
      </div>

      <div class="info-box">
        <p>
          ℹ️ Los reportes se descargarán en el formato seleccionado. Puede exportar datos de
          los últimos 365 días.
        </p>
      </div>
    </div>
  `,
  styles: [
    `
      .report-export-container {
        padding: 20px;
        max-width: 800px;
        margin: 0 auto;
      }

      h2 {
        color: #1976d2;
        margin-bottom: 20px;
      }

      .report-section {
        background: #f5f5f5;
        padding: 15px;
        border-radius: 8px;
        margin-bottom: 20px;
      }

      h3 {
        margin-top: 0;
        color: #333;
      }

      .controls {
        display: flex;
        gap: 15px;
        flex-wrap: wrap;
        align-items: center;
      }

      label {
        display: flex;
        align-items: center;
        gap: 8px;
        font-weight: 500;
      }

      input[type='number'] {
        padding: 8px;
        border: 1px solid #ccc;
        border-radius: 4px;
        width: 80px;
      }

      .format-buttons {
        display: flex;
        gap: 10px;
      }

      button {
        padding: 8px 16px;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-weight: 500;
        transition: all 0.3s ease;
      }

      .btn-pdf {
        background-color: #f44336;
        color: white;
      }

      .btn-pdf:hover {
        background-color: #d32f2f;
      }

      .btn-html {
        background-color: #ff9800;
        color: white;
      }

      .btn-html:hover {
        background-color: #f57c00;
      }

      .btn-excel {
        background-color: #4caf50;
        color: white;
      }

      .btn-excel:hover {
        background-color: #388e3c;
      }

      .info-box {
        background-color: #e3f2fd;
        border-left: 4px solid #1976d2;
        padding: 12px;
        border-radius: 4px;
      }

      .info-box p {
        margin: 0;
        color: #0d47a1;
      }
    `,
  ],
})
export class ReportExportComponent implements OnInit {
  daysIncidents = 30;
  daysFinancial = 30;

  constructor(private reportService: ReportService) {}

  ngOnInit(): void {}

  exportIncidentsPDF(): void {
    this.reportService.downloadIncidentsReport('pdf', this.daysIncidents);
  }

  exportIncidentsHTML(): void {
    this.reportService.downloadIncidentsReport('html', this.daysIncidents);
  }

  exportIncidentsExcel(): void {
    this.reportService.downloadIncidentsReport('excel', this.daysIncidents);
  }

  exportFinancialPDF(): void {
    this.reportService.downloadFinancialReport('pdf', this.daysFinancial);
  }

  exportFinancialHTML(): void {
    this.reportService.downloadFinancialReport('html', this.daysFinancial);
  }

  exportFinancialExcel(): void {
    this.reportService.downloadFinancialReport('excel', this.daysFinancial);
  }
}
