# Lightweight base
FROM node:20-alpine

# App lives here
WORKDIR /app

# Install deps first (better layer caching)
COPY package*.json ./
RUN npm ci --omit=dev

# Copy source
COPY app.js ./

# Non-root user (node image ships an unprivileged "node" user)
USER node

# Document the port
EXPOSE 3000

# Start
CMD ["node", "app.js"]