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
      output :urgent, "#{unused} research labs available on #{name}."
    end
  end
end

def check_admins
  Population.each do |pop|
    if pop.governor.nil?
      name = pop.system_body.name
      output :urgent, "No governor on #{name}."
    end
  end
end

def check_industry
  Population.each do |pop|
    used = pop.used_industry
    if used < 100.0
      name = pop.system_body.name
      if used == 0.0
        output :warning, "No industrial production on #{name}."
      else
        output :warning, "Only using #{used}% production on #{name}."
      end
    end
  end
end

def watch_until_after(time)
  had_issues = false
  first = true
  last_buffer = []

  loop do
    $buffer = []
    check_labs
    check_admins
    check_industry

    if $buffer.empty?
      if had_issues
        output :good, "All issues resolved."
      else
        output :good, "No issues."
      end
    else
      had_issues = true
    end

    sleep(1) unless first
    first = false

    if Game.time == time
      to_output = $buffer - last_buffer
      puts *to_output unless to_output.empty?
      last_buffer = $buffer
    else
      break
    end
  end
end

TIMESTAMP_FORMAT = "--- %Y-%m-%d %H:%M:%S ---"

def watch
  last_time = nil

  puts
  loop do
    time = Game.time
    timestamp = time.strftime(TIMESTAMP_FORMAT)
    puts(timestamp)

    begin
      watch_until_after(time)
    ensure
      puts('-' * timestamp.length, '')
    end
  end
rescue Interrupt
  puts 'Exiting.'
end

watch
