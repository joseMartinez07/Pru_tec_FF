using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Proyect_FF.Models;

namespace Proyect_FF.Contex
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options){}
        public DbSet<Empresa> Empresas { get; set; }
        public DbSet<Documento> Documentos { get; set; }
        public DbSet<InstanciaValidacion> InstanciasValidacion { get; set; }
        public object Empresa { get; internal set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<Empresa>(entity =>
            {
                entity.ToTable("Empresa");
                entity.HasKey(e => e.EmpresaId);
                entity.Property(e => e.Nombre).IsRequired().HasMaxLength(200);
                entity.Property(e => e.NIT).IsRequired().HasMaxLength(50);
                entity.HasIndex(e => e.NIT).IsUnique();
            });

            modelBuilder.Entity<Documento>(entity =>
            {
                entity.ToTable("Documento");
                entity.HasKey(d => d.DocumentoId);
                entity.Property(d => d.Titulo).IsRequired().HasMaxLength(300);
                entity.Property(d => d.FlujoValidacionJson).IsRequired();
                entity.Property(d => d.Estado).IsRequired().HasMaxLength(50);

                entity.HasOne(d => d.Empresa)
                      .WithMany(e => e.Documentos)
                      .HasForeignKey(d => d.EmpresaId);
            });

            modelBuilder.Entity<InstanciaValidacion>(entity =>
            {
                entity.ToTable("InstanciaValidacion");
                entity.HasKey(i => i.InstanciaValidacionId);

                entity.HasOne(i => i.Documento)
                      .WithMany(d => d.InstanciasValidacion)
                      .HasForeignKey(i => i.DocumentoId)
                      .OnDelete(DeleteBehavior.Cascade);
            });
        }

    }
}
