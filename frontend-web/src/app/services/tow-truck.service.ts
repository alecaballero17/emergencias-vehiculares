import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../environments/environment';
import { Observable } from 'rxjs';

export interface TowTruckEstimateRequest {
  client_latitude: number;
  client_longitude: number;
  workshop_id?: number;
}

export interface TowTruckEstimate {
  distance_km: number;
  base_cost: number;
  distance_cost: number;
  total_cost: number;
  estimated_time_minutes: number;
}

export interface NearestWorkshop {
  workshop_id: number;
  workshop_name: string;
  distance_km: number;
  estimated_cost: number;
  estimated_time_minutes: number;
}

/**
 * Servicio para cálculo de costos de grúa por geolocalización
 */
@Injectable({
  providedIn: 'root',
})
export class TowTruckService {
  private apiUrl = environment.apiUrl || 'http://localhost:8000/api';

  constructor(private http: HttpClient) {}

  /**
   * Obtener estimación de grúa para un taller específico
   */
  estimateTowCost(
    clientLat: number,
    clientLon: number,
    workshopId?: number
  ): Observable<TowTruckEstimate> {
    const request: TowTruckEstimateRequest = {
      client_latitude: clientLat,
      client_longitude: clientLon,
      ...(workshopId && { workshop_id: workshopId }),
    };

    return this.http.post<TowTruckEstimate>(
      `${this.apiUrl}/tow-truck/estimate`,
      request
    );
  }

  /**
   * Obtener los 5 talleres más cercanos con estimaciones
   */
  getNearestWorkshops(
    clientLat: number,
    clientLon: number
  ): Observable<NearestWorkshop[]> {
    const request: TowTruckEstimateRequest = {
      client_latitude: clientLat,
      client_longitude: clientLon,
    };

    return this.http.post<NearestWorkshop[]>(
      `${this.apiUrl}/tow-truck/nearest-workshops`,
      request
    );
  }

  /**
   * Formatear costo para mostrar
   */
  formatCost(cost: number): string {
    return `BOB ${cost.toFixed(2)}`;
  }

  /**
   * Formatear tiempo estimado
   */
  formatTime(minutes: number): string {
    if (minutes < 60) {
      return `${minutes} min`;
    }
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return `${hours}h ${mins}m`;
  }
}
