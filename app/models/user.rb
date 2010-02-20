class User < ActiveRecord::Base
  has_many :attempted_scrapings, :dependent => :destroy
  has_many :scrapings, :conditions => "found_visitations_count > 0", :class_name => "Scraping"
  has_many :visitations, :through => :scrapings
  has_many :found_visitations, :through => :scrapings
  has_many :unfound_visitations, :through => :scrapings
  
  validates_presence_of :cookie
  validates_uniqueness_of :cookie
  
  def probability_vector
    found_sites = found_visitations.find(:all, :select => 'site_id').map(&:site_id)
    visitations.find(:all, :group => 'site_id', :select => 'site_id, AVG(visited) as prob',
      :conditions => ["site_id IN (?)", found_sites]).inject({}){|m, x| m[x.site_id] = x.prob.to_f; m }
  end
  
  def url_probabilities
    prob = probability_vector
    Site.find(prob.keys).inject({}){|m,x| m[x.url] = prob[x.id]; m }
  end
end
