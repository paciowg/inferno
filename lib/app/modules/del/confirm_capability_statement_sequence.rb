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
                        Tests if the capability statement has exactly 1, valid status (active, retired, draft, or unknown)
                    )
                }

                validStatusCodes = ["active", "retired", "draft", "unknown"]
                assert !@cap.status.nil?, "Capability statement status is nil, must have exactly 1 valid status"
                assert validStatusCodes.include?(@cap.status), "Capability statement status is " + @cap.status.inspect + ", not a valid code"

            end

            test 'Capability Statement has valid date' do

                metadata{
                    id '03'
                    desc %(
                        Tests if the capability statement has exactly 1, valid date
                    )
                }

                assert !@cap.date.nil?, "Capability statement date is nil, must have exactly 1 valid date"
                assert conforms_to_dateTime_format(@cap.date), "Capability statement date is " + @cap.date.inspect + ", not a valid dateTime (see https://www.hl7.org/fhir/datatypes.html)"

            end

            test 'Capability Statement has valid kind' do

                metadata{
                    id '04'
                    desc %(
                        Tests if the capability statement has exactly 1, valid kind (instance, capability, requirements)
                    )
                }

                validKindCodes = ["instance", "capability", "requirements"]
                assert !@cap.kind.nil?, "Capability statement kind is nil, must have exactly 1 valid kind"
                assert validKindCodes.include?(@cap.kind), "Capability statement kind is " + @cap.kind.inspect + ", not a valid code"

            end

            test 'Capability Statement has valid software (if applicable)' do

                metadata{
                    id '05'
                    desc %(
                        If the capability statement has a software section, this checks that it is valid
                    )
                }

                assert @cap.software.nil? || !@cap.software.name.empty?(), "If the capability statement has a software entity, the software entity must have a name"

            end

            test 'Capability Statement has valid implementation (if applicable)' do

                metadata{
                    id '06'
                    desc %(
                        If the capability statement has an implementation section, this checks that it is valid
                    )
                }

                assert @cap.implementation.nil? || !@cap.implementation.description.empty?(), "If the capability statement has an implementation entity, it must have a description"

            end

            test 'Capability Statement has valid FHIR Version' do

                metadata{
                    id '07'
                    desc %(
                        Tests if the capability statement has exactly 1, valid FHIR Version
                    )
                }

                delVersion = "4.0.0"
                assert !@cap.fhirVersion.nil?, "Capability statement FHIR version is nil, must have exactly 1 valid fhir version"
                assert @cap.fhirVersion.eql?(delVersion), "Capability statement version is " + @cap.fhirVersion + ", must be " + delVersion

            end

        end
    end 
end
