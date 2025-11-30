using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.HttpsPolicy;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.OpenApi.Models;
using Proyect_FF.Contex;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Proyect_FF
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            // 1. Configurar DbContext con SQL Server
            services.AddDbContext<ApplicationDbContext>(options =>
                options.UseSqlServer(
                    Configuration.GetConnectionString("DefaultConnection"),
                    sqlServerOptionsAction: sqlOptions =>
                    {
                        sqlOptions.EnableRetryOnFailure(
                            maxRetryCount: 5,
                            maxRetryDelay: TimeSpan.FromSeconds(30),
                            errorNumbersToAdd: null);
                    }));

            // 2. Agregar Controllers con soporte para JSON
            services.AddControllers()
                .AddNewtonsoftJson(options =>
                {
                    // Evitar referencias circulares en JSON
                    options.SerializerSettings.ReferenceLoopHandling =
                        Newtonsoft.Json.ReferenceLoopHandling.Ignore;

                    // Ignorar valores nulos en la serialización
                    options.SerializerSettings.NullValueHandling =
                        Newtonsoft.Json.NullValueHandling.Ignore;

                    // Formato de fechas
                    options.SerializerSettings.DateFormatString = "yyyy-MM-dd HH:mm:ss";
                });

            // 3. Configurar Swagger/OpenAPI
            services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo
                {
                    Version = "v1",
                    Title = "Gestión Documental API",
                    Description = "API REST para gestión de documentos con flujo de validación jerárquico",
                    Contact = new OpenApiContact
                    {
                        Name = "Equipo de Desarrollo",
                        Email = "desarrollo@empresa.com"
                    }
                });

                // Opcional: Incluir comentarios XML
                // var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
                // var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
                // c.IncludeXmlComments(xmlPath);
            });

            // 4. Configurar CORS
            services.AddCors(options =>
            {
                // Política permisiva para desarrollo
                options.AddPolicy("AllowAll", builder =>
                {
                    builder.AllowAnyOrigin()
                           .AllowAnyMethod()
                           .AllowAnyHeader();
                });

                // Política restrictiva para producción
                options.AddPolicy("Production", builder =>
                {
                    builder.WithOrigins(
                               "https://tudominio.com",
                               "https://app.tudominio.com"
                           )
                           .AllowAnyMethod()
                           .AllowAnyHeader()
                           .AllowCredentials();
                });
            });

            // 5. Agregar servicios personalizados (Repository Pattern, Services, etc.)
            // services.AddScoped<IDocumentoRepository, DocumentoRepository>();
            // services.AddScoped<IDocumentoService, DocumentoService>();

            // 6. Configurar HttpClient (si lo necesitas)
            // services.AddHttpClient();

            // 7. Configurar Memory Cache
            services.AddMemoryCache();

            // 8. Configurar Response Compression
            services.AddResponseCompression(options =>
            {
                options.EnableForHttps = true;
            });
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            // 1. Manejo de errores según el ambiente
            if (env.IsDevelopment())
            {
                // Página de errores detallada en desarrollo
                app.UseDeveloperExceptionPage();

                // Habilitar Swagger en desarrollo
                app.UseSwagger();
                app.UseSwaggerUI(c =>
                {
                    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Gestión Documental API v1");
                    c.RoutePrefix = string.Empty; // Swagger en la raíz: http://localhost:5000/
                });
            }
            else
            {
                // Manejo de errores genérico en producción
                app.UseExceptionHandler("/error");

                // HSTS (HTTP Strict Transport Security)
                app.UseHsts();
            }

            // 2. Redirección HTTPS
            app.UseHttpsRedirection();

            // 3. Response Compression
            app.UseResponseCompression();

            // 4. Archivos estáticos (si los necesitas)
            // app.UseStaticFiles();

            // 5. Routing
            app.UseRouting();

            // 6. CORS (DEBE IR ANTES de Authorization)
            app.UseCors(env.IsDevelopment() ? "AllowAll" : "Production");

            // 7. Authentication & Authorization
            // app.UseAuthentication();
            app.UseAuthorization();

            // 8. Endpoints personalizados
            app.UseEndpoints(endpoints =>
            {
                // Mapear controllers
                endpoints.MapControllers();

                // Health check endpoint
                endpoints.MapGet("/health", async context =>
                {
                    await context.Response.WriteAsJsonAsync(new
                    {
                        status = "Healthy",
                        timestamp = DateTime.UtcNow,
                        environment = env.EnvironmentName
                    });
                });

                // Error endpoint
                endpoints.MapGet("/error", async context =>
                {
                    context.Response.StatusCode = 500;
                    await context.Response.WriteAsJsonAsync(new
                    {
                        error = "Ocurrió un error en el servidor",
                        timestamp = DateTime.UtcNow
                    });
                });
            });

            // 9. Inicializar base de datos (opcional)
            using (var serviceScope = app.ApplicationServices.GetRequiredService<IServiceScopeFactory>().CreateScope())
            {
                try
                {
                    var context = serviceScope.ServiceProvider.GetService<ApplicationDbContext>();

                    // Aplicar migraciones pendientes automáticamente
                    // context.Database.Migrate();

                    // O simplemente asegurarse de que la BD existe
                    context.Database.EnsureCreated();

                    Console.WriteLine("✅ Base de datos inicializada correctamente");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"❌ Error al inicializar la base de datos: {ex.Message}");
                }
            }

            // Mensaje de inicio
            Console.WriteLine("===========================================");
            Console.WriteLine("🚀 API de Gestión Documental Iniciada");
            Console.WriteLine($"🌐 Ambiente: {env.EnvironmentName}");
            Console.WriteLine($"📍 Swagger UI: http://localhost:5000/");
            Console.WriteLine("===========================================");
        }
    }
}
