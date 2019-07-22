require_relative '../../sequence_base_extension'

module Inferno
  module Sequence
    class ConfirmStandardFormQuestionSequence < SequenceBaseExtension

      title 'Confirm StandardFormQuestion Sequence'
      description "Verify that the server's Measures conform to HL7 standards and the StandardFormQuestion profile"
      test_id_prefix 'csfqs'

      requires :url

      @measures = nil
      @total = nil
      @sfqUrl = nil

      test 'Able to retrieve all Measures' do
      
        metadata{
          id '01'
          desc %(
            Tests if the FHIR server will return every Measure the server says it stores
          )
        }

        @sfqUrl = "https://impact-fhir.mitre.org/r4/StructureDefinition/del-StandardFormQuestion"
        @total = how_many(FHIR::Measure)
        @measures = get_all_resources(FHIR::Measure)

        @measures.each do |m|
          assert m.class.eql?(FHIR::Measure), "All measures must be instances of FHIR::Measure, not " + m.class.to_s
        end
        assert @measures.length == @total, "Server claimed to hold " + @total.to_s + " measures, actually reads in " + @measures.length.to_s

      end

      test 'Measures do not violate HL7 requirements' do
        
        metadata{
          id '02'
          desc %(
            Tests if the Measures from the FHIR server are valid according to HL7's definition of a Measure
          )
        }

        errors = check_validity(@measures)
        assert errors.empty?, errors.to_s

      end

      test 'All Measures in the server claim to conform to the StandardFormQuestion profile' do

        metadata{
          id '03'
          desc %(
            Tests if every Measure on the server specifies the StandardFormQuestion profile in its metadata
          )
        }

        sfqs = get_resource_intersection(@measures, FHIR::Measure, @sfqUrl)
        assert @measures.length == sfqs.length, "Only " + sfqs.length.to_s + "/" + @measures.length.to_s + " Measures claim the StandardFormQuestion profile"
        
      end

      test 'Measures do not violate StandardFormQuestion Profile restrictions' do
        
        metadata{
          id '04'
          desc %(
            Tests if the Measures from the FHIR server claiming to be StandardFormQuestions are valid according to the definition of an StandardFormQuestion
          )
        }

        errors = check_profiles(@measures, FHIR::Measure, @sfqUrl)
        assert errors.empty?, errors.to_s

      end

    end
  end 
end
