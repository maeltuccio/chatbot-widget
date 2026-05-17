class User < ApplicationRecord
  ROLES = %w[owner admin member].freeze

  attr_accessor :account_name

  belongs_to :account

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  before_validation :build_account_for_signup, on: :create

  validates :role, presence: true, inclusion: { in: ROLES }

  def owner?
    role == "owner"
  end

  def admin?
    role == "admin"
  end

  def member?
    role == "member"
  end

  def can_manage?
    owner? || admin?
  end

  private

  def build_account_for_signup
    return if account.present?

    build_account(
      name: account_name.presence || email.to_s.split("@").first.presence || "Nouvel espace de travail",
      owner_email: email,
      plan: "starter"
    )
    self.role = "owner"
  end
end
