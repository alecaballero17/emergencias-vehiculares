import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

@Injectable({ providedIn: 'root' })
export class AnalyticsService {
  private readonly api = `${environment.apiUrl}/analytics`;

  constructor(private http: HttpClient) {}

  getAssignmentTime(): Observable<any> {
    return this.http.get(`${this.api}/assignment-time`);
  }

  getArrivalTime(): Observable<any> {
    return this.http.get(`${this.api}/arrival-time`);
  }

  getIncidentsByType(): Observable<any> {
    return this.http.get(`${this.api}/incidents-by-type`);
  }

  getTopWorkshops(): Observable<any> {
    return this.http.get(`${this.api}/top-workshops`);
  }

  getIncidentHeatmap(): Observable<any> {
    return this.http.get(`${this.api}/incident-heatmap`);
  }

  getCancelledCases(): Observable<any> {
    return this.http.get(`${this.api}/cancelled-cases`);
  }

  getSlaCompliance(): Observable<any> {
    return this.http.get(`${this.api}/sla-compliance`);
  }

  getSummary(): Observable<any> {
    return this.http.get(`${this.api}/summary`);
  }
}
