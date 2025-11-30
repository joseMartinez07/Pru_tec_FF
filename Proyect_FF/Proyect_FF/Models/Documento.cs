using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Proyect_FF.Models
{
    public class Documento
    {
        public int DocumentoId { get; set; }
        public int EmpresaId { get; set; }
        public string Titulo { get; set; } = string.Empty;
        public string? Descripcion { get; set; }
        public string TipoDocumento { get; set; } = string.Empty;
        public string FlujoValidacionJson { get; set; } = string.Empty;   // Campo JSON - CRÍTICO
        public string Estado { get; set; } = "Borrador";
        public Guid UsuarioCreadorId { get; set; }
        public DateTime FechaCreacion { get; set; }
        public DateTime? FechaModificacion { get; set; }
        public DateTime? FechaAprobacion { get; set; }

        // Navegación
        public Empresa Empresa { get; set; } = null!;
        public ICollection<InstanciaValidacion> InstanciasValidacion { get; set; } = new List<InstanciaValidacion>();

    }
}
