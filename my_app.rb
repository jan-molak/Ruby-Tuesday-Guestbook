require 'sinatra/base'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'
require 'haml'
require 'less'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/db/comments.db")

class Comment
  include DataMapper::Resource

  property :id,         Serial
  property :posted_by,  String
  property :body,       Text
  property :created_at, DateTime
end

# automatically create the Comment table
Comment.auto_migrate! unless Comment.storage_exists?

class DateTime
  def ago
    seconds = (Time.now - Time.parse(self.to_s)).to_i

    case true
      when seconds < 60
        "less than a minute"
      when seconds < 60*5
        "less than 5 minutes"
      when seconds < 60*60
        "less than an hour"
      when seconds < 60*60*24
        "#{(seconds / 3600).to_i} hours"
      else
        "#{(seconds / (3600*24)).to_i} days"
    end

  end
end

module RubyTuesday
  include DataMapper

  class HomepageApp < Sinatra::Base
    set :haml, :format => :html5
    set :static => true
    set :public, File.dirname(__FILE__) + '/public'

    get '/' do
        @comments = Comment.all(:order => [:created_at.asc])

        haml :index
    end

    post '/' do
      @comment = Comment.create(
        :body       => params[:comment_body],
        :posted_by  => params[:comment_posted_by],
        :created_at => Time.now
      )
      if @comment.save
        redirect "/"
      end
    end

    get %r{/([\w]+)\.css} do
      less :"less/#{params[:captures].first}"
    end

  end
end