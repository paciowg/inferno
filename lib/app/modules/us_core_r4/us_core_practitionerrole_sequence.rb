# frozen_string_literal: true

module Inferno
  module Sequence
    class USCoreR4PractitionerroleSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'PractitionerRole Tests'

      description 'Verify that PractitionerRole resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'PractitionerRole' # change me

      requires :token, :patient_id
      conformance_supports :PractitionerRole

      def validate_resource_item(resource, property, value)
        case property

        when 'specialty'
          value_found = can_resolve_path(resource, 'specialty.coding.code') { |value_in_resource| value_in_resource == value }
          assert value_found, 'specialty on resource does not match specialty requested'

        when 'practitioner'
          value_found = can_resolve_path(resource, 'practitioner.reference') { |value_in_resource| value_in_resource == value }
          assert value_found, 'practitioner on resource does not match practitioner requested'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Practitionerrole Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-practitionerrole)

      )

      @resources_found = false

      test 'Server rejects PractitionerRole search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        specialty_val = @practitionerrole&.specialty&.coding&.first&.code
        search_params = { 'specialty': specialty_val }

        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from PractitionerRole search by specialty' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        specialty_val = resolve_element_from_path(@practitionerrole, 'specialty.coding.code')
        search_params = { 'specialty': specialty_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @practitionerrole = reply.try(:resource).try(:entry).try(:first).try(:resource)
        @practitionerrole_ary = reply&.resource&.entry&.map { |entry| entry&.resource }
        save_resource_ids_in_bundle(versioned_resource_class('PractitionerRole'), reply)
        validate_search_reply(versioned_resource_class('PractitionerRole'), reply, search_params)
      end

      test 'Server returns expected results from PractitionerRole search by practitioner' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@practitionerrole.nil?, 'Expected valid PractitionerRole resource to be present'

        practitioner_val = resolve_element_from_path(@practitionerrole, 'practitioner.reference')
        search_params = { 'practitioner': practitioner_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), search_params)
        validate_search_reply(versioned_resource_class('PractitionerRole'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'PractitionerRole read resource supported' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:PractitionerRole, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@practitionerrole, versioned_resource_class('PractitionerRole'))
      end

      test 'PractitionerRole vread resource supported' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:PractitionerRole, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@practitionerrole, versioned_resource_class('PractitionerRole'))
      end

      test 'PractitionerRole history resource supported' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:PractitionerRole, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@practitionerrole, versioned_resource_class('PractitionerRole'))
      end

      test 'PractitionerRole resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-practitionerrole.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('PractitionerRole')
      end

      test 'At least one of every must support element is provided in any PractitionerRole for this patient.' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @practitionerrole_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'PractitionerRole.practitioner',
          'PractitionerRole.organization',
          'PractitionerRole.code',
          'PractitionerRole.specialty',
          'PractitionerRole.location',
          'PractitionerRole.telecom',
          'PractitionerRole.telecom.system',
          'PractitionerRole.telecom.value',
          'PractitionerRole.endpoint'
        ]
        must_support_elements.each do |path|
          @practitionerrole_ary&.each do |resource|
            truncated_path = path.gsub('PractitionerRole.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @practitionerrole_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided PractitionerRole resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '09'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:PractitionerRole, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@practitionerrole)
      end
    end
  end
end
