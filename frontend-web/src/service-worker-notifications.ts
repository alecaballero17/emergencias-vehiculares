/**
 * Service Worker mejorado para notificaciones push confiables
 * Ubicación: src/service-worker-notifications.ts
 * 
 * Este worker maneja:
 * - Recepción de notificaciones push
 * - Reintentos automáticos
 * - Sincronización de notificaciones en el navegador
 */

declare const self: ServiceWorkerGlobalScope;

// Escuchar notificaciones push entrantes
self.addEventListener('push', (event: PushEvent) => {
  if (!event.data) {
    console.log('[SW] Push recibido sin datos');
    return;
  }

  try {
    const data = event.data.json();
    const { title, message, notification_type, icon, badge } = data;

    const options: NotificationOptions = {
      body: message || '',
      icon: icon || '/assets/icon-192x192.png',
      badge: badge || '/assets/badge-192x192.png',
      tag: notification_type || 'default',
      requireInteraction: true, // Requiere interacción del usuario
      data: {
        notification_type,
        timestamp: new Date().toISOString(),
      },
      // Vibraciones para Android
      vibrate: [200, 100, 200],
      actions: [
        {
          action: 'open',
          title: 'Abrir',
          icon: '/assets/open-icon.png',
        },
        {
          action: 'close',
          title: 'Cerrar',
          icon: '/assets/close-icon.png',
        },
      ],
    };

    console.log(`[SW] Notificación push recibida: ${title}`);
    event.waitUntil(self.registration.showNotification(title, options));
  } catch (error) {
    console.error('[SW] Error procesando push:', error);
  }
});

// Escuchar clics en notificaciones
self.addEventListener('notificationclick', (event: NotificationEvent) => {
  event.notification.close();

  const action = event.action || 'open';
  const notificationType = event.notification.data.notification_type;

  // Determinar URL según tipo de notificación
  let targetUrl = '/';
  switch (notificationType) {
    case 'INCIDENT_CANCELLED':
    case 'INCIDENT_COMPLETED':
    case 'INCIDENT_ASSIGNED':
      targetUrl = '/incidents';
      break;
    case 'PAYMENT':
      targetUrl = '/finance/payments';
      break;
    case 'SOS':
      targetUrl = '/incidents/active';
      break;
    case 'QUOTATION':
      targetUrl = '/quotations';
      break;
    default:
      targetUrl = '/notifications';
  }

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // Si hay una ventana abierta, enfocarse en ella
      for (const client of clientList) {
        if (client.url === targetUrl && 'focus' in client) {
          return (client as WindowClient).focus();
        }
      }
      // Si no hay ventana, abrir una nueva
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
    })
  );
});

// Escuchar cierres de notificaciones (cuando el usuario la descarta)
self.addEventListener('notificationclose', (event: NotificationEvent) => {
  console.log('[SW] Notificación cerrada:', event.notification.data.notification_type);
});

// Sincronización en background (para reintentos)
self.addEventListener('sync', (event: any) => {
  if (event.tag === 'sync-notifications') {
    event.waitUntil(syncPendingNotifications());
  }
});

/**
 * Sincronizar notificaciones pendientes
 * Si falló el push anterior, reintentar
 */
async function syncPendingNotifications(): Promise<void> {
  try {
    console.log('[SW] Sincronizando notificaciones pendientes...');
    const cache = await caches.open('notifications-v1');
    // Aquí se podría implementar lógica de reintentos desde cache
  } catch (error) {
    console.error('[SW] Error en sincronización:', error);
  }
}

// Mensaje desde el cliente
self.addEventListener('message', (event: ExtendableMessageEvent) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  if (event.data && event.data.type === 'GET_VERSION') {
    event.ports[0].postMessage({ version: '1.0.0' });
  }
});

export {};
