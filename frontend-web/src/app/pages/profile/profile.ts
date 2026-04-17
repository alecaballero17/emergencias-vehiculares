import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { WorkshopService } from '../../services/workshop.service';
import { Workshop } from '../../models/interfaces';

@Component({
  selector: 'app-profile',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './profile.html',
  styleUrl: './profile.scss'
})
export class ProfileComponent implements OnInit {
  workshop: Workshop | null = null;
  loading = false;
  saving = false;
  success = '';
  error = '';

  form = { name: '', phone: '', address: '', capacity: 1, specialties: '' };

  constructor(private ws: WorkshopService) {}

  ngOnInit(): void {
    setTimeout(() => { this.loading = false; }, 3000);
    this.ws.getProfile().subscribe({
      next: (w) => {
        this.workshop = w;
        this.form = {
          name: w.name,
          phone: w.phone || '',
          address: w.address || '',
          capacity: w.capacity,
          specialties: w.specialties?.join(', ') || ''
        };
        this.loading = false;
      },
      error: () => { this.loading = false; }
    });
  }

  save(): void {
    this.saving = true;
    this.error = '';
    this.success = '';

    const data: any = {
      name: this.form.name,
      phone: this.form.phone,
      address: this.form.address,
      capacity: this.form.capacity,
      specialties: this.form.specialties.split(',').map(s => s.trim()).filter(s => s)
    };

    this.ws.updateProfile(data).subscribe({
      next: () => {
        this.success = 'Perfil actualizado correctamente';
        this.saving = false;
      },
      error: (err) => {
        this.error = err.error?.detail || 'Error al actualizar';
        this.saving = false;
      }
    });
  }
}
