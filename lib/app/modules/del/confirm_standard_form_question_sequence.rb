require_relative '../../sequence_base_extension'

module Inferno
  module Sequence
    class ConfirmStandardFormQuestionSequence < SequenceBaseExtension

      title 'Confirm StandardFormQuestion Sequence'
      description "Verify that the server's Measures conform to the StandardFormQuestion profile"
      test_id_prefix 'csfqs'

      requires :url

      @sfqs = nil
      @sfqUrl = nil

      test 'All Measures in the server claim to conform to the StandardFormQuestion profile' do

        metadata{
          id '01'
          desc %(
            Tests if every Measure on the server specifies the StandardFormQuestion profile in its metadata
          )
        }

        total = how_many(FHIR::Measure)        
        @sfqUrl = "https://impact-fhir.mitre.org/r4/StructureDefinition/del-StandardFormQuestion"
        @sfqs = get_resource_intersection(nil, FHIR::Measure, @sflUrl)
        assert total == @sfqs.length, "Only " + @sfqs.length.inspect + "/" + total.inspect + " Measures claim the StandardFormQuestion profile"
        
      end

      test 'Measures do not violate StandardFormQuestion Profile restrictions' do
        
        metadata{
          id '02'
          desc %(
            Tests if the Measures from the FHIR server claiming to be StandardFormQuestions are valid according to the definition of an StandardFormQuestion
          )
        }

        errors = check_profiles(@sfqs, FHIR::Measure, @sfqUrl)
        assert errors.empty?, errors.to_s

      end

    end
  end 
end
