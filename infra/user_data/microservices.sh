#!/bin/bash
set -e

# Variables
PROJECT_NAME="${project_name}"
ENVIRONMENT="${environment}"
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Determine microservice number based on instance metadata
TAGS=$(aws ec2 describe-tags --region $REGION --filters "Name=resource-id,Values=$INSTANCE_ID" --query 'Tags[?Key==`Name`].Value' --output text)
MICROSERVICE_NUM=$(echo $TAGS | grep -o '[0-9]\+' | head -1)
MICROSERVICE_PORT=$((3000 + MICROSERVICE_NUM))

# Log function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Microservice-$MICROSERVICE_NUM: $1" | tee -a /var/log/user-data.log
}

log "Starting Microservice $MICROSERVICE_NUM setup for $PROJECT_NAME in $ENVIRONMENT"

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
cat > /app/.env << EOL
# Microservice Configuration
MICROSERVICE_NUM=$MICROSERVICE_NUM
MICROSERVICE_PORT=$MICROSERVICE_PORT
NODE_ENV=production

# Database Configuration
POSTGRES_HOST=\${postgres_host}
POSTGRES_PORT=5432
POSTGRES_USER=\${postgres_user}
POSTGRES_PASSWORD=\${postgres_password}
POSTGRES_DB=\${postgres_db}

MYSQL_HOST=\${mysql_host}
MYSQL_PORT=3306
MYSQL_USER=\${mysql_user}
MYSQL_PASSWORD=\${mysql_password}
MYSQL_DATABASE=\${mysql_database}

MONGODB_URI=mongodb://\${mongodb_user}:\${mongodb_password}@\${mongodb_host}:27017/\${mongodb_db}?authSource=admin

REDIS_HOST=\${redis_host}
REDIS_PORT=6379
REDIS_PASSWORD=\${redis_password}

# AWS Configuration
AWS_REGION=\${aws_region}
AWS_ACCESS_KEY_ID=\${aws_access_key_id}
AWS_SECRET_ACCESS_KEY=\${aws_secret_access_key}

# Monitoring Configuration
ENABLE_CLOUDWATCH_LOGS=true
ENABLE_SITE24X7=\${site24x7_enabled}
SITE24X7_AGENT_KEY=\${site24x7_agent_key}
ENABLE_GRAFANA=\${grafana_enabled}
GRAFANA_ENDPOINT=\${grafana_endpoint}
GRAFANA_API_KEY=\${grafana_api_key}
EOL

# Create microservice application based on number
log "Creating microservice $MICROSERVICE_NUM application..."

# Define microservice types
case $MICROSERVICE_NUM in
    1) SERVICE_NAME="products"; SERVICE_DESC="Product Management Service"; ;;
    2) SERVICE_NAME="materials"; SERVICE_DESC="Material Management Service"; ;;
    3) SERVICE_NAME="categories"; SERVICE_DESC="Category Management Service"; ;;
    4) SERVICE_NAME="quotations"; SERVICE_DESC="Quotation Management Service"; ;;
    5) SERVICE_NAME="users"; SERVICE_DESC="User Management Service"; ;;
    *) SERVICE_NAME="generic"; SERVICE_DESC="Generic Microservice"; ;;
esac

# Create package.json
cat > /app/package.json << EOL
{
  "name": "$SERVICE_NAME-service",
  "version": "1.0.0",
  "description": "$SERVICE_DESC",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "morgan": "^1.10.0",
    "dotenv": "^16.3.1",
    "winston": "^3.10.0",
    "redis": "^4.6.10",
    "axios": "^1.5.0",
    "compression": "^1.7.4",
    "mysql2": "^3.6.5",
    "pg": "^8.11.3",
    "mongodb": "^5.7.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOL

# Create microservice server
cat > /app/server.js << EOL
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const winston = require('winston');
require('dotenv').config();

const app = express();
const PORT = process.env.MICROSERVICE_PORT || $MICROSERVICE_PORT;
const SERVICE_NAME = '$SERVICE_NAME';
const SERVICE_NUM = $MICROSERVICE_NUM;

// Configure logging
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: { service: SERVICE_NAME, instance: SERVICE_NUM },
  transports: [
    new winston.transports.File({ filename: '/var/log/microservice.log' }),
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

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: SERVICE_NAME,
    instance: SERVICE_NUM,
    port: PORT,
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development'
  });
});

// Service info endpoint
app.get('/info', (req, res) => {
  res.json({
    service: SERVICE_NAME,
    description: '$SERVICE_DESC',
    instance: SERVICE_NUM,
    port: PORT,
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    pid: process.pid
  });
});

// Service-specific routes
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to $SERVICE_DESC',
    service: SERVICE_NAME,
    instance: SERVICE_NUM,
    endpoints: [
      '/health',
      '/info',
      '/api'
    ]
  });
});

// API routes
app.get('/api', (req, res) => {
  res.json({
    service: SERVICE_NAME,
    instance: SERVICE_NUM,
    message: 'API endpoint for $SERVICE_DESC',
    timestamp: new Date().toISOString()
  });
});

// Service-specific API endpoints
switch (SERVICE_NAME) {
  case 'products':
    app.get('/api/products', (req, res) => {
      res.json({
        service: SERVICE_NAME,
        instance: SERVICE_NUM,
        data: [
          { id: 1, name: 'Product 1', price: 100 },
          { id: 2, name: 'Product 2', price: 200 }
        ]
      });
    });
    break;
    
  case 'materials':
    app.get('/api/materials', (req, res) => {
      res.json({
        service: SERVICE_NAME,
        instance: SERVICE_NUM,
        data: [
          { id: 1, name: 'PLA', type: 'filament' },
          { id: 2, name: 'ABS', type: 'filament' }
        ]
      });
    });
    break;
    
  case 'categories':
    app.get('/api/categories', (req, res) => {
      res.json({
        service: SERVICE_NAME,
        instance: SERVICE_NUM,
        data: [
          { id: 1, name: 'Electronics', parent_id: null },
          { id: 2, name: 'Mechanical', parent_id: null }
        ]
      });
    });
    break;
    
  case 'quotations':
    app.get('/api/quotations', (req, res) => {
      res.json({
        service: SERVICE_NAME,
        instance: SERVICE_NUM,
        data: [
          { id: 1, customer: 'Customer 1', total: 500 },
          { id: 2, customer: 'Customer 2', total: 750 }
        ]
      });
    });
    break;
    
  case 'users':
    app.get('/api/users', (req, res) => {
      res.json({
        service: SERVICE_NAME,
        instance: SERVICE_NUM,
        data: [
          { id: 1, name: 'User 1', email: 'user1@example.com' },
          { id: 2, name: 'User 2', email: 'user2@example.com' }
        ]
      });
    });
    break;
    
  default:
    app.get('/api/data', (req, res) => {
      res.json({
        service: SERVICE_NAME,
        instance: SERVICE_NUM,
        message: 'Generic data endpoint',
        timestamp: new Date().toISOString()
      });
    });
}

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error('Unhandled error:', err);
  res.status(500).json({
    error: 'Internal server error',
    service: SERVICE_NAME,
    instance: SERVICE_NUM,
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not found',
    service: SERVICE_NAME,
    instance: SERVICE_NUM,
    path: req.originalUrl
  });
});

// Start server
app.listen(PORT, () => {
  logger.info(\`$SERVICE_DESC started on port \${PORT}\`);
  logger.info(\`Service: \${SERVICE_NAME}, Instance: \${SERVICE_NUM}\`);
  logger.info(\`Environment: \${process.env.NODE_ENV}\`);
  logger.info(\`Health check available at: http://localhost:\${PORT}/health\`);
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

# Create Dockerfile
cat > /app/Dockerfile << EOL
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
EXPOSE $MICROSERVICE_PORT

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \\
  CMD curl -f http://localhost:$MICROSERVICE_PORT/health || exit 1

# Start application
CMD ["npm", "start"]
EOL

# Create docker-compose
cat > /app/docker-compose.yml << EOL
version: '3.8'

services:
  microservice-$MICROSERVICE_NUM:
    build: .
    container_name: \${PROJECT_NAME}-microservice-$MICROSERVICE_NUM
    restart: unless-stopped
    ports:
      - "$MICROSERVICE_PORT:$MICROSERVICE_PORT"
    env_file:
      - .env
    volumes:
      - /var/log:/var/log
    networks:
      - microservice-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:$MICROSERVICE_PORT/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

networks:
  microservice-network:
    driver: bridge
EOL

# Install Node.js dependencies
log "Installing Node.js dependencies..."
cd /app
npm install

# Configure firewall
log "Configuring firewall..."
ufw --force enable
ufw allow ssh
ufw allow $MICROSERVICE_PORT/tcp

# Install and configure monitoring agents
if [ "$ENABLE_SITE24X7" = "true" ] && [ -n "$SITE24X7_AGENT_KEY" ]; then
    log "Installing Site24x7 agent..."
    wget -O /tmp/site24x7agent.sh https://staticdownloads.site24x7.com/server/Site24x7InstallScript.sh
    chmod +x /tmp/site24x7agent.sh
    /tmp/site24x7agent.sh -i -key="$SITE24X7_AGENT_KEY" -noninteractive
fi

# Start services
log "Starting microservice $MICROSERVICE_NUM..."
cd /app
docker-compose up -d

# Set up log rotation
log "Setting up log rotation..."
cat > /etc/logrotate.d/microservice << EOL
/var/log/microservice.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ubuntu ubuntu
}
EOL

# Set up automatic updates
log "Setting up automatic updates..."
(crontab -l 2>/dev/null; echo "0 3 * * * /usr/bin/docker system prune -af --volumes") | crontab -
(crontab -l 2>/dev/null; echo "0 4 * * * cd /app && /usr/local/bin/docker-compose pull && /usr/local/bin/docker-compose up -d") | crontab -

# Set permissions
chown -R ubuntu:ubuntu /app
chmod -R 755 /app

log "Microservice $MICROSERVICE_NUM setup completed successfully!"
log "Microservice is available at: http://\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):$MICROSERVICE_PORT"
log "Health check: http://\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):$MICROSERVICE_PORT/health" 