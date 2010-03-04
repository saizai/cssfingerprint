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
    FileUtils.rm(File.join(RAILS_ROOT, 'db', 'top-1m.csv.zip')) rescue true
    `cd #{File.join(RAILS_ROOT, 'db')} && wget http://s3.amazonaws.com/alexa-static/top-1m.csv.zip`
    `cd #{File.join(RAILS_ROOT, 'db')} && unzip -o top-1m.csv.zip`
    puts "Parsing..."
    alexa = FasterCSV.read(File.join(RAILS_ROOT, 'db', 'top-1m.csv'))
    puts "Importing..."
    Site.import [:alexa_rank, :url], alexa, :validate => false, :on_duplicate_key_update => [:alexa_rank] 
    Site.version!
    File.delete(File.join(RAILS_ROOT, 'update.lock'))
    puts "Done!"
  end
  
  desc "Warm up the database"
  task :warm_db => :environment do
    300.times{|i| Site.get 500 * i }
  end
end
