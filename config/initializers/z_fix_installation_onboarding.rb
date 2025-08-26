Rails.application.config.after_initialize do
  # Solo en producción y después de que la DB esté lista
  if Rails.env.production?
    begin
      # Verificar si ya tenemos superadmin
      has_superadmin = Account.joins(:account_users)
                             .where(account_users: { role: 'administrator' })
                             .exists?

      if has_superadmin
        # Si hay superadmin, eliminar la flag (instalación completada)
        flag_existed = ::Redis::Alfred.get(::Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING).present?
        
        if flag_existed
          ::Redis::Alfred.delete(::Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
          Rails.logger.info "[INSTALLATION FIX] Flag eliminada - superadmin existe, instalación completada"
        end
      else
        # Si no hay superadmin, asegurar que la flag existe (necesita instalación)
        unless ::Redis::Alfred.get(::Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
          ::Redis::Alfred.set(::Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING, true)
          Rails.logger.info "[INSTALLATION FIX] Flag establecida - no hay superadmin, instalación requerida"
        end
      end
      
    rescue => e
      Rails.logger.error "[INSTALLATION FIX] Error: #{e.message}"
      # No fallar el boot por este error
    end
  end
end
