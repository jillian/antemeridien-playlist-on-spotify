
# require 'layout'
# require 'songs'
# require 'ante_meridien_playlist_parser'
# require 'spotify_playlist_manager'

# require 'data_mapper'
# require 'dm-core'
# require 'dm-sqlite-adapter'

require 'rspotify/oauth'

class App < Sinatra::Base
  helpers Sinatra::Helpers
	enable :sessions

	DataMapper.setup(:default, 'sqlite::memory:') #in memory database
	DataMapper.finalize
	DataMapper.auto_migrate!

	app_folders = %w(lib views)
	app_folders.each do |folder|
	  Dir.glob("#{folder}/*.rb").each { |file| require_relative file }
	end

	configure do
	  use OmniAuth::Builder do
	    provider :spotify, ENV["spotify_client_id"], ENV["spotify_client_secret"], scope: 'user-read-email playlist-modify playlist-modify-private'
	  end
	end

	configure :development do
	  require 'sinatra/reloader'
	  register Sinatra::Reloader
	  app_folders.each do |folder|
	    Dir.glob("#{folder}/*.rb").each { |file| also_reload file }
	  end
	end

	helpers do 
	  include Rack::Utils
	  alias_method :h, :escape_html
	end

  login_page = lambda do
  	erb :index
  end

	get '/', &login_page

	get '/auth/spotify/callback' do
		puts "#{params}"
		require 'httparty'
		ANTE_MERIDIEN_ID = "1465352786964"
		PROGRAM_ID = "5187efc8e1c85479698fb116"

		playlist_url = "https://api.composer.nprstations.org/v1/widget/5187efb6e1c85479698fb0cf/playlist?t=#{ANTE_MERIDIEN_ID}&prog_id=#{PROGRAM_ID}"

		episodes = HTTParty.get(playlist_url).parsed_response["playlist"]

		def parse_playlist(playlists)
			playlists.each do |track|
				s = Song.create(
					track_name: track['trackName'], 
					artist:     track['artistName'], 
					album:      track['collectionName'])
			end
		end

		episodes.each do |episode|
			puts episode["date"]
			parse_playlist(episode["playlist"])
		end

		@songs = Song.all
	 
	  spotify_user = RSpotify::User.new(request.env['omniauth.auth'])

		playlist_name = "Antemeridien"
	  playlist = spotify_user.playlists.select { |p| p.name == playlist_name }.first || spotify_user.create_playlist!(playlist_name)

	  uris = []

	  require 'uri'

	  @songs.each do |song|
	  	track = URI.escape(song.track_name)
	  	artist = URI.escape(song.artist)
	  	query_url = "https://api.spotify.com/v1/search?q=track:#{track}%20" + "artist:#{artist}%20&type=track"

	  	search_results   = HTTParty.get(query_url).parsed_response["tracks"]["items"]

	  	next if search_results.empty?

			filtered = search_results.select { |t| song.track_name == t["album"]["name"] }.first
			filtered = search_results.first if !filtered

	  	song.uri = filtered["uri"]
	  	song.save

	  	uris << song unless playlist.tracks.map(&:uri).include? song.uri 
	  end
	  puts "----------------"
	  puts "out of loop"

	  puts "playlist no. of tracks: #{playlist.tracks.count}"
	  puts "uris count #{uris.count}"

	  puts uris.map(&:uri)

	  playlist.add_tracks!(uris)
	  
	  # POST https://api.spotify.com/v1/users/{user_id}/playlists/{playlist_id}/tracks
	 #  playlist_url = "https://api.spotify.com/v1/users/#{spotify_user.id}/playlists/#{playlist.id}/tracks"
	 #  HTTParty.post(playlist_url,
	 #  	body: { "uris": uris },
	 #  	headers: { "Content-Type": "application/json" }
	 #  	)

		erb :songs
	end
end