class RedisAT5 < Formula
  desc "Persistent key-value database, with built-in net interface"
  homepage "https://redis.io/"
  url "https://download.redis.io/releases/redis-5.0.14.tar.gz"
  sha256 "3ea5024766d983249e80d4aa9457c897a9f079957d0fb1f35682df233f997f32"
  license "BSD-3-Clause"
  revision 1

  keg_only :versioned_formula

  disable! date: "2022-11-30", because: :versioned_formula

  def install
    system "make", "install", "PREFIX=#{prefix}", "CC=#{ENV.cc}"

    %w[run db/redis log].each { |p| (var/p).mkpath }

    # Fix up default conf file to match our paths
    inreplace "redis.conf" do |s|
      s.gsub! "/var/run/redis.pid", var/"run/redis.pid"
      s.gsub! "dir ./", "dir #{var}/db/redis/"
      s.sub!(/^bind .*$/, "bind 127.0.0.1 ::1")
    end

    etc.install "redis.conf"
    etc.install "sentinel.conf" => "redis-sentinel.conf"
  end

  service do
    run [opt_bin/"redis-server", etc/"redis.conf", "--daemonize no"]
    keep_alive true
    working_dir var
    log_path var/"log/redis.log"
    error_log_path var/"log/redis.log"
  end

  test do
    system bin/"redis-server", "--test-memory", "2"
    %w[run db/redis log].each { |p| assert_predicate var/p, :exist?, "#{var/p} doesn't exist!" }
  end
end
