class VisitationsController < ApplicationController
  def create
    if !@current_user
      @error_msg = "You seem to be blocking cookies. This site requires cookies to track your session, so please turn them on.<br/>
                     Feel free to delete the 'cookie' cookie afterwards; it's only there as a convenience, so you don't have to type in
                     your code if you visit again."
@error_msg = session.inspect
      render '/scrapings/error.js.erb'
      return
    end
    
    @limit, @offset, @thread_id = params[:limit].to_i, params[:offset].to_i, params[:thread_id].to_i
    
    if session[:scraping_start] > 60.seconds.ago
      @offset += (@limit * effective_threads) # TODO: modify batch size dynamically?
      @sites = Site.find(:all, :order => 'alexa_rank', :limit => @limit, :offset => @offset, :select => 'alexa_rank, id, url')
      render '/visitations/new.js.erb'
      VisitationWorker.asynch_process_results :scraping_id => session[:scraping_id], :results => params[:results]
    else
      asynch_code = VisitationWorker.asynch_process_results :scraping_id => session[:scraping_id], :results => params[:results], :return => true
      @current_user.update_attribute :job_id, asynch_code
      render :js => "top.document.getElementById('status_#{@thread_id}').hide();"
    end
  end
  
  def autoscrape
    @offset, @limit = 0, 500
    @thread_id = params[:thread_id].to_i
    @offset += @limit * @thread_id
    
    @sites = Site.find(:all, :order => 'alexa_rank', :limit => @limit, :offset => @offset, :select => 'alexa_rank, id, url')
  end
  
end
