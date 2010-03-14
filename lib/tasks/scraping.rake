namespace :scraping do
  desc "Update our database from Alexa's top million sites list"
  task :alexa => :environment do
    require 'fastercsv'
    # Note: the method used here is quite expensive on RAM briefly, but should be significantly faster overall
    # If RAM needs to be conserved, use FasterCSV.foreach and Site.create instead 
    # In testing, single-item import was about ~600 items per second; batch import was ~1300
    
    with_lock do
      FileUtils.rm(File.join(RAILS_ROOT, 'db', 'top-1m.csv.zip')) rescue true
      `cd #{File.join(RAILS_ROOT, 'db')} && wget http://s3.amazonaws.com/alexa-static/top-1m.csv.zip`
      `cd #{File.join(RAILS_ROOT, 'db')} && unzip -o top-1m.csv.zip`
      puts "Parsing..."
      alexa = FasterCSV.read(File.join(RAILS_ROOT, 'db', 'top-1m.csv'))
      puts "Importing..."
      Site.import [:alexa_rank, :url], alexa, :validate => false, :on_duplicate_key_update => [:alexa_rank] 
    end
  end
  
  desc "Bloglines top 1000"
  task :bloglines => :environment do
    require 'rubygems'
    require 'scrubyt'
    with_lock do
      bloglines = Scrubyt::Extractor.define do
        fetch 'http://beta.bloglines.com/topfeeds'
        
        site "//div[@class='bl_dataUnit']" do
          rank "//div[@class='bl_nameRank']" do
            rank /\d+/
            name "//a" 
          end
          url "//div[@class='bl_subItem bl_subscribe']//a[@title='Subscribe to Feed']/@href"
        end
        
        next_page "//a[@title='Next >>']", :limit => 10
      end
      
      Feed.import [:bloglines_rank, :url, :name], bloglines.to_hash.map{|x| [x[:rank].to_i, x[:url], x[:name]]}, :validate => false, :on_duplicate_key_update => [:bloglines_rank, :name] 
    end
  end
  
  desc "Google PageRank"
  task :google => :environment do
    require 'pagerank'
    with_lock do
      g = Google::PageRank.new(nil)
      
      Site.find_each do |s|
        s.update_attribute :google_rank, g.page_rank(s.url)
      end
    end
  end
  
  desc "Top 100 Technorati blogs"
  task :technorati => :environment do
    require 'rubygems'
    require 'scrubyt'
    with_lock do
      technorati = Scrubyt::Extractor.define do
        fetch 'http://technorati.com/blogs/top100/'
        
        link_title "//td[@class='site-details']" do
          link_url "//a[@class='offsite']"
        end
    
        next_page "//a[@class='next']", :limit => 5
      end
      
      Site.import [:technorati_rank, :url], technorati.to_hash.map{|x| [0, x[:link_url].sub('http://www.', '').sub('http://','').sub(/\/$/, '')]}, 
          :validate => false, :on_duplicate_key_update => [:techonrati_rank] 
    end
  end
  
  desc "Quantcast top million"
  task :quantcast => :environment do
    with_lock do
      FileUtils.rm(File.join(RAILS_ROOT, 'db', 'quantcast-top-million.zip')) rescue true
      FileUtils.rm(File.join(RAILS_ROOT, 'db', 'Quantcast-Top-Million.txt')) rescue true
      `cd #{File.join(RAILS_ROOT, 'db')} && wget http://www.quantcast.com/quantcast-top-million.zip`
      `cd #{File.join(RAILS_ROOT, 'db')} && unzip -o quantcast-top-million.zip`
      `cd #{File.join(RAILS_ROOT, 'db')} && tail -n +7 Quantcast-Top-Million.txt > Quantcast-Top-Million_preprocessed.txt`
      puts "Importing in 1000x batches... "
      quantcast = []
      i = 0
      FasterCSV.foreach(File.join(RAILS_ROOT, 'db', 'Quantcast-Top-Million_preprocessed.txt'), :col_sep => "\t") do |row|
        quantcast << row
        i += 1
        if (i % 1000) == 0
          print "."; STDOUT.flush
          Site.import [:quantcast_rank, :url], quantcast, :validate => false, :on_duplicate_key_update => [:quantcast_rank]
          quantcast = []
        end
      end
      Site.import [:quantcast_rank, :url], quantcast, :validate => false, :on_duplicate_key_update => [:quantcast_rank] unless quantcast.empty?
    end
  end
  
  desc "Quantcast demographics (age, children, education, ethnicity, gender, income)"
  task :quantcast_demographics => :environment do
    include Quantcast
    with_lock do
      Site.find_each :conditions => 'quantcast_rank > 0' do |site|
        update_demographics_for site
      end
    end
  end
  
  desc "WTIKAY bootstrapped URLs (temporary)"
  task :wtikay => :environment do
    # require 'fastercsv'
    require 'net/http'
    require 'uri'
    
    # c = FasterCSV.open('/Users/saizai/Documents/workspace/cssfingerprint/wtikay.csv','w')
    f = File.open('/Users/saizai/Documents/workspace/cssfingerprint/wtikay.csv','a')
    
   # res = Net::HTTP.get(URI.parse('http://wtikay.com/all'))
    
   # res.scan(/t.push\("([^"]*)"\)[^(]*\(([^)]*)\)/).map{|y| f << ",#{y[1].to_i},#{y[0]}\n"; f.flush; sleep 0.0001}
    
    (32310..76507).each  do |i|
      begin 
        res = Net::HTTP.post_form(URI.parse('http://wtikay.com/submit_primary'), {'ids' => [i], 'name' => 'all',  'time' => Time.now.to_i.to_s})
        res.body.scan(/v.push\("([^"]*)"\)[^(]*\(([^)]*)\)/).map{|y| f << "#{i},#{y[1].to_i},#{y[0]}\n"; f.flush; sleep 0.0001}
        sleep 0.5
      rescue Timeout::Error
        sleep 5
        retry
      end
    end
    
    f.close
  end
  
  
  desc "Refresh the total rank based on all available a priori rankings"
  task :summarize => :environment do
    with_lock do
      Site.update_all "total_rank = ifnull(alexa_rank,((1000000 - alexa_rank) / 1000000.0)), 0) + ifnull(google_rank,((10-google_rank)/10.0),0)"
    end
  end
  
  desc "Warm up the database"
  task :warm_db => :environment do
    300.times{|i| Site.get 500 * i }
  end
  
  
  private
  
  def with_lock
    raise "Lockfile found" if File.exist?(File.join(RAILS_ROOT, 'update.lock'))
    f = File.new(File.join(RAILS_ROOT, 'update.lock'), 'w')
    f.close
    
    begin
      yield
    ensure
      File.delete(File.join(RAILS_ROOT, 'update.lock'))
    end
    
    Site.version!
  end
end
