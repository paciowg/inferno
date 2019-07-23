require_relative '../../sequence_base_extension'

module Inferno
  module Sequence
    class ConfirmValueSetSequence < SequenceBaseExtension

      title 'Confirm ValueSet Sequence'
      description "Verify that the server's ValueSets conform to HL7 standards"
      test_id_prefix 'cvss'

      requires :url

      @vss = nil

      test 'Able to retrieve all ValueSets' do
      
        metadata{
          id '01'
          desc %(
            Tests if the FHIR server will return every ValueSet the server says it stores
          )
        }

        total = how_many(FHIR::ValueSet)
        @vss = get_all_resources(FHIR::ValueSet)

        @vss.each do |vs|
          assert vs.class.eql?(FHIR::ValueSet), "All ValueSets must be instances of FHIR::ValueSet, not " + vs.class.to_s
        end
        assert @vss.length == total, "Server claimed to hold " + total.to_s + " ValueSets, actually reads in " + @vss.length.to_s

      end

      test 'The ValueSets do not violate HL7 requirements' do
        
        metadata{
          id '02'
          desc %(
            Tests if the ValueSets from the FHIR server are valid according to HL7's definition of a ValueSet
          )
        }

        errors = check_validity(@vss)
        assert errors.empty?, errors.to_s

      end
    end
  end 
end
