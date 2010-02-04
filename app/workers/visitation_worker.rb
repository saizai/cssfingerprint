class VisitationWorker < Workling::Base 
  def process_results(options)
    scraping_id, results = options[:scraping_id], options[:results]
    results = JSON.parse(results)
    sites = Site.find(:all, :conditions => ['url IN (?)', results.keys]).map{|s| [s.id, s.url]}
    Visitation.import [:scraping_id, :site_id, :visited], results.map{|key,value| [scraping_id, sites.rassoc(key)[0], value]}, :validate => false # save a bit of RAM
    
    # because we're using mass import, this isn't getting updated automagically
    Scraping.update_counters scraping_id, :visitations_count => results.size, :found_visitations_count => results.map{|k,v| v}.count(true) 
    
    logger.info "Processed #{results.count} results for scraping #{scraping_id}"
  end
end
