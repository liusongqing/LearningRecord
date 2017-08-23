require File.expand_path(File.dirname(__FILE__) + "/../lib/ticgit")
require 'fileutils'
require 'logger'
require 'tempfile'

TICGIT_HISTORY = StringIO.new

module TicGitSpecHelper

  def setup_new_git_repo
    tempdir = Dir.mktmpdir 'ticgit-gitdir-'
    Dir.chdir(tempdir) do
      git = Git.init
      new_file('test', 'content')
      Dir.mkdir('subdir')
      new_file('subdir/testfile', 'content2')
      git.add
      git.commit('first commit')
    end
    tempdir
  end

  def setup_existing_ticgit_repo
  end

  def test_opts
    tempdir = Dir.mktmpdir 'ticgit-ticdir-'
    logger = Logger.new(Tempfile.new('ticgit-log-'))
    { :tic_dir => tempdir, :logger => logger }
  end


  def new_file(name, contents)
    File.open(name, 'w') do |f|
      f.puts contents
    end
  end

  def format_expected(string)
    string.strip.enum_for(:each_line).map{|line| line.strip }
  end

  def cli(*args, &block)
    TICGIT_HISTORY.truncate 0
    TICGIT_HISTORY.rewind

    ticgit = TicGit::CLI.new(args.flatten, @path, TICGIT_HISTORY)
    ticgit.parse_options!
    ticgit.execute!

    replay_history(&block)
  rescue SystemExit => error
    replay_history(&block)
  end

  def replay_history
    TICGIT_HISTORY.rewind
    return unless block_given?

    while line = TICGIT_HISTORY.gets
      yield(line.strip)
    end
  end

end



##
# rSpec Hash additions.
#
# From
#   * http://wincent.com/knowledge-base/Fixtures_considered_harmful%3F
#   * Neil Rahilly

class Hash

  ##
  # Filter keys out of a Hash.
  #
  #   { :a => 1, :b => 2, :c => 3 }.except(:a)
  #   => { :b => 2, :c => 3 }

  def except(*keys)
    self.reject { |k,v| keys.include?(k || k.to_sym) }
  end

  ##
  # Override some keys.
  #
  #   { :a => 1, :b => 2, :c => 3 }.with(:a => 4)
  #   => { :a => 4, :b => 2, :c => 3 }

  def with(overrides = {})
    self.merge overrides
  end

  ##
  # Returns a Hash with only the pairs identified by +keys+.
  #
  #   { :a => 1, :b => 2, :c => 3 }.only(:a)
  #   => { :a => 1 }

  def only(*keys)
    self.reject { |k,v| !keys.include?(k || k.to_sym) }
  end

end
