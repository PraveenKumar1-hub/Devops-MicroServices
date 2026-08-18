# ==========================================
# STAGE 1: Build & Dependency Resolution
# ==========================================
FROM node:20-alpine AS builder

WORKDIR /usr/src/app

# Install build dependencies from src directory
COPY src/package*.json ./
RUN npm ci --only=production

# Copy application source code
COPY src/ ./

# ==========================================
# STAGE 2: Minimal Production Runtime
# ==========================================
FROM node:20-alpine AS runner

WORKDIR /usr/src/app

ENV NODE_ENV=production
ENV PORT=3000

# Security: Create a non-privileged system user & group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy only production artifacts from builder stage
COPY --from=builder --chown=appuser:appgroup /usr/src/app ./

# Switch to non-root user
USER appuser

# Expose internal container port
EXPOSE 3000

# Health check instruction inside container
HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "server.js"]