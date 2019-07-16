# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/app/models/sequence_result'
require_relative '../shared/result_status_tests'

class SequenceResultTest < MiniTest::Test
  include Inferno::ResultStatusTests

  def setup
    @result = Inferno::Models::SequenceResult.new
  end
end
