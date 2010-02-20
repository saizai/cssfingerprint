require 'rubygems'
require 'scrubyt'

namespace :technorati do
  desc "Import top 100 Technorati blogs"
  task :update => :environment do
    technorati = Scrubyt::Extractor.define do
      fetch 'http://technorati.com/blogs/top100/'
      
      link_title "//td[@class='site-details']" do
        link_url "//a[@class='offsite']"
      end
  
      next_page "//a[@class='next']", :limit => 5
    end
    
    Site.import [:alexa_rank, :url], technorati.to_hash.map{|x| [0, x[:link_url].sub('http://www.', '').sub('http://','').sub(/\/$/, '')]}, 
        :validate => false, :on_duplicate_key_update => [:alexa_rank] 
  end
end