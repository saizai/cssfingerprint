class User < ActiveRecord::Base
  has_many :scrapings, :dependent => :destroy
  has_many :successful_scrapings, :conditions => "found_visitations_count > 0", :class_name => "Scraping"
  has_many :visitations, :through => :successful_scrapings
  has_many :found_visitations, :through => :successful_scrapings
  has_many :unfound_visitations, :through => :successful_scrapings
  has_many :probability_vectors
  
  validates_presence_of :cookie
  validates_uniqueness_of :cookie
  
  before_validation :wipe_blanks
  
  def wipe_blanks
    self.name = nil if name.blank?
    self.email = nil if email.blank?
  end
  
  def probability_vector site_ids = nil
    if site_ids
      probability_vectors.find(:all, :conditions => ['site_id IN (?)', site_ids]).inject({}){|m,x| m[x.site_id] = x.avg}
    else
      probability_vectors.inject({}){|m,x| m[x.site_id] = x.avg}
    end
  end
  
  def url_probabilities prob = nil
    prob ||= probability_vector
    Site.find(prob.keys).inject({}){|m,x| m[x.url] = prob[x.id]; m }
  end
  
end
