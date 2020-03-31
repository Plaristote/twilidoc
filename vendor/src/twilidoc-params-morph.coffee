window.twilidoc_params_morph = (params) ->
  state  = 'typename'
  result = ""
  ii = 0
  while ii < params.length
    if state == 'typename'
      result += '['
      ii++ while ii == ' ' && ii < params.length
      i = ii
      authorized_words = ["const", "unsigned", "long"]
      while params[i] != ' ' && params[i] != ',' && i < params.length
        for word in authorized_words
          if params[i...i + word.length + 1] == word + ' '
            i += word.length
            continue
        if params[i] == '<'
          opened_count = 1
          i++
          while i < params.length
            opened_count += 1 if params[i] == '<'
            opened_count -= 1 if params[i] == '>'
            break if opened_count == 0
            i++
        if params[i] == '('
          opened_count = 1
          while i < params.length
            opened_count += 1 if params[i] == '('
            opened_count -= 1 if params[i] == ')'
            break if opened_count == 0
            i++
        i++
      part = params[ii...i]
      qualifiers = part.match /[&\*]$/
      if qualifiers == null
        result += part + ']'
      else
        result += part[...qualifiers.index] + ']' + qualifiers[0]
      # Looking for & or * attached to the varname instead of the typename
      if params[i] == ' '
        while i < params.length && (params[i] == ' ' || params[i] == '&' || params[i] == '$')
          result += params[i] if params[i] == '&' || params[i] == '$'
          i++
        result += ' '
      # If a coma is found right after the typename, next thing to parse is a typename
      if params[i] == ','
        state = 'typename'
      # Otherwise, next thing to parse is a varname
      else
        state = 'varname'
        i++ while params[i] == ' ' && i < params.length
      # Appending the last character and skipping it
      if params[i] == ',' || params[i] == ' '
        result += params[i]
        ii = i + 1
      else
        ii = i
      # Skipping all the spaces until the next sign
      ii++ while params[ii] == ' ' && ii < params.length
    else if state == 'varname'
      while ii < params.length && state == 'varname'
        if params[ii] != ','
          result += params[ii]
        else
          result += ','
          state = 'typename'
        ii++
      ii++ while params[ii] == ' ' && ii < params.length
    else
      console.warn "Failed to parse typename in", params
      break
  result = "[]" if result == ""
  result
