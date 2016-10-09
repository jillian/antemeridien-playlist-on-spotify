class Song
	include DataMapper::Resource

	property :id,         Serial
	property :track_name, String
	property :artist,     String
	property :album,      String
	property :uri,        String
end

DataMapper.finalize

Song.auto_upgrade!