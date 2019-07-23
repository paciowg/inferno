require_relative '../../sequence_base_extension'

module Inferno
  module Sequence
    class ConfirmCodeSystemSequence < SequenceBaseExtension

      title 'Confirm CodeSystem Sequence'
      description "Verify that the server's CodeSystems conform to HL7 standards"
      test_id_prefix 'ccoss'

      requires :url

      @csyses = nil

      test 'Able to retrieve all CodeSystems' do
      
        metadata{
          id '01'
          desc %(
            Tests if the FHIR server will return every CodeSystem the server says it stores
          )
        }

        total = how_many(FHIR::CodeSystem)
        @csyses = get_all_resources(FHIR::CodeSystem)

        @csyses.each do |csys|
          assert csys.class.eql?(FHIR::CodeSystem), "All CodeSystems must be instances of FHIR::CodeSystem, not " + csys.class.to_s
        end
        assert @csyses.length == total, "Server claimed to hold " + total.to_s + " CodeSystems, actually reads in " + @csyses.length.to_s

      end

      test 'The CodeSystems do not violate HL7 requirements' do
        
        metadata{
          id '02'
          desc %(
            Tests if the CodeSystems from the FHIR server are valid according to HL7's definition of a CodeSystem
          )
        }

        errors = check_validity(@csyses)
        assert errors.empty?, errors.to_s

      end
    end
  end 
end
