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
  }
  return gem
end

gem = {
  -- null/blue/red/green/yellow/purple
  type = 0, 
  -- Position
  x = 0,
  y = 0,
  -- Target Position (Animating)
  tx = 0,
  ty = 0,
}

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

function board:reset()
  for x = 1, board.gw do -- Top Left / Bottom Right
    board.grid[x] = {}
    for y = 1, board.gh do
      board.grid[x][y] = make_gem(x, y, 0)
      local gem = make_gem(x, y)
      local gem_type = gem.type

      while (
        ( x > 1 and
          board.grid[x-1][y]["type"] == gem_type
        ) or
        ( y > 1 and
          board.grid[x][y-1]["type"] == gem_type
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

function board:draw()
  for i = 1, board.gw do
    for j = 1, board.gh do
      local gem = board.grid[i][j]
      if (gem.type > 0) then
        spr(239 + gem.type, gem.x, gem.y)
        --print2(gem.type, -8 + 8*i, 16 + 8*j)
      end
    end
  end

  print2("-Slaying Gems-", 1, 1)

end