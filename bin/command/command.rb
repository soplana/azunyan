module Azunyan::Command 
  class Core
    class << self
      def create type
      end
    end

    def initialize interpreter
      @interpreter = interpreter
    end

    def run _command
      commands = _command.split(" ")
      command, order, params = commands[1], commands[2], commands[3..-1]
      if order == "-h"
        return "[pattern, reactionに紐づくユニーク文字列]" if command == "-d"
        return "[pattern, reactionに紐づくユニーク文字列] [パターン...]"
      end

      case command
      when "-p"
        learn_pattern order, params
      when "-r"
        learn_reaction order, params
      when "-d"
        @interpreter.model.command.drop_command order
        "はい、#{order}に関する事は全部忘れました！"
      when "-ls"
        @interpreter.model.command.ls(order)
      when "remove_all"
        remove
        "全部忘れました！"
      when "up"
        up
        "✧*。ヾ(｡>﹏<｡)ﾉﾞ。*✧"
      when "halt"
        halt
        "(´；ω；｀)"
      when "probability"
        order.nil? ? "今の反応率は#{@interpreter.probability}%ですよ先輩！" : set_probability(order)
      when "-h"
        "-p (pattern登録), -r (reaction登録), -d(delete), -ls(list), up(話し始める), halt(黙る), remove_all(全部忘れる), probability(反応率の設定, 確認)"
      else
        "は？"
      end
    end
  end
end

class Azunyan::Command::Base
end
