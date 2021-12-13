FOLD_COLUMNS = 69
RE_IDENT = /\A[A-Za-z0-9_]\z/

def fold8792_1(s, columns = FOLD_COLUMNS)
  if s.index("\t")
    warn "*** HT (\"TAB\") in text to be folded. Giving up."
    return s
  end

  lines = s.lines.map(&:chomp)
  did_fold = false
  ix = 0
  while li = lines[ix]
    col = columns
    if li[col].nil?
      if li[-1] == "\\"
        lines[ix..ix] = [li << "\\", ""]
        ix += 1
      end
      ix += 1
    else
      did_fold = true
      col -= 1                  # space for "\\"
      while li[col] == " "      # can't start new line with " "
        col -= 1
      end
      if col <= 0
        warn "*** Cannot RFC8792-fold1 #{li.inspect}"
      else
        if RE_IDENT === li[col] # Don't split IDs
          col2 = col
          while col2 > 0 && RE_IDENT === li[col2-1]
            col2 -= 1
          end
          if col2 > 0
            col = col2
          end
        end
        rest = li[col..-1]
        indent = columns - rest.size
        if li[-1] == "\\"
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
    lines[0...0] = ["=== NOTE: '\\' line wrapping per RFC 8792 ===", ""]
    lines.map{|x| x << "\n"}.join
  else
    s
  end
end
