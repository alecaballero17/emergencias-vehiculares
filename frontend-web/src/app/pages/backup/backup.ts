import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-backup',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './backup.html',
  styleUrl: './backup.scss'
})
export class BackupComponent {
  private readonly apiUrl = environment.apiUrl;
  exporting = false;
  importing = false;
  message: string | null = null;
  messageType: 'success' | 'danger' | null = null;
  selectedFile: File | null = null;

  constructor(private http: HttpClient) {}

  exportBackup(): void {
    this.exporting = true;
    this.message = null;

    this.http.get<any>(`${this.apiUrl}/backup/export`).subscribe({
      next: (response) => {
        this.exporting = false;
        
        // Crear blob y descargar el archivo JSON
        const blob = new Blob([JSON.stringify(response, null, 2)], { type: 'application/json' });
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        const dateStr = new Date().toISOString().slice(0, 19).replace(/[-T:]/g, '_');
        
        link.href = url;
        link.download = `backup_emergencias_${dateStr}.json`;
        link.click();
        
        window.URL.revokeObjectURL(url);
        this.showFeedback('Copia de seguridad exportada y descargada con éxito.', 'success');
      },
      error: (err) => {
        this.exporting = false;
        this.showFeedback(err.error?.detail || 'Error al exportar la base de datos.', 'danger');
      }
    });
  }

  onFileSelected(event: any): void {
    const file = event.target.files[0];
    if (file) {
      this.selectedFile = file;
      this.message = null;
    }
  }

  importBackup(): void {
    if (!this.selectedFile) return;

    this.importing = true;
    this.message = null;

    const fileReader = new FileReader();
    fileReader.onload = () => {
      try {
        const payload = JSON.parse(fileReader.result as string);
        
        this.http.post<any>(`${this.apiUrl}/backup/import`, payload).subscribe({
          next: (res) => {
            this.importing = false;
            this.selectedFile = null;
            this.showFeedback('¡Base de datos restaurada con éxito!', 'success');
          },
          error: (err) => {
            this.importing = false;
            this.showFeedback(err.error?.detail || 'Error al importar/restaurar la base de datos.', 'danger');
          }
        });
      } catch (e) {
        this.importing = false;
        this.showFeedback('El archivo seleccionado no es un JSON válido.', 'danger');
      }
    };

    fileReader.readAsText(this.selectedFile);
  }

  private showFeedback(msg: string, type: 'success' | 'danger'): void {
    this.message = msg;
    this.messageType = type;
  }
}
