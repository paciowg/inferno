require_relative '../../sequence_base_extension'

module Inferno
  module Sequence
    class ConfirmQuestionnaireResponseSequence < SequenceBaseExtension

      title 'Confirm QuestionnaireRespoonse Sequence'
      description "Verify that the server's QuestionnaireResponses conform to HL7 standards"
      test_id_prefix 'cqrs'

      requires :url

      @qrs = nil

      test 'Able to retrieve all QuestionnaireResponses' do
      
        metadata{
          id '01'
          desc %(
            Tests if the FHIR server will return every QuestionnaireResponse the server says it stores
          )
        }

        total = how_many(FHIR::QuestionnaireResponse)
        @qrs = get_all_resources(FHIR::QuestionnaireResponse)

        @qrs.each do |qr|
          assert qr.class.eql?(FHIR::QuestionnaireResponse), "All QuestionnaireResponses must be instances of FHIR::QuestionnaireResponse, not " + qr.class.to_s
        end
        assert @qrs.length == total, "Server claimed to hold " + total.to_s + " QuestionnaireResponses, actually reads in " + @qrs.length.to_s

      end

      test 'The QuestionnaireResponses do not violate HL7 requirements' do
        
        metadata{
          id '02'
          desc %(
            Tests if the QuestionnaireResponses from the FHIR server are valid according to HL7's definition of a QuestionnaireResponse
          )
        }

        errors = check_validity(@qrs)
        assert errors.empty?, errors.to_s

      end
    end
  end 
end
