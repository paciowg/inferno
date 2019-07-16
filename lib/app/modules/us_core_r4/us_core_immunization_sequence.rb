# frozen_string_literal: true

module Inferno
  module Sequence
    class UsCoreR4ImmunizationSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Immunization Tests'

      description 'Verify that Immunization resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'Immunization' # change me

      requires :token, :patient_id
      conformance_supports :Immunization

      def validate_resource_item(resource, property, value)
        case property

        when 'patient'
          assert resource&.patient&.reference&.include?(value), 'patient on resource does not match patient requested'

        when 'status'
          assert resource&.status == value, 'status on resource did not match status requested'

        when 'date'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Immunization Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-immunization)

      )

      @resources_found = false

      test 'Server rejects Immunization search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('Immunization'), patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from Immunization search by patient' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }

        reply = get_resource_by_params(versioned_resource_class('Immunization'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @immunization = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('Immunization'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('Immunization'), reply)
      end

      test 'Server returns expected results from Immunization search by patient+date' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@immunization.nil?, 'Expected valid Immunization resource to be present'

        patient_val = @instance.patient_id
        date_val = @immunization&.occurrenceDateTime
        search_params = { 'patient': patient_val, 'date': date_val }

        reply = get_resource_by_params(versioned_resource_class('Immunization'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Immunization search by patient+status' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@immunization.nil?, 'Expected valid Immunization resource to be present'

        patient_val = @instance.patient_id
        status_val = @immunization&.status
        search_params = { 'patient': patient_val, 'status': status_val }

        reply = get_resource_by_params(versioned_resource_class('Immunization'), search_params)
        assert_response_ok(reply)
      end

      test 'Immunization read resource supported' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Immunization, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@immunization, versioned_resource_class('Immunization'))
      end

      test 'Immunization vread resource supported' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Immunization, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@immunization, versioned_resource_class('Immunization'))
      end

      test 'Immunization history resource supported' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Immunization, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@immunization, versioned_resource_class('Immunization'))
      end

      test 'Immunization resources associated with Patient conform to Argonaut profiles' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-immunization.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Immunization')
      end

      test 'All references can be resolved' do
        metadata do
          id '09'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Immunization, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@immunization)
      end
    end
  end
end
