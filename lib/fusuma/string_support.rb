# frozen_string_literal: true

# support camerize and underscore
class String
  def camelize
    split("_").map(&:capitalize).join
  end

  #: () -> String
  def underscore
    gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
      .gsub("::", "/")
      .tr("-", "_")
      .downcase
  end
end
