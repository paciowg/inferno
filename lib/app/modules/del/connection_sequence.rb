module Inferno
    module Sequence
        class ConnectionSequence < SequenceBase

            title 'DEL Server Connection Sequence'
            description "Verify connection to the DEL FHIR Server is possible"
            test_id_prefix 'InitialDEL'

            requires :url
            defines :client

            test 'Valid URL' do
            
                metadata{
                    id '01'
                    desc %(
                        Tests that the provided URL is actually a url that could point to a FHIR server
                    )
                }
                
                urlRegex = /\Ahttps?:\/\/(www\.)?[-a-zA-Z0-9]{2,256}(\.[a-zA-Z]{2,256})+(\/[^\/]+)*\/?\z/
                assert urlRegex.match?(@instance.url), "URL is not viable, check that you input it correctly"

            end


            test 'Client Initialized' do

                metadata{
                    id '02'
                    desc %(
                        Tests if inferno was able to initialize a client
                    )
                }

                assert !@client.nil?, "Client is nil, check that your URL actually leads to a FHIR server"

                warning{
                    "This test set does not currently account for FHIR servers with restrictions on access (like OAuth)."
                }

            end

        end
    end 
end
