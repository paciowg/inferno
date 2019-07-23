require_relative '../../sequence_base_extension'

module Inferno
  module Sequence
    class ConfirmQuestionnaireSequence < SequenceBaseExtension

      title 'Confirm Questionnaire Sequence'
      description "Verify that the server's Questionnaires conform to HL7 standards"
      test_id_prefix 'cqs'

      requires :url

      @questionnaires = nil

      test 'Able to retrieve all Questionnaires' do
      
        metadata{
          id '01'
          desc %(
            Tests if the FHIR server will return every Questionnaire the server says it stores
          )
        }

        total = how_many(FHIR::Questionnaire)
        @questionnaires = get_all_resources(FHIR::Questionnaire)

        @questionnaires.each do |q|
          assert q.class.eql?(FHIR::Questionnaire), "All questionnaires must be instances of FHIR::Questionnaire, not " + q.class.to_s
        end
        assert @questionnaires.length == total, "Server claimed to hold " + total.to_s + " questionnaires, actually reads in " + @questionnaires.length.to_s

      end

      test 'The Questionnaires do not violate HL7 requirements' do
        
        metadata{
          id '02'
          desc %(
            Tests if the Questionnaires from the FHIR server are valid according to HL7's definition of a Questionnaire
          )
        }

        errors = check_validity(@questionnaires)
        assert errors.empty?, errors.to_s

      end
    end
  end 
end
