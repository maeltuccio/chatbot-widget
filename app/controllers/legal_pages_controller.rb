class LegalPagesController < ApplicationController
  skip_before_action :authenticate_user!

  def legal_notice
  end

  def privacy
  end

  def terms
  end

  def contact
  end
end
