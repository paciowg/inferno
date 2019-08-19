# frozen_string_literal: true

module Inferno
  module Sequence
    class USCoreR4MedicationrequestSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'MedicationRequest Tests'

      description 'Verify that MedicationRequest resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'MedicationRequest' # change me

      requires :token, :patient_id
      conformance_supports :MedicationRequest

      def validate_resource_item(resource, property, value)
        case property

        when 'status'
          value_found = can_resolve_path(resource, 'status') { |value_in_resource| value_in_resource == value }
          assert value_found, 'status on resource does not match status requested'

        when 'patient'
          value_found = can_resolve_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found, 'patient on resource does not match patient requested'

        when 'authoredon'
          value_found = can_resolve_path(resource, 'authoredOn') { |value_in_resource| value_in_resource == value }
          assert value_found, 'authoredon on resource does not match authoredon requested'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Medicationrequest Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-medicationrequest)

      )

      @resources_found = false

      test 'Server rejects MedicationRequest search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }

        reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from MedicationRequest search by patient' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @medicationrequest = reply.try(:resource).try(:entry).try(:first).try(:resource)
        @medicationrequest_ary = reply&.resource&.entry&.map { |entry| entry&.resource }
        save_resource_ids_in_bundle(versioned_resource_class('MedicationRequest'), reply)
        validate_search_reply(versioned_resource_class('MedicationRequest'), reply, search_params)
      end

      test 'Server returns expected results from MedicationRequest search by patient+status' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@medicationrequest.nil?, 'Expected valid MedicationRequest resource to be present'

        patient_val = @instance.patient_id
        status_val = resolve_element_from_path(@medicationrequest, 'status')
        search_params = { 'patient': patient_val, 'status': status_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
        validate_search_reply(versioned_resource_class('MedicationRequest'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from MedicationRequest search by patient+authoredon' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@medicationrequest.nil?, 'Expected valid MedicationRequest resource to be present'

        patient_val = @instance.patient_id
        authoredon_val = resolve_element_from_path(@medicationrequest, 'authoredOn')
        search_params = { 'patient': patient_val, 'authoredon': authoredon_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
        validate_search_reply(versioned_resource_class('MedicationRequest'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'MedicationRequest read resource supported' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:MedicationRequest, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@medicationrequest, versioned_resource_class('MedicationRequest'))
      end

      test 'MedicationRequest vread resource supported' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:MedicationRequest, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@medicationrequest, versioned_resource_class('MedicationRequest'))
      end

      test 'MedicationRequest history resource supported' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:MedicationRequest, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@medicationrequest, versioned_resource_class('MedicationRequest'))
      end

      test 'MedicationRequest resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-medicationrequest.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('MedicationRequest')
      end

      test 'At least one of every must support element is provided in any MedicationRequest for this patient.' do
        metadata do
          id '09'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @medicationrequest_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'MedicationRequest.status',
          'MedicationRequest.medicationCodeableConcept',
          'MedicationRequest.medicationReference',
          'MedicationRequest.subject',
          'MedicationRequest.authoredOn',
          'MedicationRequest.requester',
          'MedicationRequest.dosageInstruction',
          'MedicationRequest.dosageInstruction.text'
        ]
        must_support_elements.each do |path|
          @medicationrequest_ary&.each do |resource|
            truncated_path = path.gsub('MedicationRequest.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @medicationrequest_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided MedicationRequest resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '10'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:MedicationRequest, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@medicationrequest)
      end
    end
  end
end
