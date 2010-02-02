# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  after_filter OutputCompressionFilter # this is a workaround for lack of Apache mod_deflate. If mod_deflate is installed, remove this.

  before_filter :get_set_cookie
  
  def get_set_cookie
    last_cookie = cookies[:remember_token]
    if last_cookie
      @current_user = User.find_by_cookie(last_cookie) rescue nil
    else
      cookies[:remember_token] = ActiveSupport::SecureRandom.hex(30)
    end
  end
end
