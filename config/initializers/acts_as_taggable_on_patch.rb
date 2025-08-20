# config/initializers/acts_as_taggable_on_patch.rb
Rails.application.config.to_prepare do
  begin
    if defined?(ActsAsTaggableOn::Taggable::Cache) && defined?(Conversation)
      unless Conversation.included_modules.include?(ActsAsTaggableOn::Taggable::Cache)
        Conversation.include ActsAsTaggableOn::Taggable::Cache
        Rails.logger.info "[acts-as-taggable-on] Included Taggable::Cache into Conversation"
      end
    else
      Rails.logger.warn "[acts-as-taggable-on] Taggable::Cache not defined — skipping include"
    end
  rescue => e
    Rails.logger.warn "[acts-as-taggable-on] Error while including Taggable::Cache: #{e.class}: #{e.message}"
  end
end
