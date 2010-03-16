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
  
  DEMOGRAPHICS = %w(males 
               age3_12 age13_17 age18_34 age35_49 age50plus 
               eth_caucasian eth_african eth_asian eth_hispanic 
               kids_0_17 kids_0_2 kids_3_12 kids_13_17 
               college college_grad 
               income_0_30 income_30_60 income_60_100 income_100_plus).map(&:to_sym)
  
  def wipe_blanks
    self.name = nil if name.blank?
    self.email = nil if email.blank?
  end
  
  def probability_vector site_ids = nil, only_hits = false
    conditions = ['1=1']
    if site_ids
      conditions[0] += ' AND site_id IN (?)'
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
  
  # Average the demographics of all sites this user has visited
  def demographics 
    prob = probability_vector nil, true
    avgs, sds = User.demographics
    
    ret = Site.find(:all, :conditions => ['id IN (?) and quantcast_rank > 0', prob.keys],
     :select => DEMOGRAPHICS.map{|demo| "avg(sign(#{demo} - #{avgs[demo]}) * pow((#{demo} - #{avgs[demo]}) / #{sds[demo]}, 2)) as #{demo}"}.join(','), :group => nil).first
    DEMOGRAPHICS.inject({}){|m,v| m[v] = User.std_norm_dist(ret.send v); m}
  end
  
  # Returns avg, sd
  def self.demographics
    ret = Site.find(:all, :conditions => 'quantcast_rank > 0',
     :select => DEMOGRAPHICS.map{|demo| "avg(#{demo}) as avg_#{demo}, stddev(#{demo}) as sd_#{demo}" }.join(',')).first
    return DEMOGRAPHICS.inject({}){|m,v| m[v] = ret.send "avg_#{v}"; m}, DEMOGRAPHICS.inject({}){|m,v| m[v] = ret.send "sd_#{v}"; m}
  end
  
  # standard normal distribution, aka Φ
  def self.std_norm_dist x
    (1.0 / Math.sqrt(2 * Math::PI)) * Math.exp(-0.5 * (x ** 2))
  end
end
