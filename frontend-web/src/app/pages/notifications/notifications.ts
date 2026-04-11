import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { WorkshopService } from '../../services/workshop.service';
import { Notification } from '../../models/interfaces';

@Component({
  selector: 'app-notifications',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './notifications.html',
  styleUrl: './notifications.scss'
})
export class NotificationsComponent implements OnInit {
  notifications: Notification[] = [];
  loading = true;

  constructor(private ws: WorkshopService) {}

  ngOnInit(): void {
    this.ws.getNotifications().subscribe({
      next: (data) => { this.notifications = data; this.loading = false; },
      error: () => { this.loading = false; }
    });
  }

  markRead(n: Notification): void {
    if (n.is_read) return;
    this.ws.markNotificationRead(n.id).subscribe(() => {
      n.is_read = true;
    });
  }
}
