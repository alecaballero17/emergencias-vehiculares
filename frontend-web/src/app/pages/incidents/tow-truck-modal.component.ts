import { Component, Input, Output, EventEmitter, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TowTruckService, NearestWorkshop } from '../../services/tow-truck.service';

/**
 * Modal para selección de grúa con estimaciones de precio
 * Se muestra al reportar un incidente
 */
@Component({
  selector: 'app-tow-truck-modal',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="modal-overlay" *ngIf="isOpen" (click)="closeModal()">
      <div class="modal-content" (click)="$event.stopPropagation()">
        <div class="modal-header">
          <h2>🚗 ¿Necesita grúa?</h2>
          <button class="close-btn" (click)="closeModal()">✕</button>
        </div>

        <div class="modal-body">
          <!-- Opción: Sin grúa -->
          <div class="option-group">
            <label class="radio-option">
              <input type="radio" [(ngModel)]="selectedOption" value="no-tow" />
              <span class="label-text">
                <strong>No necesito grúa</strong>
                <small>Solo servicio de emergencia</small>
              </span>
            </label>
          </div>

          <!-- Opción: Con grúa -->
          <div class="option-group">
            <label class="radio-option">
              <input
                type="radio"
                [(ngModel)]="selectedOption"
                value="tow"
                (change)="loadNearestWorkshops()"
              />
              <span class="label-text">
                <strong>Sí necesito grúa</strong>
                <small>Servicio de remolque incluido</small>
              </span>
            </label>

            <!-- Talleres disponibles -->
            <div class="workshops-list" *ngIf="selectedOption === 'tow' && !loadingWorkshops">
              <div class="workshop-item" *ngFor="let workshop of nearestWorkshops">
                <div class="workshop-info">
                  <h4>{{ workshop.workshop_name }}</h4>
                  <p class="distance">
                    📍 {{ workshop.distance_km }} km de distancia
                  </p>
                  <p class="time">⏱️ Tiempo estimado: {{ formatTime(workshop.estimated_time_minutes) }}</p>
                </div>
                <div class="workshop-cost">
                  <span class="cost-value">{{ workshop.estimated_cost | currency: 'BOB' }}</span>
                  <button (click)="selectWorkshop(workshop)" class="btn-select">
                    Seleccionar
                  </button>
                </div>
              </div>
            </div>

            <!-- Cargando -->
            <div class="loading" *ngIf="selectedOption === 'tow' && loadingWorkshops">
              <p>🔄 Buscando talleres más cercanos...</p>
            </div>

            <!-- Error -->
            <div class="error" *ngIf="selectedOption === 'tow' && errorMessage">
              <p>❌ {{ errorMessage }}</p>
            </div>
          </div>
        </div>

        <div class="modal-footer">
          <button (click)="confirmSelection()" class="btn-confirm" [disabled]="!selectedOption">
            Confirmar
          </button>
          <button (click)="closeModal()" class="btn-cancel">Cancelar</button>
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      .modal-overlay {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        justify-content: center;
        align-items: center;
        z-index: 1000;
      }

      .modal-content {
        background: white;
        border-radius: 12px;
        box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2);
        max-width: 500px;
        width: 90%;
        max-height: 80vh;
        overflow-y: auto;
      }

      .modal-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 20px;
        border-bottom: 1px solid #eee;
      }

      .modal-header h2 {
        margin: 0;
        color: #333;
        font-size: 20px;
      }

      .close-btn {
        background: none;
        border: none;
        font-size: 24px;
        cursor: pointer;
        color: #999;
      }

      .modal-body {
        padding: 20px;
      }

      .option-group {
        margin-bottom: 20px;
      }

      .radio-option {
        display: flex;
        align-items: flex-start;
        cursor: pointer;
        padding: 12px;
        border: 2px solid #eee;
        border-radius: 8px;
        transition: all 0.3s ease;
      }

      .radio-option:hover {
        border-color: #1976d2;
        background: #f0f7ff;
      }

      input[type='radio'] {
        margin-right: 12px;
        margin-top: 4px;
        cursor: pointer;
      }

      .label-text {
        display: flex;
        flex-direction: column;
        gap: 4px;
      }

      .label-text strong {
        color: #333;
        font-size: 16px;
      }

      .label-text small {
        color: #999;
        font-size: 12px;
      }

      .workshops-list {
        margin-top: 12px;
        padding-left: 20px;
      }

      .workshop-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 12px;
        background: #f9f9f9;
        border-radius: 8px;
        margin-bottom: 10px;
      }

      .workshop-info h4 {
        margin: 0 0 8px 0;
        color: #333;
        font-size: 14px;
      }

      .workshop-info p {
        margin: 4px 0;
        font-size: 12px;
        color: #666;
      }

      .workshop-cost {
        text-align: right;
        display: flex;
        flex-direction: column;
        align-items: flex-end;
        gap: 8px;
      }

      .cost-value {
        font-size: 18px;
        font-weight: bold;
        color: #4caf50;
      }

      .btn-select {
        padding: 6px 12px;
        background-color: #1976d2;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-size: 12px;
      }

      .btn-select:hover {
        background-color: #1565c0;
      }

      .loading,
      .error {
        padding: 12px;
        border-radius: 8px;
        text-align: center;
        font-size: 14px;
      }

      .loading {
        background: #e3f2fd;
        color: #1565c0;
      }

      .error {
        background: #ffebee;
        color: #c62828;
      }

      .modal-footer {
        padding: 20px;
        border-top: 1px solid #eee;
        display: flex;
        gap: 10px;
        justify-content: flex-end;
      }

      .btn-confirm,
      .btn-cancel {
        padding: 10px 20px;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-weight: 500;
      }

      .btn-confirm {
        background-color: #4caf50;
        color: white;
      }

      .btn-confirm:hover:not(:disabled) {
        background-color: #388e3c;
      }

      .btn-confirm:disabled {
        background-color: #ccc;
        cursor: not-allowed;
      }

      .btn-cancel {
        background-color: #f0f0f0;
        color: #333;
      }

      .btn-cancel:hover {
        background-color: #e0e0e0;
      }
    `,
  ],
})
export class TowTruckModalComponent implements OnInit {
  @Input() isOpen = false;
  @Input() clientLat = 0;
  @Input() clientLon = 0;
  @Output() close = new EventEmitter<void>();
  @Output() confirm = new EventEmitter<{ needsTow: boolean; workshopId?: number; cost?: number }>();

  selectedOption: string | null = null;
  nearestWorkshops: NearestWorkshop[] = [];
  loadingWorkshops = false;
  errorMessage = '';
  selectedWorkshop: NearestWorkshop | null = null;

  constructor(private towTruckService: TowTruckService) {}

  ngOnInit(): void {}

  async loadNearestWorkshops(): Promise<void> {
    this.loadingWorkshops = true;
    this.errorMessage = '';

    try {
      this.towTruckService
        .getNearestWorkshops(this.clientLat, this.clientLon)
        .subscribe({
          next: (workshops) => {
            this.nearestWorkshops = workshops;
            this.loadingWorkshops = false;
          },
          error: (error) => {
            this.errorMessage = 'No se pudieron cargar los talleres disponibles';
            this.loadingWorkshops = false;
            console.error('Error:', error);
          },
        });
    } catch (error) {
      this.errorMessage = 'Error al buscar talleres';
      this.loadingWorkshops = false;
    }
  }

  selectWorkshop(workshop: NearestWorkshop): void {
    this.selectedWorkshop = workshop;
  }

  formatTime(minutes: number): string {
    return this.towTruckService.formatTime(minutes);
  }

  confirmSelection(): void {
    if (this.selectedOption === 'no-tow') {
      this.confirm.emit({ needsTow: false });
    } else if (this.selectedOption === 'tow' && this.selectedWorkshop) {
      this.confirm.emit({
        needsTow: true,
        workshopId: this.selectedWorkshop.workshop_id,
        cost: this.selectedWorkshop.estimated_cost,
      });
    }
    this.closeModal();
  }

  closeModal(): void {
    this.isOpen = false;
    this.selectedOption = null;
    this.selectedWorkshop = null;
    this.close.emit();
  }
}
