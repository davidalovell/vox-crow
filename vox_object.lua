--- Vox Object for Crow/JF
-- @davidlovell



-- SCALES, useful with Vox object but not required
-- modes
ionian = {0,2,4,5,7,9,11}
dorian = {0,2,3,5,7,9,10} -- 1, 2, b3, 4, 5, 6, b7
phrygian = {0,1,3,5,7,8,10} -- 1, b2, 3, 4, 5, b6, 7
lydian = {0,2,4,6,7,9,11} -- 1, 2, 3, #4, 5, 6, 7
mixolydian = {0,2,4,5,7,9,10} -- 1, 2, 3, 4, 5, 6, b7
aeolian = {0,2,3,5,7,8,10} -- 1, 2, b3, 4, 5, b6, b7
locrian = {0,1,3,5,6,8,10} -- 1, b2, b3, 4, b5, b6, b7

-- other
chromatic = {0,1,2,3,4,5,6,7,8,9,10,11}
harmoninc_min = {0,2,3,5,7,8,11} -- 1, 2, b3, 4, 5, b6, 7
diminished = {0,2,3,5,6,8,9,11}
whole = {0,2,4,6,8,10}

-- scale mask function
function mask(scale, degrees)
  local m = {}
  for k, v in ipairs(degrees) do
    m[k] = scale[v]
  end
  return m
end

-- derived pentatonic scales (using mask function)
penta_maj = mask(ionian, {1,2,3,5,6})
penta_sus = mask(dorian, {1,2,4,5,7})
blues_min = mask(phrygian, {1,3,4,6,7})
blues_maj = mask(mixolydian, {1,2,4,5,6})
penta_min = mask(aeolian, {1,3,4,5,7})
japanese = mask(phrygian, {1,2,4,5,6})

-- diatonic triads
I = {1,3,5}
II = {2,4,6}
III = {3,5,7}
IV = {4,6,8}
V = {5,7,9}
VI = {6,8,10}
VII = {7,9,11}



-- VOX OBJECT
ii.jf.mode(1) -- prerequisite for Vox object when used with JF (its current form)

Vox = {}
function Vox:new(args) -- constructor, table as args
  local o = setmetatable( {}, {__index = Vox} )
  local args = args == nil and {} or args

  o.on = args.on == nil and true or args.on
  o.level = args.level == nil and 1 or args.level
  o.scale = args.scale == nil and {0,2,4,6,7,9,11} or args.scale -- lydian by default
  o.transpose = args.transpose == nil and 0 or args.transpose
  o.degree = args.degree == nil and 1 or args.degree -- 1 based
  o.octave = args.octave == nil and 0 or args.octave
  o.synth = args.synth == nil and function(note, level) ii.jf.play_note(note / 12, level) end or args.synth -- sends notes to JF by default, volts = note / 12
  o.wrap = args.wrap ~= nil and args.wrap or false
  o.mask = args.mask
  o.negharm = args.negharm ~= nil and args.negharm or false
  
  -- empty tables for use with sequins
  o.seq = args.seq == nil and {} or args.seq
  o.clk = args.clk == nil and {} or args.clk

  return o
end

function Vox:play(args) -- play method, table as args (or pass a table of functions, see Vox.update)
  local args = args == nil and {} or self.update(args)
  local on, level, scale, transpose, degree, octave, synth, mask, wrap, negharm, ix, val, note

  on = self.on and (args.on == nil and true or args.on)
  level = self.level * (args.level == nil and 1 or args.level)
  scale = args.scale == nil and self.scale or args.scale
  transpose = self.transpose + (args.transpose == nil and 0 or args.transpose)
  degree = (self.degree - 1) + ((args.degree == nil and 1 or args.degree) - 1)
  octave = self.octave + (args.octave == nil and 0 or args.octave)
  synth = args.synth == nil and self.synth or args.synth
  wrap = args.wrap == nil and self.wrap or args.wrap
  mask = args.mask == nil and self.mask or args.mask
  negharm = args.negharm == nil and self.negharm or args.negharm

  octave = wrap and octave or octave + math.floor(degree / #scale)
  ix = mask and self.apply_mask(degree, scale, mask) % #scale + 1 or degree % #scale + 1
  val = negharm and (7 - scale[ix]) % 12 or scale[ix]
  note = val + transpose + (octave * 12)

  return on and synth(note, level)
end

function Vox.update(data) -- takes a table of functions and returns a table with the results of these functions as static values
  local updated = {}
  for k, v in pairs(data) do
    updated[k] = type(v) == 'function' and data[k]() or data[k]
  end
  return updated
end

function Vox.apply_mask(degree, scale, mask) -- currently does not round up if nearest value is in the next octave, any ideas?
  local ix, closest_val = degree % #scale + 1, mask[1]
  for _, val in ipairs(mask) do
    val = (val - 1) % #scale + 1
    closest_val = math.abs(val - ix) < math.abs(closest_val - ix) and val or closest_val
  end
  local degree = closest_val - 1
  return degree
end

function Vox.set(objects, property, val) -- set properties of multiple Vox objects
  for k, v in pairs(objects) do
    v[property] = val
  end
end

function Vox.call(objects, method, args) -- call methods of multiple Vox objects
  for k, v in pairs(objects) do
    v[method](v, args)
  end
end



-- YOUR CODE BELOW HERE
