require 'rubygems'
require 'scrubyt'

namespace :technorati do
  desc "Import top 100 Technorati blogs"
  task :update => :environment do
    raise "Lockfile found" if File.exist?(File.join(RAILS_ROOT, 'update.lock'))
    f = File.new(File.join(RAILS_ROOT, 'update.lock'), 'w')
    f.close
    
    begin
      technorati = Scrubyt::Extractor.define do
        fetch 'http://technorati.com/blogs/top100/'
        
        link_title "//td[@class='site-details']" do
          link_url "//a[@class='offsite']"
        end
    
        next_page "//a[@class='next']", :limit => 5
      end
      
      Site.import [:technorati_rank, :url], technorati.to_hash.map{|x| [0, x[:link_url].sub('http://www.', '').sub('http://','').sub(/\/$/, '')]}, 
          :validate => false, :on_duplicate_key_update => [:techonrati_rank] 
      
      Site.version!
    ensure
      File.delete(File.join(RAILS_ROOT, 'update.lock'))
    end
  end
end