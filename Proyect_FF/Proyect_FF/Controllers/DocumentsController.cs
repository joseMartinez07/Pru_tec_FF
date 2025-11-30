using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Data.SqlClient;
using Proyect_FF.Contex;
using Proyect_FF.Models;
using Proyect_FF.Models.DTOs;
using Newtonsoft.Json;

namespace Proyect_FF.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DocumentsController : ControllerBase  // Agregado ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public DocumentsController(ApplicationDbContext context)
        {
            _context = context;
        }

        // POST /api/documents
        [HttpPost]
        public async Task<ActionResult<Documento>> CreateDocument([FromBody] DocumentoCreateDto dto)
        {
            try
            {
                // Convertir flujo a JSON
                var flujoJson = JsonConvert.SerializeObject(dto.FlujoValidacion);

                // Crear documento
                var documento = new Documento
                {
                    EmpresaId = dto.EmpresaId,
                    Titulo = dto.Titulo,
                    Descripcion = dto.Descripcion,
                    TipoDocumento = dto.TipoDocumento,
                    FlujoValidacionJson = flujoJson,
                    Estado = "EnValidacion",
                    UsuarioCreadorId = dto.UsuarioCreadorId,
                    FechaCreacion = DateTime.Now
                };

                _context.Documentos.Add(documento);
                await _context.SaveChangesAsync();

                return CreatedAtAction(nameof(GetDocument), new { id = documento.DocumentoId }, documento);
            }
            catch (Exception ex)
            {
                return BadRequest(new { error = ex.Message });
            }
        }




        //  POST /api/documents/{documentId}/actions - CORREGIDO
        [HttpPost("{documentId}/actions")]
        public async Task<ActionResult> ProcessAction(int documentId, [FromBody] AccionValidacionDto dto)
        {
            try
            {
                // Parámetros CORREGIDOS - nombres correctos
                var paramDocId = new SqlParameter("@DocumentoId", documentId);
                var paramActorId = new SqlParameter("@ActorUserId", dto.ActorUserId);
                var paramAccion = new SqlParameter("@Accion", dto.Accion);  //  "Accion" no "Action"
                var paramRazon = new SqlParameter("@Razon", (object?)dto.Razon ?? DBNull.Value);

                // LLAMADA CORRECTA al stored procedure
                await _context.Database.ExecuteSqlRawAsync(
                    "EXEC sp_ProcesarAccionValidacion @DocumentoId, @ActorUserId, @Accion, @Razon",  //  Nombre correcto del SP
                    paramDocId, paramActorId, paramAccion, paramRazon
                );

                return Ok(new { message = "Acción procesada exitosamente" });
            }
            catch (SqlException ex)
            {
                // Sintaxis CORREGIDA
                return BadRequest(new { error = ex.Message });
            }
        }

        // GET /api/documents/{documentId}/download - CORREGIDO
        [HttpGet("{documentId}/download")]
        public async Task<ActionResult> GetDownloadUrl(int documentId)
        {
            var documento = await _context.Documentos
                .Include(d => d.InstanciasValidacion)
                .FirstOrDefaultAsync(d => d.DocumentoId == documentId);

            if (documento == null)
                return NotFound();

            // Mensaje de error CORREGIDO
            if (documento.Estado != "Aprobado")
            {
                return BadRequest(new
                {
                    error = "El documento aún no está aprobado",  // ✅ "aún" no "agn"
                    estado = documento.Estado
                });
            }

            // Generar URL simulada
            //var downloadUrl = $"https://storage.example.com/documents/{documento.RutaArchivo}";

            return Ok(new
            {
                documentoId = documento.DocumentoId,
                titulo = documento.Titulo,
                estado = documento.Estado,
                //downloadUrl = downloadUrl,
                fechaAprobacion = documento.FechaAprobacion
            });
        }

        // GET /api/documents/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<Documento>> GetDocument(int id)
        {
            var documento = await _context.Documentos
                .Include(d => d.Empresa)
                .Include(d => d.InstanciasValidacion)
                .FirstOrDefaultAsync(d => d.DocumentoId == id);

            if (documento == null)
                return NotFound();

            return documento;
        }


        // GET /api/documents
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Documento>>> GetDocuments()
        {
            return await _context.Documentos
                .Include(d => d.Empresa)
                .ToListAsync();
        }
    }
}