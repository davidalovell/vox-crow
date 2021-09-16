--- Vox

-- scales
-- DL, last modified 2021-09-12

-- modes
ionian = {0,2,4,5,7,9,11}
dorian = {0,2,3,5,7,9,10}
phrygian = {0,1,3,5,7,8,10}
lydian = {0,2,4,6,7,9,11}
mixolydian = {0,2,4,5,7,9,10}
aeolian = {0,2,3,5,7,8,10}
locrian = {0,1,3,5,6,8,10}

-- other scales
chromatic = {0,1,2,3,4,5,6,7,8,9,10,11}
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
  o.mask = args.mask == nil and nil or args.mask
  o.transpose = args.transpose == nil and 0 or args.transpose
  o.degree = args.degree == nil and 1 or args.degree
  o.wrap = args.wrap == nil and false or args.wrap
  o.octave = args.octave == nil and 0 or args.octave
  o.negharm = args.negharm == nil and false or args.negharm
  o.synth = args.synth == nil and function(note, level) --[[ii.jf.play_note(note / 12, level)]] return note, level end or args.synth

  o.seq = args.seq == nil and {} or args.seq

  return o
end

function Vox:set(args)
  local args = args == nil and {} or args

  self.on = args.on == nil and self.on or args.on
  self.level = args.level == nil and self.level or args.level
  self.scale = args.scale == nil and self.scale or args.scale
  self.mask = args.mask == nil and self.mask or args.mask
  self.transpose = args.transpose == nil and self.transpose or args.transpose
  self.degree = args.degree == nil and self.degree or args.degree
  self.wrap = args.wrap == nil and self.wrap or args.wrap
  self.octave = args.octave == nil and self.octave or args.octave
  self.negharm = args.negharm == nil and self.negharm or args.negharm
  self.synth = args.synth == nil and self.synth or args.synth

  self.seq = args.seq == nil and {} or args.seq
end

function Vox:play(args)
  local args = args == nil and {} or args

  args.on = self.on and (args.on == nil and true or args.on)
  args.level = self.level * (args.level == nil and 1 or args.level)
  args.scale = (args.scale == nil and self.scale or args.scale)
  args.mask = (args.mask == nil and self.mask or args.mask)
  args.transpose = self.transpose + (args.transpose == nil and 0 or args.transpose)
  args.degree = (self.degree - 1) + ((args.degree == nil and 1 or args.degree) - 1)
  args.wrap = (args.wrap == nil and self.wrap or args.wrap) and 0 or math.floor(args.degree / #args.scale)
  args.octave = self.octave + (args.octave == nil and 0 or args.octave) + args.wrap
  args.negharm = (args.negharm == nil and self.negharm or args.negharm)
  args.synth = (args.synth == nil and self.synth or args.synth)

  args.ix = args.degree % #args.scale + 1
  args.round_to_octave = 0

  if args.mask then
    local closest_val, lowest_val = args.mask[1], args.mask[1]

    for k, v in ipairs(args.mask) do
      v = (v - 1) % #args.scale + 1
      closest_val = math.abs(v - args.ix) < math.abs(closest_val - args.ix) and v or closest_val
      lowest_val = v < lowest_val and v or lowest_val
    end

    local highest_val = lowest_val + #args.scale
    closest_val = math.abs(highest_val - args.ix) < math.abs(closest_val - args.ix) and highest_val or closest_val

    args.ix = (closest_val - 1) % #args.scale + 1
    args.round_to_octave = math.floor(closest_val / #args.scale)
  end
  print(args.round_to_octave)

  args.val = args.scale[args.ix]
  args.pos = args.val
  args.neg = (7 - args.val) % 12
  args.final = args.negharm and args.neg or args.pos
  args.note = args.final + args.transpose + (args.octave * 12) + (args.round_to_octave * 12)

  return args.on and args.synth(args.note, args.level)
end
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
