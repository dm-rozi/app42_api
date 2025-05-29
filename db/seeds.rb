# Creating a large number of posts and ratings for performance testing
# This script creates:
#   100 uniq users
#   200,000+ posts with 70 uniq IP addresses
#   150,000+ ratings
# in parallel threads using application's API.
# It uses Faker to generate random data and Faraday for HTTP requests.
# The script also tracks the number of successful and failed requests and real time RPS.

require "active_record"
require "faraday"
require "faker"
require "faraday"
require "oj"
require "set"
require "concurrent-ruby"

ActiveRecord::Base.connection.execute("TRUNCATE users, posts, ratings RESTART IDENTITY CASCADE")
Faker::UniqueGenerator.clear

BATCH_SIZE_POSTS = 8000 # Number of posts to create in each thread. 25 * 8000 = 200,000 posts
POSTS_THREAD_COUNT = 25
RATINGS_THREAD_COUNT = 30

USERS = Array.new(100) { Faker::Internet.unique.username(specifier: 4..8) }
IPS = Array.new(70)  { Faker::Internet.unique.public_ip_v4_address }

SERVER_URL = "http://localhost:3000"

post_ids = Concurrent::Array.new
post_counter = Concurrent::AtomicFixnum.new
post_error_counter = Concurrent::AtomicFixnum.new
rating_counter = Concurrent::AtomicFixnum.new
rating_error_counter = Concurrent::AtomicFixnum.new

conn = Faraday.new(url: SERVER_URL)

puts "Initializing users..."
begin
  USERS.each do |login|
    conn.post("/api/v1/posts", {
                title: "Warmup",
                body: "Init post for warmup",
                login: login,
                ip: IPS.sample
              })
    post_counter.increment
  end
rescue Faraday::ConnectionFailed, Errno::ECONNREFUSED
  puts "❌ Puma is not running on http://localhost:3000 — connection refused, please start the server first."
  exit(1)
end

puts "Users initialized: #{User.count}"

start_time = Time.now

puts "\n=========================="

puts "Starting posts creation..."

print_progress = -> {
  elapsed = Time.now - start_time
  total = post_counter.value + post_error_counter.value
  rps = (total / elapsed).round(2)

  print "\rPosts: #{post_counter.value} | Post errors: #{post_error_counter.value} | Ratings: #{rating_counter.value} | Rating errors: #{rating_error_counter.value} | RPS: #{rps}"
}

state = {
  post_ids: post_ids,
  post_counter: post_counter,
  post_error_counter: post_error_counter,
  print_progress: print_progress
}

posts_creation_start_time = Time.now

def generate_posts(thread_conn, users, ips, count, state)
  count.times do
    login = users.sample
    resp = thread_conn.post("/api/v1/posts", {
                              "title" => Faker::Lorem.sentence(word_count: 3),
                              "body" => Faker::Lorem.paragraph(sentence_count: 2),
                              "login" => login,
                              "ip" => ips.sample
                            })

    if resp.success?
      post_id = Oj.load(resp.body).dig("data", "post", "id")

      if post_id
        state[:post_ids] << post_id
        state[:post_counter].increment
        state[:print_progress].call
      end
    else
      state[:post_error_counter].increment
    end
  end
end

threads = POSTS_THREAD_COUNT.times.map do
  Thread.new do
    thread_conn = Faraday.new(url: SERVER_URL)

    generate_posts(thread_conn, USERS, IPS, BATCH_SIZE_POSTS, state)
  end
end

threads.each(&:join)

puts "\nPosts created in #{(Time.now - posts_creation_start_time).round(2)} seconds"

puts "\nDone:"
puts "Users: #{User.count}"
puts "Posts: #{post_counter.value}"

puts "\n=========================="
puts "Starting ratings creation..."

post_ids_to_rate = post_ids.sample((post_ids.size * 0.76).to_i)
user_ids = User.ids
rated_pairs = Concurrent::Set.new

CHUNK_SIZE = (post_ids_to_rate.size.to_f / RATINGS_THREAD_COUNT).ceil

rating_creation_start_time = Time.now

threads = post_ids_to_rate.each_slice(CHUNK_SIZE).map do |post_chunk|
  Thread.new do
    conn = Faraday.new(url: SERVER_URL)

    post_chunk.each do |post_id|
      user_id = user_ids.sample
      key = "#{post_id}-#{user_id}"

      next if rated_pairs.include?(key)

      rated_pairs << key

      resp = conn.post("/api/v1/posts/#{post_id}/ratings", { user_id: user_id, value: rand(1..5) })

      if resp.success?
        rating_counter.increment
      else
        rating_error_counter.increment
      end

      print_progress.call
    end
  end
end

threads.each(&:join)

puts "\nRatings created in #{(Time.now - rating_creation_start_time).round(2)} seconds"
puts "\nDone!"
