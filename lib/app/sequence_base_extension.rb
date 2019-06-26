require_relative 'sequence_base'

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
      # Checks validity of profiles by testing all aspects of the server that fall under the intersection of params.
      # (Defining a param will never increase the scope of the check, in fact in most cases it will narrow the scope)
      #
      # * +resources+ the array of resources to check a subset of.
      # * +klasses+ the array of klasses that all checked resources must be a part of.
      # * +profiles+ the array of profiles that
      # * When any of these parameters are nil or empty, it is assumed to apply to the entire set of it's kind 
      #   (i.e. a nil or empty +klasses+ means all available klasses).
      #
      # This means there are 2^3 (8) potential cases for using this method:
      # 
      # 1. When no params are defined (all are nil): this will check every resource
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

        errors = {}
        resources.each do |resource|
          errArr = resource.validate.values
          errors[resource] = errArr unless blank?(errArr)
        end
        errors
      end


      ##
      # Returns how many resources of the type +klass+ are stored in server

      def how_many(klass)
        @client.read_feed(klass).resource.total
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
      # Returns +nil+ if +param+ is falsy, returns +param.to_a+ if possible, otherwise returns +param+ as only element in new +Array+

      def coerce_to_a(param)
        return nil unless param
        param.respond_to?('to_a') ? param.to_a : Array.[](param)
      end

    end

  end
end