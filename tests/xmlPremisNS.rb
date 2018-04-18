#require 'ruby-prof'
require 'libxml'

NAMESPACES = {
				'mets' => 'http://www.loc.gov/METS/',
				'xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
				'pv2' => 'info:lc/xmlns/premis-v2',
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
#RubyProf.start

#puts doc.root.namespaces.to_a
attrs =  doc.root.attributes
#puts attrs.to_a
ns = "premis"
secNS = "pv2"
attrs.each do |name|
	puts name.to_s

	if name.to_s.include? "info:lc/xmlns/premis-v2"
		ns = "pv2"
		secNS = "premis"
		puts ns
	end	
end
puts ns

df_paths = doc.find("//mets:file", NAMESPACES).map do |file_node|
#	puts file_node.namespaces.to_a
	uri = file_node['OWNERID']
#	puts uri
	object_node = doc.find_first(%Q{
		//#{ns}:object[@xsi:type='file']
				[#{ns}:objectIdentifier/#{ns}:objectIdentifierValue = '#{uri}']
	}, NAMESPACES)
	#puts object_node.namespaces.to_a
	#puts object_node if object_node?
	if object_node
		puts "object_node not nil" 
		bs_uris = object_node.find(%Q{
          #{ns}:relationship
            [ #{ns}:relationshipType = 'structural' ]
            [ #{ns}:relationshipSubType = 'includes' ] /
              #{ns}:relatedObjectIdentifier /
                #{ns}:relatedObjectIdentifierValue
        }, NAMESPACES).map { |node| node.content if node}

	else

		puts "object_node nil" 
		object_node = doc.find_first(%Q{
				//#{secNS}:object[@xsi:type='file']
						[#{secNS}:objectIdentifier/#{secNS}:objectIdentifierValue = '#{uri}']
			}, NAMESPACES)
		#puts object_node
		bs_uris = object_node.find(%Q{
          #{secNS}:relationship
            [ #{secNS}:relationshipType = 'structural' ]
            [ #{secNS}:relationshipSubType = 'includes' ] /
              #{secNS}:relatedObjectIdentifier /
                #{secNS}:relatedObjectIdentifierValue
        }, NAMESPACES).map { |node| node.content if node}
		puts "bs_uris"
        puts bs_uris
	end
end

rs = find_all_premis_objects doc
sd_id = find_mets_sip_descriptor doc
obsolete_dfs = find_obsolete_files doc

rs.each do |premis|
	id = find_first_id premis
	#find_mets_file_by_owner_id premis, id
	puts 'obsolete' if obsolete_dfs.include? id
	puts 'found sd' if id == sd_id
end

#result = RubyProf.stop
#printer = RubyProf::GraphHtmlPrinter.new result
#open( 'prof.html', 'w') { |io| printer.print io, :min_percent => 1 }
