# Stage 1
ARG BUILD_FROM=arm32v7/node:16-alpine
ARG RUN_FROM=arm32v7/alpine
FROM ${BUILD_FROM} AS BUILD_IMAGE

# Install dependencies
RUN apk update && \
    apk add --no-cache alpine-sdk python3 linux-headers && \
    rm -rf /var/cache/apk/*

# Working directory
WORKDIR /usr/src/app

# Force cache invalidation
ADD https://api.github.com/repos/adrigzr/Valetudo/git/refs/heads/feature-conga /usr/src/version.json

# Download valetudo
RUN git clone --depth 1 https://github.com/adrigzr/Valetudo --branch feature-conga --single-branch .

# Build environment
ENV PKG_CACHE_PATH=./build_dependencies/pkg
ENV NODE_ENV=production

# Install dependencies
RUN npm ci
RUN npm install pkg

# Build args
ARG PKG_TARGET=node16-linuxstatic-armv7
ARG PKG_MEMORY=34

# Build binary
RUN npx pkg \
      --targets ${PKG_TARGET} \
      --no-bytecode \
      --public-packages "*" \
      --options "expose-gc,max-heap-size=${PKG_MEMORY}" \
      --output ./build/valetudo \
      backend

# Stage 2
FROM ${RUN_FROM}

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
