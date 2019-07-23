require_relative '../../sequence_base_extension'

module Inferno
  module Sequence
    class ConfirmStructureDefinitionSequence < SequenceBaseExtension

      title 'Confirm StructureDefinition Sequence'
      description "Verify that the server's StructureDefinitions conform to HL7 standards"
      test_id_prefix 'csds'

      requires :url

      @sds = nil

      test 'Able to retrieve all StructureDefinitions' do
      
        metadata{
          id '01'
          desc %(
            Tests if the FHIR server will return every StructureDefinition the server says it stores
          )
        }

        total = how_many(FHIR::StructureDefinition)
        @sds = get_all_resources(FHIR::StructureDefinition)

        @sds.each do |sd|
          assert sd.class.eql?(FHIR::StructureDefinition), "All StructureDefinitions must be instances of FHIR::StructureDefinition, not " + sd.class.to_s
        end
        assert @sds.length == total, "Server claimed to hold " + total.to_s + " StructureDefinitions, actually reads in " + @sds.length.to_s

      end

      test 'The StructureDefinitions do not violate HL7 requirements' do
        
        metadata{
          id '02'
          desc %(
            Tests if the StructureDefinitions from the FHIR server are valid according to HL7's definition of a StructureDefinition
          )
        }

        errors = check_validity(@sds)
        assert errors.empty?, errors.to_s

      end
    end
  end 
end
