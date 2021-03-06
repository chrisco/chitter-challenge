require 'sinatra/base'
require 'sinatra/flash'
# require 'byebug'
# require 'pry'
require 'data_mapper'
require 'dm-migrations'
require 'tilt/erb'
require './lib/chit'
require './lib/user'

class App < Sinatra::Base
  set :views, proc {File.join(root, '..', 'views')}
  enable :sessions
  set :session_secret, '121212121212'
  use Rack::Session::Pool
  env = ENV['RACK_ENV'] || "development"
  DataMapper.setup(:default, ENV['DATABASE_URL'] || "postgres://localhost/ohchit_#{env}")

  # DataMapper::Logger.new($stdout, :debug)
  DataMapper::Model.raise_on_save_failure = true
  DataMapper.finalize
  # DataMapper.auto_migrate!
  DataMapper.auto_upgrade!

  register Sinatra::Flash

  # This is here as a reminder and question to myself.
  # I think I get what it does, but I don't see where the "is_user?" method is
  # coming from, so it must be inherited?  Or??  Hmmm.
  # From Thomas: https://github.com/tochman/my_app/blob/master/lib/user.rb#L39
  # before do
  #   @user = User.get(session[:user_id]) unless is_user?
  # end

  get '/' do
    erb :index
  end

  get '/sign_up' do # TODO: Use hyphens instead of underscores on routes for better user readability?
    erb :sign_up
  end

  post '/sign_up' do
    if((params[:name] == '') || (params[:email] == '') || (params[:user_name] == '') || (params[:password] == '') || (params[:password_confirm] == ''))
      flash[:warning] = "You submitted invalid data.  Please try again."
      redirect '/sign_up'
    else
      new_user = User.new
      new_user.name = params[:name]
      new_user.user_name = params[:user_name]
      new_user.email = params[:email]
      new_user.password = params[:password]
      new_user.password_confirm = params[:password_confirm]
      new_user.save
      redirect '/'
    end
  end

  get '/sign_in' do
    erb :sign_in
  end

  post '/sign_in' do
    if((params[:email] == '') || (params[:password] == ''))
      flash[:warning] = "You submitted invalid data.  Please try again."
      redirect '/sign_in'
    else
      # I'm not sure about this "begin / rescue" business.
      # Got it from Thomas and need to learn more about it.
      # https://github.com/tochman/my_app/blob/master/lib/my_app.rb#L76
      # Leaving it here as a reminder and question.
      begin
        email = params[:email]
        password = params[:password]
        @user = User.authenticate(email, password)
        session[:user_id] = @user.id
        flash[:notice] = "Welcome #{@user.name}!"
        redirect '/'
      rescue
        flash[:warning] = "You submitted invalid data.  Please try again."
        redirect "/sign_in"
      end
    end
  end

  get '/sign_out' do
    flash[:notice] = "Catcha ya later, dude!"
    session[:user_id] = nil
    @user = nil
    redirect "/"
  end

  get '/share_chit' do
    if !session[:user_id]
      redirect "sign_in"
    else
      erb :share_chit
    end
  end

    post '/share_chit' do
      if(params[:chit_text] == '')
        flash[:warning] = "You submitted invalid data.  Please try again."
        redirect '/share_chit'
      else
        begin
          new_chit = Chit.new
          new_chit.chit_text = params[:chit_text]
          new_chit.created_at = Time.now
          new_chit.user_id = session[:user_id]
          new_chit.save
          flash[:notice] = "You shared your chit!"
          redirect '/see_chit'
        rescue
          flash[:warning] = "Oops, your chit was too big.  Max chit length is 140 characters.  Please try again."
          redirect "/share_chit"
        end
      end
    end

    get '/see_chit' do
      @chits = Chit.all(limit: 10, order: [ :created_at.desc ])
      erb :see_chit
    end

    post 'search' do
      # TODO: Create search functionality
    end

    get 'search_results' do
      # TODO: Create search results page.
      # Will be like see_chit page except instead of finding all
      # it will find chits that contain the search string
    end


  # Do I need this?  If not, take it out.  Or??
  # Start the server if Ruby file executed directly:
  run! if app_file == $0
end
