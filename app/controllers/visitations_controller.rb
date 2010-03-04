class VisitationsController < ApplicationController
  def create
    if !@current_user
      @error_msg = "You seem to be blocking cookies. This site requires cookies to track your session, so please turn them on.<br/>
                     Feel free to delete the 'cookie' cookie afterwards; it's only there as a convenience, so you don't have to type in
                     your code if you visit again."
      render '/scrapings/error.js.erb'
      return
    end
    
    t = Time.now
    @thread_id = params[:thread_id].to_i
    VisitationWorker.asynch_process_results :scraping_id => session[:scraping_id], :results => params[:results]#, :return => true
    @batch_size = Rails.cache.read("scraping_#{session[:scraping_id]}_batch_size", :raw => true).to_i
    
    if session[:scraping_start] > 60.seconds.ago
      new_total = Rails.cache.increment "scraping_#{session[:scraping_id]}_total", @batch_size 
#      Scraping.update_counters session[:scraping_id], :served_urls => @batch_size 
#      Scraping.transaction do # using this instead of update_counters so we can atomically get the new value
#        @scraping = Scraping.find(session[:scraping_id], :lock => true)
#        @scraping.served_urls += @scraping.batch_size
#        @scraping.save
#      end
      logger.info "Processing create: t = #{ Time.now - t }, _total = #{Rails.cache.read('scraping_' + session[:scraping_id].to_s + '_total', :raw => true)}, \
        _threads = #{Rails.cache.read('scraping_' + session[:scraping_id].to_s + '_threads', :raw => true)}}"
      # TODO: modify batch size dynamically?
#      @offset = @scraping.served_urls - @scraping.batch_size # technically we should be updating the # served AFTER we set the current one; this just compensates
      @offset = new_total - @batch_size
      @sites = Site.get @offset, @batch_size
      render '/visitations/new.js.erb'
    else
      Rails.cache.increment "scraping_#{session[:scraping_id]}_threads", 1
#      Scraping.update_counters session[:scraping_id], :finished_threads => 1
#      Scraping.transaction do # using this instead of update_counters so we can atomically get the new value
#        @scraping = Scraping.find(session[:scraping_id], :lock => true)
#        @scraping.finished_threads += 1
#        @scraping.save
#      end
      logger.info "Processing finish: t = #{ Time.now - t }, _total = #{Rails.cache.read('scraping_' + session[:scraping_id].to_s + '_total', :raw => true)}, \
        _threads = #{Rails.cache.read('scraping_' + session[:scraping_id].to_s + '_threads', :raw => true)}}"
      render :js => "top.document.getElementById('status_#{@thread_id}').hide();"
    end
  end
  
  def autoscrape
    @thread_id = params[:thread_id].to_i
    
    t = Time.now
    @batch_size = Rails.cache.read("scraping_#{session[:scraping_id]}_batch_size", :raw => true).to_i
    new_total = Rails.cache.increment "scraping_#{session[:scraping_id]}_total", @batch_size 
#    Scraping.update_counters session[:scraping_id], :served_urls => @batch_size 
#    Scraping.transaction do # using this instead of update_counters so we can atomically get the new value
#      @scraping = Scraping.find(session[:scraping_id], :lock => true)
#      @scraping.served_urls += @scraping.batch_size
#      @scraping.save
#    end
    logger.info "Processing autoscrape: t = #{ Time.now - t }, _total = #{Rails.cache.read('scraping_' + session[:scraping_id].to_s + '_total', :raw => true)}, \
      _threads = #{Rails.cache.read('scraping_' + session[:scraping_id].to_s + '_threads', :raw => true)}}"
#    @offset = @scraping.served_urls - @scraping.batch_size
    @offset = new_total - @batch_size
    
    @sites = Site.get @offset, @batch_size
  end
  
end
