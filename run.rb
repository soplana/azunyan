# -*- coding: utf-8 -*-
require './bin/azunyan.rb'

bot = Cinch::Bot.new do
  @@azu = Azunyan::Interpreter.new
  configure do |c|
    c.server   = @@azu.model.settings["irc"]["server"]
    c.channels = [@@azu.channel_with_password]
    c.nick     = "azunyan"
  end

  on :message, /.*/ do |m|
    msg = ""
    if m.params[1] =~ /^azunyan\s.*|^azu\s.*/
      m.target.notice(@@azu.command.run(m.params[1]))
      @@azu.reload!
    else
      @@azu.all_reg.each do |k, v|
        if v[:regexp] =~ m.params[1]
          sleep(2)
          m.reply(@@azu.react? ? "@#{m.user.nick} #{v[:messages].sample}" : '？')
        end
      end
    end
  end
end

bot.start
