# Módulo 2: Servicio de Redirección de URLs

## 📋 Descripción
Servicio de redirección que valida códigos cortos en DynamoDB y redirige a URLs completas usando HTTP status code 302.

## 🏗️ Arquitectura
- **AWS Lambda**: Función GET `/{codigo}` para procesar redirecciones
- **API Gateway HTTP**: Comparte el mismo endpoint base que el módulo 1
- **DynamoDB**: Base de datos compartida con el módulo de acortamiento (tabla `UrlsTable`)

## 📦 Stack Tecnológico
- **Runtime**: Node.js 18.x
- **AWS SDK**: v3 (Document Client)
- **Infraestructura**: Terraform 5.0+

## 🚀 Características Principales
1. **Validación de Código**: Verifica que el código existe en DynamoDB
2. **Redirección 302**: HTTP status code 302 (Found) para redirecciones temporales
3. **Manejo de Errores**:
   - `400`: Código faltante
   - `404`: Código no encontrado o expirado
   - `500`: Error interno del servidor
4. **CORS**: Usa el API Gateway compartido del módulo 1 y permite solicitudes de cualquier origen

## 📁 Estructura de Archivos
```
module2_redirect/
├── src/
│   └── lambda/
│       ├── handlers/
│       │   └── redirect.js       # Manejador principal de redirección
│       └── utils/
│           └── dynamodb.js       # Configuración del cliente DynamoDB
├── terraform/
│   ├── main.tf                   # Recursos principales (Lambda, API Gateway, IAM)
│   ├── variables.tf              # Variables de entrada
│   ├── outputs.tf                # Salidas de Terraform
│   └── providers.tf              # Configuración de proveedores
├── package.json                  # Dependencias de Node.js
└── readme.md                     # Este archivo
```

## 🔐 Permisos IAM
La función Lambda tiene los siguientes permisos:
- `dynamodb:GetItem` en la tabla configurada
- `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents` (CloudWatch)

## 🛠️ Despliegue

### Requisitos Previos
- AWS CLI configurado con credenciales
- Terraform 1.0+
- Node.js 18+
- La tabla DynamoDB debe existir en la misma cuenta y región

### Pasos de Despliegue

```bash
# 1. Navegar al directorio de terraform
cd terraform/

# 2. Inicializar Terraform
terraform init

# 3. Crear plan de despliegue
terraform plan -var="table_name=url_shortener" -var="aws_region=us-east-1"

# 4. Aplicar la configuración
terraform apply -var="table_name=url_shortener" -var="aws_region=us-east-1"
```

### Alternativa: Usar terraform.tfvars
```bash
# Crear archivo terraform.tfvars
echo 'table_name = "url_shortener"' > terraform.tfvars
echo 'aws_region = "us-east-1"' >> terraform.tfvars

# Desplegar
terraform apply
```

## 📡 Uso de la API

### Redirección Básica
```bash
# Solicitar redirección (seguirá automáticamente)
curl -L "https://<api-endpoint>/abc123"

# Ver encabezados sin seguir redirección
curl -i "https://<api-endpoint>/abc123"
```

### Respuestas Esperadas

**Éxito (302)**
```http
HTTP/1.1 302 Found
Location: https://www.ejemplo.com
Access-Control-Allow-Origin: *
Cache-Control: no-cache
```

**Código no encontrado (404)**
```json
{
  "message": "El código no existe o ha expirado"
}
```

**Código faltante (400)**
```json
{
  "error": "Falta el código de redirección"
}
```

## 📊 Estructura de Datos en DynamoDB

La tabla debe tener la siguiente estructura:
```
Tabla: UrlsTable
Partition Key: shortCode (String)

Ejemplo de ítem:
{
  "shortCode": "abc123",
  "longUrl": "https://www.ejemplo.com/pagina-larga",
  "createdAt": "2025-01-01T12:00:00Z",
  "clicks": 0
}
```

## 🔄 Flujo de Funcionamiento

1. **Solicitud**: Cliente realiza GET a `/{shortCode}`
2. **Validación**: Lambda busca el `shortCode` en DynamoDB
3. **Decisión**:
   - ✅ Si existe → Retorna 302 con header `Location`
   - ❌ Si no existe → Retorna 404
4. **Redirección**: Navegador sigue automáticamente a la URL larga

## 🧹 Limpieza de Recursos

Para eliminar todos los recursos desplegados:
```bash
cd terraform/
terraform destroy -var="table_name=url_shortener" -var="aws_region=us-east-1"
```

## 📝 Notas Importantes

- Este módulo **depende de la tabla DynamoDB compartida** con el módulo de acortamiento
- La tabla debe tener `shortCode` como clave primaria (Partition Key)
- Los permisos IAM están limitados a operaciones de lectura (`GetItem`)
- La redirección usa HTTP 302 (temporal) en lugar de 301 (permanente)
- Los resultados se cachean a nivel del navegador pero no en CloudFront

## 🐛 Troubleshooting

**Error: "Lambda execution role is not authorized"**
- Verifica que los permisos de DynamoDB estén correctamente asignados
- Confirma que el nombre de la tabla es correcto

**Error: "Table not found"**
- Verifica que la tabla DynamoDB existe en la misma región
- Confirma el nombre exacto de la tabla en `terraform.tfvars`

**No redirige automáticamente**
- Usa `curl -L` para seguir redirecciones
- En navegadores modernos, deberían seguirse automáticamente

## 📚 Referencias
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [API Gateway HTTP API](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html)
- [DynamoDB Document Client](https://docs.aws.amazon.com/sdk-for-javascript/v3/developer-guide/dynamodb-document-client.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
