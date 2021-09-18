--- Vox

-- scales
-- DL, last modified 2021-09-12

-- modes
ionian = {0,2,4,5,7,9,11}
dorian = {0,2,3,5,7,9,10} -- flat 3rd, flat 7th
phrygian = {0,1,3,5,7,8,10} -- flat 2nd, flat 6th
lydian = {0,2,4,6,7,9,11} -- sharp 4th
mixolydian = {0,2,4,5,7,9,10} -- flat 7th
aeolian = {0,2,3,5,7,8,10} -- flat 3rd, flat 6th, flat 7th
locrian = {0,1,3,5,6,8,10} -- flat 2nd, flat 5th, flat 6th, flat 7th

-- other scales
chromatic = {0,1,2,3,4,5,6,7,8,9,10,11}
harmoninc_min = {0,2,3,5,7,8,11} -- aeolian, sharp 7th
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

-- pentatonic scales
penta_maj = mask(ionian, {1,2,3,5,6})
penta_sus = mask(dorian, {1,2,4,5,7})
blues_min = mask(phrygian, {1,3,4,6,7})
blues_maj = mask(mixolydian, {1,2,4,5,6})
penta_min = mask(aeolian, {1,3,4,5,7})
japanese = mask(phrygian, {1,2,4,5,6})
--




-- divisions
divs = {1/32, 1/16, 1/8, 1/4, 1/2, 1, 2, 4, 8, 16, 32}
--





-- initial values
cv = {
  scale = mixolydian,
  octave = 0,
  degree = 1
}
--




-- Vox object
-- DL, last modified 2021-09-13

Vox = {}
function Vox:new(args)
  local o = setmetatable( {}, {__index = Vox} )
  local args = args == nil and {} or args

  o.on = args.on == nil and true or args.on
  o.level = args.level == nil and 1 or args.level
  o.scale = args.scale == nil and cv.scale or args.scale
  o.transpose = args.transpose == nil and 0 or args.transpose
  o.degree = args.degree == nil and 1 or args.degree
  o.octave = args.octave == nil and 0 or args.octave
  o.synth = args.synth == nil and function(note, level) --[[ii.jf.play_note(note / 12, level)]] return note, level end or args.synth

  o.mask = args.mask
  o.wrap = args.wrap ~= nil and args.wrap or false
  o.negharm = args.negharm ~= nil and args.negharm or false

  o.seq = args.seq == nil and {} or args.seq

  return o
end

function Vox:set(args)
  local args = args == nil and {} or args

  self.on = args.on == nil and self.on or args.on
  self.level = args.level == nil and self.level or args.level
  self.scale = args.scale == nil and self.scale or args.scale
  self.transpose = args.transpose == nil and self.transpose or args.transpose
  self.degree = args.degree == nil and self.degree or args.degree
  self.octave = args.octave == nil and self.octave or args.octave
  self.synth = args.synth == nil and self.synth or args.synth

  self.mask = args.mask == nil and self.mask or args.mask
  self.wrap = args.wrap == nil and self.wrap or args.wrap
  self.negharm = args.negharm == nil and self.negharm or args.negharm

  self.seq = args.seq == nil and {} or args.seq
end

function Vox:play(args)
  local args = args == nil and {} or args
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

  ix = degree % #scale + 1
  if mask then ix, octave = self.apply_mask(ix, octave, scale, mask) end
  if not wrap then octave = self.apply_wrap(degree, octave, scale) end
  val = scale[ix]
  if negharm then val = self.apply_negharm(val) end
  note = val + transpose + (octave * 12)
  return on and synth(note, level)
end

function Vox.apply_mask(ix, octave, scale, mask)
  mask[#mask + 1] = mask[1] + #scale
  local closest_val = mask[1]

  for _, val in ipairs(mask) do
    closest_val = math.abs(val - ix) < math.abs(closest_val - ix) and val or closest_val
  end

  local ix, octave = (closest_val - 1) % #scale + 1, octave + math.floor((closest_val - 1) / #scale)
  return ix, octave
end

function Vox.apply_wrap(degree, octave, scale) return octave + math.floor(degree / #scale) end
function Vox.apply_negharm(val) return (7 - val) % 12 end
--




-- functions for mulitple Vox objects
function _set(objects, property, val)
  for k, v in pairs(objects) do
    v[property] = val
  end
end

function _do(objects, method, args)
  for k, v in pairs(objects) do
    v[method](v, args)
  end
end
--




-- helper functions
function clamp(x, min, max)
  return math.min( math.max( min, x ), max )
end

function round(x)
  return x % 1 >= 0.5 and math.ceil(x) or math.floor(x)
end

function linlin(x, in_min, in_max, out_min, out_max)
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

function selector(x, data, in_min, in_max, out_min, out_max)
  out_min = out_min or 1
  out_max = out_max or #data
  return data[ clamp( round( linlin( x, in_min, in_max, out_min, out_max ) ), out_min, out_max ) ]
end
