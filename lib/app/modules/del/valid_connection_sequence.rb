module Inferno
    module Sequence
        class ValidConnectionSequence < SequenceBase

            title 'DEL Server Valid Connection Sequence'
            description "Verify connection to the DEL FHIR Server exists"
            test_id_prefix 'vcs'

            requires :url

            test 'Valid URL' do
            
                metadata{
                    id '01'
                    desc %(
                        Tests that the provided URL is actually a url that could potentially point to a FHIR server
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


            test 'Connection in form of FHIR Client' do

                metadata{
                    id '03'
                    desc %(
                        Tests if the inferno client is capable of performing all desired actions
                    )
                }

                assert @client.respond_to?(:read), "Client cannot read from FHIR server"
                assert @client.respond_to?(:search), "Client cannot search FHIR server"
                assert @client.respond_to?(:detect_version), "Client cannot detect FHIR server version"
                assert @client.respond_to?(:create), "Client cannot search database"

            end

        end
    end 
end
