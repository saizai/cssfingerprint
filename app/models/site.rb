class Site < ActiveRecord::Base
  has_many :visitations
  has_many :scrapings, :through => :visitations
  has_many :found_visitations, :class_name => 'Visitation', :conditions => 'visited = 1'
  has_many :found_scrapings, :class_name => 'Scraping', :through => :found_visitations, :source => :scraping
  
  # NOTE: avg_visited is stored NEGATIVE to the real value, because mysql cannot use an index if ORDER BY has mixed ascendency. It's a kludge.
  
  validates_presence_of :url, :alexa_rank, :users_count
  
  def self.avg_probability_vector site_ids = nil
    if site_ids
      self.find(:all, :conditions => ['id IN (?)', site_ids], :select => 'id, avg_visited').inject({}){|m,x| m[x.id] = -x.avg_visited; m}
    else
      self.find(:all, :conditions => 'visited_users_count > 0', :select => 'id, avg_visited').inject({}){|m,x| m[x.id] = -x.avg_visited; m}
    end
  end
  
  def self.avg_url_probabilities site_ids = nil
    if site_ids
      self.find(:all, :conditions => ['id IN (?)', site_ids], :select => 'url, avg_visited').inject({}){|m,x| m[x.url] = -x.avg_visited; m}
    else
      self.find(:all, :conditions => 'visited_users_count > 0', :select => 'url, avg_visited').inject({}){|m,x| m[x.url] = -x.avg_visited; m}
    end
  end
  
  def self.update_user_counts sites = nil
    sites = sites.map(&:to_i) if sites
    return if sites.empty?
    ActiveRecord::Base.connection.execute "UPDATE sites INNER JOIN ( \
      SELECT v.site_id, count(DISTINCT user_id) AS count_distinct_user_id FROM `scrapings` INNER JOIN ( \
        SELECT site_id, scraping_id, visited FROM `visitations` WHERE visited = 1 #{ 'AND site_id IN (' + sites.join(',') + ')' if sites }) \
      as v ON scrapings.id = v.scraping_id group by site_id) \
    as s on s.site_id = sites.id   \
    SET users_count = count_distinct_user_id;"
  end
  
  def self.version
    unless v = Rails.cache.increment('sites_version', 0)
      Rails.cache.write 'sites_version', 0, :raw => true
      v = 1
    end
    v
  end
  
  def self.version!
    Rails.cache.increment 'sites_version', 1
  end
  
  def self.get offset, batch_size = 500
    key = "sites_#{offset}_#{batch_size}_#{self.version}"
    unless r = Rails.cache.read(key)
      r = Site.find(:all, :limit => batch_size, :offset => offset, :order => 'avg_visited, alexa_rank', :select => 'id, url, alexa_rank, avg_visited')
      Rails.cache.write key, r
    end
    r
  end
end
