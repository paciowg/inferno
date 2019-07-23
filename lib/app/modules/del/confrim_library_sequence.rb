require_relative '../../sequence_base_extension'

module Inferno
  module Sequence
    class ConfirmLibrarySequence < SequenceBaseExtension

      title 'Confirm Library Sequence'
      description "Verify that the server's Library conform to HL7 standards"
      test_id_prefix 'cls'

      requires :url

      @libraries = nil

      test 'Able to retrieve all Libraries' do
      
        metadata{
          id '01'
          desc %(
            Tests if the FHIR server will return every Library the server says it stores
          )
        }

        total = how_many(FHIR::Library)
        @libraries = get_all_resources(FHIR::Library)

        @libraries.each do |l|
          assert l.class.eql?(FHIR::Library), "All libraries must be instances of FHIR::Library, not " + l.class.to_s
        end
        assert @libraries.length == total, "Server claimed to hold " + total.to_s + " libraries, actually reads in " + @libraries.length.to_s

      end

      test 'The Libraries do not violate HL7 requirements' do
        
        metadata{
          id '02'
          desc %(
            Tests if the Libraries from the FHIR server are valid according to HL7's definition of a Library
          )
        }

        errors = check_validity(@libraries)
        assert errors.empty?, errors.to_s

      end
    end
  end 
end
