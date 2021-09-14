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
  o.octave = args.octave == nil and 0 or args.octave
  o.degree = args.degree == nil and 1 or args.degree
  o.transpose = args.transpose == nil and 0 or args.transpose

  o.scale = args.scale == nil and cv.scale or args.scale
  o.mask = args.mask == nil and nil or args.mask
  o.wrap = args.wrap == nil and false or args.wrap
  o.negharm = args.negharm == nil and false or args.negharm

  o.synth = args.synth == nil and function(note, level) --[[ii.jf.play_note(note / 12, level)]] return note, level end or args.synth

  o.seq = args.seq == nil and {} or args.seq

  return o
end

function Vox:set(args)
  local args = args == nil and {} or args

  self.on = args.on == nil and self.on or args.on
  self.level = args.level == nil and self.level or args.level
  self.octave = args.octave == nil and self.octave or args.octave
  self.degree = args.degree == nil and self.degree or args.degree
  self.transpose = args.transpose == nil and self.transpose or args.transpose

  self.scale = args.scale == nil and self.scale or args.scale
  self.mask = args.mask == nil and self.mask or args.mask
  self.wrap = args.wrap == nil and self.wrap or args.wrap
  self.negharm = args.negharm == nil and self.negharm or args.negharm

  self.synth = args.synth == nil and self.synth or args.synth

  self.seq = args.seq == nil and {} or args.seq
end

function Vox:play(args)
  local args = args == nil and {} or args

  args.on = args.on == nil and true or args.on
  args.level = args.level == nil and 1 or args.level
  args.octave = args.octave == nil and 0 or args.octave
  args.degree = args.degree == nil and 1 or args.degree
  args.transpose = args.transpose == nil and 0 or args.transpose

  args.scale = args.scale == nil and self.scale or args.scale
  args.mask = args.mask == nil and self.mask or args.mask
  args.wrap = args.wrap == nil and self.wrap or args.wrap
  args.negharm = args.negharm == nil and self.negharm or args.negharm

  args.synth = args.synth == nil and self.synth or args.synth

  return self:_on(args) and args.synth(self:_note(args), self:_level(args))
end

function Vox:_on(args) return self.on and args.on end
function Vox:_transpose(args) return self.transpose + args.transpose end
function Vox:_degree(args) return (self.degree - 1) + (args.degree - 1) end
function Vox:_wrap(args) return args.wrap and 0 or math.floor(self:_degree(args) / #args.scale) end
function Vox:_octave(args) return self.octave + args.octave + self:_wrap(args) end

function Vox:_note(args)
  local ix = self:_degree(args) % #args.scale + 1
  local val = args.scale[ix] + self:_transpose(args)

  if args.mask then
    local a = selector(ix, args.mask, 1, #args.scale)
    print(a)
  end

  local pos = val
  local neg = (7 - pos) % 12

  return (args.negharm and neg or pos) + self:_octave(args) * 12
end

function Vox:_level(args) return self.level * args.level end

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
