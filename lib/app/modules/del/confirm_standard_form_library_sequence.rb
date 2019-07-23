require_relative '../../sequence_base_extension'

module Inferno
  module Sequence
    class ConfirmStandardFormLibrarySequence < SequenceBaseExtension

      title 'Confirm StandardFormLibrary Sequence'
      description "Verify that the server's Libraries conform to the StandardFormLibrary profile"
      test_id_prefix 'csfls'

      requires :url

      @sfls = nil
      @sflUrl = nil

      test 'All Libraries in the server claim to conform to the StandardFormLibrary profile' do

        metadata{
          id '01'
          desc %(
            Tests if every Library on the server specifies the StandardFormLibrary profile in its metadata
          )
        }

        total = how_many(FHIR::Library)        
        @sflUrl = "https://impact-fhir.mitre.org/r4/StructureDefinition/del-StandardFormLibrary"
        @sfls = get_resource_intersection(nil, FHIR::Library, @sflUrl)
        assert total == @sfls.length, "Only " + @sfls.length.inspect + "/" + total.inspect + " Libraries claim the StandardFormLibrary profile"
        
      end

      test 'Libraries do not violate StandardFormLibrary Profile restrictions' do
        
        metadata{
          id '02'
          desc %(
            Tests if the Libraries from the FHIR server claiming to be StandardFormLibraries are valid according to the definition of an StandardFormLibrary
          )
        }

        errors = check_profiles(@sfls, FHIR::Library, @sflUrl)
        assert errors.empty?, errors.to_s

      end

    end
  end 
end
