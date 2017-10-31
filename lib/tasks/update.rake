namespace :update do
  
  desc "transfer service and agency comments to description translations" 
  task transfer_comments_to_descriptions: :environment do
    [Agency, Service].each do |table|
      table.all.each do |record|
        Comment.where(commentable_type: table.name).each do |comment|
          if comment.commentable
            puts "Setting description for #{comment.commentable.to_s}, locale: #{comment.locale}"
            comment.commentable.set_description_translation(comment.locale, comment.comment)
          end
        end
      end
      
      puts "Destroying comments for #{table.name} table"
      Comment.where(commentable_type: table.name).destroy_all
    end
  end
  
end
