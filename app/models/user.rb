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
  
  def probability_vector site_ids = nil, only_hits = false
    conditions = ['1=1']
    if site_ids
      conditions[0] += ' AND site_ids IN (?)'
      conditions << site_ids
    end
    if only_hits
      conditions[0] += ' AND hits > 0'
    end
    
    probability_vectors.find(:all, :conditions => conditions).inject({}){|m,x| m[x.site_id] = x.avg; m}
  end
  
  def url_probabilities prob = nil
    prob ||= probability_vector
    Site.find(:all, :conditions => ['id IN (?)', prob.keys]).inject({}){|m,x| m[x.url] = prob[x.id]; m }
  end
  
  def demographics prob = nil
    prob ||= probability_vector
    Site.find(:all, :conditions => ['id IN (?)', prob.keys], :select => "avg(males), avg(age3_12), avg(age13_17), avg(age18_34), avg(age35_49), avg(age50plus), 
      avg(eth_caucasian), avg(eth_african), avg(eth_asian), avg(eth_hispanic), avg(kids_0_17), avg(kids_0_2), avg(kids_3_12), avg(kids_13_17), 
      avg(college), avg(college_grad), avg(income_0_30), avg(income_30_60), avg(income_60_100), avg(income_100_plus)", :group => '1')
  end
  
end
