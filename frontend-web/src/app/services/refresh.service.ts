import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, Subject } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class RefreshService {
  private isOnlineSubject = new BehaviorSubject<boolean>(navigator.onLine);
  private refreshSubject = new Subject<void>();

  constructor() {
    window.addEventListener('online', () => {
      this.isOnlineSubject.next(true);
      this.refreshSubject.next();
    });

    window.addEventListener('offline', () => {
      this.isOnlineSubject.next(false);
    });
  }

  get isOnline$(): Observable<boolean> {
    return this.isOnlineSubject.asObservable();
  }

  get isOnline(): boolean {
    return this.isOnlineSubject.value;
  }

  get refresh$(): Observable<void> {
    return this.refreshSubject.asObservable();
  }

  triggerRefresh(): void {
    this.refreshSubject.next();
  }
}
