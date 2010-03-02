class ScrapingsController < ApplicationController
  def new
    [:scraping_id, :scraping_start, :user_id, :scraping, :finished_threads, :final_offset].map {|x| session[x] = nil; session.delete x}
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
          @current_user = User.create :cookie => params[:cookie], :name => params[:name], :email => params[:email], :release_name => params[:release_name]
        end
      end
    end
    
    if @error_msg
      render '/scrapings/error.js.erb'
      return
    end
    
    unless params[:name].blank?
      @current_user.name = params[:name]
      @current_user.release_name = params[:release_name]
    end
    @current_user.email = params[:email] unless params[:email].blank?
    @current_user.save
    
    session[:user_id] = @current_user.id
    cookies[:remember_token] = params[:cookie]
    session[:scraping_id]  = scraping_id = @current_user.scrapings.create(:user_agent => request.env["HTTP_USER_AGENT"]).id
    Rails.cache.write "scraping_#{scraping_id}_total", 0
    Rails.cache.write "scraping_#{scraping_id}_threads", 0
    session[:scraping_start] = Time.now
    
    render '/scrapings/spawn_scrapers.js.erb'
  end
  
  def results
 logger.info session.inspect
    total = Rails.cache.increment("scraping_#{session[:scraping_id]}_total", 0)
    finished_threads = Rails.cache.increment("scraping_#{session[:scraping_id]}_threads", 0)
    
#    if (total < 1) and !(finished_threads > 0)
#      head :ok
#      return
#    end
    
    @scraping = @current_user.scrapings.find(session[:scraping_id])
    
    # note: Rails.cache.read seems to return nil when increment,0 returns the correct value. Not sure why, not worth the time to debug
    if finished_threads > 0 # == effective_threads
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
        page['status'].replace_html "Processing... #{@scraping.found_visitations_count} hits found of #{@scraping.visitations_count} processed so far of #{total}"
      end
    end
  end
end
 