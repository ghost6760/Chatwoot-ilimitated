# config/initializers/conditional_email_confirmation.rb

Rails.application.config.to_prepare do
  User.class_eval do
    after_create :auto_confirm_if_disabled
    
    private
    
    def auto_confirm_if_disabled
      # Solo auto-confirmar si la variable de entorno está en true
      if ActiveModel::Type::Boolean.new.cast(ENV.fetch('DISABLE_EMAIL_CONFIRMATION', 'false'))
        confirm unless confirmed?
        puts "✅ Usuario #{email} auto-confirmado por variable de entorno"
      end
    end
  end
end

puts "📧 Confirmación por email: #{ENV.fetch('DISABLE_EMAIL_CONFIRMATION', 'false') == 'true' ? 'DESHABILITADA' : 'HABILITADA'}"
