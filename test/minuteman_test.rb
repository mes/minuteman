require 'helper'
require 'date'
require 'byebug'

@patterns = Minuteman.patterns

prepare do
  Minuteman.configure do |config|
    config.redis = Redic.new("redis://127.0.0.1:6379/1")
  end
end

setup do
  Minuteman.config.redis.call("FLUSHDB")

  Minuteman.configure do |config|
    config.patterns = @patterns
  end
end

test "a connection" do
  assert_equal Minuteman.config.redis.class, Redic
end

test "an anonymous user" do
  user = Minuteman::User.create('test')

  assert user.is_a?(Minuteman::User)
  assert user.id
end

test "track an user" do
  user = Minuteman::User.create('test')

  assert Minuteman.track("login:successful", user, scope: 'test')

  analyzer = Minuteman.analyze("login:successful")
  assert analyzer.day(Time.now.utc).count == 1
end

test "analyze should not create keys" do
  user = Minuteman::User.create('test')

  assert Minuteman.track("login:successful", user, scope: 'test')
  dbsize = Minuteman.config.redis.call("dbsize")
  Minuteman.analyze("login:successful").minute(Date.new(2001, 2, 3))
  assert Minuteman.config.redis.call("dbsize") == dbsize
end

test "create your own storage patterns and access analyzer" do
  Minuteman.configure do |config|
    config.patterns = {
      dia: -> (time) { time.strftime("%Y-%m-%d") }
    }
  end

  Minuteman.track("logeo:exitoso", scope: 'test')
  assert Minuteman("logeo:exitoso").dia.count == 1
end

test "use the method shortcut" do
  5.times { Minuteman.track("enter:website", scope: 'test') }

  assert Minuteman("enter:website").day.count == 5
end

scope "operations" do
  setup do
    Minuteman.config.redis.call("FLUSHDB")

    @users = Array.new(3) { Minuteman::User.create('test') }
    @users.each do |user|
      Minuteman.track("landing_page:new", @users, scope: 'test')
    end

    Minuteman.track("buy:product", @users[0], scope: 'test')
    Minuteman.track("buy:product", @users[2], scope: 'test')
  end

  test "AND" do
    and_op = Minuteman("landing_page:new").day & Minuteman("buy:product").day
    assert and_op.count == 2
  end

  test "OR" do
    or_op = Minuteman("landing_page:new").day | Minuteman("buy:product").day
    assert or_op.count == 3
  end

  test "XOR" do
    xor_op = Minuteman("landing_page:new").day ^ Minuteman("buy:product").day
    assert xor_op.count == 1
  end

  test "NOT" do
    assert Minuteman("buy:product").day.include?(@users[2])

    not_op = -Minuteman("buy:product").day
    assert !not_op.include?(@users[2])
  end

  test "MINUS" do
    assert Minuteman("landing_page:new").day.include?(@users[2])
    assert Minuteman("buy:product").day.include?(@users[2])

    minus_op = Minuteman("landing_page:new").day - Minuteman("buy:product").day

    assert !minus_op.include?(@users[2])
    assert minus_op.include?(@users[1])
  end
end

scope "complex operations" do
  setup do
    Minuteman.config.redis.call("FLUSHDB")
    @users = Array.new(6) { Minuteman::User.create('test') }

    [ @users[0], @users[1], @users[2] ].each do |u|
      Minuteman.track("promo:email", u, scope: 'test')
    end

    [ @users[3], @users[4], @users[5] ].each do |u|
      Minuteman.track("promo:facebook", u, scope: 'test')
    end

    [ @users[1], @users[4], @users[6] ].each do |u|
      Minuteman.track("user:new", u, scope: 'test')
    end
  end

  test "verbose" do
    got_promos = Minuteman("promo:email").day + Minuteman("promo:facebook").day

    @users[0..5].each do |u|
      assert got_promos.include?(u)
    end

    new_users = Minuteman("user:new").day
    query = got_promos & new_users

    [ @users[1], @users[4] ].each do |u|
      assert query.include?(u)
    end
    assert query.count == 2
  end

  test "readable" do
    query = (
      Minuteman("promo:email").day + Minuteman("promo:facebook").day
    ) & Minuteman("user:new").day

    assert query.count == 2
  end
end

test "count a given event" do
  10.times { Minuteman.add("enter:new_landing") }

  assert Counterman("enter:new_landing").day.count == 10
end

test "it count the given amount" do
  Minuteman.add("enter:new_landing", Time.now.utc, nil, Minuteman.config.patterns.keys, 20)
  assert Counterman("enter:new_landing").day.count == 20
end

test "count events on some dates" do
  day = Time.new(2015, 10, 15)
  next_day = Time.new(2015, 10, 16)

  5.times { Minuteman.add("drink:beer", day) }
  2.times { Minuteman.add("drink:beer", next_day) }

  assert Counterman("drink:beer").month(day).count == 7
  assert Counterman("drink:beer").day(day).count == 5
end

scope "do actions through a user" do
  test "track an event" do
    user = Minuteman::User.create('test')
    user.track("login:page", scope: 'test')

    3.times { user.add("login:attempts") }
    2.times { Minuteman.add("login:attempts") }

    assert Minuteman("login:page").day.include?(user)
    assert Counterman("login:attempts").day.count == 5
    assert user.count("login:attempts").day.count == 3
  end
end

scope "do actions through a user within a scope" do
  test "track an event" do
    user = Minuteman::User.create('test')
    user.track("login:page", scope: 'test')

    3.times { user.add("login:attempts") }
    2.times { Minuteman.add("login:attempts") }

    assert Minuteman("login:page").day.include?(user)
    assert Counterman("login:attempts").day.count == 5
    assert user.count("login:attempts").day.count == 3
  end
end
