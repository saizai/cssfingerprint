class VisitationsController < ApplicationController
  def create
    @scraping = Scraping.find(params[:scraping_id].to_i)
    @limit, @offset, @start_time, batch_start = params[:limit].to_i, params[:offset].to_i, Time.parse(params[:start_time]), Time.parse(params[:batch_start])
    
    VisitationWorker.asynch_process_results :scraping_id => @scraping.id, :results => params[:results]
    
    if @start_time > 30.seconds.ago
      p "Last batch took #{Time.now - batch_start} seconds roundtrip" # TODO: modify batch size dynamically
      @offset += @limit
      @sites = Site.find(:all, :order => 'alexa_rank', :limit => @limit, :offset => @offset)
      render '/visitations/new'
    else
      render '/scrapings/analyze'
    end
  end
  
end
