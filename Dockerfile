# Stage 1
ARG BUILD_FROM=amd64/alpine:latest
FROM node:16-alpine AS BUILD_IMAGE

# Install dependencies
RUN apk update && \
    apk add --no-cache git && \
    rm -rf /var/cache/apk/*

# Working directory
WORKDIR /usr/src/app

# Force cache invalidation
ADD https://api.github.com/repos/adrigzr/Valetudo/git/refs/heads/feature-conga /usr/src/version.json

# Download valetudo
RUN git clone --depth 1 https://github.com/adrigzr/Valetudo --branch feature-conga --single-branch .

# Build environment
ENV NODE_ENV=production
ENV PKG_CACHE_PATH=./build_dependencies/pkg

# Install dependencies
RUN npm install -g npm
RUN npm ci --production=false

# Build openapi schema
RUN npm run build_openapi_schema

# Build args
ARG PKG_TARGET=node16-linuxstatic-x64
ARG PKG_OPTIONS=expose-gc,max-heap-size=64

# Build binary
RUN npx pkg \
      --targets ${PKG_TARGET} \
      --compress Brotli \
      --no-bytecode \
      --public-packages "*" \
      --options "${PKG_OPTIONS}" \
      --output ./build/valetudo \
      backend

# Stage 2
FROM ${BUILD_FROM}

# Install dependencies
RUN apk update && rm -rf /var/cache/apk/*

# Working directory
WORKDIR /usr/local/bin

# Copy from build image
COPY --from=BUILD_IMAGE /usr/src/app/build/valetudo ./valetudo

# Exposed ports
EXPOSE 8080
EXPOSE 4010 4030 4050

# Run environment
ENV LANG C.UTF-8
ENV VALETUDO_CONFIG_PATH=/etc/valetudo.json
ENV NODE_ENV=production

# Run binary
CMD ["valetudo"]
