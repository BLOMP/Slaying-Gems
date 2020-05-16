-- general.lua

DEBUG = "test"
DEBUGX = 1
DEBUGY = 1

-- Helpers

function default(val, default_val)
  if val == nil then
      return default_val
  else
      return val
  end
end

function print2(str, x, y, color, shadow)
  local str = tostring(str)
  local x = default(x, 0)
  local y = default(y, 0)
  local color = default(color, 7) -- White
  local shadow = default(shadow, true)
  
  for i = 1, #str do
    local ch = ord(sub(str,i,i))
    if (ch > 96) ch -= 32
    -- Draw shadow
    if shadow then
      pal(7,0)
      spr(ch + 32, x + (i*8) + 1, y + 1)
    end
    -- Draw character
    pal(7,color)
    spr(ch + 32, x + (i*8), y)
    pal()
    --print(str, x, y+64)
    --print(ch, x + (i * 8), y+8)
  end
end

function rect2(x, y, w, h, col)
  col = default(col, 7)
  rect(x, y, x+w, y+h, col)
  pal()
end