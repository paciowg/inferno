# frozen_string_literal: true

module Inferno
  module Sequence
    class USCoreR4AllergyintoleranceSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'AllergyIntolerance Tests'

      description 'Verify that AllergyIntolerance resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'AllergyIntolerance' # change me

      requires :token, :patient_id
      conformance_supports :AllergyIntolerance

      def validate_resource_item(resource, property, value)
        case property

        when 'clinical-status'
          value_found = can_resolve_path(resource, 'clinicalStatus.coding.code') { |value_in_resource| value_in_resource == value }
          assert value_found, 'clinical-status on resource does not match clinical-status requested'

        when 'patient'
          value_found = can_resolve_path(resource, 'patient.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found, 'patient on resource does not match patient requested'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Allergyintolerance Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-allergyintolerance)

      )

      @resources_found = false

      test 'Server rejects AllergyIntolerance search without authorization' do
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

        reply = get_resource_by_params(versioned_resource_class('AllergyIntolerance'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from AllergyIntolerance search by patient' do
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

        reply = get_resource_by_params(versioned_resource_class('AllergyIntolerance'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @allergyintolerance = reply.try(:resource).try(:entry).try(:first).try(:resource)
        @allergyintolerance_ary = reply&.resource&.entry&.map { |entry| entry&.resource }
        save_resource_ids_in_bundle(versioned_resource_class('AllergyIntolerance'), reply)
        validate_search_reply(versioned_resource_class('AllergyIntolerance'), reply, search_params)
      end

      test 'Server returns expected results from AllergyIntolerance search by patient+clinical-status' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@allergyintolerance.nil?, 'Expected valid AllergyIntolerance resource to be present'

        patient_val = @instance.patient_id
        clinical_status_val = resolve_element_from_path(@allergyintolerance, 'clinicalStatus.coding.code')
        search_params = { 'patient': patient_val, 'clinical-status': clinical_status_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('AllergyIntolerance'), search_params)
        validate_search_reply(versioned_resource_class('AllergyIntolerance'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'AllergyIntolerance read resource supported' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:AllergyIntolerance, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@allergyintolerance, versioned_resource_class('AllergyIntolerance'))
      end

      test 'AllergyIntolerance vread resource supported' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:AllergyIntolerance, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@allergyintolerance, versioned_resource_class('AllergyIntolerance'))
      end

      test 'AllergyIntolerance history resource supported' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:AllergyIntolerance, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@allergyintolerance, versioned_resource_class('AllergyIntolerance'))
      end

      test 'AllergyIntolerance resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-allergyintolerance.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('AllergyIntolerance')
      end

      test 'At least one of every must support element is provided in any AllergyIntolerance for this patient.' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @allergyintolerance_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'AllergyIntolerance.clinicalStatus',
          'AllergyIntolerance.verificationStatus',
          'AllergyIntolerance.code',
          'AllergyIntolerance.patient'
        ]
        must_support_elements.each do |path|
          @allergyintolerance_ary&.each do |resource|
            truncated_path = path.gsub('AllergyIntolerance.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @allergyintolerance_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided AllergyIntolerance resource(s)" unless must_support_confirmed[path]
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

        skip_if_not_supported(:AllergyIntolerance, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@allergyintolerance)
      end
    end
  end
end
