# -*- coding: utf-8 -*-
require './bin/azunyan.rb'

bot = Cinch::Bot.new do
  @@azu = Azunyan::Interpreter.new
  configure do |c|
    c.server   = @@azu.model.settings["irc"]["server"]
    c.channels = [@@azu.model.settings["irc"]["channels"]]
    c.nick     = "tesnyan"
  end

  on :message, /.*/ do |m|
    msg = ""
    if m.params[1] =~ /^tesnyan\s.*|^tes\s.*/
      msg = @@azu.command.run(m.params[1])
      @@azu.reload!
    else
      @@azu.all_reg.each do |k, v|
        if v[:regexp] =~ m.params[1]
          sleep(2)
          msg = @@azu.react? ? "@#{m.user.nick} #{v[:messages].sample}" : nil
        end
      end
    end
    if !msg.nil?
      m.reply msg
    end
  end
end

bot.start
