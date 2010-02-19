class VisitationsController < ApplicationController
  def create
    @scraping = @current_user.scrapings.find(params[:scraping_id].to_i)
    @limit, @offset = params[:limit].to_i, params[:offset].to_i
    
    asynch_code = VisitationWorker.asynch_process_results :scraping_id => @scraping.id, :results => params[:results]
    
    if @scraping.created_at > 60.seconds.ago
      @offset += @limit # TODO: modify batch size dynamically?
      @sites = Site.find(:all, :order => 'alexa_rank', :limit => @limit, :offset => @offset)
      render '/visitations/new.js.erb'
    else
      @current_user.update_attribute :job_id, asynch_code
      render '/scrapings/analyze.js.erb'
    end
  end
  
end
