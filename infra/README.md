# InfraDM-Impr3q Infrastructure

Este directorio contiene la configuración de Terraform para desplegar la infraestructura de InfraDM-Impr3q en AWS.

## Arquitectura

### Componentes Principales

1. **VPC con Subnets**
   - 2 Availability Zones para alta disponibilidad
   - Subnets públicas para load balancers
   - Subnets privadas para bases de datos (futuro)

2. **Load Balancers**
   - **Application Load Balancer (ALB)**: Para el API Gateway
   - **Network Load Balancer (NLB)**: Para microservicios

3. **Auto Scaling Groups**
   - API Gateway: 1-3 instancias (t3.small)
   - Microservicios: 1-5 instancias por servicio (t3.micro)

4. **Monitoreo y Observabilidad**
   - CloudWatch Logs y Dashboard
   - Compatible con Site24x7
   - Compatible con Grafana

## Prerrequisitos

### 1. AWS CLI
```bash
# Instalar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configurar credenciales
aws configure
```

### 2. Terraform
```bash
# Instalar Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
```

### 3. Crear Key Pair en AWS
1. Ir a AWS Console → EC2 → Key Pairs
2. Crear un nuevo key pair
3. Descargar el archivo .pem
4. Configurar permisos: `chmod 400 your-key.pem`

## Configuración

### 1. Copiar archivo de configuración
```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2. Editar configuración
Editar `terraform.tfvars` con tus valores:

```hcl
# Configuración básica
aws_region = "us-east-1"
project_name = "infradm"
environment = "dev"

# Key pair (crear en AWS Console)
key_name = "tu-key-pair-name"

# Contraseñas seguras
db_password = "tu-contraseña-postgres-segura"
mysql_password = "tu-contraseña-mysql-segura"
mongodb_password = "tu-contraseña-mongodb-segura"
redis_password = "tu-contraseña-redis-segura"
jwt_secret = "tu-jwt-secret-super-seguro"

# Monitoreo (opcional)
site24x7_agent_key = "tu-site24x7-key"
grafana_api_key = "tu-grafana-api-key"
```

## Despliegue

### Despliegue Automático
```bash
# Ejecutar script de prueba y despliegue
chmod +x test_deployment.sh
./test_deployment.sh
```

### Despliegue Manual
```bash
# 1. Inicializar Terraform
terraform init

# 2. Verificar plan
terraform plan

# 3. Aplicar configuración
terraform apply

# 4. Verificar outputs
terraform output
```

## Verificación

### 1. Verificar API Gateway
```bash
# Obtener URL del API Gateway
API_URL=$(terraform output -raw api_gateway_url)

# Probar health check
curl $API_URL/health

# Probar endpoint principal
curl $API_URL/api
```

### 2. Verificar Microservicios
```bash
# Obtener DNS del NLB
NLB_DNS=$(terraform output -raw microservices_nlb_dns_name)

# Probar cada microservicio
for i in {1..5}; do
  PORT=$((3000 + i))
  echo "Testing microservice $i on port $PORT"
  curl -s "http://$NLB_DNS:$PORT/health" || echo "Service $i not ready yet"
done
```

### 3. Verificar CloudWatch
```bash
# Verificar log groups
aws logs describe-log-groups --log-group-name-prefix "/aws/ec2/infradm"

# Verificar dashboard
aws cloudwatch get-dashboard --dashboard-name "infradm-dashboard"
```

## Monitoreo

### CloudWatch Dashboard
- URL: https://console.aws.amazon.com/cloudwatch/home
- Dashboard: `infradm-dashboard`

### Logs
- API Gateway: `/aws/ec2/infradm-api-gateway`
- Microservicios: `/aws/ec2/infradm-microservices`

### Métricas Principales
- Request Count
- Target Response Time
- HTTP Error Codes
- Auto Scaling Group Metrics

## Configuración de Microservicios

### Endpoints Disponibles
Los microservicios están configurados en los siguientes puertos:

1. **Products Service**: Puerto 3001
2. **Materials Service**: Puerto 3002
3. **Categories Service**: Puerto 3003
4. **Quotations Service**: Puerto 3004
5. **Users Service**: Puerto 3005

### Comunicación
- API Gateway se comunica con microservicios a través del NLB
- Cada microservicio tiene su propio target group
- Health checks automáticos cada 30 segundos

## Costos Estimados (us-east-1)

### Instancias EC2
- API Gateway (t3.small): ~$16/mes
- Microservicios (5x t3.micro): ~$40/mes

### Load Balancers
- Application Load Balancer: ~$16/mes
- Network Load Balancer: ~$16/mes

### Otros Servicios
- Data Transfer: ~$10/mes
- CloudWatch: ~$5/mes

**Total Estimado**: ~$103/mes

## Troubleshooting

### Problemas Comunes

#### 1. Instancias no se inician
```bash
# Verificar logs de user data
aws ec2 get-console-output --instance-id <instance-id>

# Verificar security groups
aws ec2 describe-security-groups --group-ids <sg-id>
```

#### 2. Load Balancer no responde
```bash
# Verificar target groups
aws elbv2 describe-target-health --target-group-arn <tg-arn>

# Verificar listeners
aws elbv2 describe-listeners --load-balancer-arn <lb-arn>
```

#### 3. Microservicios no accesibles
```bash
# Verificar que las instancias estén en el target group
aws elbv2 describe-target-health --target-group-arn <tg-arn>

# Verificar connectivity desde instancia
ssh -i key.pem ubuntu@<instance-ip>
curl localhost:3001/health
```

### Logs de Aplicación
```bash
# Ver logs de Docker
ssh -i key.pem ubuntu@<instance-ip>
cd /app
docker-compose logs -f

# Ver logs de aplicación
ssh -i key.pem ubuntu@<instance-ip>
tail -f /var/log/api-gateway.log
tail -f /var/log/microservice.log
```

## Limpieza

### Destruir Infraestructura
```bash
# Destruir todos los recursos
terraform destroy

# Confirmar destrucción cuando se solicite
```

### Limpiar Archivos Locales
```bash
# Eliminar archivos de Terraform
rm -rf .terraform
rm -f terraform.tfstate*
rm -f tfplan
rm -f deployment_outputs.json
rm -f test_report.md
```

## Seguridad

### Recomendaciones
1. **Cambiar contraseñas por defecto** inmediatamente después del despliegue
2. **Usar AWS Secrets Manager** para producción
3. **Habilitar CloudTrail** para auditoría
4. **Configurar WAF** para protección adicional
5. **Implementar HTTPS** con certificados SSL

### Security Groups
- ALB: HTTP (80), HTTPS (443)
- NLB: HTTP (80), Microservices (3000-3010)
- API Gateway: SSH (22), HTTP (80), App (3000)
- Microservicios: SSH (22), HTTP (80), App (3000-3010)
- Databases: PostgreSQL (5432), MySQL (3306), MongoDB (27017), Redis (6379)

## Soporte

Para problemas o preguntas:
1. Revisar logs de CloudWatch
2. Verificar configuración de Terraform
3. Consultar documentación de AWS
4. Revisar métricas de CloudWatch Dashboard

## Próximos Pasos

1. **Configurar bases de datos** en subnets privadas
2. **Implementar HTTPS** con certificados SSL
3. **Configurar CI/CD** para despliegues automáticos
4. **Implementar backup** y disaster recovery
5. **Configurar alertas** en CloudWatch
6. **Optimizar costos** según uso real 