#!/usr/bin/env ruby

require 'readline'

begin
  File.open('.industry-history') do |fh|
    # This is stupid, but they use a singleton object
    # rather than an array, so I can't just +=.
    fh.each_line do |line|
      Readline::HISTORY << line.chomp
    end
  end
rescue Errno::ENOENT
  # ignore
end

puts "Input multiple lines, in the format:"
puts "  quantityXcost comment"
puts "For example:"
puts "  5x25 improved cargo"
puts "  32.61x240 auto mine"
puts "The comment is for your own reference only."
puts
puts "Enter your lines now.  Use 'done' or ctrl-D when finished."
puts

items = []
stty_save = `stty -g`.chomp
done = false
begin
  while line = Readline.readline('> ')
    if line.strip == 'done'
      done = true
      break
    end

    unless line =~ /^\s*(\d+(?:\.\d+)?)\s*[xX](\d+(?:\.\d+)?)(?:\s+(.*)|\s*)?$/
      puts "Sorry, I don't understand #{line.inspect}"
      next
    end

    quantity = $1.to_f
    unit_cost = $2.to_f
    comment = $3

    comment = "Unnamed item #{items.count + 1}" if comment.nil?

    total_cost = quantity * unit_cost
    items << [total_cost, quantity, unit_cost, comment]
    puts "Added #{comment.inspect} with total cost of #{total_cost}."
  end
ensure
  system("stty", stty_save)
  File.open('.industry-history', 'w') do |fh|
    fh.puts *Readline::HISTORY
  end
end

grand_total = items.map(&:first).inject(0) { |sum, n| sum + n }

puts unless done # if they hit ctrl-D
puts
puts "Grand total cost: #{grand_total}"
puts
exit(0) if items.empty?
puts "Percentage allocations:"

def format(float)
  float.to_s.sub(/\.0$/, '')
end

items.each do |cost, quantity, unit_cost, comment|
  percent = 100 * cost / grand_total.to_f
  columns = [
    "%.3f" % percent,
    format(quantity),
    format(unit_cost),
    comment
  ]
  puts "%10s%% %10s x %-10s %s" % columns
end

puts
