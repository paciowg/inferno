require_relative 'sequence_base'

module Inferno
  module Sequence

    ##
    # Added functionality on top of Sequence Base

    class SequenceBaseExtension < SequenceBase
      
      ##
      # initializer appeals to parent initializer

      def initialize(instance, client, disable_tls_tests = false, sequence_result = nil, metadata_only = false)
        super(instance, client, disable_tls_tests, sequence_result, metadata_only)
      end

      ##
      # Calls get_all_replies with klass for server's responses
      # Filters responses to return an array where every instance of klass from the server is repesented in an element
      # 
      # Returns [klass] (groomed array of every resource of type klass provided by the server)

      def get_all_resources(klass)
        replies = get_all_replies(klass)
        return nil unless replies
        resources = []
        replies.each do |reply|
          resources.push(reply.resource.entry.collect{ |singleEntry| singleEntry.resource })
        end
        resources.compact!
        resources.flatten(1)
      end


      ##
      # Retrieves all bundles from server when requesting every resource of type _klass
      #
      # Returns array of every unchanged server response 

      def get_all_replies(klass)
        replies = [].push(@client.read_feed(klass))
        return nil if replies.nil? || replies.empty?
        while !replies.last.nil?
          replies.push(@client.next_page(replies.last))
        end
        replies.compact
      end


      ##
      # Returns how many resources of type _klass are stored in server

      def how_many(klass)
        @client.read_feed(klass).resource.total
      end


      ##
      # Returns true if _str conforms to HL7's dateTime format, false otherwise

      def conforms_to_dateTime_format(str)
        dateTimeRegex = /\A(?:(?!0000)\d{4})(-(0[1-9]|1[0-2])(-(0[1-9]|[1-2]\d|3[0-1])(T([01]\d|2[0-3]):[0-5]\d:([0-5]\d|60)(\.\d+)?(Z|(\+|-)((0\d|1[0-3]):[0-5]\d|14:00)))?)?)?\z/
        dateTimeRegex.match(str)
      end

    end

  end
end