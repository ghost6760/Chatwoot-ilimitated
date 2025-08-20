# Dockerfile reconstruido basado en chatwoot/chatwoot:latest
# Para repo privado con adaptaciones necesarias

# Imagen base Ruby 3.4.4 sobre Alpine Linux
FROM ruby:3.4.4-alpine

# Variables de entorno base
ENV LANG=C.UTF-8
ENV RUBY_VERSION=3.4.4
ENV NODE_VERSION=23.7.0
ENV PNPM_VERSION=10.2.0
ENV BUNDLER_VERSION=2.5.11

# Variables de configuración Rails/Bundle
ENV RAILS_ENV=production
ENV BUNDLE_WITHOUT=development:test
ENV BUNDLE_FORCE_RUBY_PLATFORM=1
ENV BUNDLE_SILENCE_ROOT_WARNING=1
ENV BUNDLE_APP_CONFIG=/usr/local/bundle
ENV BUNDLE_PATH=/gems
ENV GEM_HOME=/usr/local/bundle

# Variables específicas de Chatwoot
ENV RAILS_SERVE_STATIC_FILES=true
ENV EXECJS_RUNTIME=Disabled
ENV CW_EDITION=ee

# Instalar dependencias del sistema
RUN set -eux && \
    apk add --no-cache \
        bash \
        build-base \
        curl \
        git \
        imagemagick \
        libpq-dev \
        postgresql-client \
        redis \
        tzdata \
        python3 \
        make \
        g++ \
        libc6-compat \
        vips-dev \
        vips-tools \
        shared-mime-info \
        nodejs \
        npm

# Instalar Node.js específico y pnpm
RUN curl -fsSL https://unofficial-builds.nodejs.org/download/release/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64-musl.tar.gz | \
    tar -xz -C /usr/local --strip-components=1

# Instalar pnpm globalmente
RUN npm install -g pnpm@${PNPM_VERSION}

# Instalar husky globalmente para evitar errores en prepare scripts
RUN npm install -g husky

# Crear directorio de gems
RUN mkdir -p /gems
ENV BUNDLE_PATH=/gems

# Establecer directorio de trabajo
WORKDIR /app

# Copiar Gemfile primero para cache de Docker layers
COPY Gemfile* ./

# Instalar bundler y gems
RUN gem install bundler -v ${BUNDLER_VERSION} && \
    bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copiar package.json y yarn.lock/pnpm-lock.yaml si existen
COPY package*.json yarn.lock* pnpm-lock.yaml* ./

# Instalar dependencias de Node.js
RUN if [ -f "pnpm-lock.yaml" ]; then \
        pnpm install --frozen-lockfile --prod --ignore-scripts; \
    elif [ -f "yarn.lock" ]; then \
        yarn install --production --frozen-lockfile --ignore-scripts; \
    else \
        npm ci --only=production --ignore-scripts; \
    fi

# Ejecutar prepare scripts manualmente si es necesario (sin husky)
RUN if [ -f "pnpm-lock.yaml" ]; then \
        HUSKY=0 pnpm rebuild || true; \
    fi

# Copiar el resto del código
COPY . .

# Compilar assets si es necesario
RUN if [ -f "config/application.rb" ]; then \
        SECRET_KEY_BASE=dummy bundle exec rails assets:precompile || true; \
    fi

# Crear archivo .git_sha si no existe (Railway lo usa para tracking)
RUN echo "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')" > .git_sha 2>/dev/null || echo 'local-build' > .git_sha

# Configurar permisos
RUN chown -R nobody:nogroup /app /gems
USER nobody

# Puerto que expone la aplicación
EXPOSE 3000

# Comando por defecto - Railway override esto con startCommand
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
