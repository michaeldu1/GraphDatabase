=begin
	This script creates a csv file with the variant CAID in column 1 and the clinvar id 
	in column 2. The user will be prompted for the Gene name and the name of the file where
	they would like to write the data. 
=end

require 'net/http'
require 'digest/sha1'
require 'csv'
require 'json'
require 'rest-client'
require 'rubygems'
require 'set'

#change gene by editing gene='gene_of_choice' and edit the skip limit by editing limit='limit_of_choice'
print("Please enter the gene name: ")
#example: 'BRCA1'
gene = gets.strip.to_s
$url = "http://reg.clinicalgenome.org/alleles?gene=#{gene}&limit=1000"
SKIP_NUM = 1000

#iteratively loops through to process all variants associated with a gene, putting in 
def process_gene_data(data_hash, failed_arr)
	json_data = JSON.parse(RestClient.get($url))
	num_IDs = json_data.length
	skip = 0
	count = 0
	#gets alleles 1000 at a time, loop stops when all alleles are retrieved and less than 1000 alleles are returned by API call
	while num_IDs == SKIP_NUM do 
		json_data = JSON.parse(RestClient.get($url))
		for elem in json_data
			caid = elem["@id"][33..-1]
			if elem["externalRecords"] != nil
				if elem["externalRecords"]["ClinVarVariations"] != nil
					#stores valid caid and clinvar id pair into a hashtable
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

#writes data from hash table into a csv file
def write_to_csv(data_hash)
	print("Please enter the name of the csv file to be written: ")
	#example: BRCA1_Data
	file = gets.strip.to_s
	CSV.open("#{file}.csv", 'wb') do |csv|
		for key in data_hash
		csv << [key[0], key[1]]
		end
	end
	puts "done!"
end

failed_arr = Array.new
data_hash = Hash.new
process_gene_data(data_hash, failed_arr)
write_to_csv(data_hash)
