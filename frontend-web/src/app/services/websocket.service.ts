import { Injectable } from '@angular/core';
import { Subject, Observable, BehaviorSubject } from 'rxjs';
import { environment } from '../../environments/environment';

@Injectable({ providedIn: 'root' })
export class WebSocketService {
  private socket: WebSocket | null = null;
  private messageSubject$ = new Subject<any>();
  private connectionStatusSubject$ = new BehaviorSubject<boolean>(false);

  constructor() {}

  connect(): void {
    // Evitar crear múltiples sockets si ya está abierto o conectando
    if (this.socket && (this.socket.readyState === WebSocket.OPEN || this.socket.readyState === WebSocket.CONNECTING)) {
      return;
    }

    const token = localStorage.getItem('token');
    if (!token) return;

    let wsUrl = environment.apiUrl;
    wsUrl = wsUrl.replace('/api', '');
    if (wsUrl.startsWith('https://')) {
      wsUrl = wsUrl.replace('https://', 'wss://');
    } else if (wsUrl.startsWith('http://')) {
      wsUrl = wsUrl.replace('http://', 'ws://');
    }
    
    try {
      this.socket = new WebSocket(`${wsUrl}/ws/${token}`);

      this.socket.onopen = () => {
        console.log('[WS] Connected successfully');
        this.connectionStatusSubject$.next(true);
      };

      this.socket.onmessage = (event) => {
        try {
          const parsed = JSON.parse(event.data);
          this.messageSubject$.next(parsed);
        } catch (e) {
          console.error('[WS] Error parsing message:', e);
        }
      };

      this.socket.onerror = (err) => {
        console.error('[WS] Error:', err);
      };

      this.socket.onclose = () => {
        console.log('[WS] Connection closed. Reconnecting in 5s...');
        this.connectionStatusSubject$.next(false);
        setTimeout(() => this.connect(), 5000);
      };
    } catch (e) {
      console.error('[WS] Exception during connection setup:', e);
      this.connectionStatusSubject$.next(false);
      setTimeout(() => this.connect(), 5000);
    }
  }

  get messages$(): Observable<any> {
    return this.messageSubject$.asObservable();
  }

  get status$(): Observable<boolean> {
    return this.connectionStatusSubject$.asObservable();
  }

  subscribeIncident(incidentId: number): void {
    if (this.socket && this.socket.readyState === WebSocket.OPEN) {
      this.socket.send(JSON.stringify({
        type: 'subscribe_incident',
        incident_id: incidentId
      }));
    }
  }

  sendLocationUpdate(incidentId: number, lat: number, lng: number, eta?: number): void {
    if (this.socket && this.socket.readyState === WebSocket.OPEN) {
      this.socket.send(JSON.stringify({
        type: 'location_update',
        incident_id: incidentId,
        latitude: lat,
        longitude: lng,
        eta_minutes: eta
      }));
    }
  }

  disconnect(): void {
    if (this.socket) {
      this.socket.onclose = null;
      this.socket.close();
      this.socket = null;
      this.connectionStatusSubject$.next(false);
    }
  }
}
