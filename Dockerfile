# Dockerfile simple sin docker-entrypoint.sh
FROM ruby:3.4.4

# Variables de entorno de Railway
ENV LANG=C.UTF-8 \
    RUBY_VERSION=3.4.4 \
    GEM_HOME=/usr/local/bundle \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_APP_CONFIG=/usr/local/bundle \
    NODE_VERSION=23.7.0 \
    PNPM_VERSION=10.2.0 \
    BUNDLE_WITHOUT=development:test \
    BUNDLER_VERSION=2.5.11 \
    EXECJS_RUNTIME=Disabled \
    RAILS_SERVE_STATIC_FILES=true \
    BUNDLE_FORCE_RUBY_PLATFORM=1 \
    RAILS_ENV=production \
    BUNDLE_PATH=/gems \
    CW_EDITION=ce \
    HUSKY=0

# Instalar Node.js y PNPM
RUN curl -fsSL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz \
    -o node.tar.xz \
    && tar -xJf node.tar.xz -C /usr/local --strip-components=1 \
    && rm node.tar.xz \
    && npm install -g pnpm@${PNPM_VERSION}

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    build-essential curl git \
    libpq-dev libxml2-dev libxslt1-dev \
    libmagickwand-dev imagemagick \
    libffi-dev libyaml-dev libssl-dev zlib1g-dev \
    libreadline-dev libsqlite3-dev wget tzdata \
    postgresql-client redis-tools \
    && rm -rf /var/lib/apt/lists/*

# Instalar Bundler
RUN gem install bundler -v ${BUNDLER_VERSION}

WORKDIR /app

# Copiar archivos de dependencias
COPY Gemfile Gemfile.lock package.json pnpm-lock.yaml ./

# Instalar dependencias
RUN bundle config set --local deployment 'true' \
    && bundle config set --local without ${BUNDLE_WITHOUT} \
    && bundle install --jobs 4 --retry 3 \
    && pnpm install --frozen-lockfile --prod --ignore-scripts

# Copiar código fuente
COPY . .

# Precompilar assets
RUN SECRET_KEY_BASE=dummy_for_precompile \
    DATABASE_URL=postgresql://dummy:dummy@localhost/dummy \
    REDIS_URL=redis://localhost:6379/0 \
    bundle exec rails assets:precompile

EXPOSE 3000

# Comando de inicio directo (sin script separado)
CMD ["sh", "-c", "bundle exec rails db:create db:migrate && bundle exec rails db:seed && bundle exec rails server -b 0.0.0.0 -p $PORT"]
