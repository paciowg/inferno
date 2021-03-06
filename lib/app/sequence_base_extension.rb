require_relative 'sequence_base'
require 'json'

module Inferno
  module Sequence

    ##
    # Adds functionality on top of SequenceBase

    class SequenceBaseExtension < SequenceBase
      
      ##
      # initializer appeals to parent initializer

      def initialize(instance, client, disable_tls_tests = false, sequence_result = nil, metadata_only = false)
        super(instance, client, disable_tls_tests, sequence_result, metadata_only)
      end


      ##
      # Calls +get_all_replies+ with +klasses+ for server's responses.
      # Filters responses to return an array where, for every klass indicated in the +klasses+ array, every applicable 
      # resource from the server is repesented in an element.
      # If +klasses+ is undefined or empty, it defaults to nil, which will result in returning every resource available in the server.
      # 
      # Returns <code>[resource, resource, ...]</code> (groomed array of every resource of any provided klass provided by the server), +nil+ if no replies

      def get_all_resources(klasses = nil)
        replies = get_all_replies(klasses)
        return nil unless replies
        resources = []
        replies.each do |reply|
          resources.push(reply.resource.entry.collect{ |singleEntry| singleEntry.resource })
        end
        resources.compact!
        resources.flatten(1)
      end


      ##
      # Retrieves all bundles from server when requesting every resource of each type in the +klasses+ array.
      # If +klasses+ is undefined or empty, it defaults to nil, which will return bundles of every resource with no regard for type.
      #
      # Returns <code>[reply, reply, ...]</code> (+array+ of every unchanged server response), +nil+ if no replies

      def get_all_replies(klasses = nil)
        klasses = coerce_to_a(klasses)
        replies = []
        if !blank?(klasses)
          klasses.each do |klass|
            replies.push(@client.read_feed(klass))
            while !replies.last.nil?
              replies.push(@client.next_page(replies.last))
            end
          end
        else
          replies.push(@client.all_history)
        end
        replies.compact!
        blank?(replies) ? nil : replies
      end


      ##
      # Checks validity of profiles by testing all resources against the provided params.
      # (Defining a param will never increase the scope of the check, in fact in most cases it will narrow the scope)
      #
      # * +resources+ the array of resources to check a subset of.
      # * +klasses+ the array of klasses that all checked resources must be instances of.
      # * +profiles+ the array of profile urls to check the resources against.
      # * When any of these parameters are nil or empty, it is assumed to apply to the entire set of it's kind 
      #   (i.e. a nil or empty +klasses+ means all available klasses).
      #
      # This means there are 2^3 (8) potential cases for using this method:
      # 
      # 1. When no params are defined (all are  or empty): this will check every resource
      #    in the server, regardless of klass, against all profiles they claim
      #
      # 2. When only +profiles+ is defined: this will check every resource
      #    in the server, regardless of klass, against the defined profiles
      #
      # 3. When only +klasses+ is defined: this will check every resource
      #    in the server of the specified klasses against all profiles they claim
      #
      # 4. When only +klass+ and +profile+ are defined: this will check every resource
      #    in the server of the specified klasses against the defined profiles
      #
      # 5. When only +resources+ is defined: this will check every provided resource,
      #    regardless of klass, against any profile they might claim
      #
      # 6. When only +resources+ and +profile+ are defined: this will check every provided resource,
      #    regardless of klass, against the defined profiles
      #
      # 7. When only +resources+ and +klass+ and defined: this will check every provided resource
      #    of the specified klasses, against any profile they might claim
      #
      # 8. When all params are defined: this will check every provided resource of the specified klasses
      #    against the defined profiles
      #
      # Returns array of strings describing each inconsistency between a resource and it's profile encountered.
      # This means an empty array indicates a fully consistent check.

      def check_profiles(resources = nil, klasses = nil, profiles = nil)
        resources = get_resource_intersection(resources, klasses, profiles)
        profiles = coerce_to_a(profiles)
        profiles.uniq! if profiles
        errors = {}
        profileSDs = []

        if blank?(profiles)
          resources.each { |resource| profileSDs.push(resource.meta.profile) }
          profileSDs.flatten!
          profileSDs.uniq!
          profileSDs.collect!{ |profile| Inferno::ValidationUtil.get_profile(profile) } 
        else
          profileSDs = profiles.collect{ |profile| Inferno::ValidationUtil.get_profile(profile) }
        end
        profileSDs.compact!
        if profiles && profileSDs.length != profiles.length
          errors["params"] = "Not all profile urls in the profiles param are in Inferno" 
        end

        profileSDs.each do |sd|
          errArr = resources.collect{ |resource| 
            err = sd.validate_resource(resource)
            blank?(err) ? nil : {resource.id.to_s => err}
          }
          errArr.compact!
          errors[sd.name] = errArr unless blank?(errArr)
        end
        errors
      end


      ##
      # Checks validity of resources by checking if they conform to their definitions from HL7
      # (Defining a param will never increase the scope of the check, in fact in most cases it will narrow the scope)
      #
      # * +resources+ the array of resources to check a subset of.
      # * +klasses+ the array of klasses that all checked resources must be a part of.
      # * When either of these parameters are nil or empty, it is assumed to apply to the entire set of it's kind 
      #   (i.e. a nil or empty +klasses+ means all available klasses).
      # 
      # This means there are 2^2 (4) potential cases for using this method:
      #
      # 1. When no params are defined (all are nil or empty): this will check the validity of every resource
      #    in the server, regardless of klass
      #
      # 2. When only +klasses+ is defined: this will check the validity of every resource
      #    in the server of the specified klasses
      #
      # 3. When only +resources+ is defined: this will check the validity of every provided resource,
      #    regardless of klass
      #
      # 4. When all params are defined: this will check the validity of every provided resource
      #    of the specified klasses
      #
      # Returns array of strings describing each inconsistency between a resource and its HL7 definition.
      # This means an empty array indicates a fully consistent check.

      def check_validity(resources = nil, klasses = nil)
        resources = get_resource_intersection(resources, klasses)
        errors = {}
        resources.each do |resource|
          errArr = resource.validate.values
          errors[resource.id] = errArr unless blank?(errArr)
        end
        errors
      end


      ##
      # Retrieve set of resources based on the intersection of the params.
      # (Defining a param will never increase the resource set, in fact in most cases it will narrow it)
      #
      # * +resources+ the array of resources to start with.
      # * +klasses+ the array of klasses that all retrieved resources must be an instance of.
      # * +profiles+ the array of profile urls that all retrieved resources must claim in their metadata.
      # * When any of these parameters are nil or empty, it is assumed that all associated options are acceptable. 
      #   (i.e. a nil or empty +klasses+ means all possible klasses).
      #
      # This means there are 2^3 (8) potential cases for using this method:
      # 
      # 1. When no params are defined (all are nil or empty): this will retrieve every resource
      #    from the server, regardless of klass and profile
      #
      # 2. When only +profiles+ is defined: this will retrieve every resource
      #    from the server, regardless of klass, that claims the identified profiles
      #
      # 3. When only +klasses+ is defined: this will retrieve every resource
      #    from the server of the specified klasses, regardless of the profile
      #
      # 4. When only +klass+ and +profile+ are defined: this will retrieve every resource
      #    from the server of the specified klasses that claim the identified profiles
      #
      # 5. When only +resources+ is defined: this will return every provided resource,
      #    regardless of klass and profile (so it will just return +resources+ unmodified)
      #
      # 6. When only +resources+ and +profile+ are defined: this will return every provided resource,
      #    regardless of klass, that claims the identified profiles
      #
      # 7. When only +resources+ and +klass+ and defined: this will return every provided resource
      #    of the specified klasses, regardless of the profile
      #
      # 8. When all params are defined: this will return every provided resource of the specified klasses
      #    that claims the identified resource
      #
      # Returns an array of the requested resources, derived from the intersection of the three params.

      def get_resource_intersection(resources = nil, klasses = nil, profiles = nil)
        resources = coerce_to_a(resources)
        klasses = coerce_to_a(klasses)
        profiles = coerce_to_a(profiles)

        if blank?(resources)
          resources = get_all_resources(klasses)
        elsif !blank?(klasses)
          resources.select!{ |resource| klasses.include?(resource.class) }
        end
        unless blank?(profiles)
          resources.select!{ |resource| !blank?(profiles & ((resource.meta.nil? || blank?(resource.meta.profile)) ? [] : resource.meta.profile)) }
        end

        resources
      end


      ##
      # Returns how many resources of the type +klass+ are stored in server

      def how_many(klass)
        JSON.parse(@client.raw_read(resource: klass, summary: "count").response[:body])["total"].to_i
      end


      ##
      # Returns +true+ if +str+ conforms to HL7's +dateTime+ format, +false+ otherwise

      def conforms_to_dateTime_format(str)
        dateTimeRegex = /\A(?:(?!0000)\d{4})(-(0[1-9]|1[0-2])(-(0[1-9]|[1-2]\d|3[0-1])(T([01]\d|2[0-3]):[0-5]\d:([0-5]\d|60)(\.\d+)?(Z|(\+|-)((0\d|1[0-3]):[0-5]\d|14:00)))?)?)?\z/
        dateTimeRegex.match(str)
      end


      ##
      # Returns +true+ if +param+ is +nil+ or empty, +false+ otherwise

      def blank?(param)
        param.nil? || param.empty?
      end


      ##
      # Returns +nil+ if +param+ is falsy. If +param+ is truthy, returns +param.clone.to_a+ if possible, otherwise returns +param+ as the only element in a new +Array+

      def coerce_to_a(param)
        return nil unless param
        param.respond_to?('to_a') ? param.clone.to_a : Array.[](param)
      end

    end

  end
end