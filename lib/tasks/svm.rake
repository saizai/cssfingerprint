# Mostly cribbed from http://www.igvita.com/2008/01/07/support-vector-machines-svm-in-ruby/

require 'svm' # sudo gem install tomz-libsvm-ruby-swig

namespace :svm do
  desc "Take half the data, train an SVM, and test it on the other half. Ish."
  task :train_and_test => :environment do 
    pa = Parameter.new
#    pa.C = 100
#    pa.svm_type = C_SVC #  NU_SVC
#    pa.degree = 1
#    pa.coef0 = 0
#    pa.eps= 0.001
    kernels = [ LINEAR, POLY, RBF, SIGMOID ]
    kernel_names = [ 'Linear', 'Polynomial', 'Radial basis function', 'Sigmoid' ]
    
    test_labels, test_vectors, training_labels, training_vectors = [], [], [], []
    size = Visitation.maximum(:site_id)
    
    Scraping.find_each :conditions => 'found_visitations_count > 0' do |scraping|
      test = (rand(2) == 1)
      (test ? test_labels : training_labels) << scraping.user_id
      subvector = Array.new(size, 0)
      scraping.visitations.find_each do |visitation|
        subvector[visitation.site_id] = (visitation.visited ? 1 : 0)
      end
      (test ? test_vectors : training_vectors) << subvector
    end
    
    puts "Training size: #{training_labels.size}"
    puts "Test size: #{test_labels.size}"
    
    sp = Problem.new training_labels, training_vectors
 
    puts "Errors on training, test sets:"
    
    # We're not sure which Kernel will perform best, so let's give each a try
    kernels.each_index { |j|
      # Iterate and over each kernel type
      pa.kernel_type = kernels[j]
      m = Model.new(sp, pa)
      errors = 0
      
      # Test kernel performance on the training set
      training_labels.each_index { |i|
        pred, probs = m.predict_probability(training_vectors[i])
        # puts "Prediction: #{pred}, True label: #{labels[i]}, Kernel: #{kernel_names[j]}"
        errors += 1 if training_labels[i] != pred
      }
      print "#{kernel_names[j]} kernel: #{errors}, "
      
      # Test kernel performance on the test set
      errors = 0
      test_labels.each_index { |i|
        pred, probs = m.predict_probability(test_vectors[i])
        # puts "\t Prediction: #{pred}, True label: #{test_labels[i]}"
        errors += 1 if test_labels[i] != pred
      }
      puts " #{errors}"
    }
  end
end