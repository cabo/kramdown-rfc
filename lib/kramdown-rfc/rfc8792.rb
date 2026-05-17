
# Note that this doesn't attempt to handle HT characters
def remove_indentation(s)
  l = s.lines
  indent = l.grep(/\S/).map {|l| l[/^\s*/].size}.min
  l.map {|li| li.sub(/^ {0,#{indent}}/, "")}.join
end

def trim_empty_lines_around(s)  # this deletes the trailing newline, which may need to be reconstructed
  s.sub(/\A(\r?\n)*/, '').sub(/(\r?\n)*\z/, '')
end

def fix_unterminated_line(s)
  s.sub(/[^\n]\z/) { "#$&\n" } # XXX
end

def handle_artwork_sourcecode(s, unfold = true)
  s = trim_empty_lines_around(s)
  s = unfold8792(s) if unfold
  fix_unterminated_line(s)
end

FOLD_MSG = "NOTE: '\\' line wrapping per RFC 8792".freeze
UNFOLD_RE = /\A.*#{FOLD_MSG.sub("\\", "(\\\\\\\\\\\\\\\\?)")}.*\n\r?\n/
FOLD8792_PROC_RE = /\Afold(?<columns>\d*)(?<hard>hard)?(?:(?<indent_type>left|smart)(?<spaces>\d*))?(?<dry>dry)?\z/

def fold8792_options(md)
  indent_type = md[:indent_type].to_sym if md[:indent_type]
  [md[:columns].to_i, indent_type, (md[:spaces] || 0).to_i, md[:dry], md[:hard]]
end

def unfold8792(s)
  if s =~ UNFOLD_RE
    indicator = $1
    s = $'
    sub = case indicator
          when "\\"
            s.gsub!(/\\\n[ \t]*/, '')
          when "\\\\"
            s.gsub!(/\\\n[ \t]*\\/, '')
          else
            fail "indicator"    # Cannot happen
          end
    warn "** encountered RFC 8792 header without folded lines" unless sub
  end
  s
end

MIN_FOLD_COLUMNS = FOLD_MSG.size
FOLD_COLUMNS = 69
RE_IDENT = /\A[A-Za-z0-9_]\z/

def fold8792_1(s, columns = FOLD_COLUMNS, indent_type = nil, indent_spaces = 0, dry = false, hard = false)
  if s.index("\t")
    warn "*** HT (\"TAB\") in text to be folded. Giving up."
    return s
  end
  if columns < MIN_FOLD_COLUMNS
    columns =
      if columns == 0
        FOLD_COLUMNS
      else
        warn "*** folding to #{MIN_FOLD_COLUMNS}, not #{columns}"
        MIN_FOLD_COLUMNS
      end
  end

  lines = s.lines.map(&:chomp)
  did_fold = false
  smart_indent = nil
  ix = 0
  while li = lines[ix]
    col = columns
    if li[col].nil?
      if li[-1] == "\\"
        lines[ix..ix] = [li << "\\", ""]
        ix += 1
      end
      smart_indent = nil
      ix += 1
    else
      did_fold = true
      left_indent =
        case indent_type
        when :left
          indent_spaces
        when :smart
          smart_indent ||= li[/\A */].size + indent_spaces
        end
      min_indent = left_indent || 0
      col -= 1                  # space for "\\"
      while li[col] == " "      # can't start new line with " "
        col -= 1
      end
      if col <= min_indent
        indent_msg = "with indent #{min_indent}" if indent_type
        warn "*** Cannot RFC8792-fold1 to #{columns} cols #{indent_msg}  |#{li.inspect}|"
        smart_indent = nil
      else
        if !hard && RE_IDENT === li[col] # Don't split IDs
          col2 = col
          while col2 > min_indent && RE_IDENT === li[col2-1]
            col2 -= 1
          end
          if col2 > min_indent
            col = col2
          end
        end
        rest = li[col..-1]
        indent = left_indent || columns - rest.size
        if !left_indent && li[-1] == "\\"
          indent -= 1           # leave space for next round
        end
        if indent > 0
         rest = " " * indent + rest
        end
        lines[ix..ix] = [li[0...col] << "\\", rest]
      end
      ix += 1
    end
  end

  if did_fold
    msg = FOLD_MSG.dup
    if !dry && columns >= msg.size + 4
      delta = columns - msg.size - 2 # 2 spaces
      half = delta/2
      msg = "#{"=" * half} #{msg} #{"=" * (delta - half)}"
    end
    lines[0...0] = [msg, ""]
    lines.map{|x| x << "\n"}.join
  else
    s
  end
end
