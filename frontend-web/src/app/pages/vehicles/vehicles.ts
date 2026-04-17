import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { VehicleService } from '../../services/vehicle.service';
import { Vehicle } from '../../models/interfaces';

@Component({
  selector: 'app-vehicles',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './vehicles.html',
  styleUrl: './vehicles.scss'
})
export class VehiclesComponent implements OnInit {
  vehicles: Vehicle[] = [];
  loading = false;
  saving = false;
  error = '';
  showForm = false;
  editingId: number | null = null;

  form = {
    brand: '',
    model: '',
    year: 2024,
    color: '',
    license_plate: '',
    vin: ''
  };

  constructor(private vehicleService: VehicleService) {}

  ngOnInit(): void {
    setTimeout(() => { this.loading = false; }, 3000);
    this.loadVehicles();
  }

  loadVehicles(): void {
    this.vehicleService.list().subscribe({
      next: (data) => { this.vehicles = data; this.loading = false; },
      error: () => { this.error = 'Error al cargar vehículos'; this.loading = false; }
    });
  }

  openNew(): void {
    this.editingId = null;
    this.form = { brand: '', model: '', year: 2024, color: '', license_plate: '', vin: '' };
    this.showForm = true;
    this.error = '';
  }

  openEdit(v: Vehicle): void {
    this.editingId = v.id;
    this.form = {
      brand: v.brand,
      model: v.model,
      year: v.year,
      color: v.color,
      license_plate: v.license_plate,
      vin: v.vin || ''
    };
    this.showForm = true;
    this.error = '';
  }

  save(): void {
    if (!this.form.brand || !this.form.model) return;
    this.saving = true;
    this.error = '';

    const obs = this.editingId
      ? this.vehicleService.update(this.editingId, this.form)
      : this.vehicleService.create(this.form);

    obs.subscribe({
      next: () => {
        this.saving = false;
        this.showForm = false;
        this.editingId = null;
        this.loadVehicles();
      },
      error: (err) => {
        this.error = err.error?.detail || 'Error al guardar';
        this.saving = false;
      }
    });
  }

  deleteVehicle(id: number): void {
    if (!confirm('¿Eliminar este vehículo?')) return;
    this.vehicleService.delete(id).subscribe({
      next: () => this.loadVehicles(),
      error: (err) => { this.error = err.error?.detail || 'Error al eliminar'; }
    });
  }
}
