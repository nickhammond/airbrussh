require "minitest_helper"
require "airbrussh/capistrano/tasks"
require "airbrussh/configuration"
require "stringio"
require "tempfile"

class Airbrussh::Capistrano::TasksTest < Minitest::Test
  class DSL
    def set(*)
    end

    def namespace(*)
    end

    def task(*)
    end
  end

  def setup
    @dsl = DSL.new
    @config = Airbrussh::Configuration.new
    @stderr = StringIO.new
    @tasks = Airbrussh::Capistrano::Tasks.new(@dsl, @stderr, @config)
  end

  def test_no_warning_is_printed_when_proper_dsl_is_present
    assert_empty(stderr)
  end

  def test_prints_warning_if_dsl_is_missing
    bad_dsl = Object.new
    Airbrussh::Capistrano::Tasks.new(bad_dsl, @stderr, @config)
    assert_match(/WARNING.*must be loaded by Capistrano/, stderr)
  end

  def test_configures_for_capistrano
    assert_equal("log/capistrano.log", @config.log_file)
    assert(@config.monkey_patch_rake)
    assert_equal(:auto, @config.color)
    assert_equal(:auto, @config.truncate)
    assert_equal(:auto, @config.banner)
    refute(@config.command_output)
  end

  def test_sets_airbrussh_formatter_on_load_defaults
    @dsl.expects(:set).with(:format, :airbrussh)
    @tasks.load_defaults
  end

  def test_prints_last_20_logfile_lines_on_deploy_failure
    log_file = Tempfile.new("airbrussh-test-")
    begin
      log_file.write((11..31).map { |i| "line #{i}\n" }.join)
      log_file.close

      @config.log_file = log_file.path
      @tasks.deploy_failed

      assert_match("DEPLOY FAILED", stderr)
      refute_match("line 11", stderr)
      (12..31).each { |i| assert_match("line #{i}", stderr) }
    ensure
      log_file.unlink
    end
  end

  def test_does_not_print_anything_on_deploy_failure_if_nil_logfile
    @config.log_file = nil
    @tasks.deploy_failed
    assert_empty(stderr)
  end

  private

  def stderr
    @stderr.string
  end
end