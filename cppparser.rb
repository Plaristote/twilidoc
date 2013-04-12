module CppParser
  def self.handle_skip code_sample, i
    skipping_seqs   = [
       { beg: '"',  end: '"',  can_escape: true  },
       { beg: "'",  end: "'",  can_escape: true  },
       { beg: '/*', end: '*/', can_escape: false },
       { beg: '//', end: "\n", can_escape: false }
     ]
     skipping_seqs.each do |skipping_seq|
       if code_sample[i...(i + skipping_seq[:beg].size)] == skipping_seq[:beg]
         skip     = skipping_seq
         i       += skipping_seq[:beg].size + 1
         left     = code_sample[(i - 1)...code_sample.size]
         left.scan skipping_seq[:end] do
           offset = $~.offset 0
           next if skipping_seq[:can_escape] == true and left[offset[0] - 1] == '\\' # that part isn't reliable enough
           i     += offset[1] - 2
           break
         end
       end
     end
     i
  end

  def self.get_block code_sample
    i               = 0
    opened_brackets = 0
    found_first     = -1
    while i < code_sample.size

      # Looking for skipping sequences
      i = handle_skip code_sample, i
      # Looking for brackets and counting them
      if code_sample[i] == '{'
        opened_brackets += 1
        found_first      = i + 1 if found_first == -1
      elsif code_sample[i] == '}'
        opened_brackets -= 1
        break if opened_brackets == 0
      end
      i               += 1
    end
    code_sample[found_first...i]
  end

  def self.attribute_from_type words, i = 0
    attribute = SexyDoc::Attribute.new
    words.each do |type_spec|
      case type_spec
      when 'unsigned'
        attribute.attrs |= SexyDoc::ATTR_UNSIGNED
      when 'const'
        attribute.attrs |= SexyDoc::ATTR_CONST
      when 'static'
        attribute.attrs |= SexyDoc::ATTR_STATIC
      when 'virtual', 'inline', 'typename'
        nil
      when 'return', 'new', 'delete', 'friend', 'class', 'struct', 'union', 'typedef', 'ifdef', 'ifndef', 'if', 'else', 'enum'
        return nil
      else
        last_char = type_spec[type_spec.size - 1]
        if last_char == '*' or last_char == '&'
          type_spec = type_spec[0...type_spec.size - 1]
          if i == 0
            if last_char == '*'
              attribute.attrs |= SexyDoc::ATTR_PTR
            elsif last_char == '&'
              attribute.attrs |= SexyDoc::ATTR_REF
            end
          end
        end
        if attribute.type.nil?
          attribute.type   = type_spec
        elsif type_spec != ''
          throw "Attempted to replace #{attribute.type} with #{type_spec} (#{type_spec.class.name})"
        end
      end
    end
    attribute
  end
end

