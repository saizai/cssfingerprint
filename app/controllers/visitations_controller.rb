class VisitationsController < ApplicationController
  def create
    if !@current_user
      @error_msg = "You seem to be blocking cookies. This site requires cookies to track your session, so please turn them on.<br/>
                     Feel free to delete the 'cookie' cookie afterwards; it's only there as a convenience, so you don't have to type in
                     your code if you visit again."
      render '/scrapings/error.js.erb'
      return
    end
    
    @scraping = @current_user.scrapings.find(params[:scraping_id].to_i)
    @limit, @offset, @thread_id = params[:limit].to_i, params[:offset].to_i, params[:thread_id].to_i
    
    asynch_code = VisitationWorker.asynch_process_results :scraping_id => @scraping.id, :results => params[:results]
    
    if @scraping.created_at > 60.seconds.ago
      @offset += (@limit * THREADS) # TODO: modify batch size dynamically?
      @sites = Site.find(:all, :order => 'alexa_rank', :limit => @limit, :offset => @offset, :select => 'alexa_rank, id, url')
      render '/visitations/new.js.erb'
    elsif @thread_id == THREADS - 1
      @current_user.update_attribute :job_id, asynch_code
      render :js => "top.document.getElementById('status_#{@thread_id}').hide(); top.analyze();" #  '/scrapings/analyze.js.erb'
    else
      render :js => "top.document.getElementById('status_#{@thread_id}').hide();"
    end
  end
  
  def autoscrape
    @offset, @limit = 0, 500
    @scraping = @current_user.scrapings.find(params[:scraping_id].to_i)
    @thread_id = params[:thread_id].to_i
    @offset += @limit * @thread_id
    
    @sites = Site.find(:all, :order => 'alexa_rank', :limit => @limit, :offset => @offset, :select => 'alexa_rank, id, url')
  end
  
end
