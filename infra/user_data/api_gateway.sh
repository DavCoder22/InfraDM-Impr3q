#!/bin/bash
set -e

# Variables
PROJECT_NAME="${project_name}"
ENVIRONMENT="${environment}"
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Log function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/user-data.log
}

log "Starting API Gateway setup for $PROJECT_NAME in $ENVIRONMENT"

# Update system
log "Updating system packages..."
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Install required packages
log "Installing required packages..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    git \
    nginx \
    ufw \
    htop \
    unzip \
    jq \
    python3-pip \
    python3-venv

# Install Docker
log "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
log "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Create application directory
mkdir -p /app
cd /app

# Create environment file
log "Creating environment configuration..."
cat > /app/.env << 'EOL'
# Application
NODE_ENV=production
PORT=3000
JWT_SECRET=change-me-to-a-secure-secret

# API Gateway Configuration
API_GATEWAY_PORT=3000
API_GATEWAY_HOST=0.0.0.0

# Microservices Configuration
MICROSERVICES_COUNT=5
MICROSERVICES_BASE_PORT=3001

# Load Balancer Configuration
ALB_DNS_NAME=${alb_dns_name}
NLB_DNS_NAME=${nlb_dns_name}

# Database Configuration
POSTGRES_HOST=${postgres_host}
POSTGRES_PORT=5432
POSTGRES_USER=${postgres_user}
POSTGRES_PASSWORD=${postgres_password}
POSTGRES_DB=${postgres_db}

MYSQL_HOST=${mysql_host}
MYSQL_PORT=3306
MYSQL_USER=${mysql_user}
MYSQL_PASSWORD=${mysql_password}
MYSQL_DATABASE=${mysql_database}

MONGODB_URI=mongodb://${mongodb_user}:${mongodb_password}@${mongodb_host}:27017/${mongodb_db}?authSource=admin

REDIS_HOST=${redis_host}
REDIS_PORT=6379
REDIS_PASSWORD=${redis_password}

# AWS Configuration
AWS_REGION=${aws_region}
AWS_ACCESS_KEY_ID=${aws_access_key_id}
AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}

# Monitoring Configuration
ENABLE_CLOUDWATCH_LOGS=true
ENABLE_SITE24X7=${site24x7_enabled}
SITE24X7_AGENT_KEY=${site24x7_agent_key}
ENABLE_GRAFANA=${grafana_enabled}
GRAFANA_ENDPOINT=${grafana_endpoint}
GRAFANA_API_KEY=${grafana_api_key}
EOL

# Create API Gateway application
log "Creating API Gateway application..."
cat > /app/package.json << 'EOL'
{
  "name": "api-gateway",
  "version": "1.0.0",
  "description": "API Gateway for InfraDM-Impr3q",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "http-proxy-middleware": "^2.0.6",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "morgan": "^1.10.0",
    "dotenv": "^16.3.1",
    "winston": "^3.10.0",
    "redis": "^4.6.10",
    "axios": "^1.5.0",
    "compression": "^1.7.4",
    "swagger-ui-express": "^5.0.0",
    "swagger-jsdoc": "^6.2.8"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOL

# Create API Gateway server
cat > /app/server.js << 'EOL'
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const winston = require('winston');
const swaggerUi = require('swagger-ui-express');
const swaggerJsdoc = require('swagger-jsdoc');
require('dotenv').config();

const app = express();
const PORT = process.env.API_GATEWAY_PORT || 3000;

// Configure logging
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: '/var/log/api-gateway.log' }),
    new winston.transports.Console()
  ]
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(compression());
app.use(morgan('combined', { stream: { write: message => logger.info(message.trim()) } }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Swagger configuration
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'InfraDM-Impr3q API Gateway',
      version: '1.0.0',
      description: 'API Gateway para el sistema de cotización de impresión 3D',
      contact: {
        name: 'API Support',
        email: 'support@infradm.com'
      }
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Development server'
      }
    ],
    components: {
      schemas: {
        Product: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              format: 'uuid',
              description: 'ID único del producto'
            },
            codigo: {
              type: 'string',
              maxLength: 50,
              description: 'Código del producto'
            },
            precio: {
              type: 'number',
              format: 'decimal',
              description: 'Precio del producto'
            },
            stock: {
              type: 'integer',
              description: 'Cantidad en stock'
            },
            activo: {
              type: 'boolean',
              description: 'Estado activo del producto'
            },
            fecha_creacion: {
              type: 'string',
              format: 'date-time',
              description: 'Fecha de creación'
            }
          }
        },
        Material: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              format: 'uuid',
              description: 'ID único del material'
            },
            nombre: {
              type: 'string',
              maxLength: 100,
              description: 'Nombre del material'
            },
            descripcion: {
              type: 'string',
              description: 'Descripción del material'
            },
            codigo: {
              type: 'string',
              maxLength: 50,
              description: 'Código del material'
            },
            especificaciones_tecnicas: {
              type: 'object',
              properties: {
                tipo_material: {
                  type: 'string',
                  description: 'Tipo de material (PLA, ABS, etc.)'
                },
                temperatura_impresion: {
                  type: 'integer',
                  description: 'Temperatura de impresión recomendada'
                },
                velocidad_recomendada: {
                  type: 'integer',
                  description: 'Velocidad de impresión recomendada'
                }
              }
            }
          }
        },
        Category: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              format: 'uuid',
              description: 'ID único de la categoría'
            },
            nombre: {
              type: 'string',
              maxLength: 100,
              description: 'Nombre de la categoría'
            },
            descripcion: {
              type: 'string',
              description: 'Descripción de la categoría'
            },
            categoria_padre_id: {
              type: 'string',
              format: 'uuid',
              description: 'ID de la categoría padre (opcional)'
            }
          }
        },
        Quotation: {
          type: 'object',
          properties: {
            id: {
              type: 'integer',
              description: 'ID único de la cotización'
            },
            customer_name: {
              type: 'string',
              maxLength: 100,
              description: 'Nombre del cliente'
            },
            customer_email: {
              type: 'string',
              format: 'email',
              description: 'Email del cliente'
            },
            total_amount: {
              type: 'number',
              format: 'decimal',
              description: 'Monto total de la cotización'
            },
            status: {
              type: 'string',
              enum: ['pending', 'approved', 'rejected'],
              description: 'Estado de la cotización'
            }
          }
        },
        User: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              format: 'uuid',
              description: 'ID único del usuario'
            },
            username: {
              type: 'string',
              maxLength: 50,
              description: 'Nombre de usuario'
            },
            email: {
              type: 'string',
              format: 'email',
              description: 'Email del usuario'
            },
            role: {
              type: 'string',
              enum: ['admin', 'user', 'operator'],
              description: 'Rol del usuario'
            }
          }
        }
      }
    }
  },
  apis: ['./routes/*.js', './server.js']
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);

// Swagger UI
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'InfraDM-Impr3q API Documentation'
}));

// Swagger JSON endpoint
app.get('/swagger.json', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.send(swaggerSpec);
});

/**
 * @swagger
 * /health:
 *   get:
 *     summary: Health check endpoint
 *     description: Verifica el estado del API Gateway
 *     tags: [System]
 *     responses:
 *       200:
 *         description: API Gateway funcionando correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: OK
 *                 timestamp:
 *                   type: string
 *                   format: date-time
 *                 service:
 *                   type: string
 *                   example: api-gateway
 *                 version:
 *                   type: string
 *                   example: 1.0.0
 */
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'api-gateway',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development'
  });
});

/**
 * @swagger
 * /api:
 *   get:
 *     summary: Información del API Gateway
 *     description: Obtiene información general del API Gateway y servicios disponibles
 *     tags: [System]
 *     responses:
 *       200:
 *         description: Información del API Gateway
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: InfraDM-Impr3q API Gateway
 *                 version:
 *                   type: string
 *                   example: 1.0.0
 *                 services:
 *                   type: array
 *                   items:
 *                     type: string
 *                   example: ["products", "materials", "categories", "quotations", "users"]
 */
app.get('/api', (req, res) => {
  res.json({
    message: 'InfraDM-Impr3q API Gateway',
    version: '1.0.0',
    services: [
      'products',
      'materials',
      'categories',
      'quotations',
      'users'
    ],
    documentation: '/api-docs',
    swagger: '/swagger.json'
  });
});

// Microservices proxy configuration
const microservices = [
  { name: 'products', port: 3001, description: 'Gestión de productos' },
  { name: 'materials', port: 3002, description: 'Gestión de materiales' },
  { name: 'categories', port: 3003, description: 'Gestión de categorías' },
  { name: 'quotations', port: 3004, description: 'Gestión de cotizaciones' },
  { name: 'users', port: 3005, description: 'Gestión de usuarios' }
];

// Create proxy routes for each microservice
microservices.forEach(service => {
  /**
   * @swagger
   * /api/{service}:
   *   get:
   *     summary: Proxy to {service} microservice
   *     description: Redirige la petición al microservicio {service}
   *     tags: [Microservices]
   *     parameters:
   *       - in: path
   *         name: service
   *         required: true
   *         schema:
   *           type: string
   *         description: Nombre del microservicio
   *     responses:
   *       200:
   *         description: Respuesta del microservicio
   *       503:
   *         description: Microservicio no disponible
   */
  app.use(`/api/${service.name}`, createProxyMiddleware({
    target: `http://localhost:${service.port}`,
    changeOrigin: true,
    pathRewrite: {
      [`^/api/${service.name}`]: ''
    },
    onError: (err, req, res) => {
      logger.error(`Proxy error for ${service.name}:`, err);
      res.status(503).json({
        error: 'Service temporarily unavailable',
        service: service.name,
        description: service.description
      });
    },
    onProxyReq: (proxyReq, req, res) => {
      logger.info(`Proxying request to ${service.name}: ${req.method} ${req.path}`);
    }
  }));
});

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error('Unhandled error:', err);
  res.status(500).json({
    error: 'Internal server error',
    service: 'api-gateway',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not found',
    service: 'api-gateway',
    path: req.originalUrl,
    available_endpoints: [
      '/health',
      '/api',
      '/api-docs',
      '/swagger.json',
      '/api/products',
      '/api/materials',
      '/api/categories',
      '/api/quotations',
      '/api/users'
    ]
  });
});

// Start server
app.listen(PORT, () => {
  logger.info(`API Gateway started on port ${PORT}`);
  logger.info(`Environment: ${process.env.NODE_ENV}`);
  logger.info(`Health check available at: http://localhost:${PORT}/health`);
  logger.info(`API Documentation available at: http://localhost:${PORT}/api-docs`);
  logger.info(`Swagger JSON available at: http://localhost:${PORT}/swagger.json`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  process.exit(0);
});
EOL

# Create Dockerfile for API Gateway
cat > /app/Dockerfile << 'EOL'
FROM node:18-alpine

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy application code
COPY . .

# Create log directory
RUN mkdir -p /var/log

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Start application
CMD ["npm", "start"]
EOL

# Create docker-compose for API Gateway
cat > /app/docker-compose.yml << 'EOL'
version: '3.8'

services:
  api-gateway:
    build: .
    container_name: ${PROJECT_NAME}-api-gateway
    restart: unless-stopped
    ports:
      - "3000:3000"
    env_file:
      - .env
    volumes:
      - /var/log:/var/log
    networks:
      - api-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  nginx:
    image: nginx:alpine
    container_name: ${PROJECT_NAME}-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/conf.d:/etc/nginx/conf.d
    depends_on:
      - api-gateway
    networks:
      - api-network

networks:
  api-network:
    driver: bridge
EOL

# Create nginx configuration
mkdir -p /app/nginx/conf.d

cat > /app/nginx/nginx.conf << 'EOL'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;

    # Upstream for API Gateway
    upstream api_gateway {
        server api-gateway:3000;
    }

    # Main server block
    server {
        listen 80;
        server_name _;

        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

        # Health check endpoint
        location = /health {
            access_log off;
            add_header Content-Type application/json;
            return 200 '{"status":"OK","service":"nginx","timestamp":"$time_iso8601"}';
        }

        # API Gateway proxy
        location / {
            limit_req zone=api burst=20 nodelay;
            
            proxy_pass http://api_gateway;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            
            # Timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }
    }
}
EOL

# Install Node.js dependencies
log "Installing Node.js dependencies..."
cd /app
npm install

# Configure firewall
log "Configuring firewall..."
ufw --force enable
ufw allow ssh
ufw allow 'Nginx Full'
ufw allow 3000/tcp

# Install and configure monitoring agents
if [ "$ENABLE_SITE24X7" = "true" ] && [ -n "$SITE24X7_AGENT_KEY" ]; then
    log "Installing Site24x7 agent..."
    wget -O /tmp/site24x7agent.sh https://staticdownloads.site24x7.com/server/Site24x7InstallScript.sh
    chmod +x /tmp/site24x7agent.sh
    /tmp/site24x7agent.sh -i -key="$SITE24X7_AGENT_KEY" -noninteractive
fi

# Start services
log "Starting services..."
cd /app
docker-compose up -d

# Set up log rotation
log "Setting up log rotation..."
cat > /etc/logrotate.d/api-gateway << 'EOL'
/var/log/api-gateway.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ubuntu ubuntu
    postrotate
        systemctl reload nginx > /dev/null 2>&1 || true
    endscript
}
EOL

# Set up automatic updates
log "Setting up automatic updates..."
(crontab -l 2>/dev/null; echo "0 3 * * * /usr/bin/docker system prune -af --volumes") | crontab -
(crontab -l 2>/dev/null; echo "0 4 * * * cd /app && /usr/local/bin/docker-compose pull && /usr/local/bin/docker-compose up -d") | crontab -

# Set permissions
chown -R ubuntu:ubuntu /app
chmod -R 755 /app

log "API Gateway setup completed successfully!"
log "API Gateway is available at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
log "Health check: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/health" 