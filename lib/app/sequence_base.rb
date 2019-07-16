# frozen_string_literal: true

require_relative 'utils/assertions'
require_relative 'utils/skip_helpers'
require_relative 'ext/fhir_client'
require_relative 'utils/logged_rest_client'
require_relative 'utils/exceptions'
require_relative 'utils/validation'
require_relative 'utils/walk'
require_relative 'utils/web_driver'
require_relative 'utils/terminology'

require 'bloomer'
require 'bloomer/msgpackable'
require 'json'

module Inferno
  module Sequence
    Inferno::Terminology.load_validators

    class SequenceBase
      include Assertions
      include SkipHelpers
      include Inferno::WebDriver

      STATUS = {
        pass: 'pass',
        fail: 'fail',
        error: 'error',
        todo: 'todo',
        wait: 'wait',
        skip: 'skip'
      }.freeze

      @@test_index = 0

      @@group = {}
      @@preconditions = {}
      @@titles = {}
      @@descriptions = {}
      @@details = {}
      @@requires = {}
      @@conformance_supports = {}
      @@defines = {}
      @@versions = {}
      @@test_metadata = {}

      @@optional = []
      @@show_uris = []

      @@test_id_prefixes = {}

      def initialize(instance, client, disable_tls_tests = false, sequence_result = nil, metadata_only = false)
        @client = client
        @instance = instance
        @client.set_bearer_token(@instance.token) unless @client.nil? || @instance.nil? || @instance.token.nil?
        @client&.monitor_requests
        @sequence_result = sequence_result
        @disable_tls_tests = disable_tls_tests
        @test_warnings = []
        @metadata_only = metadata_only
      end

      def resume(request = nil, headers = nil, params = nil, fail_message = nil, &block)
        @params = params unless params.nil?

        @sequence_result.test_results.last.pass!

        if fail_message.present?
          @sequence_result.test_results.last.result = STATUS[:fail]
          @sequence_result.test_results.last.message = fail_message
        end

        unless request.nil?
          @sequence_result.test_results.last.request_responses << Models::RequestResponse.new(
            direction: 'inbound',
            request_method: request.request_method.downcase,
            request_url: request.url,
            request_headers: headers.to_json,
            request_payload: request.body.read,
            instance_id: @instance.id
          )
        end

        @sequence_result.pass!
        @sequence_result.wait_at_endpoint = nil
        @sequence_result.redirect_to_url = nil

        @sequence_result.save!

        start(&block)
      end

      def start(test_set_id = nil, test_case_id = nil, &block)
        if @sequence_result.nil?
          @sequence_result = Models::SequenceResult.new(
            name: sequence_name,
            result: STATUS[:pass],
            testing_instance: @instance,
            required: !optional?,
            test_set_id: test_set_id,
            test_case_id: test_case_id,
            app_version: VERSION
          )
          @sequence_result.save!
        end

        start_at = @sequence_result.test_results.length

        load_input_params(sequence_name)

        output_results = save_output(sequence_name)

        methods = self.methods.grep(/_test$/).sort[start_at..-1]

        run_tests(methods, &block)

        update_output(sequence_name, output_results)
        @sequence_result.output_results = output_results.to_json if output_results.present?

        @sequence_result.reset!
        @sequence_result.pass!

        update_result_counts

        @sequence_result
      end

      def load_input_params(sequence_name)
        input_parameters = {}
        @@requires[sequence_name]
          &.select { |requirement| @instance.respond_to? requirement }
          &.each do |requirement|
            input_value = @instance.send(requirement).to_s
            input_value = 'none' if input_value.empty?
            input_parameters[requirement.to_sym] = input_value
          end
        @sequence_result.input_params = input_parameters.to_json
      end

      def save_output(sequence_name)
        {}.tap do |output_results|
          @@defines[sequence_name]
            &.select { |output| @instance.respond_to? output }
            &.each do |output|
              output_value = @instance.send(output).to_s
              output_value = 'none' if output_value.empty?
              output_results[output.to_sym] = { original: output_value }
            end
        end
      end

      def update_output(sequence_name, output_results)
        @@defines[sequence_name]
          &.select { |output| @instance.respond_to? output }
          &.each do |output|
            output_value = @instance.send(output).to_s
            output_value = 'none' if output_value.empty?
            output_results[output.to_sym][:updated] = output_value
          end
      end

      def run_tests(methods)
        methods.each do |test_method|
          @client.requests = [] unless @client.nil?
          LoggedRestClient.clear_log
          result = method(test_method).call

          # Check to see if we are in headless mode and should redirect

          if result.wait_at_endpoint == 'redirect' && !@instance.standalone_launch_script.nil?
            begin
              @params = run_script(@instance.standalone_launch_script, result.redirect_to_url)
              result.pass!
            rescue StandardError => e
              result.fail!
              result.message = "Automated browser script failed: #{e}"
            end
          elsif result.wait_at_endpoint == 'launch' && !@instance.ehr_launch_script.nil?
            begin
              @params = run_script(@instance.ehr_launch_script)
              result.pass!
            rescue StandardError => e
              result.fail!
              result.message = "Automated browser script failed: #{e}"
            end
          end

          @client&.requests&.each do |req|
            result.request_responses << Models::RequestResponse.from_request(req, @instance.id, 'outbound')
          end

          LoggedRestClient.requests.each do |req|
            result.request_responses << Models::RequestResponse.from_request(OpenStruct.new(req), @instance.id)
          end

          yield result if block_given?

          @sequence_result.test_results << result

          next unless result.wait?

          @sequence_result.redirect_to_url = result.redirect_to_url
          @sequence_result.wait_at_endpoint = result.wait_at_endpoint
          break
        end
      end

      def update_result_counts
        @sequence_result.test_results.each do |result|
          if result.required
            @sequence_result.required_total += 1
          else
            @sequence_result.optional_total += 1
          end
          case result.result
          when STATUS[:pass]
            if result.required
              @sequence_result.required_passed += 1
            else
              @sequence_result.optional_passed += 1
            end
          when STATUS[:todo]
            @sequence_result.todo_count += 1
          when STATUS[:fail]
            if result.required
              @sequence_result.result = result.result unless @sequence_result.error?
            end
          when STATUS[:error]
            if result.required
              @sequence_result.error_count += 1
              @sequence_result.result = result.result
            end
          when STATUS[:skip]
            if result.required
              @sequence_result.skip_count += 1
              @sequence_result.result = result.result if @sequence_result.pass?
            end
          when STATUS[:wait]
            @sequence_result.result = result.result
          end
        end
      end

      def self.test_count
        new(nil, nil).test_count
      end

      def test_count
        methods.grep(/_test$/).length
      end

      def sequence_name
        self.class.sequence_name
      end

      def self.group(group = nil)
        @@group[sequence_name] = group unless group.nil?
        @@group[sequence_name] || []
      end

      def self.sequence_name
        name.demodulize
      end

      attr_reader :sequence_result

      def self.title(title = nil)
        @@titles[sequence_name] = title unless title.nil?
        @@titles[sequence_name] || sequence_name
      end

      def self.description(description = nil)
        @@descriptions[sequence_name] = description unless description.nil?
        @@descriptions[sequence_name]
      end

      def self.details(details = nil)
        @@details[sequence_name] = details unless details.nil?
        @@details[sequence_name]
      end

      def self.requires(*requires)
        @@requires[sequence_name] = requires unless requires.empty?
        @@requires[sequence_name] || []
      end

      def self.conformance_supports(*supports)
        @@conformance_supports[sequence_name] = supports unless supports.empty?
        @@conformance_supports[sequence_name] || []
      end

      def self.versions(*versions)
        @@versions[sequence_name] = versions unless versions.empty?
        @@versions[sequence_name] || FHIR::VERSIONS
      end

      def self.missing_requirements(instance, recurse = false)
        return [] unless @@requires.key?(sequence_name)

        requires = @@requires[sequence_name]

        missing = requires.select { |r| instance.respond_to?(r) && instance.send(r).nil? }

        dependencies = {}
        dependencies[self] = missing.map do |requirement|
          [requirement, instance.sequences.select { |sequence| sequence.defines.include? requirement }]
        end

        # move this into a hash so things are duplicated.

        return dependencies[self] unless recurse

        linked_dependencies = {}
        dependencies[self].each do |dep|
          return if linked_dependencies.key? dep

          dep[1].each do |seq|
            linked_dependencies.merge! seq.missing_requirements(instance, true)
          end
        end

        dependencies.merge! linked_dependencies

        dependencies
      end

      def self.defines(*defines)
        @@defines[sequence_name] = defines unless defines.empty?
        @@defines[sequence_name] || []
      end

      def self.test_id_prefix(test_id_prefix = nil)
        @@test_id_prefixes[sequence_name] = test_id_prefix unless test_id_prefix.nil?
        @@test_id_prefixes[sequence_name]
      end

      def self.tests
        @@test_metadata[sequence_name] || []
      end

      def optional?
        self.class.optional?
      end

      def self.optional
        @@optional << sequence_name
      end

      def self.optional?
        @@optional.include?(sequence_name)
      end

      def self.show_uris
        @@show_uris << sequence_name
      end

      def self.show_uris?
        @@show_uris.include?(sequence_name)
      end

      def self.preconditions(description, &block)
        @@preconditions[sequence_name] = {
          block: block,
          description: description
        }
      end

      def self.preconditions_description
        @@preconditions[sequence_name] && @@preconditions[sequence_name][:description]
      end

      def self.preconditions_met_for?(instance)
        return true unless @@preconditions.key?(sequence_name)

        block = @@preconditions[sequence_name][:block]
        new(instance, nil).instance_eval(&block)
      end

      # this must be called to ensure that the child class is referenced in self.sequence_name
      def self.extends_sequence(klass)
        @@test_metadata[klass.sequence_name].each do |metadata|
          @@test_metadata[sequence_name] ||= []
          @@test_metadata[sequence_name] << metadata
          @@test_metadata[sequence_name].last[:test_index] = @@test_metadata[sequence_name].length - 1
          define_method metadata[:method_name], metadata[:method]
        end
      end

      # Defines a new test.
      #
      # name - The String name of the test
      # block - The Block test to be executed
      def self.test(name, &block)
        @@test_index += 1

        test_index = @@test_index

        test_method = "#{@@test_index.to_s.rjust(4, '0')} #{name} test".downcase.tr(' ', '_').to_sym
        @@test_metadata[sequence_name] ||= []
        @@test_metadata[sequence_name] << { name: name,
                                            test_index: test_index,
                                            required: true,
                                            versions: FHIR::VERSIONS }

        test_index_in_sequence = @@test_metadata[sequence_name].length - 1

        wrapped = lambda do
          instance_eval(&block) if @metadata_only # just run the test to hit the metadata block

          @test_warnings = []
          @links = []
          @requires = []
          @validates = []
          result = Models::TestResult.new(test_id: @@test_metadata[sequence_name][test_index_in_sequence][:test_id],
                                          name: name,
                                          ref: @@test_metadata[sequence_name][test_index_in_sequence][:ref],
                                          required: @@test_metadata[sequence_name][test_index_in_sequence][:required],
                                          description: @@test_metadata[sequence_name][test_index_in_sequence][:description],
                                          url: @@test_metadata[sequence_name][test_index_in_sequence][:url],
                                          versions: @@test_metadata[sequence_name][test_index_in_sequence][:versions].join(','),
                                          result: STATUS[:pass],
                                          test_index: test_index)
          begin
            fhir_version_included = @@test_metadata[sequence_name][test_index_in_sequence][:versions].include? @instance.fhir_version&.to_sym
            skip_unless(fhir_version_included, 'This test does not run with this FHIR version') unless @instance.fhir_version.nil?
            Inferno.logger.info "Starting Test: #{@@test_metadata[sequence_name][test_index_in_sequence][:test_id]} [#{name}]"
            instance_eval(&block)
          rescue AssertionException, ClientException => e
            result.fail!
            result.message = e.message
            result.details = e.details
          rescue PassException => e
            result.pass!
            result.message = e.message
          rescue TodoException => e
            result.todo!
            result.message = e.message
          rescue WaitException => e
            result.wait!
            result.wait_at_endpoint = e.endpoint
          rescue RedirectException => e
            result.wait!
            result.wait_at_endpoint = e.endpoint
            result.redirect_to_url = e.url
          rescue SkipException => e
            result.skip!
            result.message = e.message
            result.details = e.details
          rescue StandardError => e
            Inferno.logger.error "Fatal Error: #{e.message}"
            Inferno.logger.error e.backtrace
            result.error!
            result.message = "Fatal Error: #{e.message}"
          end
          result.test_warnings = @test_warnings.map { |w| Models::TestWarning.new(message: w) } unless @test_warnings.empty?
          Inferno.logger.info "Finished Test: #{@@test_metadata[sequence_name][test_index_in_sequence][:test_id]} [#{result.result}]"
          result
        end

        define_method test_method, wrapped

        @@test_metadata[sequence_name][test_index_in_sequence][:method] = wrapped
        @@test_metadata[sequence_name][test_index_in_sequence][:method_name] = test_method

        instance = new(nil, nil, nil, nil, true)
        begin
          instance.send(test_method)
        rescue MetadataException
        end
      end

      def metadata
        return unless @metadata_only

        yield
        raise MetadataException
      end

      def id(test_id)
        complete_test_id = @@test_id_prefixes[sequence_name] + '-' + test_id
        @@test_metadata[sequence_name].last[:test_id] = complete_test_id
      end

      def link(link)
        @@test_metadata[sequence_name].last[:url] = link
      end

      def ref(_ref)
        @@test_metadata[sequence_name].last[:ref] = requirement
      end

      def optional
        @@test_metadata[sequence_name].last[:required] = false
      end

      def desc(description)
        @@test_metadata[sequence_name].last[:description] = description
      end

      def versions(*versions)
        @@test_metadata[sequence_name].last[:versions] = versions
      end

      def todo(message = '')
        raise TodoException, message
      end

      def pass(message = '')
        raise PassException, message
      end

      def skip(message = '', details = nil)
        raise SkipException.new message, details
      end

      def skip_unless(test, message = '', details = nil)
        raise SkipException.new message, details unless test
      end

      def wait_at_endpoint(endpoint)
        raise WaitException, endpoint
      end

      def redirect(url, endpoint)
        raise RedirectException.new url, endpoint
      end

      def warning
        yield
      rescue AssertionException => e
        @test_warnings << e.message
      end

      def get_resource_by_params(klass, params = {})
        assert !params.empty?, 'No params for search'
        options = {
          search: {
            flag: false,
            compartment: nil,
            parameters: params
          }
        }
        @client.search(klass, options)
      end

      def versioned_resource_class(klass)
        @client.versioned_resource_class klass
      end

      def check_sort_order(entries)
        relevant_entries = entries.reject { |x| x.request.try(:local_method) == 'DELETE' }
        begin
          relevant_entries.map!(&:resource).map!(&:meta).compact
        rescue StandardError
          assert(false, 'Unable to find meta for resources returned by the bundle')
        end

        relevant_entries.each_cons(2) do |left, right|
          if !left.versionId.nil? && !right.versionId.nil?
            assert (left.versionId > right.versionId), 'Result contains entries in the wrong order.'
          elsif !left.lastUpdated.nil? && !right.lastUpdated.nil?
            assert (left.lastUpdated >= right.lastUpdated), 'Result contains entries in the wrong order.'
          else
            raise AssertionException, 'Unable to determine if entries are in the correct order -- no meta.versionId or meta.lastUpdated'
          end
        end
      end

      def validate_resource_item(_resource, _property, _value)
        assert false, 'Could not validate resource'
      end

      def validate_search_reply(klass, reply, search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        entries = reply.resource.entry.select { |entry| entry.resource.class == klass }
        assert !entries.empty?, 'No resources of this type were returned'

        if klass == versioned_resource_class('Patient')
          assert !reply.resource.get_by_id(@instance.patient_id).nil?, 'Server returned nil patient'
          assert reply.resource.get_by_id(@instance.patient_id).equals?(@patient, ['_id', 'text', 'meta', 'lastUpdated']), 'Server returned wrong patient'
        end

        entries.each do |entry|
          # This checks to see if the base resource conforms to the specification
          # It does not validate any profiles.
          base_resource_validation_errors = entry.resource.validate
          assert base_resource_validation_errors.empty?, "Invalid #{entry.resource.resourceType}: #{base_resource_validation_errors}"

          search_params.each do |key, value|
            validate_resource_item(entry.resource, key.to_s, value)
          end
        end
      end

      def save_resource_ids_in_bundle(klass, reply)
        return if reply.try(:resource).try(:entry).nil?

        entries = reply.resource.entry.select { |entry| entry.resource.class == klass }

        entries.each do |entry|
          @instance.post_resource_references(resource_type: klass.name.split(':').last,
                                             resource_id: entry.resource.id)
        end
      end

      def validate_read_reply(resource, klass)
        assert !resource.nil?, "No #{klass.name.split(':').last} resources available from search."
        if resource.is_a? FHIR::DSTU2::Reference
          read_response = resource.read
        else
          id = resource.try(:id)
          assert !id.nil?, "#{klass} id not returned"
          read_response = @client.read(klass, id)
          assert_response_ok read_response
          read_response = read_response.resource
        end
        assert !read_response.nil?, "Expected valid #{klass} resource to be present"
        assert read_response.is_a?(klass), "Expected resource to be valid #{klass}"
      end

      def validate_history_reply(resource, klass)
        assert !resource.nil?, "No #{klass.name.split(':').last} resources available from search."
        id = resource.try(:id)
        assert !id.nil?, "#{klass} id not returned"
        history_response = @client.resource_instance_history(klass, id)
        assert_response_ok history_response
        assert_bundle_response history_response
        assert_equal 'history', history_response.try(:resource).try(:type)
        entries = history_response.try(:resource).try(:entry)
        assert entries, 'No bundle entries returned'
        assert entries.try(:length).positive?, 'No resources of this type were returned'
        check_sort_order entries
      end

      def validate_vread_reply(resource, klass)
        assert !resource.nil?, "No #{klass.name.split(':').last} resources available from search."
        id = resource.try(:id)
        assert !id.nil?, "#{klass} id not returned"
        version_id = resource.try(:meta).try(:versionId)
        assert !version_id.nil?, "#{klass} version_id not returned"
        vread_response = @client.vread(klass, id, version_id)
        assert_response_ok vread_response
        assert !vread_response.resource.nil?, "Expected valid #{klass} resource to be present"
        assert vread_response.resource.is_a?(klass), "Expected resource to be valid #{klass}"
      end

      attr_accessor :profiles_encountered
      attr_accessor :profiles_failed

      def test_resources_against_profile(resource_type, specified_profile = nil)
        @profiles_encountered ||= []
        @profiles_failed ||= {}

        all_errors = []

        resources = @instance.resource_references.select { |r| r.resource_type == resource_type }
        skip("Skip profile validation since no #{resource_type} resources found for Patient.") if resources.empty?

        @instance.resource_references.select { |r| r.resource_type == resource_type }.map(&:resource_id).each do |resource_id|
          resource_response = @client.read(versioned_resource_class(resource_type), resource_id)
          assert_response_ok resource_response
          resource = resource_response.resource
          assert resource.is_a?(versioned_resource_class(resource_type)), "Expected resource to be of type #{resource_type}"

          p = Inferno::ValidationUtil.guess_profile(resource, @instance.fhir_version.to_sym)
          if specified_profile
            warn { assert false, "No #{specified_profile} found for this Resource" }
            next unless p.url == specified_profile
          end
          if p
            @profiles_encountered << p.url
            @profiles_encountered.uniq!
            errors = p.validate_resource(resource)
            @test_warnings.concat(p.warnings.reject(&:empty?))
            unless errors.empty?
              errors.map! { |e| "#{resource_type}/#{resource_id}: #{e}" }
              @profiles_failed[p.url] = [] unless @profiles_failed[p.url]
              @profiles_failed[p.url].concat(errors)
            end
            all_errors.concat(errors)
          else
            warn { assert false, 'No profiles found for this Resource' }
            errors = resource.validate
            all_errors.concat(errors.values)
          end
        end
        # TODO
        # bundle = client.next_bundle
        assert(all_errors.empty?, all_errors.join("<br/>\n"))
      end

      def validate_reference_resolutions(resource)
        problems = []

        walk_resource(resource) do |value, meta, path|
          next if meta['type'] != 'Reference'

          begin
            # Should potentially update valid? method in fhir_dstu2_models
            # to check for this type of thing
            # e.g. "patient/54520" is invalid (fhir_client resource_class method would expect "Patient/54520")
            if value.relative?
              begin
                value.resource_class
              rescue NameError
                problems << "#{path} has invalid resource type in reference: #{value.type}"
                next
              end
            end
            value.read
          rescue ClientException => e
            problems << "#{path} did not resolve: #{e}"
          end
        end

        assert(problems.empty?, problems.join("<br/>\n"))
      end

      def versioned_conformance_class
        if @instance.fhir_version == 'dstu2'
          FHIR::DSTU2::Conformance
        elsif @instance.fhir_version == 'stu3'
          FHIR::STU3::CapabilityStatement
        else
          FHIR::CapabilityStatement
        end
      end

      def check_resource_against_profile(resource, resource_type, specified_profile = nil)
        assert resource.is_a?("FHIR::DSTU2::#{resource_type}".constantize),
               "Expected resource to be of type #{resource_type}"

        p = Inferno::ValidationUtil.guess_profile(resource, @instance.fhir_version.to_sym)
        if specified_profile
          return unless p.url == specified_profile
        end
        if p
          @profiles_encountered << p.url
          @profiles_encountered.uniq!
          errors = p.validate_resource(resource)
          unless errors.empty?
            errors.map! { |e| "#{resource_type}/#{resource.id}: #{e}" }
            @profiles_failed[p.url] = [] unless @profiles_failed[p.url]
            @profiles_failed[p.url].concat(errors)
          end
        else
          errors = entry.resource.validate
        end
        assert(errors.empty?, errors.join("<br/>\n"))
      end
    end

    Dir.glob(File.join(__dir__, 'modules', '**', '*_sequence.rb')).each { |file| require file }
  end
end
