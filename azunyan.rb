# -*- coding: utf-8 -*-
require 'bundler/setup'
require 'mongo'
require 'uri'
require 'json'
require 'yaml'
require 'cinch'

class Collection
  def initialize connection
    @connection = connection
  end

  def remove_all
    @collection.remove({})
  end

  def all
    @collection.find
  end
end

class Command < Collection
  def initialize connection
    super connection
    @collection = connection.collection("command")
  end

  def create_pattern order, regexp
    create order, regexp, "pattern"
  end

  def create_reaction order, regexp
    create order, regexp, "reaction"
  end

  def update_regexp doc, regexp, type
    @collection.update({'_id' => doc["_id"]}, {'$set' => {type => regexp}})
  end

  def find_by_order order
    @collection.find(order: order).first
  end

  def help
    "azunyan [command] [command名（ユニーク）] [一致パターン]"
  end

  private
  def create order, regexp, type
    if doc = find_by_order(order)
      types = doc[type] || []
      return nil if regexp.all?{|reg| types.include?(reg)}
      update_regexp(doc, (types+regexp).uniq, type)
    else
      @collection.insert(order: order, type => regexp)
    end
  end
end

class Lexical < Collection
  def initialize connection
    super connection
    @collection = connection.collection("lexical")
  end
end

class AzuMongo
  attr_accessor :commands, :lexicals

  def initialize
    setting_load
    get_collections
  end

  def get_collections
    @commands = Command.new connection
    @lexicals = Lexical.new connection
  end

  def collection_names
    connection.collection_names
  end
  
  def connection
    return @connection if @connection
    db      = URI.parse(connect_uri)
    db_name = db.path.gsub(/^\//, '')
    @connection = Mongo::Connection.new(db.host, db.port).db(db_name)
    @connection.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
    @connection
  end

  private
  def setting_load
    @settings = YAML.load(open("./settings.yml").read)
  end
  
  def connect_uri
    return @uri if @uri
    uri =  "mongodb://#{@settings["user"]["name"]}:#{@settings["user"]["password"]}"
    uri += "@#{@settings["database"]["host"]}:#{@settings["database"]["port"]}/"
    uri += @settings["database"]["name"]
    @uri = uri
  end
end

class Azunyan
  def initialize
    @my = AzuMongo.new
  end

  def learn_pattern order, pattern
    if @my.commands.create_pattern(order, pattern)
      "[#{pattern.join(",")}]ですね！覚えました！"
    else
      "ば、馬鹿にしないでください先輩！そんなことくらいもう知ってます＞＜"
    end
  end

  def learn_reaction order, reaction
    if @my.commands.create_reaction(order, reaction)
      "[#{reaction.join(",")}]ですね！覚えました！"
    else
      "ば、馬鹿にしないでください先輩！そんなことくらいもう知ってます＞＜"
    end
  end

  def all_reg
    @all ||= @my.commands.all.inject({}) do |data, com|
      data[com["order"]] = {
        regexp: Regexp.union(com["pattern"]), 
        messages: com["reaction"]
      }
      data 
    end
  end

  def reload!
    @all = @my.commands.all.inject({}) do |data, com|
      data[com["order"]] = {
        regexp: Regexp.union(com["pattern"]), 
        messages: com["reaction"]
      }
      data 
    end
  end

  def command _command
    commands = _command.split(" ")
    command, order, params = commands[1], commands[2], commands[3..-1]
    case command
    when "pattern"
      learn_pattern order, params
    when "reaction"
      learn_reaction order, params
    when "remove_all"
      remove
      "全部忘れました！"
    else
      "は？"
    end
  end

  def remove
    @my.commands.remove_all
  end
end



bot = Cinch::Bot.new do
  @@azu = Azunyan.new
  configure do |c|
    c.server = "irc.leeno.jp"
    c.channels = ["#member, 831mogumogu"]
    c.nick     = "azucat"
    #c.plugins.plugins = [Hello]
  end

  on :message, /.*/ do |m|
    if m.params[1] =~ /^azunyan\s.*/
      m.reply @@azu.command(m.params[1])
      @@azu.reload!
    else
      @@azu.all_reg.each do |k, v|
        if v[:regexp] =~ m.params[1]
          m.reply "@#{m.user.nick} #{v[:messages].sample}"
        end
      end
    end
  end
end

bot.start
