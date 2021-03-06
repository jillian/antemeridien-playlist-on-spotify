class Song
	include DataMapper::Resource

	property :id,     Serial
	property :track,  String
	property :artist, String
	property :album,  String
end

DataMapper.finalize
Song.auto_upgrade!