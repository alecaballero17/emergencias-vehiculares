import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { environment } from '../../../environments/environment';

interface Tenant {
  id: number;
  name: string;
  slug: string;
  is_active: boolean;
}

@Component({
  selector: 'app-tenants',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './tenants.html',
  styleUrl: './tenants.scss'
})
export class TenantsComponent implements OnInit {
  tenants: Tenant[] = [];
  loading = true;
  error = '';
  success = '';

  // Formulario de creación/edición
  showModal = false;
  isEdit = false;
  editingId: number | null = null;
  formName = '';
  formSlug = '';
  formActive = true;
  actionLoading = false;

  private readonly api = `${environment.apiUrl}/tenants`;

  constructor(private http: HttpClient, private cd: ChangeDetectorRef) {}

  ngOnInit(): void {
    this.loadTenants();
  }

  getHeaders() {
    const token = localStorage.getItem('token');
    return {
      headers: new HttpHeaders({
        'Authorization': `Bearer ${token}`
      })
    };
  }

  loadTenants(): void {
    this.loading = true;
    this.error = '';
    this.http.get<Tenant[]>(`${this.api}/admin`, this.getHeaders()).subscribe({
      next: (res) => {
        this.tenants = res;
        this.loading = false;
        this.cd.detectChanges();
      },
      error: (err) => {
        this.error = err.error?.detail || 'No se pudieron cargar los tenants de la plataforma';
        this.loading = false;
        this.cd.detectChanges();
      }
    });
  }

  openCreateModal(): void {
    this.isEdit = false;
    this.editingId = null;
    this.formName = '';
    this.formSlug = '';
    this.formActive = true;
    this.showModal = true;
    this.error = '';
    this.success = '';
  }

  openEditModal(tenant: Tenant): void {
    this.isEdit = true;
    this.editingId = tenant.id;
    this.formName = tenant.name;
    this.formSlug = tenant.slug;
    this.formActive = tenant.is_active;
    this.showModal = true;
    this.error = '';
    this.success = '';
  }

  closeModal(): void {
    this.showModal = false;
  }

  saveTenant(): void {
    if (!this.formName.trim() || !this.formSlug.trim()) {
      this.error = 'El nombre y el slug son obligatorios';
      return;
    }

    this.actionLoading = true;
    this.error = '';
    this.success = '';

    const payload = {
      name: this.formName,
      slug: this.formSlug.toLowerCase().replace(/[^a-z0-9-_]/g, ''),
      is_active: this.formActive
    };

    if (this.isEdit && this.editingId) {
      this.http.put<Tenant>(`${this.api}/${this.editingId}`, payload, this.getHeaders()).subscribe({
        next: () => {
          this.success = 'Tenant actualizado correctamente';
          this.actionLoading = false;
          this.cd.detectChanges();
          setTimeout(() => {
            this.closeModal();
            this.loadTenants();
          }, 1000);
        },
        error: (err) => {
          this.error = err.error?.detail || 'Error al actualizar el tenant';
          this.actionLoading = false;
          this.cd.detectChanges();
        }
      });
    } else {
      this.http.post<Tenant>(`${this.api}/`, payload, this.getHeaders()).subscribe({
        next: () => {
          this.success = 'Tenant creado exitosamente';
          this.actionLoading = false;
          this.cd.detectChanges();
          setTimeout(() => {
            this.closeModal();
            this.loadTenants();
          }, 1000);
        },
        error: (err) => {
          this.error = err.error?.detail || 'Error al crear el tenant';
          this.actionLoading = false;
          this.cd.detectChanges();
        }
      });
    }
  }

  toggleTenantStatus(tenant: Tenant): void {
    const newStatus = !tenant.is_active;
    this.http.put<Tenant>(`${this.api}/${tenant.id}`, { is_active: newStatus }, this.getHeaders()).subscribe({
      next: () => {
        tenant.is_active = newStatus;
        this.cd.detectChanges();
      },
      error: (err) => {
        alert(err.error?.detail || 'Error al cambiar estado del tenant');
        this.cd.detectChanges();
      }
    });
  }
}
