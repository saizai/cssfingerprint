class VisitationsController < ApplicationController
  def create
    if !@current_user
      @error_msg = "You seem to be blocking cookies. This site requires cookies to track your session, so please turn them on.<br/>
                     Feel free to delete the 'cookie' cookie afterwards; it's only there as a convenience, so you don't have to type in
                     your code if you visit again."
      render '/scrapings/error.js.erb'
      return
    end
    
    @thread_id = params[:thread_id].to_i
    VisitationWorker.asynch_process_results :scraping_id => session[:scraping_id], :results => params[:results]#, :return => true
    
    if session[:scraping_start] > 60.seconds.ago
      Scraping.transaction do # using this instead of update_counters so we can atomically get the new value
        @scraping = Scraping.find(session[:scraping_id], :lock => true)
        @scraping.served_urls += @scraping.batch_size
        @scraping.save
      end
      # TODO: modify batch size dynamically?
      @offset = @scraping.served_urls - @scraping.batch_size # technically we should be updating the # served AFTER we set the current one; this just compensates
      @sites = Site.find(:all, :order => 'alexa_rank', :limit => @scraping.batch_size, :offset => @offset, :select => 'alexa_rank, id, url')
      render '/visitations/new.js.erb'
    else
      Scraping.transaction do # using this instead of update_counters so we can atomically get the new value
        @scraping = Scraping.find(session[:scraping_id], :lock => true)
        @scraping.finished_threads += 1
        @scraping.save
      end
      render :js => "top.document.getElementById('status_#{@thread_id}').hide();"
    end
  end
  
  def autoscrape
    @thread_id = params[:thread_id].to_i
    
    Scraping.transaction do # using this instead of update_counters so we can atomically get the new value
      @scraping = Scraping.find(session[:scraping_id], :lock => true)
      @scraping.served_urls += @scraping.batch_size
      @scraping.save
    end
    @offset = @scraping.served_urls - @scraping.batch_size
    
    @sites = Site.find(:all, :order => 'alexa_rank', :limit => @scraping.batch_size, :offset => @offset, :select => 'alexa_rank, id, url')
  end
  
end
