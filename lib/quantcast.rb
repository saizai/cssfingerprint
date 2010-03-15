module Quantcast
  require 'RMagick'
  require 'base64'
  require 'net/http'
  require 'uri'
  
  def update_demographics_for site
    s = site # just shorthand
    %w(gender age children ethnicity income education).each do |demo|
      img = Magick::Image.read_inline(Base64.encode64(Net::HTTP.get URI.parse("http://www.quantcast.com/profile/demographicGraph?demo=#{ demo }&wunit=wd%3A#{s.url.split('.').reverse.join('.') }"))).first
      
      return nil if img.columns < 90 # if one isn't right, the others probably aren't also
      
      case demo
      when 'gender':
        male, female = bar_graph_set img, 0..1
        s.males = male.to_f / (male + female)
      when 'age':
        a3_12, a13_17, a18_34, a35_49, a50 = bar_graph_set img, 0..4
        total = [a3_12, a13_17, a18_34, a35_49, a50].sum
        s.age3_12, s.age13_17, s.age18_34, s.age35_49, s.age50plus = [a3_12,a13_17,a18_34,a35_49,a50].map{|x| x.to_f / total}
      when 'ethnicity':
        caucasian, african, asian, hispanic = bar_graph_set img, 0..4
        total = [caucasian, african, asian, hispanic].sum
        s.eth_caucasian, s.eth_african, s.eth_asian, s.eth_hispanic = [caucasian, african, asian, hispanic].map{|x| x.to_f / total}
      when 'children':
        nokids_0_17, yeskids_0_17, nokids_0_2, yeskids_0_2, nokids_3_12, yeskids_3_12, nokids_13_17, yeskids_13_17 = bar_graph_set img, [0,1,3,4,6,7,9,10]
        s.kids_0_17 = yeskids_0_17.to_f / (yeskids_0_17 + nokids_0_17)
        s.kids_0_2 = yeskids_0_2.to_f / (yeskids_0_2 + nokids_0_2)
        s.kids_3_12 = yeskids_3_12.to_f / (yeskids_3_12 + nokids_3_12)
        s.kids_13_17 = yeskids_13_17.to_f / (yeskids_13_17 + nokids_13_17)
      when 'education':
        no_college, college, grad = bar_graph_set img, 0..2
        total = [no_college, college, grad].sum
        s.college, s.college_grad = [college, grad].map{|x| x.to_f / total}
      when 'income':
        inc_0_30, inc_30_60, inc_60_100, inc_100 = bar_graph_set img, 0..3
        total = [inc_0_30, inc_30_60, inc_60_100, inc_100].sum
        s.income_0_30, s.income_30_60, s.income_60_100, s.income_100_plus = [inc_0_30, inc_30_60, inc_60_100, inc_100].map{|x| x.to_f / total}
      end
    end
    
    s.save
  end
  
  def bar_graph_set img, offsets
    offsets = offsets.to_a if offsets.is_a? Range
    offsets.map{|offset| bar_graph_size img, offset}
  end
  
  def bar_graph_size img, offset
    38 - (img.get_pixels(97,21 + (15 * offset),38,1).map(&:red).index(102) || 38)
  end
end