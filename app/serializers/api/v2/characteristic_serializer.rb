module Api
  module V2
    
    # Parent serializer for Accommodations, Eligibilities, and Purposes
    class CharacteristicSerializer < ApiSerializer
      attributes :code, :name, :note, :question
      
      def name
        object.try(:name, scope[:locale])
      end
      
      def note
        object.try(:note, scope[:locale])
      end
      
      def question
        object.try(:question, scope[:locale])
      end
      
    end
  end
end
