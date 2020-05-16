-- board.lua
board = {
  -- Top left position of board
  -- Starting with first rung
  x = 40, -- 5 * 8
  y = 72, -- 14 * 8
  -- Gem Width/Height
  gw = 6,
  gh = 6,
  grid = {},
}

function make_gem(ix,iy,gem_type)
  local gem_type = default(gem_type, flr(rnd(5) + 1))
  local gem = {
    -- null/blue/red/green/yellow/purple
    type = gem_type, 
    -- Position
    x = 0,
    y = 0,
    -- Target Position (Animating)
    tx = 0,
    ty = 0,
    moving = false,
    update=function(self)
      if (self.x != self.tx) then 
        self.x += (self.tx - self.x) * 0.125 -- Move toward tx
        moving = true
      end
      if (self.y != self.ty) then
        self.y += (self.ty - self.y) * 0.125 -- Move toward ty
        moving = true
      end

      if (moving and
        abs(self.tx - self.x) < 1 and
        abs(self.ty - self.y) < 1) then
          self.x = self.tx
          self.y = self.ty
          moving = false
          --board.check_matches()
      end

    end,
    draw=function(self)
      spr(239 + self.type, self.x, self.y)
    end,
  }
  return gem
end

function board.in_board(px, py)
  px = default(px, 0)
  py = default(py, 0)
  
  local rx = px - board.x
  local ry = py - board.y
  local cellx = flr(rx / 8)
  local celly = flr(ry / 8)

  local result = {
    x = 0,
    y = 0,
    inside = false,
  }

  if (cellx >= 0 and cellx < 6) result.x = cellx + 1
  if (celly >= 0 and celly < 6) result.y = celly + 1
  if (result.x > 0 and result.y > 0) result.inside = true

  return result
end

function board.check_matches()
  
  for x = 1, board.gw  do
    for y = 1, board.gh do
      local gem = board.grid[x][y]
      if (gem.moving) goto continue -- Don't check gems in the middle of moving
      DEBUG = "Check Called"
      offsetx = 1
      offsety = 1

      if (x == board.gw) offsetx = -1
      if (y == board.gh) offsety = -1

      if (gem.type > 0) then
        if (board.grid[x+offsetx][y]["type"] == gem.type) then
          board.grid[x][y]["type"] = 0 -- Temp
          board.grid[x+offsetx][y]["type"] = 0
        end
        if (board.grid[x][y+offsety]["type"] == gem.type) then
          board.grid[x][y]["type"] = 0 -- Temp
          board.grid[x][y+offsety]["type"] = 0
        end
      end
      ::continue::
    end
  end
  board:side()
end

function board:side()
  for x = 1, board.gw  do
    for y = 2, board.gh do 
      local gem = board.grid[x][y]
      local gem_above = board.grid[x][y-1]

      if (gem_above.type == 0) then
        gem_above.tx = board.x + (x-1) * 8
        gem_above.ty = board.y + (y-2) * 8
        gem_above.type = gem.type
        board.grid[x][y-1] = gem_above
        board.grid[x][y]["type"] = 0
      end

      if (y == board.gh and gem.type == 0) then
        local new_gem = make_gem(x, y)
        new_gem.x = board.x + (x-1) * 8
        new_gem.tx = new_gem.x
        new_gem.y = board.y + (y-1) * 8
        new_gem.ty = new_gem.y
        board.grid[x][y] = new_gem
      end
    end
  end
end

function board.respawn()
  for x = 1, board.gw  do
    for y = 1, board.gh do
      local gem = board.grid[x][y]

      if (gem.type == 0) then
        local new_gem = make_gem(x, y)
        new_gem.x = board.x + (x-1) * 8
        new_gem.tx = new_gem.x
        new_gem.y = board.y + (y-1) * 8
        new_gem.ty = new_gem.y
        board.grid[x][y] = new_gem
      end

    end
  end
end

function board.swap(x, y, direction)
  local x2 = x
  local y2 = y

  if direction == "right" then
    if (x >= board.gw) return -- Exit early
    x2 += 1

  elseif direction == "left" then
    if (x <= 1) return -- Exit early
    x2 -= 1
  end

  local this_gem = board.grid[x][y]
  local that_gem = board.grid[x2][y2]

  this_gem.tx = board.x + (x2 - 1) * 8
  this_gem.ty = board.y + (y2 - 1) * 8
  that_gem.tx = board.x + (x - 1) * 8
  that_gem.ty = board.y + (y - 1) * 8

  board.grid[x][y] = that_gem
  board.grid[x2][y2] = this_gem

end

function board:reset()
  for x = 1, board.gw do -- Top Left / Bottom Right
    board.grid[x] = {}
    for y = 1, board.gh do
      board.grid[x][y] = make_gem(x, y, 0)
      local gem = make_gem(x, y)
      local gem_type = gem.type

      while (
        ( x >=3 and
          board.grid[x-1][y]["type"] == gem_type and
          board.grid[x-2][y]["type"] == gem_type
        ) or
        ( y >=3 and
          board.grid[x][y-1]["type"] == gem_type and
          board.grid[x][y-2]["type"] == gem_type
        )
      ) do
        gem = make_gem(x, y)
        gem_type = gem.type
      end

      gem.x = board.x + (x-1) * 8
      gem.tx = gem.x
      gem.y = board.y + (y-1) * 8
      gem.ty = gem.y
      board.grid[x][y] = gem

    end
  end
end


function board:init()
  board.reset()
end

function board:update()
  local has_gaps = false
  for i = 1, board.gw do
    for j = 1, board.gh do
      local gem = board.grid[i][j]
      if (gem.type > 0) then
        gem:update()
      else
        has_gaps = true
      end
    end
  end
  if has_gaps then 
    board:side()
  end
end

function board:draw()
  for i = 1, board.gw do
    for j = 1, board.gh do
      local gem = board.grid[i][j]
      if (gem.type > 0) then
        gem:draw()
        --print2(gem.type, -8 + 8*i, 16 + 8*j)
      end
    end
  end

  print2("-Slaying Gems-", 1, 1)

end