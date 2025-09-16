# config/initializers/smtp.rb
# Configuración SMTP forzada para ActionMailer

if Rails.env.production?
  puts "=== SMTP INITIALIZER DEBUG ==="
  puts "ENV SMTP_USERNAME: #{ENV['SMTP_USERNAME']}"
  puts "ENV SMTP_PASSWORD present?: #{ENV['SMTP_PASSWORD'].present?}"
  puts "================================"

  if ENV['SMTP_USERNAME'].present?
    puts "✓ Configurando SMTP en inicializador..."
    
    # Configuración SMTP forzada
    ActionMailer::Base.delivery_method = :smtp
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.raise_delivery_errors = true
    
    # Determinar si usar SSL o TLS
    use_ssl = ENV.fetch('SMTP_USE_SSL', 'false') == 'true'
    port = ENV.fetch('SMTP_PORT', use_ssl ? 465 : 587).to_i
    
    ActionMailer::Base.smtp_settings = {
      address: ENV.fetch('SMTP_HOST', 'smtp.gmail.com'),
      port: port,
      domain: ENV.fetch('SMTP_DOMAIN', 'gmail.com'),
      user_name: ENV.fetch('SMTP_USERNAME'),
      password: ENV.fetch('SMTP_PASSWORD'),
      authentication: :plain,
      enable_starttls_auto: !use_ssl,
      tls: use_ssl,
      openssl_verify_mode: 'none',
      open_timeout: 30,
      read_timeout: 30
    }
    
    puts "✓ SMTP configurado en inicializador:"
    puts "  delivery_method: #{ActionMailer::Base.delivery_method}"
    puts "  smtp_settings: #{ActionMailer::Base.smtp_settings}"
    puts "  Puerto: #{port}, SSL: #{use_ssl}"
    
    # Verificar la configuración después de configurarla
    Rails.application.config.after_initialize do
      puts "=== POST-INIT SMTP CHECK ==="
      puts "ActionMailer delivery_method: #{ActionMailer::Base.delivery_method}"
      puts "ActionMailer smtp_settings: #{ActionMailer::Base.smtp_settings}"
      puts "============================"
    end
  else
    puts "✗ SMTP_USERNAME no presente en inicializador"
  end
end
