# Mostly cribbed from http://www.igvita.com/2008/01/07/support-vector-machines-svm-in-ruby/

namespace :svm do
  desc "Take half the data, train an SVM, and test it on the other half. Ish."
  task :train_and_test => :environment do 
    pa = Parameter.new
#    pa.C = 100
#    pa.svm_type = C_SVC #  NU_SVC
#    pa.degree = 1
#    pa.coef0 = 0
#    pa.eps= 0.001
    pa.probability = 1
    kernels = [ LINEAR, POLY, RBF, SIGMOID ]
    kernel_names = [ 'Linear', 'Polynomial', 'Radial basis function', 'Sigmoid' ]
    
    test_labels, test_vectors, training_labels, training_vectors = [], [], [], []
    used_sites = Site.find(:all, :conditions => 'avg_visited < 0', :select => 'id').map(&:id).sort
    size = used_sites.count
    
     Scraping.find(:all,  :conditions => 'found_visitations_count > 0').each do |scraping|
      test = (rand(2) == 1)
#test = true
      (test ? test_labels : training_labels) << scraping.user_id
      subvector = Array.new(size, 0)
      scraping.visitations.find(:all, :conditions => ['site_id IN (?)', used_sites], :order => 'site_id').each do |visitation|
        subvector[visitation.site_id] = (visitation.visited ? 1 : 0)
      end
      (test ? test_vectors : training_vectors) << subvector
    end
    
#sp = Problem.new(*read_file(File.join(RAILS_ROOT, 'css_svm_all.txt')))
#m = Model.new(sp, pa)
#tests = Scraping.find(:first, :conditions => ['id > ? and found_visitations_count > 0 and user_id != 1', (rand * Scraping.maximum('id')).round])
#testv = tests.visitations.find(:all, :conditions => ['site_id IN (?)', used_sites ]).inject({}){|mm,xx| mm[xx.site_id] = (xx.visited ? 1 : 0).to_f; mm}
#pred, probs = m.predict_probability testv;probs.sort_by{|k,v| -v}
#"#{tests.user_id}: #{probs[tests.user_id]} / ##{probs.sort_by{|k,v| -v}.map{|x|x[0]}.index(tests.user_id)}"
#testv.select{|k,v|v==1}

#    uu = User.find(:all, :include => :probability_vectors)
#    training_vectors = uu.map(&:probability_vector)
#    training_labels = uu.map(&:id)
    sp = Problem.new training_labels, training_vectors
    puts "Training size: #{training_labels.size}"
    puts "Test size: #{test_labels.size}"
    
    puts "Errors on training, test sets:"
    
    # We're not sure which Kernel will perform best, so let's give each a try
    kernels.each_index { |j|
      # Iterate and over each kernel type
      pa.kernel_type = kernels[j]
      m = Model.new(sp, pa)
      errors = 0
      
      # Test kernel performance on the training set
      training_labels.each_index { |i|
        pred = m.predict(training_vectors[i])
#        pred, probs = m.predict_probability(training_vectors[i])
        # puts "Prediction: #{pred}, True label: #{labels[i]}, Kernel: #{kernel_names[j]}"
        errors += 1 if training_labels[i] != pred
      }
      print "#{kernel_names[j]} kernel: #{errors}, "
      
      # Test kernel performance on the test set
      errors = 0
      test_labels.each_index { |i|
        pred = m.predict(test_vectors[i])
#        pred, probs = m.predict_probability(test_vectors[i])
        # puts "\t Prediction: #{pred}, True label: #{test_labels[i]}"
        errors += 1 if test_labels[i] != pred
      }
      puts " #{errors}"
    }
  end
end