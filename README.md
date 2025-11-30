## Sistema de Gestión Documental con Flujo de Validación

Sistema de gestión documental con flujo de aprobación jerárquico implementado en **ASP.NET Core Web API** y **SQL Server**, utilizando **Entity Framework Core** y procedimientos almacenados.


## Requisitos Previos

### Software Requerido

- **SQL Server** 2019+ o SQL Server Express
- **.NET SDK** 5.0
- **Visual Studio 2019**
- **Postman**

---

## Instalación y Configuración

### Paso 1: Clonar o Descargar el Proyecto

```bash
git clone https://github.com/joseMartinez07/Pru_tec_FF.git
cd gestion-documental-api
```

---

### Paso 2: Crear la Base de Datos

#### Orden de Ejecución de Scripts SQL

Ejecuta los scripts en el siguiente orden desde **SQL Server Management Studio**:

**Script 1: `1-Script_create_table_index_vista.sql`** - Creación de tablas, índices y vista

**Script 2: `2-Script_create_trigger.sql`** - Triggers para automatización

**Script 3: `3-Script_Procedimiento_Almacenado.sql`** - Procedimientos almacenados

---

## Configuración del Proyecto .NET

### Paso 3: Restaurar Paquetes NuGet

```bash
cd Proyect_FF
dotnet restore
```

### Paso 4: Configurar Cadena de Conexión

Edita el archivo **`appsettings.json`**:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=DB_GDoc;Trusted_Connection=True;TrustServerCertificate=True;"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

### Paso 5: Verificar Configuración

```bash
# Compilar el proyecto
dotnet build

# Si hay errores, verifica que tengas todos los paquetes
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Tools
dotnet add package Microsoft.AspNetCore.Mvc.NewtonsoftJson
dotnet add package Swashbuckle.AspNetCore
```

---

## Ejecutar la API

### Opción 1: Desde Visual Studio

1. Abre el proyecto en **Visual Studio 2019**
2. Selecciona el perfil de ejecución (cambia de "IIS Express" a "Proyect_FF")

### Verificar que la API está Corriendo

Deberías ver en la consola:

```
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: https://localhost:5001
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://localhost:5000
```
---

## Endpoints de la API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/documents` | Listar todos los documentos |
| `GET` | `/api/documents/{id}` | Obtener un documento específico |
| `POST` | `/api/documents` | Crear un nuevo documento |
| `POST` | `/api/documents/{id}/actions` | Aprobar o rechazar documento |
| `GET` | `/api/documents/{id}/download` | Obtener URL de descarga |

---

## Flujo de Validación JSON

### Estructura del JSON

El campo `FlujoValidacionJson` debe seguir esta estructura:

```json
{
  "steps": [
    {
      "order": 1,
      "role": "Analista",
      "userId": "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d"
    },
    {
      "order": 2,
      "role": "Jefe",
      "userId": "b2c3d4e5-f6a7-5b6c-9d0e-1f2a3b4c5d6e"
    },
    {
      "order": 3,
      "role": "Gerente",
      "userId": "c3d4e5f6-a7b8-6c7d-0e1f-2a3b4c5d6e7f"
    }
  ]
}
```

---

## Ejemplos de Uso

### 1. Crear un Documento

**Request:**
```http
POST http://localhost:5000/api/documents
Content-Type: application/json

{
  "empresaId": 1,
  "titulo": "Contrato de Servicios 2025",
  "descripcion": "Contrato anual de servicios de TI",
  "tipoDocumento": "Contrato",
  "nombreArchivo": "contrato_2025.pdf",
  "usuarioCreadorId": "d4e5f6a7-b8c9-7d8e-1f2a-3b4c5d6e7f8a",
  "flujoValidacion": {
    "steps": [
      {
        "order": 1,
        "role": "Analista",
        "userId": "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d"
      },
      {
        "order": 2,
        "role": "Jefe",
        "userId": "b2c3d4e5-f6a7-5b6c-9d0e-1f2a3b4c5d6e"
      },
      {
        "order": 3,
        "role": "Gerente",
        "userId": "c3d4e5f6-a7b8-6c7d-0e1f-2a3b4c5d6e7f"
      }
    ]
  }
}
```

**Response:**
```json
{
  "documentoId": 1,
  "empresaId": 1,
  "titulo": "Contrato de Servicios 2025",
  "estado": "EnValidacion",
  "flujoValidacionJson": "{\"steps\":[...]}",
  "fechaCreacion": "2025-11-29T10:30:00"
}
```

---

### 2. Consultar un Documento

**Request:**
```http
GET http://localhost:5000/api/documents/1
```

**Response:**
```json
{
  "documentoId": 1,
  "titulo": "Contrato de Servicios 2025",
  "estado": "EnValidacion",
  "tipoDocumento": "Contrato",
  "flujoValidacionJson": "{\"steps\":[...]}",
  "instanciasValidacion": [
    {
      "ordenPaso": 1,
      "rolValidador": "Analista",
      "accion": "Pendiente",
      "fechaAccion": "2025-11-29T10:30:00"
    }
  ]
}
```

---

### 3. Aprobar un Documento

**Request:**
```http
POST http://localhost:5000/api/documents/1/actions
Content-Type: application/json

{
  "actorUserId": "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d",
  "accion": "Aprobar",
  "razon": "Documentación completa y correcta"
}
```

**Response:**
```json
{
  "message": "Acción procesada exitosamente"
}
```

---

### 4. Rechazar un Documento

**Request:**
```http
POST http://localhost:5000/api/documents/1/actions
Content-Type: application/json

{
  "actorUserId": "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d",
  "accion": "Rechazar",
  "razon": "Falta información de contacto del proveedor"
}
```

**Response:**
```json
{
  "message": "Acción procesada exitosamente"
}
```
---

### 5. Obtener URL de Descarga

**Request:**
```http
GET http://localhost:5000/api/documents/1/download
```

**Response (si está aprobado):**
```json
{
  "documentoId": 1,
  "titulo": "Contrato de Servicios 2025",
  "estado": "Aprobado",
  "fechaAprobacion": "2025-11-29T11:00:00"
}
```

**Response (si NO está aprobado):**
```json
{
  "error": "El documento aún no está aprobado",
  "estado": "EnValidacion"
}
```
