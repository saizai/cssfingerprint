class VisitationWorker < Workling::Base 
  # The logger and return store ought to be set by the environment, but they're not.
  # This is faster than debugging why. Yes it's a kludge.
  Workling::Return::Store.instance = Workling::Return::Store::StarlingReturnStore.new
  logfile = File.open("#{RAILS_ROOT}/log/#{RAILS_ENV}-background.log", 'a')
  logfile.sync = true
  BG_LOGGER = Logger.new(logfile) 
  BG_LOGGER.debug "#{Time.now.to_s}: Loading VisitationWorker. Return store: #{Workling.return.inspect}"
  
  def process_results(options)
    scraping_id, results = options[:scraping_id], options[:results]
    results = JSON.parse(results).inject({}){|m,v| m[v[0].to_i] = v[1]; m}
#    sites = Site.find(:all, :conditions => ['url IN (?)', results.keys.map{|x| URI.decode x}], :select => 'id, url').map{|s| [s.id, s.url]}
#    site_results = results.inject({}){|m,v| m[sites.rassoc(URI.decode v[0])[0]] = v[1]; m}
    found_site_ids = results.reject{|k,v| !v}.keys
    Visitation.import [:scraping_id, :site_id, :visited], results.map{|k,v| [scraping_id, k, v]}, :validate => false # save a bit of RAM
    
    # because we're using mass import, this isn't getting updated automagically
    found_count = found_site_ids.count
    Scraping.update_counters scraping_id, :visitations_count => results.size, :found_visitations_count => found_count
    scraping = Scraping.find(scraping_id) # AFTER the update
    ProbabilityVector.report scraping.user_id, results
    
    # (almost) all done. Sometimes batches seem to get lost over the wire.
    # FIXME: why are they getting lost? Why are some threads not finishing?
    if scraping.created_at < 60.seconds.ago  and scraping.served_urls <= scraping.visitations_count + scraping.batch_size * THREADS and !scraping.job_id
      ScrapingWorker.asynch_version_sites_once_idle!
#      ScrapingWorker.asynch_update_probability_vectors :scraping_id => scraping_id
      Workling.return.set options[:uid], "done"
      scraping.update_attribute :job_id, options[:uid] # ScrapingWorker.asynch_process_results(:scraping_id => scraping_id)
    end
    
    BG_LOGGER.debug "#{Time.now.to_s}: #{options[:uid]}: Processed scraping #{scraping_id} offset #{results.keys.min}; found #{found_count} / #{results.size}: #{found_site_ids.join(', ')}"
  rescue => e
    BG_LOGGER.debug "#{Time.now.to_s}: #{options[:uid]}: ERROR #{e}"
  end
end
