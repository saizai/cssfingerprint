class ScrapingsController < ApplicationController
  def create
    @user = User.find_or_create_by_cookie(params[:cookie])
    cookies[:remember_token] = params[:cookie]
    @scraping = @user.scrapings.create
    @offset, @limit = 0, 200
    @sites = Site.find(:all, :order => 'alexa_rank', :limit => @limit, :offset => @offset)
    @start_time = params[:start_time]
    
    render '/visitations/new'
  end

end
 