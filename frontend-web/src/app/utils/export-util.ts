/**
 * Utilidades para exportación de reportes a PDF, HTML y Excel (CSV).
 */

export class ExportUtil {
  /**
   * Exporta datos tabulares a un archivo CSV (compatible con Excel).
   * @param filename Nombre del archivo a descargar (ej: 'reporte.csv')
   * @param headers Cabeceras de la tabla
   * @param rows Filas con datos correspondientes a las cabeceras
   */
  static exportToExcel(filename: string, headers: string[], rows: any[][]): void {
    // Generar formato CSV con BOM UTF-8 para soporte de caracteres con tilde y emojis
    const BOM = '\uFEFF';
    let csvContent = BOM + headers.map(h => `"${h.replace(/"/g, '""')}"`).join(',') + '\n';

    rows.forEach(row => {
      const line = row.map(val => {
        const valStr = val === null || val === undefined ? '' : String(val);
        return `"${valStr.replace(/"/g, '""')}"`;
      }).join(',');
      csvContent += line + '\n';
    });

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    if (link.download !== undefined) {
      const url = URL.createObjectURL(blob);
      link.setAttribute('href', url);
      link.setAttribute('download', filename.endsWith('.csv') ? filename : `${filename}.csv`);
      link.style.visibility = 'hidden';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    }
  }

  /**
   * Genera y descarga un archivo HTML estático e interactivo con el reporte.
   */
  static exportToHtml(filename: string, title: string, contentHtml: string): void {
    const htmlPage = `
      <!DOCTYPE html>
      <html lang="es">
      <head>
        <meta charset="UTF-8">
        <title>${title}</title>
        <style>
          body {
            font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background-color: #0f172a;
            color: #f1f5f9;
            margin: 0;
            padding: 40px 20px;
            display: flex;
            justify-content: center;
          }
          .report-container {
            width: 100%;
            max-width: 900px;
            background: #1e293b;
            border: 1px solid rgba(148, 163, 184, 0.15);
            border-radius: 14px;
            padding: 30px;
            box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.3);
          }
          .report-header {
            border-bottom: 2px solid rgba(148, 163, 184, 0.15);
            padding-bottom: 20px;
            margin-bottom: 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
          }
          h1 {
            margin: 0;
            font-size: 24px;
            color: #38bdf8;
          }
          .meta-info {
            font-size: 13px;
            color: #94a3b8;
            text-align: right;
          }
          table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
          }
          th {
            background-color: #0f172a;
            color: #38bdf8;
            font-size: 11px;
            text-transform: uppercase;
            font-weight: 700;
            padding: 12px 16px;
            text-align: left;
            border-bottom: 2px solid rgba(148, 163, 184, 0.15);
          }
          td {
            padding: 14px 16px;
            font-size: 13px;
            border-bottom: 1px solid rgba(148, 163, 184, 0.1);
            color: #cbd5e1;
          }
          tr:hover td {
            background: rgba(56, 189, 248, 0.05);
          }
          .btn-print {
            background: linear-gradient(135deg, #38bdf8 0%, #6366f1 100%);
            color: #fff;
            border: none;
            padding: 8px 16px;
            font-weight: 600;
            border-radius: 8px;
            cursor: pointer;
            font-size: 12px;
          }
          .badge {
            display: inline-block;
            padding: 2px 8px;
            font-size: 10px;
            font-weight: 700;
            border-radius: 9999px;
            text-transform: uppercase;
          }
          .badge-success { background: rgba(16, 185, 129, 0.15); color: #10b981; }
          .badge-warning { background: rgba(245, 158, 11, 0.15); color: #f59e0b; }
          .badge-danger { background: rgba(239, 68, 68, 0.15); color: #ef4444; }
          .badge-info { background: rgba(6, 182, 212, 0.15); color: #22d3ee; }
          
          /* Estilo para imprimir */
          @media print {
            body { background-color: #fff; color: #000; padding: 0; }
            .report-container { border: none; box-shadow: none; padding: 0; background: none; }
            .btn-print { display: none; }
            th { color: #000; border-bottom: 2px solid #000; }
            td { color: #000; border-bottom: 1px solid #ddd; }
          }
        </style>
      </head>
      <body>
        <div class="report-container">
          <div class="report-header">
            <div>
              <h1>${title}</h1>
              <div style="font-size: 12px; color: #94a3b8; margin-top: 4px;">Plataforma de Emergencias Vehiculares</div>
            </div>
            <div class="meta-info">
              <div>Fecha: ${new Date().toLocaleDateString('es-ES')}</div>
              <div style="margin-top: 6px;"><button class="btn-print" onclick="window.print()">🖨️ Imprimir PDF</button></div>
            </div>
          </div>
          <div class="report-content">
            ${contentHtml}
          </div>
        </div>
      </body>
      </html>
    `;

    const blob = new Blob([htmlPage], { type: 'text/html;charset=utf-8;' });
    const link = document.createElement('a');
    if (link.download !== undefined) {
      const url = URL.createObjectURL(blob);
      link.setAttribute('href', url);
      link.setAttribute('download', filename.endsWith('.html') ? filename : `${filename}.html`);
      link.style.visibility = 'hidden';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    }
  }

  /**
   * Abre una ventana de impresión para guardar directamente como PDF.
   */
  static exportToPdf(title: string, contentHtml: string): void {
    const printWindow = window.open('', '_blank');
    if (!printWindow) return;

    printWindow.document.write(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>${title}</title>
        <style>
          body {
            font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
            color: #000;
            padding: 30px;
          }
          .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 2px solid #333;
            padding-bottom: 15px;
            margin-bottom: 25px;
          }
          h1 { margin: 0; font-size: 22px; color: #0284c7; }
          .date { font-size: 12px; color: #666; }
          table { width: 100%; border-collapse: collapse; margin-top: 15px; }
          th {
            background-color: #f3f4f6;
            color: #000;
            font-size: 10px;
            text-transform: uppercase;
            font-weight: bold;
            padding: 10px 12px;
            text-align: left;
            border-bottom: 2px solid #333;
          }
          td {
            padding: 10px 12px;
            font-size: 11px;
            border-bottom: 1px solid #e5e7eb;
          }
          .badge {
            display: inline-block;
            padding: 2px 6px;
            font-size: 9px;
            font-weight: bold;
            border-radius: 9999px;
            border: 1px solid #ccc;
          }
          .money { font-weight: bold; }
        </style>
      </head>
      <body>
        <div class="header">
          <div>
            <h1>${title}</h1>
            <div style="font-size: 11px; color: #555; margin-top: 2px;">Emergencias Vehiculares SaaS</div>
          </div>
          <div class="date">Fecha de Emisión: ${new Date().toLocaleDateString('es-ES')}</div>
        </div>
        <div class="content">
          ${contentHtml}
        </div>
        <script>
          window.onload = function() {
            window.print();
            setTimeout(function() { window.close(); }, 500);
          }
        </script>
      </body>
      </html>
    `);
    printWindow.document.close();
  }
}
