import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { CommonModule } from '@angular/common';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './register.html',
  styleUrl: './register.scss'
})
export class RegisterComponent implements OnInit {
  form: FormGroup;
  error = '';
  success = '';
  loading = false;
  tenants: any[] = [];

  constructor(private fb: FormBuilder, private http: HttpClient, private router: Router) {
    this.form = this.fb.group({
      name: ['', [Validators.required, Validators.minLength(3)]],
      email: ['', [Validators.required, Validators.email]],
      phone: ['', [Validators.required, Validators.minLength(7)]],
      address: ['', [Validators.required]],
      tenant_id: ['', [Validators.required]],
      password: ['', [Validators.required, Validators.minLength(6)]],
      confirmPassword: ['', Validators.required]
    });
  }

  ngOnInit(): void {
    this.http.get<any[]>(`${environment.apiUrl}/tenants`).subscribe({
      next: (res) => {
        this.tenants = res;
      },
      error: () => {
        this.tenants = [];
      }
    });
  }

  onSubmit(): void {
    if (this.form.invalid) return;

    const { confirmPassword, ...data } = this.form.value;
    if (data.password !== confirmPassword) {
      this.error = 'Las contraseñas no coinciden';
      return;
    }

    this.loading = true;
    this.error = '';
    this.success = '';

    const payload = {
      ...data,
      tenant_id: Number(data.tenant_id),
      latitude: -17.7833, // Coordenadas por defecto (Santa Cruz)
      longitude: -63.1822,
      capacity: 5,
      specialties: ['battery', 'tire', 'engine', 'crash', 'other'] // Especialidades por defecto
    };

    this.http.post(`${environment.apiUrl}/auth/register/workshop`, payload).subscribe({
      next: () => {
        this.success = '¡Taller registrado exitosamente! Redirigiendo al login...';
        this.loading = false;
        setTimeout(() => this.router.navigate(['/login']), 2000);
      },
      error: (err) => {
        this.error = err.error?.detail || 'Error al registrar el taller. Intente nuevamente.';
        this.loading = false;
      }
    });
  }
}
