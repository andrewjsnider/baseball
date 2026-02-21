class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :set_my_team

  def set_my_team
    @my_team ||= Team.find_by(name: 'Giants')
  end
end
