require_relative '../../sequence_base_extension'

module Inferno
  module Sequence
    class ConfirmAssessmentSequence < SequenceBaseExtension

      title 'Confirm Assessment Sequence'
      description "Verify that the server's QuestionnaireResponses conform to the Assessment profile"
      test_id_prefix 'cas'

      requires :url

      @aqrs = nil
      @assessmentUrl = nil

      test 'All QuestionnaireResponses in the server claim to conform to the Assessment profile' do

        metadata{
          id '01'
          desc %(
            Tests if every QuestionnaireResponse on the server specifies the Assessment profile in its metadata
          )
        }

        @assessmentUrl = "https://impact-fhir.mitre.org/r4/StructureDefinition/del-Assessment"
        total = how_many(FHIR::QuestionnaireResponse)
        @aqrs = get_resource_intersection(nil, FHIR::QuestionnaireResponse, @assessmentUrl)
        assert total == @aqrs.length, "Only " + @aqrs.length.inspect + "/" + total.inspect + " QuestionnaireResponses claim the Assessment profile"
        
      end

      test 'QuestionnaireResponses do not violate Assessment Profile restrictions' do
        
        metadata{
          id '02'
          desc %(
            Tests if the QuestionnaireResponses from the FHIR server claiming to be Assessments are valid according to the definition of an Assessment
          )
        }

        errors = check_profiles(@aqrs, FHIR::QuestionnaireResponse, @assessmentUrl)
        assert errors.empty?, errors.to_s

      end

    end
  end 
end
