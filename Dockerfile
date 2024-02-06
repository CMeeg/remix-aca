FROM node:18-bullseye-slim AS base

# Set for base and all layer that inherit from it
ENV NODE_ENV production

# Install all dependencies for the build step
FROM base AS deps
WORKDIR /app

# A lockfile is required
COPY package.json package-lock.json* ./
RUN \
  if [ -f package-lock.json ]; then npm ci --include=dev; \
  else echo "Lockfile not found." && exit 1; \
  fi

# Filter out dev dependencies for production usage
FROM base AS deps-prod
WORKDIR /app

# Copy all deps and then prune only dev deps
COPY --from=deps /app/node_modules ./node_modules
COPY package.json package-lock.json* ./

RUN npm prune --omit=dev

# Build the source code
FROM base AS builder
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN npm run build

# Create the production image, copy all the files and run the server
FROM base AS runner
WORKDIR /app

COPY --from=deps-prod /app/node_modules ./node_modules
COPY --from=builder /app/build ./build
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/server.js ./server.js

EXPOSE 3000

ENV PORT 3000

CMD ["node", "server.js"]
