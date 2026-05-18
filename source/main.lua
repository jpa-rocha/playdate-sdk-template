import "CoreLibs/graphics"
import "CoreLibs/timer"

local gfx = playdate.graphics
local timer = playdate.timer

local x = 200
local y = 120
local message = "Hello, World!"

function playdate.update()
  gfx.clear(gfx.kColorWhite)

  -- Draw centered text
  gfx.drawTextAligned(message, x, y, kTextAlignment.center)

  -- Draw a small crank indicator
  local crankAngle = math.rad(playdate.getCrankPosition())
  local radius = 20
  local cx, cy = 200, 200
  local endX = cx + radius * math.sin(crankAngle)
  local endY = cy - radius * math.cos(crankAngle)

  gfx.drawCircleAtPoint(cx, cy, radius)
  gfx.drawLine(cx, cy, endX, endY)
  gfx.drawTextAligned("Crank me!", cx, cy - radius - 16, kTextAlignment.center)

  timer.updateTimers()
end
