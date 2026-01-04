# -------- Base --------
FROM node:24-alpine AS base
WORKDIR /app

RUN apk add --no-cache libc6-compat

# -------- Dependencies --------
FROM base AS deps
COPY package*.json ./
RUN npm ci --omit=dev

# -------- Runtime --------
FROM base AS runner

ENV NODE_ENV=production
ENV PORT=3000

RUN addgroup -S nodejs && adduser -S nodejs -G nodejs

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN chown -R nodejs:nodejs /app
USER nodejs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
    CMD node -e "fetch('http://localhost:3000/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "index.js"]
