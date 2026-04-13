import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { VehicleService } from '../../services/vehicle.service';
import { Vehicle } from '../../models/interfaces';

@Component({
  selector: 'app-vehicles',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './vehicles.html',
  styleUrl: './vehicles.scss'
})
export class VehiclesComponent implements OnInit {
  vehicles: Vehicle[] = [];
  form: FormGroup;
  loading = true;
  saving = false;
  error = '';
  success = '';
  showForm = false;
  editingId: number | null = null;
  deleteConfirmId: number | null = null;

  constructor(private vehicleService: VehicleService, private fb: FormBuilder, private cdr: ChangeDetectorRef) {
    this.form = this.fb.group({
      brand: ['', Validators.required],
      model: ['', Validators.required],
      year: [2024, [Validators.required, Validators.min(1990), Validators.max(2030)]],
      color: ['', Validators.required],
      license_plate: ['', Validators.required],
      vin: ['']
    });
  }

  ngOnInit(): void {
    this.loadVehicles();
  }

  loadVehicles(): void {
    this.loading = true;
    this.vehicleService.list().subscribe({
      next: (data) => { this.vehicles = data; this.loading = false; this.cdr.detectChanges(); },
      error: (err) => { console.error('[Vehicles] Error:', err); this.error = 'Error al cargar vehículos'; this.loading = false; this.cdr.detectChanges(); }
    });
  }

  openCreate(): void {
    this.editingId = null;
    this.form.reset({ year: 2024 });
    this.showForm = true;
    this.error = '';
    this.success = '';
  }

  openEdit(v: Vehicle): void {
    this.editingId = v.id;
    this.form.patchValue({
      brand: v.brand,
      model: v.model,
      year: v.year,
      color: v.color,
      license_plate: v.license_plate,
      vin: v.vin || ''
    });
    this.showForm = true;
    this.error = '';
    this.success = '';
  }

  cancelForm(): void {
    this.showForm = false;
    this.editingId = null;
  }

  onSubmit(): void {
    if (this.form.invalid) return;
    this.saving = true;
    this.error = '';

    const data = this.form.value;
    const obs = this.editingId
      ? this.vehicleService.update(this.editingId, data)
      : this.vehicleService.create(data);

    obs.subscribe({
      next: () => {
        this.success = this.editingId ? 'Vehículo actualizado correctamente' : 'Vehículo registrado correctamente';
        this.saving = false;
        this.showForm = false;
        this.editingId = null;
        this.loadVehicles();
        setTimeout(() => this.success = '', 3000);
      },
      error: (err) => {
        this.error = err.error?.detail || 'Error al guardar el vehículo';
        this.saving = false;
      }
    });
  }

  confirmDelete(id: number): void {
    this.deleteConfirmId = id;
  }

  cancelDelete(): void {
    this.deleteConfirmId = null;
  }

  deleteVehicle(id: number): void {
    this.vehicleService.delete(id).subscribe({
      next: () => {
        this.success = 'Vehículo eliminado correctamente';
        this.deleteConfirmId = null;
        this.loadVehicles();
        setTimeout(() => this.success = '', 3000);
      },
      error: (err) => {
        this.error = err.error?.detail || 'Error al eliminar';
        this.deleteConfirmId = null;
      }
    });
  }
}
