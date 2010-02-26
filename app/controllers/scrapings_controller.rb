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
    
    render '/scrapings/spawn_scrapers.js.erb'
  end
  
  def results
    start_time = Time.now
    until Workling.return.get(@current_user.job_id) or (start_time < 10.seconds.ago)
      ; # wait for it rather than polling
    end
    @scraping = @current_user.scrapings.last # .find(params[:id])
    @sites = @scraping.found_sites.map(&:url)
    @unfound_sites = @scraping.unfound_sites.map(&:url)
    pv = @current_user.probability_vector
    @probabilities = @current_user.url_probabilities(pv)
    @avg_up = User.avg_url_probabilities pv.keys
  end
end
 