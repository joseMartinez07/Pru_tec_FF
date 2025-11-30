using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Proyect_FF.Models
{
    public class Empresa
    {
        public int EmpresaId { get; set; }
        public string Nombre { get; set; } = string.Empty;
        public string NIT { get; set; } = string.Empty;
        public string? Telefono { get; set; }
        public string? Direccion { get; set; }
        public string? Email { get; set; }
        public bool Activo { get; set; } = true;
        public DateTime FechaCreacion { get; set; }
        public DateTime? FechaModificacion { get; set; }

        // Navegación
        public ICollection<Documento> Documentos { get; set; } = new List<Documento>();

    }
}
