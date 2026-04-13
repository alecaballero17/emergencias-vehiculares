import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { Vehicle, VehicleCreate } from '../models/interfaces';

@Injectable({ providedIn: 'root' })
export class VehicleService {
  private readonly api = `${environment.apiUrl}/vehicles`;

  constructor(private http: HttpClient) {}

  list(): Observable<Vehicle[]> {
    return this.http.get<Vehicle[]>(`${this.api}/`);
  }

  get(id: number): Observable<Vehicle> {
    return this.http.get<Vehicle>(`${this.api}/${id}`);
  }

  create(data: VehicleCreate): Observable<Vehicle> {
    return this.http.post<Vehicle>(`${this.api}/`, data);
  }

  update(id: number, data: Partial<VehicleCreate>): Observable<Vehicle> {
    return this.http.put<Vehicle>(`${this.api}/${id}`, data);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.api}/${id}`);
  }
}
