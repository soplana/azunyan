# -*- coding: utf-8 -*-
module Azunyan::Model
  class Core
    attr_accessor :command, :settings

    def initialize
      setting_load
      get_collections
    end

    def get_collections
      @command = Azunyan::Model::Command.new connection
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
end

class Azunyan::Model::Base
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

class Azunyan::Model::Command < Azunyan::Model::Base
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

  def drop_command order
    @collection.remove({order: order})
  end

  def ls order=""
    if order.nil?
      all.map{|cm| cm["order"]}.join(", ")
    else
      cm = find_by_order(order)
      return "‚í‚©‚ñ‚È‚¢‚Å‚·„ƒ" if cm.nil?
      "pattern:#{cm["pattern"].join(",")} reaction:#{cm["reaction"].join(",")}"[1..100]
    end
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
