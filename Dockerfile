# Use a multi-stage build for smaller final image size
FROM node:18-alpine as builder

WORKDIR /app

# Copy package files
COPY package*.json ./


# Install dependencies
RUN npm ci

# Copy source code
COPY . .


# Build the application
RUN npm run build

# Production stage
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./


# Install only production dependencies
RUN npm ci --only=production

# Copy built files from builder
COPY --from=builder /app/dist ./dist

# Expose the app port
EXPOSE 3000

# Command to run the application
CMD ["node", "dist/main.js"]
