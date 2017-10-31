module Api
  module V2
    
    # Parent serializer for Accommodations, Eligibilities, and Purposes
    class CharacteristicSerializer < ApiSerializer
      attributes :code, :name, :note, :question
      
      def name
        object.try(:name, locale)
      end
      
      def note
        object.try(:note, locale)
      end
      
      def question
        object.try(:question, locale)
      end
      
    end
  end
end
