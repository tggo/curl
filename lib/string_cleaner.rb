# encoding: UTF-8
require "unidecoder"

module String::Cleaner

  def clean
    fix_encoding.fix_endlines.fix_invisible_chars
  end

  def fix_encoding
    utf8 = dup
    if utf8.respond_to?(:force_encoding)
      utf8.force_encoding("UTF-8") # for Ruby 1.9+
      unless utf8.valid_encoding? # if invalid UTF-8
        utf8 = utf8.force_encoding("ISO8859-1")
        utf8.encode!("UTF-8", :invalid => :replace, :undef => :replace, :replace => "")
      end
      utf8.gsub!(/\u0080|¤/, "€") # special case for euro sign from Windows-1252
      utf8
    else
      require "iconv"
      utf8 << " "
      begin
        Iconv.new("UTF-8", "UTF-8").iconv(utf8)
      rescue
        utf8.gsub!(/\x80/n, "\xA4")
        Iconv.new("UTF-8//IGNORE", "ISO8859-1").iconv(utf8).gsub("¤", "€")
      end
    end
  end

  def fix_endlines
    gsub(/(?:\r\n|\r)/u, "\n")
  end
  
  SPECIAL_SPACES = [
    0x00A0,                # NO-BREAK SPACE
    0x1680,                # OGHAM SPACE MARK
    0x180E,                # MONGOLIAN VOWEL SEPARATOR
    (0x2000..0x200A).to_a, # EN QUAD..HAIR SPACE
    0x2028,                # LINE SEPARATOR
    0x2029,                # PARAGRAPH SEPARATOR
    0x202F,                # NARROW NO-BREAK SPACE
    0x205F,                # MEDIUM MATHEMATICAL SPACE
    0x3000,                # IDEOGRAPHIC SPACE
  ].flatten.collect{|e| [e].pack 'U*'}

  ZERO_WIDTH = [
    0x200B,                # ZERO WIDTH SPACE
    0x200C,                # ZERO WIDTH NON-JOINER
    0x200D,                # ZERO WIDTH JOINER
    0x2060,                # WORD JOINER
    0xFEFF,                # ZERO WIDTH NO-BREAK SPACE
  ].flatten.collect{|e| [e].pack 'U*'}

  def fix_invisible_chars
    utf8 = self.dup
    utf8.gsub!(Regexp.new(ZERO_WIDTH.join("|")), "")
    utf8 = if utf8.respond_to?(:force_encoding)
      utf8 = (utf8 << " ").split(/\n/u).each{|line|
        line.gsub!(/[\s\p{C}]/u, " ")
      }.join("\n").chop!
    else
      require "oniguruma"
      utf8.split(/\n/n).collect{|line|
        Oniguruma::ORegexp.new("[\\p{C}]", {:encoding => Oniguruma::ENCODING_UTF8}).gsub(line, " ")
      }.join("\n").chop!
    end
    utf8.gsub!(Regexp.new(SPECIAL_SPACES.join("|") + "|\s"), " ")
    utf8
  end

  def trim(chars = "")
    chars.size>0 ? gsub(/\A[#{chars}]+|[#{chars}]+\z/, "") : strip
  end

  def to_permalink(separator="-")
    clean.to_ascii(chartable).downcase.gsub(/[^a-z0-9]+/, separator).trim(separator)
  end

  def nl2br
    gsub("\n", "<br/>\n")
  end
  
  def to_nicer_sym
    to_permalink("_").to_sym
  end

  def chartable(options = {})
    options = {
      :clean_binary => true,
      :translit_symbols => true,
    }.merge(options)
    char = "%c"
    table = {
      "`" => "'",  # dec = 96
      "¦" => "|",  # dec = 166, broken vertical bar
      "¨" => "",   # dec = 168, spacing diaeresis - umlaut
      "ª" => "",   # dec = 170, feminine ordinal indicator
      "«" => "\"", # dec = 171, left double angle quotes
      "¬" => "!",  # dec = 172, not sign
      "­" => "-",  # dec = 173, soft hyphen
      "¯" => "-",  # dec = 175, spacing macron - overline
      "²" => "2",  # dec = 178, superscript two - squared
      "³" => "3",  # dec = 179, superscript three - cubed
      "´" => "'",  # dec = 180, acute accent - spacing acute
      "·" => "",   # dec = 183, middle dot - Georgian comma
      "¸" => "",   # dec = 184, spacing cedilla
      "¹" => "1",  # dec = 185, superscript one
      "º" => "0",  # dec = 186, masculine ordinal indicator
      "»" => "\"", # dec = 187, right double angle quotes
      "¿" => "",   # dec = 191, inverted question mark
      "Ý" => "Y",  # dec = 221
      "–" => "-",  # hex = 2013, en dash
      "—" => "-",  # hex = 2014, em dash
      "‚" => "'",  # hex = 201A, single low-9 quotation mark
      "„" => "\"", # hex = 201E, double low-9 quotation mark
    }
    if options[:clean_binary]
      table[char %   0] = ""  # null
      table[char %   1] = ""  # start of heading
      table[char %   2] = ""  # start of text
      table[char %   3] = ""  # end of text
      table[char %   4] = ""  # end of transmission
      table[char %   5] = ""  # enquiry
      table[char %   6] = ""  # acknowledge
      table[char %   7] = ""  # bell
      table[char %   8] = ""  # backspace
      table[char %   9] = " " # tab
      table[char %  11] = ""  # vertical tab
      table[char %  12] = ""  # form feed
      table[char %  14] = ""  # shift out
      table[char %  15] = ""  # shift in
      table[char %  16] = ""  # data link escape
      table[char %  17] = ""  # device control 1
      table[char %  18] = ""  # device control 2
      table[char %  19] = ""  # device control 3
      table[char %  20] = ""  # device control 4
      table[char %  21] = ""  # negative acknowledgement
      table[char %  22] = ""  # synchronous idle
      table[char %  23] = ""  # end of transmission block
      table[char %  24] = ""  # cancel
      table[char %  25] = ""  # end of medium
      table[char %  26] = ""  # substitute
      table[char %  27] = ""  # escape
      table[char %  28] = ""  # file separator
      table[char %  29] = ""  # group separator
      table[char %  30] = ""  # record separator
      table[char %  31] = ""  # unit separator
      table[char % 127] = ""  # delete
    end
    if options[:translit_symbols]
      table["$"]        = " dollars "              # dec = 36, dollar sign
      table["%"]        = " percent "              # dec = 37, percent sign
      table["&"]        = " and "                  # dec = 38, ampersand
      table["@"]        = " at "                   # dec = 64, at symbol
      table[char % 128] = " euros "                # windows euro
      table["¢"]        = " cents "                # dec = 162, cent sign
      table["£"]        = " pounds "               # dec = 163, pound sign
      table["¤"]        = " euros "                # dec = 164, currency sign
      table["¥"]        = " yens "                 # dec = 165, yen sign
      table["§"]        = " section "              # dec = 167, section sign
      table["©"]        = " copyright "            # dec = 169, copyright sign
      table["®"]        = " registered trademark " # dec = 174, registered trade mark sign
      table["°"]        = " degrees "              # dec = 176, degree sign
      table["±"]        = " approx "               # dec = 177, plus-or-minus sign
      table["µ"]        = " micro "                # dec = 181, micro sign
      table["¶"]        = " paragraph "            # dec = 182, pilcrow sign - paragraph sign
      table["¼"]        = " 1/4 "                  # dec = 188, fraction one quarter
      table["½"]        = " 1/2 "                  # dec = 189, fraction one half
      table["¾"]        = " 3/4 "                  # dec = 190, fraction three quarters
      table["€"]        = " euros "                # hex = 20AC, unicode euro
      table["™"]        = " trademark "            # hex = 2122, trade mark
    end
    table
  end

end
class String
  include String::Cleaner
end
