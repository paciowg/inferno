module Inferno
    module Sequence
        class RetrieveResourcesSequence < SequenceBase

            title 'DEL Server Resource Retrieval Sequence'
            description "Verify the client's ability to read resources from the server"
            test_id_prefix 'rrs'

            requires :url

            test 'Retrieve Conformance Statement' do
            
                metadata{
                    id '01'
                    desc %(
                        Tests if the FHIR server will return a conformance statement
                    )
                }

                confState = @client.conformance_statement

                assert !confState.nil?, "No conformance statement retrieved upon request to server"
                assert confState.is_a?(FHIR::CapabilityStatement), "Server indicated an error in reading the conformance statement"

            end

        end
    end 
end
