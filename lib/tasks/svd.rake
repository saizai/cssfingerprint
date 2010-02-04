require 'linalg'

namespace :svd do
  desc "Take half the data, extract SVD, and test it on the other half. Ish."
  task :train_and_test => :environment do 
    test_labels, test_vectors, training_labels, training_vectors = [], [], [], []
    size = 200 # Visitation.maximum(:site_id)
    
    Scraping.find_each :conditions => 'found_visitations_count > 0' do |scraping|
      test = (rand < 0.3)
      (test ? test_labels : training_labels) << scraping.user_id
      subvector = Array.new(size, 0)
      scraping.visitations.find(:all, :order => :site_id, :limit => size).each do |visitation|
        subvector[visitation.site_id - 1] = (visitation.visited ? 1 : 0)
      end
      (test ? test_vectors : training_vectors) << subvector
    end
    
    puts "Training size: #{training_labels.size}"
    puts "Test size: #{test_labels.size}"
    
    m = Linalg::DMatrix.rows training_vectors.transpose
    u, s, vt = m.singular_value_decomposition
    vt = vt.transpose
    # Take the 2-rank approximation of the Matrix
    #   - Take first and second columns of u  (6x2)
    #   - Take first and second columns of vt (4x2)
    #   - Take the first two eigen-values (2x2)
    u2 = Linalg::DMatrix.join_columns [u.column(0), u.column(1)]
    v2 = Linalg::DMatrix.join_columns [vt.column(0), vt.column(1)]
    eig2 = Linalg::DMatrix.columns [s.column(0).to_a.flatten[0,2], s.column(1).to_a.flatten[0,2]]
    
    test_results = []
    test_vectors.each_with_index do |test, i|
      test = Linalg::DMatrix.rows [test]
      testEmbed = test * u2 * eig2.inverse
      
      # Compute the cosine similarity between Bob and every other User in our 2-D space
      user_sim = {}
      v2.rows.each_with_index { |x, j|
        user_sim[j] = (testEmbed.transpose.dot(x.transpose)) / (x.norm * testEmbed.norm)
        test_results << [i, j, user_sim[j], (training_labels[j] == test_labels[i] ? 1 : 0)] unless user_sim[j].nan?
      }
      
      # Remove all users who fall below the 0.90 cosine similarity cutoff and sort by similarity
      # similar_users = user_sim.delete_if {|k,sim| sim < 0.6 or sim.nan? }.sort {|a,b| b[1] <=> a[1] }
      # similar_users.each { |u| printf "(ID: %d, Similarity: %0.3f) \n", u[0], u[1]  }
      
    end
    
    z = test_results.map{|y|[ (y[3]-y[2]).abs, 1].min **2}
    puts "RMSE: #{Math.sqrt(z.sum / z.size)}"
    z = test_results.map{|y|[ (y[3]-rand).abs, 1].min **2}
    puts "random RMSE: #{Math.sqrt(z.sum / z.size)}"
  end
end

 
# # We'll use a simple strategy in this case:
# #   1) Select the most similar user
# #   2) Compare all items rated by this user against your own and select items that you have not yet rated
# #   3) Return the ratings for items I have not yet seen, but the most similar user has rated
# similarUsersItems = m.column(similar_users[0][0]-1).transpose.to_a.flatten
# myItems = bob.transpose.to_a.flatten
#  
# not_seen_yet = {}
# myItems.each_index { |i|
#   not_seen_yet[i+1] = similarUsersItems[i] if myItems[i] == 0 and similarUsersItems[i] != 0
# }
#  
# printf "\\n %s recommends: \\n", users[similar_users[0][0]]
# not_seen_yet.sort {|a,b| b[1] <=> a[1] }.each { |item|
#   printf "\\tSeason %d .. I gave it a rating of %d \\n", item[0], item[1]
# }
#  
# print "We've seen all the same seasons, bugger!" if not_seen_yet.size == 0
