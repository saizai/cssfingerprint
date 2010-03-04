class ScrapingWorker < Workling::Base 
  Workling::Return::Store.instance = Workling::Return::Store::StarlingReturnStore.new
  logfile = File.open("#{RAILS_ROOT}/log/#{RAILS_ENV}-background.log", 'a')
  logfile.sync = true
  BG_LOGGER = Logger.new(logfile) 
  BG_LOGGER.debug "#{Time.now.to_s}: Loading ScrapingWorker. Return store: #{Workling.return.inspect}"
  
  def version_sites_once_idle!(options)
    if Rails.cache.read 'version_sites_once_idle_lock'
      BG_LOGGER.debug "#{Time.now.to_s}: #{options[:uid]}: version_sites_once_idle already in queue"
      return
    else
      Rails.cache.write 'version_sites_once_idle_lock', true
    end
    
    while Scraping.last.created_at > 2.minutes.ago
      BG_LOGGER.debug "#{Time.now.to_s}: #{options[:uid]}: Not idle..."
      sleep 10
    end
    
    Site.version!
    BG_LOGGER.debug "#{Time.now.to_s}: #{options[:uid]}: Versioned!"
    300.times{|i| Site.get 500 * i }
    BG_LOGGER.debug "#{Time.now.to_s}: #{options[:uid]}: Warmed up!"
    
    Rails.cache.delete 'version_sites_once_idle_lock'
  rescue => e
    BG_LOGGER.debug "#{Time.now.to_s}: #{options[:uid]}: ERROR #{e}"
  end
end