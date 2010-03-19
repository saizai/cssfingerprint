class AI
  
  def self.regenerate
    used_sites = Site.find(:all, :conditions => 'avg_visited > 0', :select => 'id').map(&:id).sort
    f_all = File.open File.join(RAILS_ROOT, 'db', 'ai', 'css_svm_all.txt'), 'w'
    f_train = File.open File.join(RAILS_ROOT, 'db', 'ai', 'css_svm_train.txt'), 'w'
    f_test  = File.open File.join(RAILS_ROOT, 'db', 'ai', 'css_svm_test.txt'), 'w'
    Scraping.find(:all,  :conditions => 'found_visitations_count > 0').each do |scraping|
      file = ((rand(2) == 1) ? f_test : f_train) 
      string = self.get_line_for scraping, used_sites
      file << string
      f_all << string
      file.flush
      f_all.flush
    end
    f_train.close
    f_test.close
    f_all.close
    
    self.update_model
  end
  
  def self.update scraping_id
    f_all = File.open File.join(RAILS_ROOT, 'db', 'ai', 'css_svm_all.txt'), 'a'
    f_train = File.open File.join(RAILS_ROOT, 'db', 'ai', 'css_svm_train.txt'), 'a'
    f_test  = File.open File.join(RAILS_ROOT, 'db', 'ai', 'css_svm_test.txt'), 'a'
    file = ((rand(2) == 1) ? f_test : f_train)
    scraping = Scraping.find(scraping_id)
    used_sites = Site.find(:all, :conditions => 'avg_visited > 0', :select => 'group_concat(id) as ids').ids.split(',').sort
    string = self.get_line_for scraping, used_sites
    file << string
    f_all << string
    f_all.close
    f_train.close
    f_test.close
    
    self.update_model
  end
  
  def self.get_line_for scraping, used_sites
    string = "#{scraping.user_id} "
    scraping.visitations.find(:all, :conditions => ['site_id IN (?)', used_sites], :order => 'site_id', :select => 'site_id, visited').each do |visitation|
      string += "#{visitation.site_id}:#{(visitation.visited ? 1 : 0).to_f} "
    end
    string += "\n"
  end
  
  def self.update_model
    model = self.make_model 'css_svm_all.txt'
    model.save(File.join(RAILS_ROOT, 'db', 'ai', 'css_svm_model.txt'))
  end
  
  def self.make_model datafile
    pa = Parameter.new
    pa.probability = 1
    pa.kernel_type = LINEAR
    pa.C = 0.5
    pa.gamma = 0.0078125
#    pa.kernel_type = SIGMOID
#    pa.C = 32768.0
#    pa.gamma = 3.0517578125e-05
    sp = Problem.new(*read_file(File.join(RAILS_ROOT, 'db', 'ai', datafile)))
    model = Model.new(sp, pa)
  end
  
  def self.parse_line line
    user_id = line.first.to_i
    vector = line[2..-1].split(' ').inject({}){|m,x| y = x.split(':'); m[y[0].to_i] = y[1].to_f; m }
    return user_id, vector
  end
  
  # This is a very expensive call to regenerate.
  def self.avg_pv regen = false
    if regen or !(ret = Rails.cache.read('AI.avg_pv'))
      f_all = File.open File.join(RAILS_ROOT, 'db', 'ai', 'css_svm_all.txt'), 'r'
      scrapings = []
      while line = f_all.gets
        scrapings << line
      end
      f_all.close
      
      preds = []
      total_probs = {}
      scrapings.size.times do |i|
        print "#{i}: "
        f_temp = File.open File.join(RAILS_ROOT, 'db', 'ai', 'css_svm_temp.txt'), 'w'
        user_id, vector = self.parse_line scrapings[i]
        other_lines = scrapings[(i+1)..-1]
        other_lines += scrapings[0..(i-1)] if i != 0
        f_temp << other_lines
        f_temp.close
        model = self.make_model 'css_svm_temp.txt'
        pred, prob = model.predict_probability vector
        preds << [user_id, pred.to_i, prob]
        prob.map do |k,v|
          total_probs[k] ||= {:count => 0, :total => 0}
          total_probs[k][:count] += 1
          total_probs[k][:total] += v
        end  
      end
      ret = total_probs.inject({}){|m,x| m[x[0]] = x[1][:total] / x[1][:count]; m}, preds
      Rails.cache.write 'AI.avg_pv', ret
    end
    ret
  end
  
  def self.error_rate
    total_probs, preds = self.avg_pv
    repeat_users = User.find(:all, :conditions => 'scrapings_count > 1', :select => 'id').map(&:id)
    
    hits, misses = 0, 0
    preds.map{|pred| 
      next unless repeat_users.include? pred[0]
      pred[0] == pred[1] ? hits += 1 : misses += 1
    }
    
    hits.to_f / (hits + misses)
  end
end