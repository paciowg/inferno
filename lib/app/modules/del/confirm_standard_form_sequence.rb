require_relative '../../sequence_base_extension'

module Inferno
  module Sequence
    class ConfirmStandardFormSequence < SequenceBaseExtension

      title 'Confirm StandardForm Sequence'
      description "Verify that the server's Questionnaires conform to the StandardForm profile"
      test_id_prefix 'csfs'

      requires :url

      @sfs = nil
      @sfUrl = nil

      test 'All Questionnaires in the server claim to conform to the StandardForm profile' do

        metadata{
          id '01'
          desc %(
            Tests if every Questionnaire on the server specifies the StandardForm profile in its metadata
          )
        }

        total = how_many(FHIR::Questionnaire)        
        @sfUrl = "https://impact-fhir.mitre.org/r4/StructureDefinition/del-StandardForm"
        @sfs = get_resource_intersection(nil, FHIR::Questionnaire, @sfUrl)
        assert total == @sfs.length, "Only " + @sfs.length.inspect + "/" + total.inspect + " Questionnaires claim the StandardForm profile"
        
      end

      test 'Questionnaires do not violate StandardForm Profile restrictions' do
        
        metadata{
          id '02'
          desc %(
            Tests if the Questionnaires from the FHIR server claiming to be StandardForms are valid according to the definition of an StandardForm
          )
        }

        errors = check_profiles(@sfs, FHIR::Questionnaire, @sfUrl)
        assert errors.empty?, errors.to_s

      end

    end
  end 
end
