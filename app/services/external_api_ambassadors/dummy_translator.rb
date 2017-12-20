# Implements the same methods as google translator, but doesn't really translate
# anything -- meaning it's free to use. Good for testing.
class DummyTranslator
  
  attr_accessor :target_lang, :source_lang
  
  def initialize(opts={})
    @target_lang = opts[:target] || opts[:target_lang] || opts[:to] || "es"
    @source_lang = opts[:source] || opts[:source_lang] || opts[:from] || "en"
  end

  # Translates the given query q from the source language to the target language
  def translate q, target=@target_lang, source=@source_lang
    return "[#{source}->#{target}]#{q.to_s}"
  end
  
  # Sets the source language, and returns self so method can be chained
  def from(lang)
    @source_lang = lang
    return self
  end
  
  # Sets the target language, and returns self so method can be chained
  def to(lang)
    @target_lang = lang
    return self
  end

end
