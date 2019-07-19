require_relative '../../sequence_base_extension'

module Inferno
  module Sequence
    class ConfirmAssessmentSequence < SequenceBaseExtension

      title 'Confirm Assessment Sequence'
      description "Verify that the server's QuestionnaireResponses conform to HL7 standards and the Assessment profile"
      test_id_prefix 'cas'

      requires :url

      @responses = nil
      @total = nil
      @assessmentUrl = nil

      test 'Able to retrieve all QuestionnaireResponses' do
      
        metadata{
          id '01'
          desc %(
            Tests if the FHIR server will return every QuestionnaireResponse the server says it stores
          )
        }

        @assessmentUrl = "https://impact-fhir.mitre.org/r4/StructureDefinition/del-Assessment"
        @total = how_many(FHIR::QuestionnaireResponse)
        @responses = get_all_resources(FHIR::QuestionnaireResponse)

        @responses.each do |r|
          assert r.class.eql?(FHIR::QuestionnaireResponse), "All questionnaires must be instances of FHIR::Questionnaire, not " + r.class.to_s
        end
        assert @responses.length == @total, "Server claimed to hold " + @total.to_s + " questionnaires, actually reads in " + @responses.length.to_s

      end

      test 'QuestionnaireResponses do not violate HL7 requirements' do
        
        metadata{
          id '02'
          desc %(
            Tests if the QuestionnaireResponses from the FHIR server are valid according to HL7's definition of a QuestionnaireResponse
          )
        }

        errors = check_validity(@responses)
        assert errors.empty?, errors.to_s

      end

      test 'All QuestionnaireResponses in the server claim to conform to the Assessment profile' do

        metadata{
          id '03'
          desc %(
            Tests if every QuestionnaireResponse on the server specifies the Assessment profile in its metadata
          )
        }

        aqrs = get_resource_intersection(@responses, FHIR::QuestionnaireResponse, @assessmentUrl)
        assert @responses.length == aqrs.length, "Only " + aqrs.length.to_s + "/" + @responses.length.to_s + " QuestionnaireResponses claim the Assessment profile"
        
      end

      test 'QuestionnaireResponses do not violate Assessment Profile restrictions' do
        
        metadata{
          id '04'
          desc %(
            Tests if the QuestionnaireResponses from the FHIR server claiming to be Assessments are valid according to the definition of an Assessment
          )
        }

        errors = check_profiles(@responses, FHIR::QuestionnaireResponse, @assessmentUrl)
        assert errors.empty?, errors.to_s

      end

    end
  end 
end
