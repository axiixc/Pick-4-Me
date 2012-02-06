require 'rubygems'
require 'sinatra'
require 'haml'
require 'yaml'
require 'uri'

configure do
    RESTAURANTS_DATA_FILE = 'restaurants.yaml'
end

helpers do
    def readRestaurants
        YAML::load_file RESTAURANTS_DATA_FILE
    end
    
    def makeWeightedArray source
        values = []
        source.each { |name, weight| weight.times { values << name } }
        values
    end
    
    def pickRandom values
        values[rand(values.count - 1)]
    end
    
    def writeRestaurants restaurants
        File.open(RESTAURANTS_DATA_FILE, 'w') { |f| f.write(restaurants.to_yaml) }
    end
end

get '/upvote/:rname' do |rname|
    restaurant = readRestaurants
    
    if !restaurant[rname].nil?
        restaurant[rname] += 1
        writeRestaurants restaurant
    end

    redirect '/' + rname
end

get '/downvote/:rname' do |rname|
    restaurant = readRestaurants

    if !restaurant[rname].nil?
        restaurant[rname] -= 1
        writeRestaurants restaurant
    end
    
    redirect '/' + rname
end

post '/add' do
    if params[:name].empty? || params[:weight].empty?
        @location = url('/edit')
        @message = 'Cannot leave name or weight empty when adding a new restaurant.'
        haml :error
    else
        restaurants = readRestaurants
        restaurants[params[:name]] = params[:weight].to_i
        writeRestaurants restaurants
        
        redirect '/edit'
    end
end

get '/delete/:rname' do |rname|
    restaurants = readRestaurants
    restaurants.delete rname
    writeRestaurants restaurants
    
    redirect '/edit'
end

post '/update' do
    restaurants = {}
    
    params[:name].each_with_index do |name, index|
        restaurants[name] = params[:weight][index].to_i unless name.empty?
    end
    
    writeRestaurants restaurants
    
    redirect '/edit'
end

get '/edit' do
    @restaurants = readRestaurants.sort
    haml :edit
end

get '/?:rname?' do |rname|
    @full_page = true
    
    restaurants = readRestaurants
    @name = (restaurants.has_key? rname) ? rname : pickRandom(makeWeightedArray(restaurants))
    @rank = restaurants[@name]
    
    haml :picker
end