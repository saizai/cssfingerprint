module WTIKAY

  def scrape
    # require 'fastercsv'
    require 'net/http'
    require 'uri'
    
    # c = FasterCSV.open('/Users/saizai/Documents/workspace/cssfingerprint/wtikay.csv','w')
    f = File.open('/Users/saizai/Documents/workspace/cssfingerprint/wtikay.csv','w')
    
    res = Net::HTTP.get(URI.parse('http://wtikay.com/all'))
    
    res.scan(/t.push\("([^"]*)"\)[^(]*\(([^)]*)\)/).map{|y| f << ",#{y[1].to_i},#{y[0]}\n"; f.flush; sleep 0.0001}
    
    (11505..76507).each  do |i|
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

end