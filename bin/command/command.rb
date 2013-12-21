# -*- coding: utf-8 -*-
module Azunyan::Command 
  class Parser
    attr_accessor :command, :order, :params
    def initialize cmd
      cmds = cmd.split
      @command, @order, @params = cmds[1], cmds[2], cmds[3..-1]
    end
  end

  class Core
    class << self
      def create type
      end
    end

    def initialize interpreter
      @interpreter = interpreter
      @bin = {
        '-p'   => Pattern,
        '-pd'  => PatternDelete,
        '-r'   => Reaction,
        '-rd'  => ReactionDelete,
        '-d'   => Delete,
        '-ls'  => List,
        '-h'   => Help,
        'up'   => Up,
        'halt' => Halt,
        'probability' => Probability
      }
    end

    def run cmd
      instance = create_command_instance Azunyan::Command::Parser.new(cmd)
      instance.run
      instance.result
    #rescue
    
    #'は？'
    end

    private
    def create_command_instance parser
      @bin[ parser.command ].new(@interpreter, parser)
    end
  end

  class Base
    def initialize interpreter, parser
      @interpreter, @parser = interpreter, parser
    end

    def run
      @out = @parser.order == '-h' ? help : __run__
    end

    def result
      @out || 'なんかわかんないですけど、実行しました＞＜'
    end

    def help
      'せ、先輩... すみません... わかんないです...'
    end
  end

  class Pattern < Base
    def help
      '-p [パターンに紐づくユニーク文字列(-lsで確認)] [パターン...]'
    end

    private
    def __run__
      @interpreter.learn_pattern @parser.order, @parser.params
    end
  end

  class Reaction < Base
    def help
      '-r [リアクションに紐づくユニーク文字列(-lsで確認)] [リアクション...]'
    end

    private
    def __run__
       @interpreter.learn_reaction @parser.order, @parser.params
    end
  end

  class Delete < Base
    def result
      @out || "はい、#{@parser.order}に関する事は全部忘れました！"
    end

    def help
      '-d [パターン||リアクションに紐づくユニーク文字列(-lsで確認)]'
    end

    private
    def __run__
      @interpreter.drop_command @parser.order
    end
  end

  class List < Base
    private
    def __run__
      @interpreter.ls @parser.order
    end
  end

  class RemoveAll < Base
    def result
      "全部忘れました！"
    end

    private
    def __run__
      @interpreter.remove
    end
  end

  class Up < Base
    def result
      "✧*。ヾ(。>﹏<。)ノ゛。*✧"
    end

    private
    def __run__
      @interpreter.up
    end
  end

  class Halt < Base
    def result
      "(´；ω；｀)"
    end

    private
    def __run__
      @interpreter.halt
    end
  end

  class Probability < Base
    private
    def __run__
      @parser.order.nil? ? 
        "今の反応率は#{@interpreter.probability}%ですよ先輩！" : 
        @interpreter.set_probability(@parser.order)
    end
  end

  class  Help < Base
    def result
      "-p(pattern登録), -r(reaction登録), -d(delete), -ls(list), up(話し始める), halt(黙る), remove_all(全部忘れる), probability(反応率の設定, 確認)"
    end

    private
    def __run__
    end
  end
end
