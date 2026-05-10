class Conversation < ApplicationRecord
  belongs_to :agent
  has_many :messages, dependent: :destroy
  belongs_to :summarized_until_message,
    class_name: "Message",
    optional: true

  before_validation :generate_public_token, on: :create

  validates :public_token, presence: true, uniqueness: true

  def touch_last_message_at!
    update!(last_message_at: Time.current)
  end

  private

  def generate_public_token
    self.public_token ||= SecureRandom.hex(12)
  end
end
