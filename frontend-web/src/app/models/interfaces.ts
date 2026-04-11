export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  access_token: string;
  token_type: string;
  role: string;
}

export interface Workshop {
  id: number;
  name: string;
  email: string;
  phone: string;
  address: string;
  latitude: number;
  longitude: number;
  is_active: boolean;
  capacity: number;
  specialties: string[];
}

export interface Technician {
  id: number;
  workshop_id: number;
  name: string;
  phone: string;
  specialties: string[];
  is_available: boolean;
  current_latitude: number | null;
  current_longitude: number | null;
  created_at: string;
}

export interface Evidence {
  id: number;
  incident_id: number;
  evidence_type: string;
  file_url: string | null;
  content: string | null;
  ai_analysis: string | null;
  created_at: string;
}

export interface ServiceHistory {
  id: number;
  incident_id: number;
  status: string;
  notes: string | null;
  created_by: string | null;
  created_at: string;
}

export interface Payment {
  id: number;
  incident_id: number;
  amount: number;
  commission_amount: number;
  commission_percent: number;
  payment_status: string;
  payment_method: string;
  created_at: string;
}

export interface Incident {
  id: number;
  user_id: number;
  vehicle_id: number;
  latitude: number;
  longitude: number;
  address: string | null;
  description: string | null;
  audio_transcription: string | null;
  incident_type: string;
  priority: string;
  status: string;
  ai_classification: string | null;
  ai_confidence: number | null;
  ai_summary: string | null;
  workshop_id: number | null;
  technician_id: number | null;
  estimated_arrival_minutes: number | null;
  final_cost: number | null;
  created_at: string;
  updated_at: string;
  assigned_at: string | null;
  completed_at: string | null;
}

export interface IncidentDetail extends Incident {
  evidences: Evidence[];
  status_history: ServiceHistory[];
  payment: Payment | null;
  user_name?: string;
  user_phone?: string;
  vehicle_brand?: string;
  vehicle_model?: string;
  vehicle_year?: number;
  vehicle_color?: string;
  vehicle_license_plate?: string;
}

export interface Notification {
  id: number;
  title: string;
  message: string;
  notification_type: string;
  is_read: boolean;
  created_at: string;
}
