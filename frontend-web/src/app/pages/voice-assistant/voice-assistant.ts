import { Component, OnDestroy, ChangeDetectorRef, ViewChild, ElementRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';

interface ChatMessage {
  sender: 'user' | 'ai';
  text: string;
}

@Component({
  selector: 'app-voice-assistant',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './voice-assistant.html',
  styleUrl: './voice-assistant.scss'
})
export class VoiceAssistantComponent implements OnDestroy {
  @ViewChild('chatWindow') private chatWindow!: ElementRef;
  private readonly apiUrl = environment.apiUrl;
  recording = false;
  loading = false;
  mediaRecorder: MediaRecorder | null = null;
  audioChunks: Blob[] = [];
  chatHistory: ChatMessage[] = [
    { sender: 'ai', text: '¡Hola! Soy tu asistente de voz. Haz clic en el micrófono y pídeme un reporte. Por ejemplo: "Dame un reporte de incidentes", "dame un reporte financiero" o "cómo va el taller".' }
  ];

  constructor(private http: HttpClient, private cdr: ChangeDetectorRef) {}

  toggleRecording(): void {
    if (this.recording) {
      this.stopRecording();
    } else {
      this.startRecording();
    }
  }

  startRecording(): void {
    navigator.mediaDevices.getUserMedia({ audio: true }).then(stream => {
      this.audioChunks = [];
      this.mediaRecorder = new MediaRecorder(stream);
      
      this.mediaRecorder.ondataavailable = (event) => {
        this.audioChunks.push(event.data);
      };

      this.mediaRecorder.onstop = () => {
        const audioBlob = new Blob(this.audioChunks, { type: 'audio/wav' });
        this.sendAudioToBackend(audioBlob);
      };

      this.mediaRecorder.start();
      this.recording = true;
      this.cdr.detectChanges();
    }).catch(err => {
      console.error('Error al acceder al micrófono:', err);
      alert('Por favor, permite el acceso al micrófono para usar el asistente de voz.');
      this.recording = false;
      this.cdr.detectChanges();
    });
  }

  stopRecording(): void {
    if (this.mediaRecorder && this.recording) {
      this.mediaRecorder.stop();
      this.mediaRecorder.stream.getTracks().forEach(track => track.stop());
      this.recording = false;
      this.cdr.detectChanges();
    }
  }

  sendAudioToBackend(audioBlob: Blob): void {
    this.loading = true;
    this.cdr.detectChanges();
    const formData = new FormData();
    formData.append('audio', audioBlob, 'voice_query.wav');

    this.http.post<any>(`${`${this.apiUrl}/ai/voice-report`}`, formData).subscribe({
      next: (res) => {
        this.loading = false;
        // Agregar transcripción del usuario
        this.chatHistory.push({ sender: 'user', text: res.transcription });
        // Agregar respuesta de la IA
        this.chatHistory.push({ sender: 'ai', text: res.answer });
        this.cdr.detectChanges();
        this.scrollToBottom();
        // Hablar en voz alta
        this.speakOutLoud(res.answer);
      },
      error: (err) => {
        this.loading = false;
        const errMsg = err.error?.detail || 'Lo siento, no pude procesar tu consulta de voz. Asegúrate de hablar claro y cerca del micrófono.';
        this.chatHistory.push({ sender: 'ai', text: `❌ ${errMsg}` });
        this.cdr.detectChanges();
        this.scrollToBottom();
        this.speakOutLoud(errMsg);
      }
    });
  }

  private scrollToBottom(): void {
    try {
      setTimeout(() => {
        this.chatWindow.nativeElement.scrollTop = this.chatWindow.nativeElement.scrollHeight;
      }, 100);
    } catch (err) {}
  }

  speakOutLoud(text: string): void {
    if ('speechSynthesis' in window) {
      // Cancelar reproducción en curso
      window.speechSynthesis.cancel();
      
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = 'es-ES';
      
      // Buscar una voz en español
      const voices = window.speechSynthesis.getVoices();
      const spanishVoice = voices.find(v => v.lang.startsWith('es'));
      if (spanishVoice) {
        utterance.voice = spanishVoice;
      }
      
      window.speechSynthesis.speak(utterance);
    }
  }

  ngOnDestroy(): void {
    // Apagar micrófono si el componente se destruye
    this.stopRecording();
    if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel();
    }
  }
}
