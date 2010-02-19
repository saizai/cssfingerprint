# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :results
  
  before_filter :get_set_cookie
  
  def get_set_cookie
    last_cookie = cookies[:remember_token]
    if last_cookie
      @current_user = User.find_by_cookie(last_cookie) rescue nil
    # else
# Force user to input something
#      cookies[:remember_token] = random_string
    end
  end
end
