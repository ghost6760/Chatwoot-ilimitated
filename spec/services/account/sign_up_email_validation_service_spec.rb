# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account::SignUpEmailValidationService, type: :service do
  let(:service) { described_class.new(email) }
  let(:blocked_domains) { "tempmail.com\nmailinator.com" } # Cambiado: ya no incluimos Gmail ni Outlook
  let(:valid_email_address) { instance_double(ValidEmail2::Address, valid?: true, disposable?: false) }
  let(:disposable_email_address) { instance_double(ValidEmail2::Address, valid?: true, disposable?: true) }
  let(:invalid_email_address) { instance_double(ValidEmail2::Address, valid?: false) }

  before do
    allow(GlobalConfigService).to receive(:load).with('BLOCKED_EMAIL_DOMAINS', '').and_return(blocked_domains)
  end

  describe '#perform' do
    context 'when email is invalid format' do
      let(:email) { 'invalid-email' }

      it 'raises InvalidEmail with invalid message' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(invalid_email_address)
        expect { service.perform }.to raise_error do |error|
          expect(error).to be_a(CustomExceptions::Account::InvalidEmail)
          expect(error.message).to eq(I18n.t('errors.signup.invalid_email'))
        end
      end
    end

    # Test modificado: Gmail ahora debería ser permitido
    context 'when email is from Gmail (now allowed)' do
      let(:email) { 'test@gmail.com' }

      it 'returns true for Gmail addresses' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(valid_email_address)
        expect(service.perform).to be(true)
      end
    end

    # Test modificado: Hotmail/Outlook ahora debería ser permitido
    context 'when email is from Hotmail/Outlook (now allowed)' do
      let(:email) { 'test@hotmail.com' }

      it 'returns true for Hotmail addresses' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(valid_email_address)
        expect(service.perform).to be(true)
      end
    end

    # Test modificado: Outlook también permitido
    context 'when email is from Outlook (now allowed)' do
      let(:email) { 'test@outlook.com' }

      it 'returns true for Outlook addresses' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(valid_email_address)
        expect(service.perform).to be(true)
      end
    end

    # Test para dominios que SÍ deberían seguir bloqueados
    context 'when domain is actually blocked' do
      let(:email) { 'test@tempmail.com' }

      it 'raises InvalidEmail with blocked domain message' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(valid_email_address)
        expect { service.perform }.to raise_error do |error|
          expect(error).to be_a(CustomExceptions::Account::InvalidEmail)
          expect(error.message).to eq(I18n.t('errors.signup.blocked_domain'))
        end
      end
    end

    context 'when email is from disposable provider' do
      let(:email) { 'test@mailinator.com' }

      it 'raises InvalidEmail with disposable message' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(disposable_email_address)
        expect { service.perform }.to raise_error do |error|
          expect(error).to be_a(CustomExceptions::Account::InvalidEmail)
          expect(error.message).to eq(I18n.t('errors.signup.disposable_email'))
        end
      end
    end

    context 'when email is valid business email' do
      let(:email) { 'test@example.com' }

      it 'returns true' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(valid_email_address)
        expect(service.perform).to be(true)
      end
    end

    # Tests adicionales para verificar case insensitive
    context 'when Gmail domain is uppercase' do
      let(:email) { 'test@GMAIL.COM' }

      it 'returns true for uppercase Gmail addresses' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(valid_email_address)
        expect(service.perform).to be(true)
      end
    end
  end
end
