require 'ruby-prof'
require 'libxml'

NAMESPACES = {
				'mets' => 'http://www.loc.gov/METS/',
				'xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
				'premis' => 'http://www.loc.gov/premis/v3',
				'mix' => 'http://www.loc.gov/mix/v20',
				'aes' => 'http://www.aes.org/audioObject',
				'tcf' => 'http://www.aes.org/tcf',
				'txt' => 'http://www.loc.gov/standards/textMD',
				'doc' => 'http://www.fcla.edu/dls/md/docmd',
				'p2' => 'info:lc/xmlns/premis-v2-beta',
				'mods' => 'http://www.loc.gov/mods/v3',
				'daitss' => 'http://www.fcla.edu/dls/md/daitss/',
				'marc' => 'http://www.loc.gov/MARC21/slim',
				'dc' => 'http://purl.org/dc/elements/1.1/'
}

def find_all_premis_objects doc
	doc.find("//premis:object[@xsi:type='file']", NAMESPACES)
end

def find_first_id premis
	premis.find_first("premis:objectIdentifier/premis:objectIdentifierValue", NAMESPACES).content
end

def find_obsolete_files doc
	doc.find("//mets:file[not(mets:FLocat)]", NAMESPACES).map { |n| n['OWNERID'] }.to_set
end

def find_mets_sip_descriptor premis
	n = premis.find_first("//mets:file[@USE='sip descriptor']", NAMESPACES)
	n['OWNERID']
end

f = ARGV.shift or fail "pass in a file"

doc = LibXML::XML::Document.file f
RubyProf.start

rs = find_all_premis_objects doc
sd_id = find_mets_sip_descriptor doc
obsolete_dfs = find_obsolete_files doc

rs.each do |premis|
	id = find_first_id premis
	#find_mets_file_by_owner_id premis, id
	puts 'obsolete' if obsolete_dfs.include? id
	puts 'found sd' if id == sd_id
end

result = RubyProf.stop
printer = RubyProf::GraphHtmlPrinter.new result
open( 'prof.html', 'w') { |io| printer.print io, :min_percent => 1 }
