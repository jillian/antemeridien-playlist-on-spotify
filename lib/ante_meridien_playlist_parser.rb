# require_relative 'song'

# class AnteMeridianPlaylistParser
# 	ANTE_MERIDIEN_ID = "1465352786964"
# 	PROGRAM_ID = "5187efc8e1c85479698fb116"

# 	playlist_uri = "https://api.composer.nprstations.org/v1/widget/5187efb6e1c85479698fb0cf/playlist?t=#{ANTE_MERIDIEN_ID}&prog_id=#{PROGRAM_ID}"

# 	episodes = HTTParty.get(playlist_uri).parsed_response["playlist"]

# 	def parse_playlist(episodes)
# 		playlist.each do |track|
# 			Song.create(track: track['trackName'], artist: track['artistName'])
# 		end
# 	end

# 	episodes.each do |episode|
# 		puts episode["date"]
# 		parse_playlist(episode["playlist"])
# 	end

# end