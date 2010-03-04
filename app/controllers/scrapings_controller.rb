class ScrapingsController < ApplicationController
  def new
    [:scraping_id, :scraping_start, :user_id, :scraping, :finished_threads, :final_offset].map {|x| session[x] = nil; session.delete x}
  end
  
  def create
    if File.exist?(File.join(RAILS_ROOT, 'update.lock'))
      @error_msg = "Our sites database is currently being updated. Please wait a few minutes and try again."
    elsif params[:cookie].blank?
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
    session[:scraping_id]  = scraping_id = @current_user.scrapings.create(:user_agent => request.env["HTTP_USER_AGENT"], :batch_size => 500).id
    Rails.cache.write "scraping_#{scraping_id}_total", 0
    Rails.cache.write "scraping_#{scraping_id}_threads", 0
    session[:scraping_start] = Time.now
    
    render '/scrapings/spawn_scrapers.js.erb'
  end
  
  def results
#    if (total < 1) and !(finished_threads > 0)
#      head :ok
#      return
#    end
    logger.info session
    @scraping = @current_user.scrapings.find(session[:scraping_id])
    
    if @scraping.job_id
      result = Workling.return.get(@scraping.job_id)
      if result.nil?
        head :ok
      elsif result == 'done'
        Workling.return.set @scraping.job_id, "Starting results calculation..."
        @sites = @scraping.found_sites.find(:all, :select => :url).map(&:url)
        @unfound_sites = @scraping.unfound_sites.find(:all, :select => :url).map(&:url)
        Workling.return.set @scraping.job_id, "Calculating results... 1/5"
        pv = @current_user.probability_vector
        Workling.return.set @scraping.job_id, "Calculating results... 2/5"
        @probabilities = @current_user.url_probabilities(pv)
        Workling.return.set @scraping.job_id, "Calculating results... 3/5"
        @avg_up = User.avg_url_probabilities pv.keys
        Workling.return.set @scraping.job_id, "Calculating results... 4/5"
        render :update do |page|
          page.assign 'completed', true
          page['status'].hide
          page['results'].replace_html :partial => '/scrapings/results'
        end
        @scraping.update_attribute :job_id, nil
      else
        render :update do |page|
          page['status'].replace_html result
        end
      end
    else
      render :update do |page|
        page['status'].replace_html "Processing ##{@scraping.id}... #{@scraping.found_visitations_count} hits found. #{@scraping.visitations_count} processed so far of #{@scraping.served_urls} scraped. \
          #{WORKLING_CLIENT.stats.first[1]['curr_items']} jobs in queue."
      end
    end
  end
end
 