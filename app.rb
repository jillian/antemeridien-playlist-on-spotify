require 'rspotify/oauth'
require 'dotenv'
Dotenv.load

class Log
  def self.logger
    if @logger.nil?
    	file = File.new("#{File.dirname(__FILE__)}/log/development.log", 'a+')
    	file.sync = true
      @logger = Logger.new file
      @logger.level = Logger::INFO
      @logger.datetime_format = '%a %d-%m-%Y %H%M'
    end
    @logger
  end
end

class App < Sinatra::Base
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

	  enable :sessions

	  enable :logging

    # use Rack::CommonLogger, file
    set :logging, nil
    logger = Log.logger
    set :logger, logger

	end

	helpers do 
	  include Rack::Utils
	  alias_method :h, :escape_html
	end

  login_page = lambda do
  	erb :index
  end

  logout = lambda do

  end

	get '/', &login_page

	get '/auth/spotify/callback' do
		AnteMeridiemPlaylistParser.run
		@songs = Song.all
		Log.logger.info "Song count: #{@songs.count}"
		spm = SpotifyPlaylistManager.new(request.env['omniauth.auth'])
		spm.run

		erb :songs
	end
end