# frozen_string_literal: true

require_relative '../smart/ehr_launch_sequence'

module Inferno
  module Sequence
    class OncEHRLaunchSequence < EHRLaunchSequence
      extends_sequence EHRLaunchSequence

      title 'ONC EHR Launch Sequence'

      description 'Demonstrate the ONC SMART EHR Launch Sequence.'

      test_id_prefix 'OELS'

      requires :client_id, :confidential_client, :client_secret, :oauth_authorize_endpoint, :oauth_token_endpoint, :scopes, :initiate_login_uri, :redirect_uris

      defines :token, :id_token, :refresh_token, :patient_id

      @@resource_types = [
        'Patient',
        'AllergyIntolerance',
        'CarePlan',
        'Condition',
        'Device',
        'DiagnosticReport',
        'DocumentReference',
        'Encounter',
        'ExplanationOfBenefit',
        'Goal',
        'Immunization',
        'Medication',
        'MedicationDispense',
        'MedicationStatement',
        'MedicationOrder',
        'Observation',
        'Procedure',
        'DocumentReference',
        'Provenance'
      ]

      test 'Scopes enabling user-level access with OpenID Connect and Refresh Token present' do
        metadata do
          id '11'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#quick-start'
          desc %(
            The scopes being input must follow the guidelines specified in the smart-app-launch guide
          )
        end
        scopes = @instance.scopes.split(' ')

        assert scopes.include?('openid'), 'Scope did not include "openid"'
        scopes.delete('openid')
        assert scopes.include?('fhirUser'), 'Scope did not include "fhirUser"'
        scopes.delete('fhirUser')
        assert scopes.include?('launch'), 'Scope did not include "launch"'
        scopes.delete('launch')
        assert scopes.include?('offline_access'), 'Scope did not include "offline_access"'
        scopes.delete('offline_access')

        # Other 'okay' scopes
        scopes.delete('online_access')

        user_scope_found = false

        scopes.each do |scope|
          scope_pieces = scope.split('/')
          assert scope_pieces.count == 2, "Scope '#{scope}' does not follow the format: user/[ resource | * ].[ read | * ]"
          assert scope_pieces[0] == 'user', "Scope '#{scope}' does not follow the format: user/[ resource | * ].[ read | * ]"
          resource_access = scope_pieces[1].split('.')
          assert resource_access.count == 2, "Scope '#{scope}' does not follow the format: user/[ resource | * ].[ read | * ]"
          assert resource_access[0] == '*' || @@resource_types.include?(resource_access[0]), "'#{resource_access[0]}' must be either a valid resource type or '*'"
          assert resource_access[1] =~ /^(\*|read)/, "Scope '#{scope}' does not follow the format: user/[ resource | * ].[ read | * ]"

          user_scope_found = true
        end
        assert user_scope_found, 'Must contain a user-level scope in the format: user/[ resource | * ].[ read | *].'
      end
    end
  end
end
