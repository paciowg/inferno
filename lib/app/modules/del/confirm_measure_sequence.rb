require_relative '../../sequence_base_extension'

module Inferno
  module Sequence
    class ConfirmMeasureSequence < SequenceBaseExtension

      title 'Confirm Measure Sequence'
      description "Verify that the server's Measures conform to HL7 standards"
      test_id_prefix 'cms'

      requires :url

      @measures = nil

      test 'Able to retrieve all Measures' do
      
        metadata{
          id '01'
          desc %(
            Tests if the FHIR server will return every Measure the server says it stores
          )
        }

        total = how_many(FHIR::Measure)
        @measures = get_all_resources(FHIR::Measure)

        @measures.each do |m|
          assert m.class.eql?(FHIR::Measure), "All measures must be instances of FHIR::Measure, not " + m.class.to_s
        end
        assert @measures.length == total, "Server claimed to hold " + total.to_s + " measures, actually reads in " + @measures.length.to_s

      end

      test 'The Measures do not violate HL7 requirements' do
        
        metadata{
          id '02'
          desc %(
            Tests if the Measures from the FHIR server are valid according to HL7's definition of a Measure
          )
        }

        errors = check_validity(@measures)
        assert errors.empty?, errors.to_s

      end
    end
  end 
end
