=begin
	This file uses the csv file created from the Gene_To_CSV.rb file to create another csv file that
	will be used to in Neo4j to create the linked data graph. The user will be prompted to enter the 
	name of the file containing the CAID and clinvar ids and the name of the file where they would like 
	to write the new information.  The result of this script is a csv file containing the information 
	needed to create the graph in Neo4j.
=end

require 'net/http'
require 'digest/sha1'
require 'csv'
require 'json'
require 'rest-client'
require 'rubygems'
require 'set'

#parses and calls different apis to get relevant information
def get_info(result_arr)
	parsed_file = CSV.read(FILE, { :col_sep => "," })
	i = 0
	for elem in parsed_file
		caid = elem[0]
		clinvar_id = elem[1]
		puts "#{i} alleles processed"
		i += 1
		temp = [caid]
		#only pushes temp into result_arr if valid data
		if get_ncbi(clinvar_id, temp)
			result_arr.push(temp)
		end
	end
end

#this method concanetes a rating for the review status (1-4 stars)
def rank_review_status(review_status)
	if(review_status == "criteria provided, single submitter")
		return "#{review_status} (one star)"
	elsif(review_status == "criteria provided, multiple submitters, no conflicts")
		return "#{review_status} (two stars)"
	elsif(review_status == "reviewed by expert panel")
		return "#{review_status} (three stars)"
	elsif(review_status == "practice guideline")
		return "#{review_status} (four stars)"
	else 
		return "#{review_status} (zero stars)"
	end
end

#given an array of allele frequencies, this returns the largest
def get_largest_freq(freq_arr)
	largest = freq_arr[0]["value"]
	for freq in freq_arr
		if freq["value"] > largest
			largest = freq["value"]
		end
	end
	return largest.to_s
end

#uses clinvar id to get clinical signficance, review status, and allele frequence. returns true if data is valid and false if not
def get_ncbi(clinvar_id, temp)
	url = "https://www.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=clinvar&id=#{clinvar_id}&retmode=json"
	json_data = JSON.parse(RestClient.get(url))
	if json_data["result"]["#{clinvar_id}"]["error"] == nil
		protein = json_data["result"]["#{clinvar_id}"]["variation_set"][0]["variation_name"]
		clinsig = json_data["result"]["#{clinvar_id}"]["clinical_significance"]["description"]
		review_status = rank_review_status(json_data["result"]["#{clinvar_id}"]["clinical_significance"]["review_status"])
		last_eval = json_data["result"]["#{clinvar_id}"]["clinical_significance"]["last_evaluated"]
		if(protein.split('p.')[1] != nil)
			temp.push(protein.split('p.')[1][0..-2].strip)
		else
			temp.push(protein)
		end
		temp.push(clinsig)
		temp.push(review_status)
		allele_freq = json_data["result"]["#{clinvar_id}"]["variation_set"][0]["allele_freq_set"]
		if(allele_freq[0] == nil)
			temp.push("N/A")
		else
			temp.push(get_largest_freq(allele_freq))
		end
		temp.push(last_eval)
		return true
	end
	return false 
end

#creates a csv tab delimited file of the CAIDs and the GWAS urls
def write_to_csv(result_arr)
	print "Please enter the file you would like to write the gene data to: "
	#example: 'BRCA1_DATA'
	file_name = gets.strip.to_s 
	CSV.open("#{file_name}.csv", 'wb') do |csv|
		csv << ['CAID', 'Protein Changes', 'Clinical Significance', 'Review Status', 'Allele freq', 'Last Evaluated']
		for elem in result_arr
			if elem[2] == nil 
				csv << [elem[0], elem[1], "N/A", elem[3], elem[4], elem[5]]
			else
				csv << [elem[0], elem[1], elem[2], elem[3], elem[4], elem[5]]
			end
		end
	end
end

print "Please enter the file containing the CAIDs and ClinVar IDs: "
#file containing CAID and clinvar ID pairs. Example: 'BRCA1.csv'
FILE = gets.strip.to_s
result_arr = Array.new
get_info(result_arr)
write_to_csv(result_arr)



