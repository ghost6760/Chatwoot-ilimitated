# frozen_string_literal: true

class Account::SignUpEmailValidationService
  include CustomExceptions::Account
  attr_reader :email

  def initialize(email)
    @email = email
  end

  def perform
    # Si la validación está desactivada, solo verificar formato básico
    if GlobalConfigService.load('DISABLE_EMAIL_VALIDATION', 'false') == 'true'
      address = ValidEmail2::Address.new(email)
      raise InvalidEmail.new({ valid: false, disposable: nil }) unless address.valid?
      return true
    end

    # Lógica original
    address = ValidEmail2::Address.new(email)

    raise InvalidEmail.new({ valid: false, disposable: nil }) unless address.valid?

    raise InvalidEmail.new({ domain_blocked: true }) if domain_blocked?

    raise InvalidEmail.new({ valid: true, disposable: true }) if address.disposable?

    true
  end

  private

  def domain_blocked?
    domain = email.split('@').last&.downcase
    
    # Lista de dominios que siempre están permitidos
    allowed_domains = [
      'gmail.com', 
      'hotmail.com', 
      'outlook.com', 
      'live.com',
      'yahoo.com',
      'icloud.com'
    ]
    
    # Si el dominio está en la lista permitida, no está bloqueado
    return false if allowed_domains.include?(domain)
    
    blocked_domains.any? { |blocked_domain| domain.match?(blocked_domain.downcase) }
  end

  def blocked_domains
    domains = GlobalConfigService.load('BLOCKED_EMAIL_DOMAINS', '')
    return [] if domains.blank?

    domains.split("\n").map(&:strip)
  end
end
