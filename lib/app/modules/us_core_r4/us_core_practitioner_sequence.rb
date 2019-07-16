# frozen_string_literal: true

module Inferno
  module Sequence
    class UsCoreR4PractitionerSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Practitioner Tests'

      description 'Verify that Practitioner resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'Practitioner' # change me

      requires :token, :patient_id
      conformance_supports :Practitioner

      def validate_resource_item(resource, property, value)
        case property

        when 'name'
          found = resource&.name&.any? do |name|
            name.text&.include?(value) ||
              name.family.include?(value) ||
              name.given.any { |given| given&.include?(value) } ||
              name.prefix.any { |prefix| prefix.include?(value) } ||
              name.suffix.any { |suffix| suffix.include?(value) }
          end
          assert found, 'name on resource does not match name requested'
        when 'identifier'
          assert resource&.identifier&.any? { |identifier| identifier.value == value }, 'identifier on resource did not match identifier requested'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Practitioner Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-practitioner)

      )

      @resources_found = false

      test 'Server rejects Practitioner search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('Practitioner'), patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from Practitioner search by name' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        name_val = @practitioner&.name&.first&.family
        search_params = { 'name': name_val }

        reply = get_resource_by_params(versioned_resource_class('Practitioner'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @practitioner = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('Practitioner'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('Practitioner'), reply)
      end

      test 'Server returns expected results from Practitioner search by identifier' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@practitioner.nil?, 'Expected valid Practitioner resource to be present'

        identifier_val = @practitioner&.identifier&.first&.value
        search_params = { 'identifier': identifier_val }

        reply = get_resource_by_params(versioned_resource_class('Practitioner'), search_params)
        assert_response_ok(reply)
      end

      test 'Practitioner read resource supported' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Practitioner, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@practitioner, versioned_resource_class('Practitioner'))
      end

      test 'Practitioner vread resource supported' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Practitioner, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@practitioner, versioned_resource_class('Practitioner'))
      end

      test 'Practitioner history resource supported' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Practitioner, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@practitioner, versioned_resource_class('Practitioner'))
      end

      test 'Practitioner resources associated with Patient conform to Argonaut profiles' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-practitioner.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Practitioner')
      end

      test 'All references can be resolved' do
        metadata do
          id '08'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Practitioner, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@practitioner)
      end
    end
  end
end
