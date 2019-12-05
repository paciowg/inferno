require_relative '../../sequence_base_extension'

module Inferno
  module Sequence
    class ConfirmAccurateSearchingSequence < SequenceBaseExtension

      title 'Confirm Accurate Searching Sequence'
      description "Verify that the server can be accurately queried for Measures"
      test_id_prefix 'cass'

      requires :url

      test 'Check for accurate responses to s' do
      
        metadata{
          id '01'
          desc %(
            
          )
        }

      end

    end
  end 
end
