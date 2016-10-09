require 'rspotify/oauth'

class App < Sinatra::Base
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
	    provider :spotify, ENV["SPOTIFY_CLIENT_ID"], ENV["SPOTIFY_CLIENT_SECRET"], scope: 'user-read-email playlist-modify playlist-modify-private'
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
		# require 'httparty'
		# ANTE_MERIDIEN_ID = "1465352786964"
		# PROGRAM_ID = "5187efc8e1c85479698fb116"

		# playlist_url = "https://api.composer.nprstations.org/v1/widget/5187efb6e1c85479698fb0cf/playlist?t=#{ANTE_MERIDIEN_ID}&prog_id=#{PROGRAM_ID}"
		puts "hello"
		# episodes = HTTParty.get(playlist_url).parsed_response["playlist"]

		# def parse_playlist(playlists)
		# 	playlists.each do |track|
		# 		s = Song.create(
		# 			track: track['trackName'], 
		# 			artist:     track['artistName'], 
		# 			album:      track['collectionName'])
		# 	end
		# end

		# episodes.each do |episode|
		# 	puts episode["date"]
		# 	parse_playlist(episode["playlist"])
		# end
		AnteMeridiemPlaylistParser.run

		@songs = Song.all

		puts @songs.count
		puts "*"
		puts "*"
		puts "****"


	 
	  spotify_user = RSpotify::User.new(request.env['omniauth.auth'])

		playlist_name = "test"
	  playlist = spotify_user.playlists.select { |p| p.name == playlist_name }.first || spotify_user.create_playlist!(playlist_name)

	  song_ids = []

	  require 'uri'

	  @songs.each do |song|
	  	track = URI.escape(song.track)
	  	artist = URI.escape(song.artist)
	  	query_url = "https://api.spotify.com/v1/search?q=track:#{track}%20" + "artist:#{artist}%20&type=track"

	  	search_results = HTTParty.get(query_url).parsed_response["tracks"]["items"]

	  	next if search_results.empty?

			filtered = search_results.select { |t| song.track == t["album"]["name"] }.first
			filtered = search_results.first if !filtered

	  	song_id = filtered["id"]
	  	song_ids << song_id unless playlist.tracks.map(&:id).include? song_id 
	  end
	  puts "----------------"
	  puts "out of loop"

	  puts song_ids

	  if !song_ids.empty?
		  tracks = RSpotify::Track.find(song_ids)
		  playlist.add_tracks!(tracks)
		end

	  puts "playlist no. of tracks: #{playlist.tracks.count}"
	  puts "song ids count: #{song_ids.count}"


	  puts "playlist no. of tracks: #{playlist.tracks.count}"

		erb :songs
	end
end