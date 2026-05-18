# Módulo 2: Servicio de Redirección de URLs

## 📋 Descripción
Servicio que valida códigos cortos almacenados en DynamoDB y redirige a la URL completa con HTTP 302.

## 🏗️ Arquitectura
- **AWS Lambda**: Función `GET /{shortCode}` para procesar redirecciones
- **API Gateway HTTP**: Comparte el endpoint base con el módulo 1 de acortamiento
- **DynamoDB**: Tabla compartida con el módulo de acortamiento

## 📦 Tecnología
- **Runtime**: Node.js 18.x
- **AWS SDK**: v3 (`@aws-sdk/client-dynamodb`, `@aws-sdk/lib-dynamodb`)
- **Infraestructura**: Terraform

## 📁 Estructura del Proyecto
```
module2_redirect/
├── src/
│   └── lambda/
│       ├── handlers/
│       │   └── redirect.js       # Función Lambda de redirección
│       └── utils/
│           └── dynamodb.js       # Cliente DynamoDB Document Client
├── terraform/
│   ├── main.tf                   # Lambda, API Gateway, roles y permisos
│   ├── variables.tf              # Variables de configuración
│   ├── outputs.tf                # Salidas de Terraform
│   └── providers.tf              # Proveedor AWS
├── package.json                  # Dependencias Node.js
└── readme.md                     # Documentación del módulo
```

## 🔐 Permisos IAM
La función Lambda necesita:
- `dynamodb:GetItem` en la tabla configurada
- Permisos básicos de Lambda para escribir logs en CloudWatch

## 📦 Variables de Terraform
- `aws_region` (string): Región AWS donde se crea el recurso. Valor por defecto: `us-east-1`
- `table_name` (string): Nombre de la tabla DynamoDB compartida. Valor por defecto: `UrlsTable`

## 🛠️ Despliegue
### Requisitos previos
- AWS CLI configurado con credenciales válidas
- Terraform instalado
- Tabla DynamoDB existente en la misma región y cuenta
- Acceso al estado remoto del módulo 1 (`module1_shorten`) si se usa el recurso compartido

### Pasos
```bash
cd terraform
terraform init
terraform plan -var="table_name=UrlsTable" -var="aws_region=us-east-1"
terraform apply -var="table_name=UrlsTable" -var="aws_region=us-east-1"
```

### Usando `terraform.tfvars`
```hcl
aws_region = "us-east-1"
table_name = "UrlsTable"
```

Luego:
```bash
cd terraform
tf apply
```

## 📡 Uso de la API
### Ejemplo de redirección
```bash
curl -L "https://<api-endpoint>/abc123"
```

### Encabezados de respuesta esperados
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

## 📊 Estructura esperada en DynamoDB
- Tabla: `UrlsTable`
- Partition Key: `shortCode` (String)

Ejemplo de ítem:
```json
{
  "shortCode": "abc123",
  "longUrl": "https://www.ejemplo.com/pagina-larga"
}
```

## 🔄 Flujo de funcionamiento
1. El cliente solicita `GET /{shortCode}`
2. Lambda consulta DynamoDB por `shortCode`
3. Si existe y tiene `longUrl`, retorna `302` con `Location`
4. Si no existe, retorna `404`

## 🧹 Eliminación de recursos
```bash
cd terraform
terraform destroy -var="table_name=UrlsTable" -var="aws_region=us-east-1"
```

## 📝 Notas
- Este módulo depende de la tabla DynamoDB compartida con el módulo de acortamiento
- La redirección es temporal (`302`)
- El header `Access-Control-Allow-Origin: *` se agrega en la respuesta de Lambda

## 📚 Referencias
- AWS Lambda
- API Gateway HTTP
- DynamoDB Document Client
- Terraform AWS Provider
