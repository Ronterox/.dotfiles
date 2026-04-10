-- Chord registry module for opencode-mm Mastermind mode
-- Manages registered chords for command expansion

local M = {}

--- Ordered list of registered chords: { key, text, has_arg, description }
M.chords = {}

--- Build chord registry from configuration
-- @param config table Configuration with chords and parametric_chords
M.setup = function(config)
  if not config or not config.chords then
    return
  end

  -- Add basic chords
  for key, text in pairs(config.chords) do
    M.register(key, text, false)
  end

  -- Add parametric chords
  if config.parametric_chords then
    for key, text in pairs(config.parametric_chords) do
      M.register(key, text, true)
    end
  end
end

--- Register or update a chord
-- @param key string Chord key
-- @param text string Text to display
-- @param has_arg boolean Whether chord requires an argument
M.register = function(key, text, has_arg)
  local index = M._find_index(key)
  if index then
    M.chords[index].text = text
    M.chords[index].has_arg = has_arg
    return
  end

  table.insert(M.chords, { key = key, text = text, has_arg = has_arg })
end

--- Remove a registered chord
-- @param key string Chord key to remove
M.unregister = function(key)
  local index = M._find_index(key)
  if index then
    table.remove(M.chords, index)
  end
end

--- Find chord index by key
-- @param key string Chord key
-- @return number|nil Index in chords table or nil if not found
M._find_index = function(key)
  for i, chord in ipairs(M.chords) do
    if chord.key == key then
      return i
    end
  end
  return nil
end

--- Expand chord text with argument
-- @param key string Chord key
-- @param arg_buffer string Argument string
-- @return string Expanded text with argument placeholder replaced
M.expand = function(key, arg_buffer)
  local index = M._find_index(key)
  if not index then
    return ""
  end

  local text = M.chords[index].text
  local has_arg = M.chords[index].has_arg

  if not has_arg then
    return text
  end

  return text:gsub("$arg", arg_buffer or "")
end

--- Get all chords sorted alphabetically for hint display
-- @return table Sorted list of all chords
M.get_all = function()
  local sorted = {}
  for _, chord in ipairs(M.chords) do
    table.insert(sorted, chord)
  end
  table.sort(sorted, function(a, b) return a.key < b.key end)
  return sorted
end

--- Check if key is a registered chord
-- @param key string Chord key
-- @return boolean True if chord exists
M.is_chord = function(key)
  return M._find_index(key) ~= nil
end

--- Check if chord has argument parameter
-- @param key string Chord key
-- @return boolean True if chord has_arg set
M.is_parametric = function(key)
  local index = M._find_index(key)
  if not index then
    return false
  end
  return M.chords[index].has_arg
end

return M
