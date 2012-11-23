require 'import_test_setup'

class ImportUnitTest < MiniTest::Unit::TestCase 

  include InterTest
  include ImportTest

  def test_run_with_wrong_rails_env
    Rails.stub(:env).and_return ActiveSupport::StringInquirer.new("development")

    exception = assert_raises IntercomRails::ImportError do
      IntercomRails::Import.run
    end

    assert_equal exception.message, "You can only import your users from your production environment"
  end

  def test_run_with_no_user_class
    IntercomRails::Import.any_instance.stub(:user_klass).and_return(nil)

    exception = assert_raises IntercomRails::ImportError do
      IntercomRails::Import.run
    end
    
    assert_equal exception.message, "We couldn't find your user class, please set one in config/initializers/intercom_rails.rb"
  end

  def test_run_with_non_activerecord_user_class
    IntercomRails::Import.any_instance.stub(:user_klass).and_return(Class)

    exception = assert_raises IntercomRails::ImportError do
      IntercomRails::Import.run
    end
    
    assert_equal exception.message, "Only ActiveRecord models are supported"
  end

  def test_run_with_no_api_key
    IntercomRails.config.stub(:api_key).and_return(nil)

    exception = assert_raises IntercomRails::ImportError do
      IntercomRails::Import.run
    end
    
    assert_equal exception.message, "Please add an Intercom API Key to config/initializers/intercom.rb"
  end

  def test_status_output
    @import = IntercomRails::Import.new(:status_enabled => true)
    @import.stub(:send_users).and_return('failed' => [1])
    @import.should_receive(:batches).and_yield(nil, 3)

    $stdout.flush
    @old_stdout = $stdout.dup
    $stdout = @output = StringIO.new

    @import.run
    expected_output = <<-output
* Found user class: User
* Intercom API key found
* Sending users in batches of 100:
..F
* Successfully created 2 users
* Failed to create 1 user, this is likely due to bad data
output
    $stdout.flush

    assert_equal expected_output, @output.string
  ensure
    $stdout = @old_stdout
  end

end