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
               eth_african eth_asian eth_caucasian eth_hispanic 
               kids_0_17 kids_0_2 kids_3_12 kids_13_17 
               college college_grad 
               income_0_30 income_30_60 income_60_100 income_100_plus).map(&:to_sym)
  
  # This array is index-coordinated w/ the above one
  FRIENDLY_NAMES = ["Male", "Age 3-12", "Age 13-17", "Age 18-34", "Age 35-49", "Age 50+",
                    "Ethnicity: African", "Ethnicity: Asian", "Ethnicity: Caucasian", "Ethnicity: Hispanic",
                    "Has kids age 0-17", "Has kids age 0-2", "Has kids age 3-12", "Has kids age 13-17",
                    "Attended college", "Attended graduate school", 
                    "Income $0-$30k/yr", "Income $30-60k/yr", "Income $60-100k/yr", "Income $100k+"]
  DEMOGRAPHIC_NAMES = DEMOGRAPHICS.inject({}){|m,x| m[x] = FRIENDLY_NAMES[DEMOGRAPHICS.index(x)]; m }
  
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
    
    ret = Site.find(:first, :conditions => ['id IN (?) and quantcast_rank > 0', prob.keys],
     :select => DEMOGRAPHICS.map{|demo| "#{avgs[demo] / (1-avgs[demo]) } * exp(sum(ln( \ 
          (#{demo}/(1 - #{demo})) / #{avgs[demo] / (1-avgs[demo])} \ 
        ))) as #{demo}"}.join(','), :group => nil)
    DEMOGRAPHICS.inject({}){|m,v| ratio = ret.send("#{v}").to_f; m[v] = ratio/(1+ratio); m}
  end
  
  # Returns avg, sd
  def self.demographics
    ret = Site.find(:all, :conditions => 'quantcast_rank > 0',
     :select => DEMOGRAPHICS.map{|demo| "avg(#{demo}) as avg_#{demo}, stddev(#{demo}) as sd_#{demo}" }.join(',')).first
    return DEMOGRAPHICS.inject({}){|m,v| m[v] = ret.send("avg_#{v}").to_f; m}, DEMOGRAPHICS.inject({}){|m,v| m[v] = ret.send("sd_#{v}").to_f; m}
  end
  
  # standard normal distribution, aka Φ
  def self.std_norm_dist x
    (1.0 / Math.sqrt(2 * Math::PI)) * Math.exp(-0.5 * (x ** 2))
  end
end
