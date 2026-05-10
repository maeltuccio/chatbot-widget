class Message < ApplicationRecord
  ROLES = %w[visitor assistant].freeze

  belongs_to :conversation, touch: true

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :content, presence: true
end
