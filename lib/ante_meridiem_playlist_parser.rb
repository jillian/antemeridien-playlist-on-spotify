require_relative 'song'
require 'httparty'

class AnteMeridiemPlaylistParser
	ANTE_MERIDIEM_ID = "1465352786964"
	PROGRAM_ID = "5187efc8e1c85479698fb116"
	BASE_PATH = "https://api.composer.nprstations.org/v1/widget/5187efb6e1c85479698fb0cf"
	
	class << self 
		def run
			playlist_uri = "#{BASE_PATH}/playlist?t=#{ANTE_MERIDIEM_ID}&prog_id=#{PROGRAM_ID}"
			episodes = HTTParty.get(playlist_uri).parsed_response["playlist"]
			episodes.each { |episode| parse_playlist(episode["playlist"]) }
		end

		private 
		def parse_playlist(playlists)
			playlists.each do |track|
				Song.create(track: track['trackName'], artist: track['artistName'], album: track['collectionName'])
			end
		end
	end
end