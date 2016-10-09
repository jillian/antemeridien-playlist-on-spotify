require 'rspotify/oauth'
require 'dotenv'
Dotenv.load

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
		AnteMeridiemPlaylistParser.run

		@songs = Song.all

		spm = SpotifyPlaylistManager.new(request.env['omniauth.auth'])
		spm.run

		erb :songs
	end
end