import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';

interface PendingPayment {
  id: number;
  incident_id: number;
  amount: number;
  cancellation_fee: number;
  payment_status: string;
  created_at: string;
  incident: {
    description: string;
    status: string;
    created_at: string;
  };
}

/**
 * Componente para mostrar pagos pendientes
 * Se muestra cuando hay penalizaciones por cancelación
 */
@Component({
  selector: 'app-pending-payments',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="pending-payments-container">
      <h2>💳 Pagos Pendientes</h2>

      <div *ngIf="pendingPayments.length === 0" class="no-payments">
        <p>✅ No tienes pagos pendientes</p>
      </div>

      <div *ngIf="pendingPayments.length > 0" class="payments-list">
        <div class="payment-card" *ngFor="let payment of pendingPayments">
          <div class="payment-header">
            <h3>Incidente #{{ payment.incident_id }}</h3>
            <span class="status" [ngClass]="payment.payment_status.toLowerCase()">
              {{ payment.payment_status }}
            </span>
          </div>

          <div class="payment-details">
            <p class="description">{{ payment.incident.description }}</p>
            <p class="date">
              📅 {{ payment.created_at | date: 'short' }}
            </p>

            <div class="amount-section">
              <div *ngIf="payment.cancellation_fee" class="fee-row">
                <span>Penalización por cancelación:</span>
                <strong>BOB {{ payment.cancellation_fee.toFixed(2) }}</strong>
              </div>
              <div class="total-row">
                <span>Total a pagar:</span>
                <strong class="total-amount">BOB {{ payment.amount.toFixed(2) }}</strong>
              </div>
            </div>

            <button class="btn-pay" (click)="goToPayment(payment)">
              Pagar Ahora
            </button>
          </div>
        </div>
      </div>

      <div class="info-box" *ngIf>
        <p>
          ℹ️ Cuando cancelas un incidente después de que el mecánico está en camino, se aplica
          una penalización de BOB 50. Debes realizar el pago para completar tu registro.
        </p>
      </div>
    </div>
  `,
  styles: [
    `
      .pending-payments-container {
        padding: 20px;
        max-width: 600px;
        margin: 0 auto;
      }

      h2 {
        color: #ff5722;
        margin-bottom: 20px;
      }

      .no-payments {
        background: #e8f5e9;
        border-left: 4px solid #4caf50;
        padding: 15px;
        border-radius: 4px;
        text-align: center;
        color: #2e7d32;
      }

      .payments-list {
        display: flex;
        flex-direction: column;
        gap: 15px;
      }

      .payment-card {
        background: white;
        border: 1px solid #e0e0e0;
        border-radius: 8px;
        padding: 15px;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        transition: box-shadow 0.3s ease;
      }

      .payment-card:hover {
        box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
      }

      .payment-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 12px;
        border-bottom: 1px solid #f0f0f0;
        padding-bottom: 10px;
      }

      .payment-header h3 {
        margin: 0;
        font-size: 16px;
        color: #333;
      }

      .status {
        padding: 4px 12px;
        border-radius: 12px;
        font-size: 12px;
        font-weight: 600;
        text-transform: uppercase;
      }

      .status.pending {
        background-color: #fff3cd;
        color: #856404;
      }

      .status.completed {
        background-color: #d4edda;
        color: #155724;
      }

      .status.failed {
        background-color: #f8d7da;
        color: #721c24;
      }

      .payment-details {
        display: flex;
        flex-direction: column;
        gap: 10px;
      }

      .description {
        margin: 0;
        font-size: 14px;
        color: #666;
      }

      .date {
        margin: 0;
        font-size: 12px;
        color: #999;
      }

      .amount-section {
        background: #f9f9f9;
        padding: 12px;
        border-radius: 6px;
        margin: 8px 0;
      }

      .fee-row,
      .total-row {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin: 6px 0;
        font-size: 14px;
      }

      .total-row {
        border-top: 1px solid #e0e0e0;
        padding-top: 8px;
        margin-top: 8px;
      }

      .total-amount {
        font-size: 18px;
        color: #ff5722;
      }

      .btn-pay {
        padding: 10px 16px;
        background-color: #1976d2;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-weight: 500;
        margin-top: 8px;
        transition: background-color 0.3s ease;
      }

      .btn-pay:hover {
        background-color: #1565c0;
      }

      .info-box {
        background-color: #e3f2fd;
        border-left: 4px solid #1976d2;
        padding: 12px;
        border-radius: 4px;
        margin-top: 20px;
      }

      .info-box p {
        margin: 0;
        color: #0d47a1;
        font-size: 13px;
      }
    `,
  ],
})
export class PendingPaymentsComponent implements OnInit {
  pendingPayments: PendingPayment[] = [];
  loading = false;
  apiUrl = environment.apiUrl || 'http://localhost:8000/api';

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.loadPendingPayments();
  }

  loadPendingPayments(): void {
    this.loading = true;
    this.http
      .get<{ data: PendingPayment[] }>(
        `${this.apiUrl}/payments/pending`
      )
      .subscribe({
        next: (response) => {
          this.pendingPayments = response.data || [];
          this.loading = false;
        },
        error: (error) => {
          console.error('Error cargando pagos pendientes:', error);
          this.loading = false;
        },
      });
  }

  goToPayment(payment: PendingPayment): void {
    // Navegar a formulario de pago
    window.location.href = `/finance/payments/${payment.id}`;
  }
}
