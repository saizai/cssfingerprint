# From http://rosettacode.org/wiki/LZW_compression#Ruby

class LZW
def self.compress(uncompressed)
    # Build the dictionary.
    dict_size = 256
    dictionary = Hash[ Array.new(dict_size) {|i| [i.chr, i.chr]} ]
 
    w = ""
    result = []
    for c in uncompressed.split('')
        wc = w + c
        if dictionary.has_key?(wc)
            w = wc
        else
            result << dictionary[w]
            # Add wc to the dictionary.
            dictionary[wc] = dict_size
            dict_size += 1
            w = c
        end
    end
 
    # Output the code for w.
    result << dictionary[w] unless w.empty?
    result
end
 
# Decompress a list of output ks to a string.
def self.decompress(compressed)
    # Build the dictionary.
    dict_size = 256
    dictionary = Hash[ Array.new(dict_size) {|i| [i.chr, i.chr]} ]
 
    w = result = compressed.shift
    for k in compressed
        if dictionary.has_key?(k)
            entry = dictionary[k]
        elsif k == dict_size
            entry = w + w[0,1]
        else
            raise 'Bad compressed k: %s' % k
        end
        result += entry
 
        # Add w+entry[0] to the dictionary.
        dictionary[dict_size] = w + entry[0,1]
        dict_size += 1
 
        w = entry
    end
    result
end
end
