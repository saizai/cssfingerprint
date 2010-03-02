class ScrapingWorker < Workling::Base 
  Workling::Return::Store.instance = Workling::Return::Store::StarlingReturnStore.new
  logfile = File.open("#{RAILS_ROOT}/log/#{RAILS_ENV}-background.log", 'a')
  logfile.sync = true
  BG_LOGGER = Logger.new(logfile) 
  BG_LOGGER.debug "#{Time.now.to_s}: Loading ScrapingWorker. Return store: #{Workling.return.inspect}"
  
  def process_results(options)
    Workling.return.set options[:uid], "Starting results calculation..."
    scraping = Scraping.find(options[:scraping_id])
    BG_LOGGER.debug "#{Time.now.to_s}: #{options[:uid]}: Starting results for scraping #{scraping.id}"
    sites = scraping.found_sites.find(:all, :select => :url).map(&:url)
    Workling.return.set options[:uid], "Calculating results... 1/5"
    unfound_sites = scraping.unfound_sites.find(:all, :select => :url).map(&:url)
    Workling.return.set options[:uid], "Calculating results... 2/5"
    pv = scraping.user.probability_vector
    Workling.return.set options[:uid], "Calculating results... 3/5"
    probabilities = scraping.user.url_probabilities(pv)
    Workling.return.set options[:uid], "Calculating results... 4/5"
    avg_up = User.avg_url_probabilities pv.keys
    Workling.return.set options[:uid], "Calculating results... 5/5"
    BG_LOGGER.debug "#{Time.now.to_s}: #{options[:uid]}: Returning results for scraping #{scraping.id}"
    
    Workling.return.set options[:uid], :sites => sites, :unfound_sites => unfound_sites, :probabilities => probabilities, :avg_up => avg_up 
    BG_LOGGER.debug "#{Time.now.to_s}: #{options[:uid]}: Processed results for scraping #{scraping.id}"
  rescue => e
    BG_LOGGER.debug "#{Time.now.to_s}: #{options[:uid]}: ERROR #{e}"
  end
end