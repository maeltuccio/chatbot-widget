class Agent < ApplicationRecord
  WIDGET_POSITIONS = %w[bottom_right bottom_left].freeze

  belongs_to :account
  has_many :conversations, dependent: :destroy
  has_many :knowledge_sources, dependent: :destroy
  has_many :knowledge_chunks, dependent: :destroy

  before_validation :set_widget_defaults
  before_validation :generate_public_token, on: :create

  validates :name, presence: true
  validates :public_token, presence: true, uniqueness: true
  validates :widget_position, inclusion: { in: WIDGET_POSITIONS }
  validates :widget_primary_color,
    format: { with: /\A#[0-9a-fA-F]{6}\z/, message: "must be a hex color like #2563eb" },
    allow_blank: true

  private

  def set_widget_defaults
    self.widget_title = name if widget_title.blank?
    self.widget_primary_color = "#111827" if widget_primary_color.blank?
    self.widget_position = "bottom_right" if widget_position.blank?
    self.widget_send_label = "Send" if widget_send_label.blank?
    self.widget_placeholder = "Entrez votre message ..." if widget_placeholder.blank?
  end

  def generate_public_token
    self.public_token ||= SecureRandom.hex(10)
  end
end
