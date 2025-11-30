using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Proyect_FF.Models
{
    public class InstanciaValidacion
    {
        public int InstanciaValidacionId { get; set; }
        public int DocumentoId { get; set; }
        public int OrdenPaso { get; set; }
        public string RolValidador { get; set; } = string.Empty;
        public Guid UsuarioValidadorId { get; set; }
        public string Accion { get; set; } = string.Empty;
        public string? Observaciones { get; set; }
        public DateTime FechaAccion { get; set; }
        public string? DatosAdicionales { get; set; }

        // Navegación
        public Documento Documento { get; set; } = null!;
    }
}
