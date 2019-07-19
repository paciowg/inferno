require_relative '../../sequence_base_extension'

module Inferno
  module Sequence
    class ConfirmStandardFormLibrarySequence < SequenceBaseExtension

      title 'Confirm StandardFormLibrary Sequence'
      description "Verify that the server's Libraries conform to HL7 standards and the StandardFormLibrary profile"
      test_id_prefix 'csfls'

      requires :url

      @libraries = nil
      @total = nil
      @sflUrl = nil

      test 'Able to retrieve all Libaries' do
      
        metadata{
          id '01'
          desc %(
            Tests if the FHIR server will return every Library the server says it stores
          )
        }

        @sflUrl = "https://impact-fhir.mitre.org/r4/StructureDefinition/del-StandardFormLibrary"
        @total = how_many(FHIR::Library)
        @libraries = get_all_resources(FHIR::Library)

        @libraries.each do |l|
          assert l.class.eql?(FHIR::Library), "All libraries must be instances of FHIR::Library, not " + l.class.to_s
        end
        assert @libraries.length == @total, "Server claimed to hold " + @total.to_s + " libraries, actually reads in " + @libraries.length.to_s

      end

      test 'Libraries do not violate HL7 requirements' do
        
        metadata{
          id '02'
          desc %(
            Tests if the Libraries from the FHIR server are valid according to HL7's definition of a Library
          )
        }

        errors = check_validity(@libraries)
        assert errors.empty?, errors.to_s

      end

      test 'All Libraries in the server claim to conform to the StandardFormLibrary profile' do

        metadata{
          id '03'
          desc %(
            Tests if every Library on the server specifies the StandardFormLibrary profile in its metadata
          )
        }

        sfls = get_resource_intersection(@libraries, FHIR::QuestionnaireResponse, @sflUrl)
        assert @libraries.length == sfls.length, "Only " + sfls.length.to_s + "/" + @libraries.length.to_s + " Libraries claim the StandardFormLibrary profile"
        
      end

      test 'Libraries do not violate StandardFormLibrary Profile restrictions' do
        
        metadata{
          id '04'
          desc %(
            Tests if the Libraries from the FHIR server claiming to be StandardFormLibraries are valid according to the definition of an StandardFormLibrary
          )
        }

        errors = check_profiles(@libraries, FHIR::Library, @sflUrl)
        assert errors.empty?, errors.to_s

      end

    end
  end 
end
