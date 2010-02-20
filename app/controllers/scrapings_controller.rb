class ScrapingsController < ApplicationController
  def create
    if params[:cookie].blank?
      @error_msg = "Please enter a unique code."
    else
      @current_user = User.find_by_cookie(params[:cookie])
      if params[:repeat_user]
        @error_msg = "We didn't find that code. Please try again!" if @current_user.nil?
      else
        if @current_user
          @error_msg = "Somebody already used that code. Please enter something more unique!"
        else
          @current_user = User.create :cookie => params[:cookie]
        end
      end
    end
    
    if @error_msg
      render '/scrapings/error.js.erb'
      return
    end
    
    cookies[:remember_token] = params[:cookie]
    @scraping = @current_user.scrapings.create :user_agent => request.env["HTTP_USER_AGENT"]
    @offset, @limit = 0, 500
    @sites = Site.find(:all, :order => 'alexa_rank', :limit => @limit, :offset => @offset)
  
    render '/visitations/new.js.erb'
  end
  
  def results
    start_time = Time.now
    until Workling.return.get(@current_user.job_id) or (start_time < 10.seconds.ago)
      ; # wait for it rather than polling
    end
    @scraping = @current_user.scrapings.find(params[:id])
    @sites = @scraping.found_sites.map(&:url)
    @probabilities = @current_user.url_probabilities
  end
end
 