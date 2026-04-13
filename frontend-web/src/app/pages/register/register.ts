import { Component } from '@angular/core';
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
export class RegisterComponent {
  form: FormGroup;
  error = '';
  success = '';
  loading = false;

  constructor(private fb: FormBuilder, private http: HttpClient, private router: Router) {
    this.form = this.fb.group({
      full_name: ['', [Validators.required, Validators.minLength(3)]],
      email: ['', [Validators.required, Validators.email]],
      phone: ['', [Validators.required, Validators.minLength(7)]],
      password: ['', [Validators.required, Validators.minLength(6)]],
      confirmPassword: ['', Validators.required]
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

    this.http.post(`${environment.apiUrl}/auth/register/user`, data).subscribe({
      next: () => {
        this.success = '¡Cuenta creada exitosamente! Redirigiendo al login...';
        this.loading = false;
        setTimeout(() => this.router.navigate(['/login']), 2000);
      },
      error: (err) => {
        this.error = err.error?.detail || 'Error al registrar. Intente nuevamente.';
        this.loading = false;
      }
    });
  }
}
