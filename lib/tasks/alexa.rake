require 'fastercsv'

namespace :alexa do
  desc "Update our database from Alexa's top million sites list"
  task :update => :environment do
    # Note: the method used here is quite expensive on RAM briefly, but should be significantly faster overall
    # If RAM needs to be conserved, use FasterCSV.foreach and Site.create instead 
    # In testing, single-item import was about ~600 items per second; batch import was ~1300
    
    raise "Lockfile found" if File.exist?(File.join(RAILS_ROOT, 'update.lock'))
    f = File.new(File.join(RAILS_ROOT, 'update.lock'), 'w')
    f.close
    begin
      FileUtils.rm(File.join(RAILS_ROOT, 'db', 'top-1m.csv.zip')) rescue true
      `cd #{File.join(RAILS_ROOT, 'db')} && wget http://s3.amazonaws.com/alexa-static/top-1m.csv.zip`
      `cd #{File.join(RAILS_ROOT, 'db')} && unzip -o top-1m.csv.zip`
      puts "Parsing..."
      alexa = FasterCSV.read(File.join(RAILS_ROOT, 'db', 'top-1m.csv'))
      puts "Importing..."
      Site.import [:alexa_rank, :url], alexa, :validate => false, :on_duplicate_key_update => [:alexa_rank] 
      Site.version!
    ensure
      File.delete(File.join(RAILS_ROOT, 'update.lock'))
      puts "Done!"
    end
  end
  
  task :quantcast => :environment do
    raise "Lockfile found" if File.exist?(File.join(RAILS_ROOT, 'update.lock'))
    f = File.new(File.join(RAILS_ROOT, 'update.lock'), 'w')
    f.close
    begin
      FileUtils.rm(File.join(RAILS_ROOT, 'db', 'quantcast-top-million.zip'))
      FileUtils.rm(File.join(RAILS_ROOT, 'db', 'Quantcast-Top-Million.txt'))
      `cd #{File.join(RAILS_ROOT, 'db')} && wget http://www.quantcast.com/quantcast-top-million.zip`
      `cd #{File.join(RAILS_ROOT, 'db')} && unzip -o quantcast-top-million.zip`
      `cd #{File.join(RAILS_ROOT, 'db')} && tail -n +7 Quantcast-Top-Million.txt > Quantcast-Top-Million_preprocessed.txt`
      puts "Importing..."
      quantcast = []
      i = 0
      FasterCSV.foreach(File.join(RAILS_ROOT, 'db', 'Quantcast-Top-Million_preprocessed.txt'), :col_sep => "\t") do |row|
        quantcast << row
        if (i % 200) == 0
          Site.import [:alexa_rank, :url], quantcast, :validate => false, :on_duplicate_key_update => [:quantcast_rank]
          quantcast = []
        end
      end
      Site.import [:alexa_rank, :url], quantcast, :validate => false, :on_duplicate_key_update => [:quantcast_rank]
      Site.version!
    ensure
      File.delete(File.join(RAILS_ROOT, 'update.lock'))
      puts "Done!"
    end
  end
  
  desc "Warm up the database"
  task :warm_db => :environment do
    300.times{|i| Site.get 500 * i }
  end
end
