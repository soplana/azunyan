# -*- coding: utf-8 -*-
class Azunyan::Interpreter
  attr_accessor :model, :command, :probability

  def initialize
    @model   = Azunyan::Model::Core.new
    @command = Azunyan::Command::Core.new(self)
    @probability = 100
    up
  end

  def up
    @move = true
  end

  def halt
    @move = false
  end

  def learn_pattern order, pattern
    learn(order, pattern, "pattern")
  end

  def learn_reaction order, reaction
    learn(order, reaction, "reaction")
  end

  def all_reg
    return {} if @move == false
    @all ||= convert_command
  end

  def reload!
    @all = convert_command
  end

  def react?
    a = Array.new(@probability, true)
    b = Array.new(100 - @probability, false)
    (a+b).sample
  end

  def set_probability probability
    return "は？" if probability !~ /^\d*$/
    probability = probability.to_i
    return "#{probability}%とかワロタｗｗｗ小卒かよｗｗ" if 100 < probability
    @probability = probability
    return "先輩, #{probability}%に設定しました！"
  end

  def remove
    @model.command.remove_all
  end

  def drop_command order
    @model.command.drop_command order
  end

  def ls order
    @model.command.ls order
  end

  private
  def learn order, params, type
    if @model.command.__send__("create_#{type}", order, params)
      "[#{params.join(",")}]ですね！覚えました！"
    else
      "ば、馬鹿にしないでください先輩！そんなことくらいもう知ってます＞＜"
    end
  end

  def convert_command
    @model.command.all.inject({}) do |data, com|
      data[com["order"]] = {
        regexp: Regexp.union(com["pattern"]), 
        messages: com["reaction"]
      }
      data 
    end
  end
end
