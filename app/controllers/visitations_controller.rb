class VisitationsController < ApplicationController
  def create
    @scraping = Scraping.find(params[:scraping_id].to_i)
    @limit, @offset, @start_time, batch_start = params[:limit].to_i, params[:offset].to_i, Time.parse(params[:start_time]), Time.parse(params[:batch_start])
    results = JSON.parse(params[:results])
    sites = Site.find(:all, :conditions => ['url IN (?)', results.keys]).map{|s| [s.id, s.url]}
    
    Visitation.import [:scraping_id, :site_id, :visited], results.map{|key,value| [@scraping.id, sites.rassoc(key)[0], value]}, :validate => false # save a bit of RAM
    Scraping.update_counters @scraping.id, :visitations_count => results.size # because we're using mass import, this isn't getting updated automagically 
    
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
