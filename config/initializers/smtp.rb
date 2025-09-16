# config/initializers/smtp.rb
# Configuración SMTP para SendGrid

if Rails.env.production?
  puts "=== SMTP INITIALIZER DEBUG ==="
  puts "ENV SMTP_USERNAME: #{ENV['SMTP_USERNAME']}"
  puts "ENV SMTP_PASSWORD present?: #{ENV['SMTP_PASSWORD'].present?}"
  puts "ENV SMTP_HOST: #{ENV['SMTP_HOST']}"
  puts "================================"

  if ENV['SMTP_USERNAME'].present?
    puts "✓ Configurando SMTP en inicializador..."
    
    # Configuración optimizada para SendGrid
    ActionMailer::Base.delivery_method = :smtp
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.raise_delivery_errors = true
    
    ActionMailer::Base.smtp_settings = {
      address: ENV.fetch('SMTP_HOST', 'smtp.sendgrid.net'),
      port: ENV.fetch('SMTP_PORT', 587).to_i,
      domain: ENV.fetch('SMTP_DOMAIN', 'chatwootultimate-production.up.railway.app'),
      user_name: ENV.fetch('SMTP_USERNAME'),
      password: ENV.fetch('SMTP_PASSWORD'),
      authentication: :plain,
      enable_starttls_auto: true,
      openssl_verify_mode: 'none'
    }
    
    puts "✓ SMTP configurado en inicializador:"
    puts "  delivery_method: #{ActionMailer::Base.delivery_method}"
    puts "  host: #{ActionMailer::Base.smtp_settings[:address]}"
    puts "  port: #{ActionMailer::Base.smtp_settings[:port]}"
    puts "  domain: #{ActionMailer::Base.smtp_settings[:domain]}"
    
    # Verificar la configuración después de configurarla
    Rails.application.config.after_initialize do
      puts "=== POST-INIT SMTP CHECK ==="
      puts "ActionMailer delivery_method: #{ActionMailer::Base.delivery_method}"
      puts "SMTP Host: #{ActionMailer::Base.smtp_settings[:address]}"
      puts "============================"
    end
  else
    puts "✗ SMTP_USERNAME no presente en inicializador"
  end
end
