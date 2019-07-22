require_relative '../../sequence_base_extension'

module Inferno
  module Sequence
    class ConfirmCapabilityStatementSequence < SequenceBaseExtension

      title 'Confirm Capability Statement Sequence'
      description "Verify that the server's capability statement conforms to HL7 standards"
      test_id_prefix 'ccss'

      requires :url

      test 'The Capability Statement does not violate HL7 requirements' do
        
        metadata{
          id '01'
          desc %(
            Tests if the Capability Statement from the FHIR server is valid according to HL7's definition of a Capability Statement
          )
        }

        cap = @client.conformance_statement
        errors = check_validity(cap)
        assert errors.empty?, errors.to_s

      end
    end
  end 
end
