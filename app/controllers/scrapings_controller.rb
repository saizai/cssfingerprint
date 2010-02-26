class ScrapingsController < ApplicationController
  def new
    session[:scraping_id] = nil
  end
  
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
    
    session[:user_id] = @current_user.id
    cookies[:remember_token] = params[:cookie]
    session[:scraping_id]  = @current_user.scrapings.create(:user_agent => request.env["HTTP_USER_AGENT"]).id
    session[:scraping_start] = Time.now
    
    render '/scrapings/spawn_scrapers.js.erb'
  end
  
  def results
    if session[:scraping_id].blank?
      head :ok
      return
    end
    
    @scraping = @current_user.scrapings.find(session[:scraping_id])
    
    if Workling.return.get(@current_user.job_id)
      @sites = @scraping.found_sites.find(:all, :select => :url).map(&:url)
      @unfound_sites = @scraping.unfound_sites.find(:all, :select => :url).map(&:url)
      pv = @current_user.probability_vector
      @probabilities = @current_user.url_probabilities(pv)
      @avg_up = User.avg_url_probabilities pv.keys
      render :update do |page|
        page.assign 'completed', true
        page['status'].hide
        page['results'].replace_html :partial => '/scrapings/results'
      end
    else
      render :update do |page|
        page['status'].replace_html "Processing... #{@scraping.found_visitations_count} hits found of #{@scraping.visitations_count} processed so far"
      end
    end
rescue => e
  render :inline => session.inspect + e.inspect + @current_user.inspect
  end
end
 