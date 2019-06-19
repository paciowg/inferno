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

            test 'Capability Statement has valid status' do

                metadata{
                    id '02'
                    desc %(
                        Tests if the Capability statement has exactly 1, valid status (active, retired, draft, or unknown)
                    )
                }

                validStatusCodes = ["active", "retired", "draft", "unknown"]
                assert !@cap.status.nil?, "Capability statement status is nil, must have exactly 1 valid status"
                assert validStatusCodes.include?(@cap.status), "Capability status is " + @cap.status.inspect + ", not a valid code"

            end

            test 'Capability Statement has valid date' do

                metadata{
                    id '03'
                    desc %(
                        Tests if the Capability statement has exactly 1, valid date
                    )
                }

                #Below Regex is heavily taken from hl7 with some improvements
                dateTimeRegex = /\A(?:(?!0000)\d{4})(-(0[1-9]|1[0-2])(-(0[1-9]|[1-2]\d|3[0-1])(T([01]\d|2[0-3]):[0-5]\d:([0-5]\d|60)(\.\d+)?(Z|(\+|-)((0\d|1[0-3]):[0-5]\d|14:00)))?)?)?\z/
                assert !@cap.date.nil?, "Capability statement date is nil, must have exactly 1 valid date"
                assert dateTimeRegex.match(@cap.date), "Capability status is " + @cap.date + ", not a valid dateTime (see https://www.hl7.org/fhir/datatypes.html)"

            end


        end
    end 
end
