module Inferno
    module Sequence
        class ConfirmAssessmentSequence < SequenceBase

            title 'Confirm Capability Statement Sequence'
            description "Verify that the server's capability statement conforms to HL7 standards"
            test_id_prefix 'cas'

            requires :url

            @questionnaires = nil
            @assessments = nil

            test 'Able to retrieve all Questionnaires' do
            
                metadata{
                    id '01'
                    desc %(
                        Tests if the FHIR server will return every Questionnaire the bundles say it will
                    )
                }

                replies = [].push(@client.read_feed(FHIR::Questionnaire))
                @questionnaires = []

                assert !replies.last.nil?, "Could not read questionnaires from server"

                total = replies.last.resource.total
                while !replies.last.nil?
                    @questionnaires.push(replies.last.resource.entry.collect{ |singleEntry| singleEntry.resource })
                    replies.push(@client.next_page(replies.last))
                end
                @questionnaires.compact!
                @questionnaires = @questionnaires.flatten(1)

                @questionnaires.each do |q|
                    assert q.class.eql?(FHIR::Questionnaire), "All questionnaires must actually be instances of FHIR::Questionnaire, not " + q.class.to_s
                end
                assert @questionnaires.length == total, "Server claimed to hold " + total.to_s + " questionnaires, actually reads in " + @questionnaires.length.to_s                

            end

            test 'Questionnaires do not violate HL7 requirements' do
                
                metadata{
                    id '02'
                    desc %(
                        Tests if the Questionnaires from the FHIR server are valid according to HL7's definition of a Questionnaire
                    )
                }

                @questionnaires.each do |q|
                    errors = q.validate
                    assert errors.empty?, errors.to_s
                end

            end

        end
    end 
end
