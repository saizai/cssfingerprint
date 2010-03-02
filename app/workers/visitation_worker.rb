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
    results = JSON.parse(results)
    sites = Site.find(:all, :conditions => ['url IN (?)', results.keys.map{|x| URI.decode x}], :select => 'id, url').map{|s| [s.id, s.url]}
    Visitation.import [:scraping_id, :site_id, :visited], results.map{|key,value| [scraping_id, sites.rassoc(URI.decode key)[0], value]}, :validate => false # save a bit of RAM
    
    # because we're using mass import, this isn't getting updated automagically
    found_count = results.map{|k,v| v}.count(true) 
    Scraping.update_counters scraping_id, :visitations_count => results.size, :found_visitations_count => found_count
    scraping = Scraping.find(scraping_id) # AFTER the update
    
    # (almost) all done. Sometimes batches seem to get lost over the wire.
    # FIXME: why are they getting lost? Why are some threads not finishing?
    if scraping.finished_threads <= THREADS - 1  and scraping.served_urls <= scraping.visitations_count + scraping.batch_size * THREADS  
      Workling.return.set options[:uid], "done"
      scraping.update_attribute :job_id, options[:uid] # ScrapingWorker.asynch_process_results(:scraping_id => scraping_id)
    end
    
    
    # BG_LOGGER.debug "#{Time.now.to_s}: #{options[:uid]}: Updating scrapings count..."
    # there should be a faster way of doing this
    # sites.map{|s| s.update_attribute :users_count, x.found_scrapings.count('DISTINCT user_id')}
    
    BG_LOGGER.debug "#{Time.now.to_s}: #{options[:uid]}: Processed scraping #{scraping_id} offset #{sites.first[0]}; found #{found_count} / #{results.size}"
  rescue => e
    BG_LOGGER.debug "#{Time.now.to_s}: #{options[:uid]}: ERROR #{e}"
  end
end
