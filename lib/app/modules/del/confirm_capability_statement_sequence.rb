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


            test 'Capability Statement has valid rest (if applicable)' do

                metadata{
                    id '08'
                    desc %(
                        If the capability statement has a rest entity, this checks if that rest entity is valid
                    )
                }

                rests = @cap.rest

                if rests.nil? || rests.empty?
                    assert true
                else
                    modeCodes = ["client", "server"]
                    rests.each do |rest|
                        assert !rest.mode.nil?, "If the capability statement has a rest, it must define that rest's mode"
                        assert modeCodes.include?(rest.mode), "A rest's mode must be client or server, not " + rest.mode.inspect

                        resources = rest.resource
                        if !resources.nil? && !resources.empty?
                            genericCodeRegex = /\A[^\s]+(\s[^\s]+)*\z/
                            resources.each do |resource|
                                assert !resource.type.nil?, "If the CS has a rest, and the rest has a resource, then the resource must have a type"
                                assert genericCodeRegex.match(resource.type), "CS.rest.resource is " + resource.type.inspect + ", which is not a valid code"

                                interactions = resource.interaction
                                if !interactions.nil? && !interactions.empty?
                                    interactionCodes = ["read", "vread", "update", "patch", "delete", "history-instance", "history-type", "create", "search-type"]
                                    interactions.each do |interaction|
                                        assert !interaction.code.nil?, "If CS.rest.resource.interaction exists, interactions must have a code"
                                        assert interactionCodes.include?(interaction.code), "CS.rest.resource.ineraction.code id " + interaction.code.inspect + ", which is not a valid option"
                                    end
                                end

                                searchParams = resource.searchParam
                                if !searchParams.nil? && !searchParams.empty?
                                    searchParams.each do |searchParam|
                                        assert !searchParam.name.nil?, "If CS.rest.resource.searchParam exists, it's name cannot be nil "
                                        assert !searchParam.name.empty?, "If CS.rest.resource.searchParam exists, it must have a name"

                                        typeOptions = ["number", "date", "string", "token", "reference", "composite", "quantity", "uri", "special"]
                                        assert !searchParam.type.nil?, "If CS.rest.resource.searchParam exists, it's type cannot be nil"
                                        assert typeOptions.include?(searchParam.type), "If CS.rest.resource.searchParam exists, it's type must exist and cannot be " + searchParam.type.inspect
                                    end
                                end

                                operations = resource.operation
                                if !operations.nil? && !operations.empty?
                                    operations.each do |operation|
                                        assert !operation.name.nil? && !operation.name.empty?(), "If CS.rest.resource.operation exists, it must have a name"

                                        assert !operation.definition.nil? && !operation.definition.empty?(), "If CS.rest.resource.operation exists, it must have a definition"
                                    end 
                                end
                            end
                        end

                        interactions = rest.interaction
                        if !interactions.nil? && !interactions.empty?
                            interactionCodes = ["transaction", "batch", "search-system", "history-system"]
                            interactions.each do |interaction|
                                assert !interaction.code.nil?, "If CS.rest.interaction exists, it must have a code"
                                assert interactionCodes.include?(interaction.code), "If CS.rest.resource.operation exists, it's code cannot be " + interaction.code.inspect
                            end
                        end
                    end
                end

            end

            test 'Capability Statement has valid messaging (if applicable)' do
                
                metadata{
                    id '09'
                    desc %(
                        If the capability statement has a messaging entity, this checks if that message entity is valid
                    )
                }
                
                messagings = @cap.messaging
                if messagings.nil? || messagings.empty?
                    assert true
                else
                    messagings.each do |messaging|            
                        
                        endpoints = messaging.endpoint
                        if !endpoints.nil? && !endpoints.empty?
                            protocolCodes = ["http", "ftp", "mllp"]
                            endpoints.each do |endpoint|
                                assert !endpoint.protocol.nil? && !endpoint.protocol.empty?(), "If CS.rest.messaging.endpoint exists, it must have a protocol"
                                assert protocolCodes.include?(endpoint.protocol), "If CS.rest.messaging.endpoint exists, it cannot have " + endpoint.protocol.inspect + " as a protocol"

                                assert !endpoint.address.nil? && !endpoint.address.empty?(), "If CS.rest.messaging.endpoint exists, it must have an address"
                            end
                        end

                        supportedMessages = messaging.supportedMessages
                        if !supportedMessages.nil? && !supportedMessages.empty?
                            modeCodes = ["sender", "reciever"]
                            supportedMEssages.each do |supMess|
                                assert !supMess.mode.nil?, "If CS.rest.messaging.supportedMessage exists, it must have a mode"
                                assert modeCodes.include?(supMess.mode), "If CS.rest.messaging.suppertedMessage exists, it cannot have " + supMess.mode.inspect + " as a protocol"

                                assert !supMess.definition.nil?, "If CS.rest.messaging.supportedMessage exists, it must have a definition"
                            end
                        end 
                    end
                end
            end

            test 'Capability Statement has valid document (if applicable)' do

                metadata{
                    id '10'
                    desc %(
                        If the capability statement has a document, this checks that the document is valid
                    )
                }

                documents = @cap.document
                if documents.nil? || documents.empty?
                    assert true
                else
                    modeCodes = ["producer", "consumer"]
                    documents.each do |document|
                        assert !document.mode.nil?, "If CS.document is going to exist, it must have a code"
                        assert modeCodes.include?(document.mode), "If CS.document is going to exist, it's code cannot be " + document.mode.inspect

                        assert !document.profile.nil?, "If CS.document is going to exist, it must have a profile"
                    end
                end

            end

            test 'Validate test' do

                metadata{
                    id '11'
                    desc %(
                        Existing validation method
                    )
                }

                assert @cap.valid?, "The Capability Statement is invalid and does not fully conform to HL7 requirements"

            end

        end
    end 
end
