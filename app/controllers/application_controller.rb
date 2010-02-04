# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  before_filter :get_set_cookie
  
  def get_set_cookie
    last_cookie = cookies[:remember_token]
    if last_cookie
      @current_user = User.find_by_cookie(last_cookie) rescue nil
    else
      cookies[:remember_token] = 3.times.map{WEBSTER.random_word}.join(' ')  # ActiveSupport::SecureRandom.hex(30)
    end
  end
end
