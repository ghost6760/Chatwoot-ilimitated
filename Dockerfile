FROM ruby:3.4.4

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

# Node + pnpm
RUN curl -fsSL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz \
    -o node.tar.xz \
    && tar -xJf node.tar.xz -C /usr/local --strip-components=1 \
    && rm node.tar.xz \
    && npm install -g pnpm@${PNPM_VERSION}

RUN apt-get update && apt-get install -y \
    build-essential curl git \
    libpq-dev libxml2-dev libxslt1-dev \
    libmagickwand-dev imagemagick \
    libffi-dev libyaml-dev libssl-dev zlib1g-dev \
    libreadline-dev libsqlite3-dev wget tzdata \
    postgresql-client redis-tools \
    && rm -rf /var/lib/apt/lists/*

RUN gem install bundler -v ${BUNDLER_VERSION}

WORKDIR /app

# copiar archivos de dependencia (capa cacheable)
COPY Gemfile Gemfile.lock package.json pnpm-lock.yaml ./

# instalar deps ruby + js
RUN bundle config set --local deployment 'true' \
    && bundle config set --local without ${BUNDLE_WITHOUT} \
    && bundle install --jobs 4 --retry 3 \
    && pnpm install --frozen-lockfile --prod --ignore-scripts

# --- DIAGNÓSTICO: buscar módulo / archivos del gem acts-as-taggable-on ---
# La salida de estos comandos aparecerá en los build logs de Railway.
RUN echo "=== BUNDLE INFO acts-as-taggable-on ===" \
 && bundle info acts-as-taggable-on 2>/dev/null || bundle show acts-as-taggable-on 2>/dev/null || true \
 && echo "=== LIST /lib of gem ===" \
 && (GEM_PATH=$(bundle show acts-as-taggable-on 2>/dev/null || true) && [ -n "$GEM_PATH" ] && ls -la "$GEM_PATH/lib" || echo "No pude localizar la ruta del gem") \
 && echo "=== GREP: buscar 'module .*Cache' e 'Taggable::Cache' en lib ===" \
 && (GEM_PATH=$(bundle show acts-as-taggable-on 2>/dev/null || true) && [ -n "$GEM_PATH" ] && (grep -R --line-number \"module .*Cache\" \"$GEM_PATH/lib\" || true) && (grep -R --line-number \"Taggable::Cache\" \"$GEM_PATH/lib\" || true) || true) \
 && echo "=== COMPROBACIÓN RUNTIME via ruby (intentando require y defined?) ===" \
 && bundle exec ruby -e "begin; require 'acts_as_taggable_on'; rescue LoadError => e; puts 'require acts_as_taggable_on failed: '+e.message; end; begin; require 'acts-as-taggable-on'; rescue LoadError => e; puts 'require acts-as-taggable-on failed: '+e.message; end; puts 'ActsAsTaggableOn defined? -> ' + (!!defined?(ActsAsTaggableOn)).to_s; begin; puts 'ActsAsTaggableOn::Taggable::Cache defined? -> ' + (!!defined?(ActsAsTaggableOn::Taggable::Cache)).to_s rescue puts 'ActsAsTaggableOn::Taggable::Cache -> error or not defined'; end" \
 || true

# copiar el resto del código
COPY . .

# precompile assets
RUN rm -rf tmp/cache/* public/assets/* node_modules/.cache node_modules/.vite
RUN SECRET_KEY_BASE=dummy_for_precompile \
    DATABASE_URL=postgresql://dummy:dummy@localhost/dummy \
    REDIS_URL=redis://localhost:6379/0 \
    bundle exec rails assets:precompile

EXPOSE 3000

CMD ["sh", "-c", "bundle exec rails db:create db:migrate && bundle exec rails db:seed && bundle exec rails server -b 0.0.0.0 -p $PORT"]
