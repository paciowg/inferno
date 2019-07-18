require_relative '../../sequence_base_extension'

module Inferno
  module Sequence
    class ConfirmStandardFormSequence < SequenceBaseExtension

      title 'Confirm StandardForm Sequence'
      description "Verify that the server's questionnaires conform to HL7 standards and the StandardForm profile"
      test_id_prefix 'csfs'

      requires :url

      @questionnaires = nil
      @total = nil
      @standardFormUrl = nil

      test 'Able to retrieve all Questionnaires' do
      
        metadata{
          id '01'
          desc %(
            Tests if the FHIR server will return every Questionnaire the bundles say it will
          )
        }

        @standardFormUrl = "https://impact-fhir.mitre.org/r4/StructureDefinition/del-StandardForm"
        @total = how_many(FHIR::Questionnaire)
        @questionnaires = get_all_resources(FHIR::Questionnaire)

        @questionnaires.each do |q|
          assert q.class.eql?(FHIR::Questionnaire), "All questionnaires must be instances of FHIR::Questionnaire, not " + q.class.to_s
        end
        assert @questionnaires.length == @total, "Server claimed to hold " + @total.to_s + " questionnaires, actually reads in " + @questionnaires.length.to_s

      end

      test 'Questionnaires do not violate HL7 requirements' do
        
        metadata{
          id '02'
          desc %(
            Tests if the Questionnaires from the FHIR server are valid according to HL7's definition of a Questionnaire
          )
        }

        errors = check_validity(@questionnaires)
        assert errors.empty?, errors.to_s

      end

      test 'All Questionnaires in the server claim to conform to the StandardForm profile' do

        metadata{
          id '03'
          desc %(
            Tests if every Questionnaire on the server specifies the StandardForm profile in its metadata
          )
        }

        sfqs = get_resource_intersection(@questionnaires, FHIR::Questionnaire, @standardFormUrl)
        assert @questionnaires.length == sfqs.length, "Only " + sfqs.length.to_s + "/" + @questionnaires.length.to_s + " Questionnaires claim the StandardForm profile"
        
      end

      test 'Questionnaires do not violate StandardForm Profile restrictions' do
        
        metadata{
          id '04'
          desc %(
            Tests if the Questionnaires from the FHIR server claiming to be StandardForms are valid according to the definition of a StandardForm
          )
        }

        errors = check_profiles(@questionnaires, FHIR::Questionnaire, @standardFormUrl)
        assert errors.empty?, errors.to_s

      end

    end
  end 
end
