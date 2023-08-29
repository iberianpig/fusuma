# frozen_string_literal: true

# Patch to hash
class Hash
  # activesupport-5.2.0/lib/active_support/core_ext/hash/deep_merge.rb
  def deep_merge(other_hash, &block)
    dup.deep_merge!(other_hash, &block)
  end

  # Same as +deep_merge+, but modifies +self+.
  def deep_merge!(other_hash, &block)
    merge!(other_hash) do |key, this_val, other_val|
      if this_val.is_a?(Hash) && other_val.is_a?(Hash)
        this_val.deep_merge(other_val, &block)
      elsif block
        block.call(key, this_val, other_val)
      else
        other_val
      end
    end
  end

  def deep_stringify_keys
    deep_transform_keys(&:to_s)
  end

  # activesupport-4.1.1/lib/active_support/core_ext/hash/keys.rb
  def deep_symbolize_keys
    deep_transform_keys do |key|
      key.to_sym
    rescue
      key
    end
  end

  def deep_transform_keys(&block)
    result = {}
    each do |key, value|
      result[yield(key)] = value.is_a?(Hash) ? value.deep_transform_keys(&block) : value
    end
    result
  end

  # activesupport/lib/active_support/core_ext/hash/deep_transform_values.rb
  def deep_transform_values(&block)
    _deep_transform_values_in_object(self, &block)
  end

  private

  # Support methods for deep transforming nested hashes and arrays.
  def _deep_transform_values_in_object(object, &block)
    case object
    when Hash
      object.transform_values { |value| _deep_transform_values_in_object(value, &block) }
    when Array
      object.map { |e| _deep_transform_values_in_object(e, &block) }
    else
      yield(object)
    end
  end
end
