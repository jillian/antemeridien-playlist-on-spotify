require 'uri'
require 'httparty'

class SpotifyPlaylistManager
	PLAYLIST    = "Ante Meridiem"
	SEARCH_PATH = "https://api.spotify.com/v1/search"

	def initialize(env)
		@spotify_user = RSpotify::User.new(env)
		@playlist 		= @spotify_user.playlists.select { |p| p.name == PLAYLIST }.first || @spotify_user.create_playlist!(PLAYLIST)
		@song_ids 		= []
	end

	def run
		get_tracks
		add_tracks
	end

	private
		def get_tracks
			@songs = Song.all
		  @songs.each do |song|
		  	query_url = "#{SEARCH_PATH}?q=track:#{URI.escape(song.track)}%20" + "artist:#{URI.escape(song.artist)}%20&type=track"

		  	search_results = HTTParty.get(query_url).parsed_response["tracks"]["items"]
		  	next if search_results.empty?

				filtered = search_results.select { |t| song.track == t["album"]["name"] }.first
				filtered = search_results.first if !filtered

		  	song_id = filtered["id"]
		  	@song_ids << song_id unless @playlist.tracks.map(&:id).include? song_id 
		  end
		  Log.logger.info "Songs Found on Spotify: #{@song_ids.count}"
		end

		def add_tracks
			if !@song_ids.empty?
		  	tracks = RSpotify::Track.find(@song_ids) 
		  	@playlist.add_tracks!(tracks)
		  	Log.logger.info "Playlist track count: #{@playlist.tracks.count}"
		  end
		end
end