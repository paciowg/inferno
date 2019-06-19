module Inferno
    module Sequence
        class ConfirmCapabilityStatementSequence < SequenceBase

            title 'Confirm Capability Statement Sequence'
            description "Verify that the server's capability statement conforms to HL7 standards"
            test_id_prefix 'ccss'

            requires :url

            @cap = nil

            test 'Retrieve Capability Statement' do
            
                metadata{
                    id '01'
                    desc %(
                        Tests if the FHIR server will return a viable capability statement
                    )
                }

                @cap = @client.capability_statement

                assert !@cap.nil?, "No capability statement retrieved upon request to server"
                assert @cap.is_a?(FHIR::CapabilityStatement), "Server indicated an error in reading the capability statement"

            end

            test 'Capability Statement has status' do

                metadata{
                    id '02'
                    desc %(
                        Tests if the Capability statement has exactly 1, valid status (active, retired, draft, or unknown)
                    )
                }

                validStatusCodes = ["active", "retired", "draft", "unknown"]
                assert !@cap.status.nil?, "Capability statement status is nil, must have exactly 1 valid status"
                assert validStatusCodes.include?(@cap.status), "Capabiltiy status is " + @cap.status.inspect + ", not a valid code"

            end


        end
    end 
end
