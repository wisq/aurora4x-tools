#!/usr/bin/env ruby

require 'bundler/setup'
require 'pry'
require 'set'

$LOAD_PATH << File.dirname(__FILE__)
require 'lib/model'

PRIORITIES = {
  urgent:  [1, 31],
  warning: [1, 33],
  good:    [1, 32],
}

def output(priority, message)
  message = message.force_encoding('cp1252').encode('utf-8')
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
      unused = total_labs - used_labs
      output :urgent, "#{unused} research labs available on #{pop.name}."
    end
  end
end

def check_admins
  Population.each do |pop|
    if pop.governor.nil?
      output :urgent, "No governor on #{pop.name}."
    end
  end

  SectorCommand.each do |sector|
    if sector.governor.nil?
      output :urgent, "No governor for #{sector.name}."
    end
  end
end

def check_industry
  Population.each do |pop|
    next unless pop.has_industry?

    used = pop.used_industry
    if used < 100.0
      if used == 0.0
        output :warning, "No industrial production on #{pop.name}."
      else
        output :warning, "Only using #{used}% production on #{pop.name}."
      end
    end
  end
end

def check_mines
  populations = Population.all
  mass_driver_target_ids = populations.map { |p| p[:MassDriverDest].to_i }

  populations.each do |pop|
    # Don't check colonies that are probably producing mines
    # and producing + receiving mass drivers.
    next if pop.has_industry?
    # Developed colonies might need mass drivers to receive resources,
    # e.g. for ground unit training.
    next if pop.population > 1_000_000.0

    if pop.has_mines?
      if !pop.has_minerals?
        output :warning, "Mining colony #{pop.name} has no minerals left."
      elsif pop.has_mass_drivers? && !pop.has_mass_driver_target?
        output :warning, "Mining colony #{pop.name} has no mass driver target." \
          unless mass_driver_target_ids.include?(pop.id)
      end
    elsif pop.has_mass_drivers?
      output :warning, "Colony #{pop.name} has mass drivers but no mines."
    end
  end
end

def check_cmdr_health
  [Governor, Researcher].each do |cls|
    cls.each do |cmdr|
      if (risk = cmdr.health_risk) > 5.0
        output :warning, "#{cmdr.full_title} has a #{"%.1f" % risk}% annual health risk."
      end
    end
  end
end

def run_check(issues, function, text)
  old_count = $buffer.count
  send(function)

  if $buffer.count != old_count
    issues << function
  elsif issues.delete?(function)
    output :good, text
  end
end

def watch_until_after(time)
  last_buffer = []
  issues = Set.new
  first_pass = true

  loop do
    $buffer = []

    run_check(issues, :check_labs, 'All research labs busy.')
    run_check(issues, :check_admins, 'All administrators assigned.')
    run_check(issues, :check_industry, 'All industry in use.')
    run_check(issues, :check_mines, 'All mining colonies operational.')
    run_check(issues, :check_cmdr_health, 'All administrators & resarchers are healthy.')

    sleep_duration = 2.0
    if issues.empty?
      output :good, 'No issues.' if issues.empty?
      sleep_duration = 5.0
    else
      output :warning, "(#{issues.count} issues)"
    end

    # So here's a problem we have:
    #
    # When you click a time advance button, the game starts
    # simulating immediately, without updating the game time.
    #
    # This means that new issues can pop up before we know
    # the current turn is over.  The issues from this turn
    # will show up in the previous turn, making the user
    # think they left something unfixed.
    #
    # To mitigate this (without making things annoyingly
    # unresponsive), on the first pass, we output immediately;
    # but on subsequent passes, we do our sleep (and turn check)
    # *before* we output anything, and skip output if time advances.
    #
    # We still want a basic time check, however, so we do a
    # zero-second sleep here no matter what.
    wait_game_advance(time, if first_pass then 0.0 else sleep_duration end)

    to_output = $buffer - last_buffer
    puts *to_output unless to_output.empty?
    last_buffer = $buffer

    # We don't need to do a zero-second sleep here,
    # so we only sleep on the first run.
    break if first_pass && wait_game_advance(time, sleep_duration)
  end
end

def wait_game_advance(game_time, seconds)
  target = Time.now + seconds
  loop do
    return true if Game.time != game_time
    return false if Time.now > target
    sleep(0.2)
  end
end

def deathwatch(time_range)
  $buffer = []
  GameLog.where(EventType: 99, Time: time_range).order(:Time).each do |log|
    next if log.time == time_range.min
    next if log.text.end_with?(': Unassigned')
    next if log.text.include?(': C.O. ')

    prio = if log.text.include?('Assignment prior to ') then :urgent else :warning end

    log.text.gsub(/  +/, ' ').split(/(?<=\.) (?=(?:Current )?Assignment)/).each do |line|
      output prio, line
    end
    $buffer << ''
  end
  puts *$buffer unless $buffer.empty?
end

TIMESTAMP_FORMAT = "--- %Y-%m-%d %H:%M:%S ---"

def watch
  last_time = Game.last_time

  puts
  loop do
    time = Game.time
    deathwatch(last_time..time) if last_time

    timestamp = Game.real_time(time).strftime(TIMESTAMP_FORMAT)
    puts(timestamp)

    begin
      watch_until_after(time)
    ensure
      puts('-' * timestamp.length, '')
    end
    last_time = time
  end
rescue Interrupt
  puts 'Exiting.'
end

watch
