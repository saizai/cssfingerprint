class User < ActiveRecord::Base
  has_many :scrapings, :dependent => :destroy
  has_many :successful_scrapings, :conditions => "found_visitations_count > 0", :class_name => "Scraping"
  has_many :visitations, :through => :successful_scrapings
  has_many :found_visitations, :through => :successful_scrapings
  has_many :unfound_visitations, :through => :successful_scrapings
  
  validates_presence_of :cookie
  validates_uniqueness_of :cookie
  
  def probability_vector
    found_site_ids = found_visitations.find(:all, :select => 'site_id').map(&:site_id)
    visitations.find(:all, :group => 'site_id', :select => 'site_id, AVG(visited) as prob',
      :conditions => ["site_id IN (?)", found_site_ids]).inject({}){|m, x| m[x.site_id] = x.prob.to_f; m }
  end
  
  def url_probabilities prob = nil
    prob ||= probability_vector
    Site.find(prob.keys).inject({}){|m,x| m[x.url] = prob[x.id]; m }
  end
  
  # FIXME: Make this make each user weight 1, i.e. each visitation weighted (1 / # scrapings for this user-site)
  def self.avg_probability_vector site_ids = nil
    site_ids ||= Visitation.find(:all, :select => 'site_id', :conditions => 'visited = 1').map(&:site_id)
    successful_scraping_ids = Scraping.find(:all, :select => 'id', :conditions => 'found_visitations_count > 0').map(&:id)
    Visitation.find(:all, :group => 'site_id', :select => 'site_id, AVG(visited) as prob',
      :conditions => ["site_id IN (?) AND scraping_id IN (?)", site_ids, successful_scraping_ids]).inject({}){|m, x|
         m[x.site_id] = x.prob.to_f; m }
  end
  
  def self.avg_url_probabilities site_ids = nil
    prob = avg_probability_vector(site_ids)
    Site.find(prob.keys).inject({}){|m,x| m[x.url] = prob[x.id]; m }
  end
end
