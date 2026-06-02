import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { Workshop, Technician, Incident, IncidentDetail, Notification } from '../models/interfaces';

@Injectable({ providedIn: 'root' })
export class WorkshopService {
  private readonly api = environment.apiUrl;

  constructor(private http: HttpClient) {}

  // === Perfil ===
  getProfile(): Observable<Workshop> {
    return this.http.get<Workshop>(`${this.api}/workshops/me`);
  }

  updateProfile(data: Partial<Workshop>): Observable<Workshop> {
    return this.http.put<Workshop>(`${this.api}/workshops/me`, data);
  }

  // === Técnicos ===
  getTechnicians(): Observable<Technician[]> {
    return this.http.get<Technician[]>(`${this.api}/workshops/technicians`);
  }

  addTechnician(data: Partial<Technician>): Observable<Technician> {
    return this.http.post<Technician>(`${this.api}/workshops/technicians`, data);
  }

  updateTechnician(id: number, data: Partial<Technician>): Observable<Technician> {
    return this.http.put<Technician>(`${this.api}/workshops/technicians/${id}`, data);
  }

  deleteTechnician(id: number): Observable<any> {
    return this.http.delete(`${this.api}/workshops/technicians/${id}`);
  }

  // === Incidentes ===
  getAssignedIncidents(status?: string): Observable<Incident[]> {
    let params = new HttpParams();
    if (status) params = params.set('status', status);
    return this.http.get<Incident[]>(`${this.api}/workshops/incidents`, { params });
  }

  getAvailableIncidents(): Observable<Incident[]> {
    return this.http.get<Incident[]>(`${this.api}/workshops/incidents/available`);
  }

  getIncidentDetail(id: number): Observable<IncidentDetail> {
    return this.http.get<IncidentDetail>(`${this.api}/workshops/incidents/${id}`);
  }

  acceptIncident(id: number, technicianId: number): Observable<any> {
    return this.http.put(`${this.api}/workshops/incidents/${id}/accept`, { technician_id: technicianId });
  }

  rejectIncident(id: number, reason?: string): Observable<any> {
    return this.http.put(`${this.api}/workshops/incidents/${id}/reject`, { reason });
  }

  completeIncident(id: number, cost: number, notes?: string): Observable<any> {
    return this.http.put(`${this.api}/workshops/incidents/${id}/complete`, { final_cost: cost, notes });
  }

  // === Cotizaciones & Fase 2 Transiciones ===
  sendQuotation(incidentId: number, amount: number, hours: number, description: string): Observable<any> {
    return this.http.post(`${this.api}/quotations/${incidentId}`, {
      amount,
      estimated_repair_hours: hours,
      description
    });
  }

  markEnRoute(id: number): Observable<any> {
    return this.http.put(`${this.api}/workshops/incidents/${id}/en-route`, {});
  }

  markArrived(id: number): Observable<any> {
    return this.http.put(`${this.api}/workshops/incidents/${id}/arrive`, {});
  }

  // === Notificaciones ===
  getNotifications(unreadOnly = false): Observable<Notification[]> {
    let params = new HttpParams();
    if (unreadOnly) params = params.set('unread_only', 'true');
    return this.http.get<Notification[]>(`${this.api}/notifications/workshop`, { params });
  }

  markNotificationRead(id: number): Observable<any> {
    return this.http.put(`${this.api}/notifications/${id}/read`, {});
  }
}
