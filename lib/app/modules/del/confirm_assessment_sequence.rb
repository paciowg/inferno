require_relative '../../sequence_base_extension'

module Inferno
  module Sequence
    class ConfirmAssessmentSequence < SequenceBaseExtension

      title 'Confirm Assessment Sequence'
      description "Verify that the server's assessment conforms to HL7 standards"
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

        total = how_many(FHIR::Questionnaire)
        @questionnaires = get_all_resources(FHIR::Questionnaire)

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

      test 'Questionnaires do not violate StandardForm Profile restrictions' do
        
        metadata{
          id '03'
          desc %(
            Tests if the Questionnaires from the FHIR server are valid according to the definition of a StandardForm
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
