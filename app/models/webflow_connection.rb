class WebflowConnection < ApplicationRecord
  STATUSES = %w[connected configured failed].freeze

  belongs_to :agent

  validates :access_token_ciphertext, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  def access_token
    encryptor.decrypt_and_verify(access_token_ciphertext)
  end

  def access_token=(token)
    self.access_token_ciphertext = encryptor.encrypt_and_sign(token)
  end

  def configured?
    status == "configured" && site_id.present? && collection_id.present?
  end

  def syncable?
    site_id.present? && collection_id.present?
  end

  private

  def encryptor
    key = Rails.application.key_generator.generate_key("webflow access token", 32)
    ActiveSupport::MessageEncryptor.new(key)
  end
end
