require_relative '../../sequence_base_extension'

module Inferno
  module Sequence
    class ConfirmQuestionnaireTypeConsistencySequence < SequenceBaseExtension

      title 'Confirm Questionnaire Type Consistency Sequence'
      description "Verify that the server's Questionnaires have types that are consistent with their options for answers"
      test_id_prefix 'cqtcs'

      requires :url

      @questionnaires = nil

      test 'All Questionnaire Types Consistent with Potential Answers' do
      
        metadata{
          id '01'
          desc %(
            Tests if all Questionnaire items have the correct potential answers
          )
        }

        @questionnaires = get_all_resources(FHIR::Questionnaire)

        @questionnaires.each do |q|
          flattenQuestionnaire(q).each do |qItem|
            type = qItem.item.type
            if type.eql?("choice")
              assert qItem.item.answerOption && !qItem.item.answerOption.empty?, qItem.item.linkId + " is of type " + type + " and must have answerOptions"
            elsif type.eql?("open-choice")
              warning{
                assert qItem.item.answerOption && !qItem.item.answerOption.empty?, qItem.item.linkId + " is of type " + type + " and should have answerOptions, though it doesn't have to."
              }
            else
              assert qItem.item.answerOption.empty?, qItem.item.linkId + " is of type " + type + " and should not have answerOptions"
            end
          end
        end

      end

      def flattenQuestionnaire(q)
        qFlat = [].append(getItem(q.item))
        qFlat.flatten()
      end

      def getItem(itemArray, level=0)
        items = []
        return nil if itemArray.nil?
        itemArray.each do |item|
          items.append(QItem.new(item, level))
            if item.item
              items.append(getItem(item.item, level + 1))
            end
        end
        items
      end

      class QItem
        attr_reader :item
        attr_reader :level

        def initialize(item, level=0)
          @item = item
          @level = level
        end
      end

    end
  end 
end
