import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../environments/environment';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

export type ReportFormat = 'pdf' | 'html' | 'excel';
export type ReportType = 'incidents' | 'financial' | 'workshop-incidents';

/**
 * Servicio para exportación de reportes en múltiples formatos
 */
@Injectable({
  providedIn: 'root',
})
export class ReportService {
  private apiUrl = environment.apiUrl || 'http://localhost:8000/api';

  constructor(private http: HttpClient) {}

  /**
   * Descargar reporte de incidentes
   */
  downloadIncidentsReport(format: ReportFormat, days: number = 30): void {
    const url = `${this.apiUrl}/reports/incidents/export?format=${format}&days=${days}`;
    this.downloadFile(url, `incidents_report_${format}`, format);
  }

  /**
   * Descargar reporte financiero
   */
  downloadFinancialReport(format: ReportFormat, days: number = 30): void {
    const url = `${this.apiUrl}/reports/financial/export?format=${format}&days=${days}`;
    this.downloadFile(url, `financial_report_${format}`, format);
  }

  /**
   * Descargar reporte de incidentes del taller (solo para talleres)
   */
  downloadWorkshopIncidentsReport(format: ReportFormat, days: number = 30): void {
    const url = `${this.apiUrl}/reports/workshop/incidents/export?format=${format}&days=${days}`;
    this.downloadFile(url, `workshop_incidents_${format}`, format);
  }

  /**
   * Descargar archivo con el nombre y tipo correcto
   */
  private downloadFile(url: string, filename: string, format: ReportFormat): void {
    this.http
      .get(url, {
        responseType: 'blob',
      })
      .pipe(
        tap((blob) => {
          const link = document.createElement('a');
          const extension = this.getFileExtension(format);
          link.href = window.URL.createObjectURL(blob);
          link.download = `${filename}_${new Date().toISOString().split('T')[0]}.${extension}`;
          link.click();
          window.URL.revokeObjectURL(link.href);
        })
      )
      .subscribe({
        error: (error) => {
          console.error('Error descargando reporte:', error);
        },
      });
  }

  /**
   * Obtener extensión de archivo según formato
   */
  private getFileExtension(format: ReportFormat): string {
    switch (format) {
      case 'pdf':
        return 'pdf';
      case 'html':
        return 'html';
      case 'excel':
        return 'xlsx';
      default:
        return 'bin';
    }
  }

  /**
   * Obtener MIME type según formato
   */
  getContentType(format: ReportFormat): string {
    switch (format) {
      case 'pdf':
        return 'application/pdf';
      case 'html':
        return 'text/html; charset=utf-8';
      case 'excel':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }
}
