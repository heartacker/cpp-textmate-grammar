def regex_to_s(regex)
    as_string = regex.to_s
    # if it is the default settings (AKA -mix) then remove it
    if (as_string.size > 6) and (as_string[0..5] == '(?-mix')
        return regex.inspect[1..-2]
    else 
        return as_string
    end
end

class Pattern
    @regex
    @type
    @arguments
    @next_regex
    attr_accessor :next_regex

    def initialize(*arguments)
        arg1 = arguments[0]
        # if only a pattern, set attributes to {}
        if arg1.instance_of? Regexp
            @regex = arg1
            @arguments = {}
        # if its a Hash then extract the regex, and use the rest of the hash as the attributes
        elsif arg1.instance_of? Hash
            @regex = arg1[:match]
            @arguments = arg1.clone
            @arguments.delete(:match)
        end
    end
    def name
        if @arguments[:reference] != nil
            return @arguments[:reference]
        elsif @arguments[:tag_as] != nil
            return @arguments[:tag_as]
        end
        self.to_s
    end
    def to_tag
        regex_as_string = regex_to_s(self.to_r)
        output = {
            match: regex_as_string,
            captures: self.captures,
        }
        if @arguments[:tag_as] != nil
            # optimize captures be removing outermost
            regex_as_string = regex_as_string[1..-2]
            output[:name] = @arguments[:tag_as]
        end
        # fixup matchResultOf and recursivelyMatch
        # for each of the keys in output[:captures] replace $match and $reference() with
        # the appropriate number
        output
    end
    def to_s(top_level = true)
        output = top_level ? "Pattern.new(" : ".then("
        output += "\n  match: " + ((@regex.is_a? Pattern) ? @regex.to_s : @regex.inspect)
        output += ",\n  tag_as: " + @arguments[:tag_as] if @arguments[:tag_as] != nil
        output += ",\n  reference: " + @arguments[:reference] if @arguments[:reference] != nil
        output += ",\n)"
        output += @next_regex.to_s(false) if @next_regex != nil
        return output
    end
    def to_r
        self_regex = regex_to_s((@regex.is_a? Pattern) ? @regex.to_r : @regex)
        if @arguments[:tag_as] != nil
            self_regex = "(#{self_regex})"
        end
        if next_regex == nil
            return /#{self_regex}/
        end
        /#{self_regex}(?:#{regex_to_s(next_regex.to_r)})/
    end
    def start_pattern
        self
    end
    def then(pattern)
        pattern = Pattern.new(pattern) unless pattern.is_a? Pattern
        last = self
        last = last.next_regex while last.next_regex != nil
        last.next_regex = pattern
        self
    end
    def captures
    end
end

test = Pattern.new(
    match: /abc/,
    tag_as: "abc",
    reference: "abc"
).then(/def/)

puts "regex:"
puts test.to_r.inspect
puts "\ntag:"
puts test.to_tag
puts "\nname:"
puts test.name
puts "\ncanonical form:"
puts test