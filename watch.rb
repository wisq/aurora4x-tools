#!/usr/bin/env ruby

require 'bundler/setup'
require 'pry'

$LOAD_PATH << File.dirname(__FILE__)
require 'lib/model'

PRIORITIES = {
  urgent:  [1, 31],
  warning: [1, 33],
  good:    [1, 32],
}

def output(priority, message)
  $buffer << ansi(PRIORITIES.fetch(priority)) + message + ansi_normal
end

def ansi(colour)
  code = [*colour].join(';')
  "\e[#{code}m"
end

def ansi_normal
  ansi(0)
end

def check_labs
  populations = Population.where { researchlabs > 0.0 }.each do |pop|
    total_labs = pop.total_labs
    used_labs = pop.used_labs

    if used_labs != total_labs
      name = pop.system_body.name
      unused = total_labs - used_labs
      output :urgent, "#{unused} research labs available on #{name}"
    end
  end
end

def check_admins
  Population.each do |pop|
    if pop.governor.nil?
      name = pop.system_body.name
      output :urgent, "No governor on #{name}"
    end
  end
end

def watch_cycle(time)
  $buffer = []

  check_labs
  check_admins

  if $buffer.empty?
    output :good, "No issues."
  end

  timestamp = time.strftime("--- %Y-%m-%d %H:%M:%S ---")
  $buffer.unshift(timestamp)
  $buffer.push('-' * timestamp.length)
  $buffer.push('')

  puts *$buffer
end

def watch
  last_time = nil
  loop do
    time = Game.time
    if time != last_time
      last_time = time
      watch_cycle(time)
    end
    sleep(2)
  end
rescue Interrupt
  puts "Exiting."
end

puts
watch
