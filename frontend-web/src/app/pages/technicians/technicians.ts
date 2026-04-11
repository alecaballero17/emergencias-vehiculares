import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { WorkshopService } from '../../services/workshop.service';
import { Technician } from '../../models/interfaces';

@Component({
  selector: 'app-technicians',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './technicians.html',
  styleUrl: './technicians.scss'
})
export class TechniciansComponent implements OnInit {
  technicians: Technician[] = [];
  loading = true;
  showForm = false;
  editingId: number | null = null;

  form = { name: '', phone: '', specialties: '' };
  error = '';

  constructor(private ws: WorkshopService) {}

  ngOnInit(): void {
    this.loadTechnicians();
  }

  loadTechnicians(): void {
    this.loading = true;
    this.ws.getTechnicians().subscribe({
      next: (data) => { this.technicians = data; this.loading = false; },
      error: () => { this.loading = false; }
    });
  }

  openNew(): void {
    this.editingId = null;
    this.form = { name: '', phone: '', specialties: '' };
    this.showForm = true;
    this.error = '';
  }

  openEdit(tech: Technician): void {
    this.editingId = tech.id;
    this.form = {
      name: tech.name,
      phone: tech.phone,
      specialties: tech.specialties?.join(', ') || ''
    };
    this.showForm = true;
    this.error = '';
  }

  save(): void {
    const data: any = {
      name: this.form.name,
      phone: this.form.phone,
      specialties: this.form.specialties.split(',').map(s => s.trim()).filter(s => s)
    };

    if (this.editingId) {
      this.ws.updateTechnician(this.editingId, data).subscribe({
        next: () => { this.showForm = false; this.loadTechnicians(); },
        error: (err) => { this.error = err.error?.detail || 'Error al actualizar'; }
      });
    } else {
      this.ws.addTechnician(data).subscribe({
        next: () => { this.showForm = false; this.loadTechnicians(); },
        error: (err) => { this.error = err.error?.detail || 'Error al crear'; }
      });
    }
  }

  toggleAvailability(tech: Technician): void {
    this.ws.updateTechnician(tech.id, { is_available: !tech.is_available } as any).subscribe({
      next: () => this.loadTechnicians()
    });
  }

  delete(tech: Technician): void {
    if (!confirm(`¿Eliminar al técnico ${tech.name}?`)) return;
    this.ws.deleteTechnician(tech.id).subscribe({
      next: () => this.loadTechnicians()
    });
  }
}
