class ScrapingsController < ApplicationController
  def create
    @user = User.find_or_create_by_cookie(params[:cookie])
    cookies[:remember_token] = params[:cookie]
    @scraping = @user.scrapings.create :user_agent => request.env["HTTP_USER_AGENT"]
    @offset, @limit = 0, 500
    @sites = Site.find(:all, :order => 'alexa_rank', :limit => @limit, :offset => @offset)
    
    render '/visitations/new.js.erb'
  end

end
 