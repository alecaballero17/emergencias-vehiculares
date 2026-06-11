import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../environments/environment';
import { BehaviorSubject, Observable, firstValueFrom } from 'rxjs';

/**
 * Servicio de notificaciones push con manejo de Firebase Cloud Messaging
 * Incluye:
 * - Registro de tokens FCM
 * - Refresh periódico de tokens
 * - Sincronización de notificaciones
 * - Reintentos automáticos
 */

interface NotificationPermission {
  granted: boolean;
  timestamp: Date;
}

@Injectable({
  providedIn: 'root',
})
export class NotificationService {
  private apiUrl = environment.apiUrl || 'http://localhost:8000/api';
  private notificationsSubject = new BehaviorSubject<any[]>([]);
  public notifications$ = this.notificationsSubject.asObservable();

  private tokenRefreshInterval = 24 * 60 * 60 * 1000; // 24 horas
  private readonly TOKEN_STORAGE_KEY = 'fcm_token';
  private readonly TOKEN_EXPIRY_KEY = 'fcm_token_expiry';

  constructor(private http: HttpClient) {}

  /**
   * Inicializar notificaciones push
   * Se debe llamar después del login
   */
  async initializePushNotifications(): Promise<boolean> {
    if (!this.isPushNotificationSupported()) {
      console.warn('Las notificaciones push no son soportadas en este navegador');
      return false;
    }

    try {
      // Registrar Service Worker
      const registration = await this.registerServiceWorker();

      // Solicitar permiso al usuario
      const permission = await this.requestNotificationPermission();
      if (!permission) {
        console.log('El usuario rechazó las notificaciones push');
        return false;
      }

      // Obtener y guardar token FCM
      await this.refreshFCMToken();

      // Configurar refresh periódico de tokens
      this.scheduleTokenRefresh();

      // Escuchar mensajes del Service Worker
      this.setupServiceWorkerMessages();

      console.log('✅ Notificaciones push inicializadas correctamente');
      return true;
    } catch (error) {
      console.error('❌ Error inicializando notificaciones push:', error);
      return false;
    }
  }

  /**
   * Registrar Service Worker con reintentos
   */
  private async registerServiceWorker(maxRetries: number = 3): Promise<ServiceWorkerRegistration> {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        console.log(`Registrando Service Worker (intento ${attempt}/${maxRetries})...`);
        const registration = await navigator.serviceWorker.register('/service-worker-notifications.js');
        console.log('✅ Service Worker registrado:', registration);

        // Recargar Service Worker si hay actualizaciones
        registration.addEventListener('updatefound', () => {
          const newWorker = registration.installing;
          if (newWorker) {
            newWorker.addEventListener('statechange', () => {
              if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                console.log('🔄 Nueva versión del Service Worker disponible');
                // Notificar al usuario sobre actualización
                this.notifyUpdate();
              }
            });
          }
        });

        return registration;
      } catch (error) {
        console.error(`Intento ${attempt} fallido:`, error);
        if (attempt < maxRetries) {
          await this.delay(2 ** attempt * 1000); // Backoff exponencial
        } else {
          throw error;
        }
      }
    }
    throw new Error('No se pudo registrar el Service Worker');
  }

  /**
   * Solicitar permiso de notificaciones al usuario
   */
  private async requestNotificationPermission(): Promise<boolean> {
    if (Notification.permission === 'granted') {
      return true;
    }

    if (Notification.permission !== 'denied') {
      try {
        const permission = await Notification.requestPermission();
        return permission === 'granted';
      } catch (error) {
        console.error('Error solicitando permiso:', error);
        return false;
      }
    }

    return false;
  }

  /**
   * Obtener y guardar token FCM con reintentos
   */
  private async refreshFCMToken(maxRetries: number = 3): Promise<void> {
    // Verificar si el token aún es válido (menos de 24 horas)
    const storedToken = localStorage.getItem(this.TOKEN_STORAGE_KEY);
    const tokenExpiry = localStorage.getItem(this.TOKEN_EXPIRY_KEY);
    const now = new Date().getTime();

    if (storedToken && tokenExpiry && now < parseInt(tokenExpiry)) {
      console.log('✅ Token FCM válido');
      return;
    }

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Nota: Aquí deberías integrar Firebase SDK
        // Por ahora, usamos un token genérico de SessionStorage
        const token = this.generateToken();
        const expiry = new Date().getTime() + this.tokenRefreshInterval;

        localStorage.setItem(this.TOKEN_STORAGE_KEY, token);
        localStorage.setItem(this.TOKEN_EXPIRY_KEY, expiry.toString());

        // Enviar token al servidor (opcional)
        await this.sendTokenToServer(token);

        console.log('✅ Token FCM actualizado');
        return;
      } catch (error) {
        console.error(`Intento ${attempt} fallido:`, error);
        if (attempt < maxRetries) {
          await this.delay(1000);
        } else {
          console.error('❌ No se pudo obtener token FCM');
        }
      }
    }
  }

  /**
   * Enviar token FCM al servidor
   */
  private sendTokenToServer(token: string): Promise<any> {
    return firstValueFrom(this.http.post(`${this.apiUrl}/notifications/register-token`, { token }));
  }

  /**
   * Programar refresh periódico de tokens
   */
  private scheduleTokenRefresh(): void {
    setInterval(() => {
      console.log('🔄 Refrescando token FCM...');
      this.refreshFCMToken();
    }, this.tokenRefreshInterval);
  }

  /**
   * Configurar listeners de mensajes desde el Service Worker
   */
  private setupServiceWorkerMessages(): void {
    if (!('serviceWorker' in navigator)) return;

    navigator.serviceWorker.addEventListener('message', (event) => {
      console.log('📨 Mensaje del SW:', event.data);

      if (event.data.type === 'notification') {
        // Actualizar lista de notificaciones
        const current = this.notificationsSubject.value;
        this.notificationsSubject.next([event.data, ...current]);
      }
    });
  }

  /**
   * Obtener notificaciones del usuario
   */
  getUserNotifications(unreadOnly: boolean = false): Observable<any[]> {
    const url = unreadOnly
      ? `${this.apiUrl}/notifications/user?unread_only=true`
      : `${this.apiUrl}/notifications/user`;
    return this.http.get<any[]>(url);
  }

  /**
   * Marcar notificación como leída
   */
  markAsRead(notificationId: number): Observable<any> {
    return this.http.put(`${this.apiUrl}/notifications/${notificationId}/read`, {});
  }

  /**
   * Verificar si las notificaciones push son soportadas
   */
  private isPushNotificationSupported(): boolean {
    return 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window;
  }

  /**
   * Generar token simulado (reemplazar con Firebase)
   */
  private generateToken(): string {
    return `token_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Delay auxiliar
   */
  private delay(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  /**
   * Notificar sobre actualización de Service Worker
   */
  private notifyUpdate(): void {
    const message = '📦 Nueva versión disponible. Recarga la página para actualizarla.';
    console.log(message);
    // Podrías mostrar un toast o snackbar aquí
  }
}
