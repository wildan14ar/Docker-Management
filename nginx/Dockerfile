# Using latest nginx image
FROM nginx:latest

# Install additional tools for networking (optional)
RUN apt-get update && apt-get install -y \
    curl \
    iputils-ping \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Copy nginx main config
COPY ./nginx.conf /etc/nginx/nginx.conf

# Copy server configuration
COPY ./config/default.conf /etc/nginx/conf.d/default.conf

# Delete default conf (if exists)
RUN rm -f /etc/nginx/conf.d/default.conf.bak

# Create log directory
RUN mkdir -p /var/log/nginx

# Set permissions
RUN chown -R nginx:nginx /var/log/nginx

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1