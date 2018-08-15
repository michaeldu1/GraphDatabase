require 'net/http'
require 'digest/sha1'
require 'csv'
require 'json'
require 'rest-client'
require 'rubygems'
require 'set'

$url = "http://reg.clinicalgenome.org/alleles?gene=BRCA1&limit=1000"
SKIP_NUM = 1000

def process_gene_data(data_hash, failed_arr)
	json_data = JSON.parse(RestClient.get($url))
	num_IDs = json_data.length
	skip = 0
	count = 0
	while num_IDs == SKIP_NUM do 
		json_data = JSON.parse(RestClient.get($url))
		for elem in json_data
			caid = elem["@id"][33..-1]
			if elem["externalRecords"] != nil
				if elem["externalRecords"]["ClinVarVariations"] != nil
					data_hash["#{caid}"] = elem["externalRecords"]["ClinVarVariations"][0]["@id"][46..-1].to_s
				else
					failed_arr.push(caid)
				end
			else
				failed_arr.push(caid)
			end
		end
		skip += json_data.length
		$url = 'http://reg.clinicalgenome.org/alleles?gene=BRCA1&skip=' + skip.to_s + '&limit=1000'
		count += json_data.length
		puts "Processed: #{count} alleles"
		num_IDs = json_data.length
	end
end

def write_to_csv(data_hash)
	CSV.open('BRCA1.csv', 'wb') do |csv|
		for key in data_hash
		csv << [key[0], key[1]]
		end
	end
	puts "done!"
end

failed_arr = Array.new
data_hash = Hash.new
process_gene_data(data_hash, failed_arr)
puts data_hash
puts data_hash.length
write_to_csv(data_hash)
