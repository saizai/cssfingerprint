class User < ActiveRecord::Base
  has_many :scrapings, :dependent => :destroy
  
  validates_presence_of :cookie
  validates_uniqueness_of :cookie
  
  def probability_vector
    found_sites = scrapings.map(&:found_visitations).flatten.map(&:site_id) # inefficient but not worth fixing
    scale = scrapings.count * 1.0
    vector = found_sites.inject({}){|m,x| m[x] ||= 0; m[x] += (1 / scale); m  }
  end
  
  def url_probabilities
    prob = probability_vector
    Site.find(prob.keys).inject({}){|m,x| m[x.url] = prob[x.id]; m }
  end
end
