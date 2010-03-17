class ScrapingsController < ApplicationController
  def new
    [:scraping_id, :scraping_start, :user_id, :scraping, :finished_threads, :final_offset].map {|x| session[x] = nil; session.delete x}
  end
  
  def create
    if File.exist?(File.join(RAILS_ROOT, 'total.lock'))
      @error_msg = "The site is currently being updated. Please wait a few minutes and try again."
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
      @current_user.release_name = params[:release_name] || false
    end
    @current_user.email = params[:email] unless params[:email].blank?
    @current_user.save
    
    session[:user_id] = @current_user.id
    cookies[:remember_token] = params[:cookie]
    session[:scraping_id]  = scraping_id = @current_user.scrapings.create(:user_agent => request.env["HTTP_USER_AGENT"], :batch_size => 500).id
    Rails.cache.write "scraping_#{scraping_id}_method", params[:fastest_method]
    Rails.cache.write "scraping_#{scraping_id}_batch_size", 500, :raw => true # raw is necessary to prevent marshalling, which kills increment
    Rails.cache.write "scraping_#{scraping_id}_total", 0, :raw => true
    Rails.cache.write "scraping_#{scraping_id}_threads", 0, :raw => true
    session[:scraping_start] = Time.now
    
    render '/scrapings/spawn_scrapers.js.erb'
  end
  
  def results
#    if (total < 1) and !(finished_threads > 0)
#      head :ok
#      return
#    end
    logger.info session
    if !@current_user
      render :update do |page|
        page.assign 'completed', true
        page['status'].replace_html "Your session has broken for some reason. Please ensure cookies & javascript are on and try again."
      end
      return
    end
    
    @scraping = @current_user.scrapings.find(session[:scraping_id])
    @scraping.update_attributes :served_urls => Rails.cache.read("scraping_#{session[:scraping_id]}_total", :raw => true).to_i,
                                :finished_threads => Rails.cache.read("scraping_#{session[:scraping_id]}_threads", :raw => true).to_i if @scraping.created_at > 2.minutes.ago
    
    if @scraping.job_id
      result = Workling.return.get(@scraping.job_id)
      if result.nil?
        head :ok
      elsif result == 'done'
        Workling.return.set @scraping.job_id, "Calculating results... 1/5"
        @sites = @scraping.found_sites.find(:all, :select => :url).map(&:url)
        Workling.return.set @scraping.job_id, "Calculating results... 2/5"
# TODO: Come up with a more efficient solution. For now, loading all the unfound sites into memory is just way too expensive.
#        @unfound_sites = @scraping.unfound_sites.find(:all, :select => :url).map(&:url)
        Workling.return.set @scraping.job_id, "Calculating results... 3/5"
        pv = @current_user.probability_vector nil, true
        Workling.return.set @scraping.job_id, "Calculating results... 4/5"
        @probabilities = @current_user.url_probabilities(pv)
        Workling.return.set @scraping.job_id, "Calculating results... 5/5"
        @avg_up = Site.avg_url_probabilities pv.keys
        Workling.return.set @scraping.job_id, "Checking your demographic profile..."
        @demographics = @current_user.demographics
        Workling.return.set @scraping.job_id, "Asking the AI who you are..."
        @similarities = @scraping.identify.sort_by{|k,v| -v} # show in decreasing order
        @other_users = User.find(:all, :conditions => ['id IN (?) and release_name = 1', @similarities.map{|x|x[0]}.sort]).inject({}){|m,u| m[u.id] = u.name;m } if @current_user.release_name
        ScrapingWorker.asynch_update_svm :scraping_id => @scraping.id
        
        render :update do |page|
          page.assign 'completed', true
          page['status'].hide
          page['results'].replace_html :partial => '/scrapings/results'
        end
        @scraping.update_attribute :job_id, nil
      else
        render :update do |page|
          page['scrapers'].remove
          page['status'].replace_html result
        end
      end
    else
      render :update do |page|
        page['status'].replace_html "Processing ##{@scraping.id}... #{@scraping.found_visitations_count} hits found. #{@scraping.visitations_count} processed so far of #{@scraping.served_urls} scraped. \
          #{pending_jobs} jobs in queue."
      end
    end
  end
end
 