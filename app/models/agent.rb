class Agent < ApplicationRecord
  belongs_to :account

  before_create :generate_public_token

  private

  def generate_public_token
    self.public_token = SecureRandom.hex(10)
  end
end
