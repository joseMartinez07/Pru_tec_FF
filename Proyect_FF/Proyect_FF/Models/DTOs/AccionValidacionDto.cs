using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Proyect_FF.Models.DTOs
{
    public class AccionValidacionDto
    {
        public Guid ActorUserId { get; set; }
        public string Accion { get; set; } = string.Empty; // "Aprobar" o "Rechazar"
        public string? Razon { get; set; }
    }
}
