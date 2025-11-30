using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Proyect_FF.Models.DTOs
{
    public class DocumentoCreateDto
    {
        public int EmpresaId { get; set; }
        public string Titulo { get; set; } = string.Empty;
        public string? Descripcion { get; set; }
        public string TipoDocumento { get; set; } = string.Empty;
        public FlujoValidacionDto FlujoValidacion { get; set; } = new();
        public Guid UsuarioCreadorId { get; set; }
    }

    public class FlujoValidacionDto
    {
        public List<PasoValidacionDto> Steps { get; set; } = new();
    }

    public class PasoValidacionDto
    {
        public int Order { get; set; }
        public string Role { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;
    }
}
