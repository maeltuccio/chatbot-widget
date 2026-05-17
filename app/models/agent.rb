class Agent < ApplicationRecord
  WIDGET_POSITIONS = %w[bottom_right bottom_left].freeze
  WIDGET_THEMES = %w[glass light dark].freeze

  belongs_to :account
  has_many :conversations, dependent: :destroy
  has_many :knowledge_sources, dependent: :destroy
  has_many :knowledge_chunks, dependent: :destroy
  has_many :usage_events, dependent: :destroy
  has_one :webflow_connection, dependent: :destroy

  before_validation :set_widget_defaults
  before_validation :generate_public_token, on: :create

  validates :name, presence: true
  validates :public_token, presence: true, uniqueness: true
  validates :widget_position, inclusion: { in: WIDGET_POSITIONS }
  validates :widget_theme, inclusion: { in: WIDGET_THEMES }
  validates :widget_primary_color,
    format: { with: /\A#[0-9a-fA-F]{6}\z/, message: "must be a hex color like #2563eb" },
    allow_blank: true

  def allowed_origin_list
    allowed_origins.to_s
      .split(/[\s,]+/)
      .map(&:strip)
      .reject(&:blank?)
      .map { |origin| normalize_origin(origin) }
      .compact
      .uniq
  end

  def origin_allowed?(origin)
    allowed = allowed_origin_list
    return Rails.env.development? if allowed.blank?
    return false if origin.blank?

    normalized_origin = normalize_origin(origin)
    allowed.include?(normalized_origin)
  end

  private

  def set_widget_defaults
    self.widget_title = name if widget_title.blank?
    self.widget_primary_color = "#111827" if widget_primary_color.blank?
    self.widget_position = "bottom_right" if widget_position.blank?
    self.widget_theme = "glass" if widget_theme.blank?
    self.widget_show_title = true if widget_show_title.nil?
    self.widget_send_label = "Envoyer" if widget_send_label.blank?
    self.widget_placeholder = "Entrez votre message ..." if widget_placeholder.blank?
  end

  def generate_public_token
    self.public_token ||= SecureRandom.hex(10)
  end

  def normalize_origin(origin)
    value = origin.to_s.strip
    value = "https://#{value}" unless value.match?(/\Ahttps?:\/\//)

    uri = URI.parse(value)
    return if uri.host.blank?

    port = uri.port
    default_port = uri.scheme == "https" ? 443 : 80
    normalized = "#{uri.scheme}://#{uri.host.downcase}"
    normalized += ":#{port}" if port.present? && port != default_port
    normalized
  rescue URI::InvalidURIError
    nil
  end
end
