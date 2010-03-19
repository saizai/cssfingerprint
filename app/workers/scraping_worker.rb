require 'svm'

class ScrapingWorker < Workling::Base 
  Workling::Return::Store.instance = Workling::Return::Store::StarlingReturnStore.new
  logfile = File.open("#{RAILS_ROOT}/log/#{RAILS_ENV}-background.log", 'a')
  logfile.sync = true
  BG_LOGGER = Logger.new(logfile) 
  BG_LOGGER.debug "#{Time.now.to_s}: Loading ScrapingWorker. Return store: #{Workling.return.inspect}"
  
  def update_probability_vectors options
    scraping = Scraping.find(options[:scraping_id])
    results = scraping.visitations.find(:all, :conditions => ['site_id IN (?)', used_sites], :order => 'site_id', :select => 'site_id, visited').inject({}){|m,v| m[v.site_id] = v.visited}
    ProbabilityVector.report scraping.user_id, results
  end
  
  def update_svm options
    AI.update options[:scraping_id]
    BG_LOGGER.debug "#{Time.now.to_s}: #{options[:uid]}: Updated SVM!"
  rescue => e
    BG_LOGGER.debug "#{Time.now.to_s}: #{options[:uid]}: ERROR #{e}"
  end
  
  def analyze_results options
    scraping = Scraping.find options[:scraping_id]
    user = scraping.user
    return if scraping.job_id # ensure there's only one
    
    scraping.update_attribute :job_id, options[:uid]
    Workling.return.set options[:uid], "1/7: Checking found sites"
    # Should be somewhat better on RAM, as it requires instantiating fewer objects
    sites = scraping.found_sites.find(:first, :select => "group_concat(url) as urls").urls.split(',')
    Workling.return.set options[:uid], "2/7: Checking your probability vector"
    pv = user.probability_vector nil, true
    Workling.return.set options[:uid], "3/7: Checking your probability vector"
    probabilities = user.url_probabilities(pv)
    Workling.return.set options[:uid], "4/7: Checking average probability vectors"
    avg_up = Site.avg_url_probabilities pv.keys
    Workling.return.set options[:uid], "5/7: Checking your demographic profile"
    demographics = user.demographics
    Workling.return.set options[:uid], "6/7: Determining major influences of your demographic profile"
    demographic_pullers = user.demographic_pullers
    Workling.return.set options[:uid], "7/7: Asking the AI who you are"
    similarities = scraping.identify.sort_by{|k,v| -v} # show in decreasing order
    other_users = User.find(:all, :conditions => ['id IN (?) and release_name = 1', similarities.map{|x|x[0]}.sort], :select => 'id, name').inject({}){|m,u| m[u.id] = u.name;m } if user.release_name
    
    Workling.return.set options[:uid], {:other_users => other_users, :similarities => similarities, :demographics => demographics, :demographic_pullers => demographic_pullers,
      :avg_up => avg_up, :probabilities => probabilities, :sites => sites}
    
    ScrapingWorker.asynch_update_svm :scraping_id => scraping.id
  rescue => e
    BG_LOGGER.debug "#{Time.now.to_s}: #{options[:uid]}: ERROR #{e}"
  end
  
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