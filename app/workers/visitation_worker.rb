class VisitationWorker < Workling::Base 
  # The logger and return store ought to be set by the environment, but they're not.
  # This is faster than debugging why. Yes it's a kludge.
  Workling::Return::Store.instance = Workling::Return::Store::StarlingReturnStore.new
  BG_LOGGER = Logger.new("#{RAILS_ROOT}/log/#{RAILS_ENV}-background.log") 
  BG_LOGGER.debug "#{Time.now.to_s}: Loading VisitationWorker. Return store: #{Workling.return.inspect}"
  
  def process_results(options)
    scraping_id, results = options[:scraping_id], options[:results]
    results = JSON.parse(results)
    sites = Site.find(:all, :conditions => ['url IN (?)', results.keys], :select => 'id, url').map{|s| [s.id, s.url]}
    Visitation.import [:scraping_id, :site_id, :visited], results.map{|key,value| [scraping_id, sites.rassoc(key)[0], value]}, :validate => false # save a bit of RAM
    
    # because we're using mass import, this isn't getting updated automagically
    found_count = results.map{|k,v| v}.count(true) 
    Scraping.update_counters scraping_id, :visitations_count => results.size, :found_visitations_count => found_count
    
    Workling.return.set options[:uid], found_count
    
    # BG_LOGGER.debug "#{Time.now.to_s}: #{options[:uid]}: Updating scrapings count..."
    # there should be a faster way of doing this
    # sites.map{|s| s.update_attribute :users_count, x.found_scrapings.count('DISTINCT user_id')}
    
    BG_LOGGER.debug "#{Time.now.to_s}: #{options[:uid]}: Processed scraping #{scraping_id} offset #{sites.first[0]}; found #{found_count} / #{results.size}"
  end
end
