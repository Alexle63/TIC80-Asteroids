-- title:  Driving Model
-- author: msx80
-- desc:   implements a driving model for my racing car game
-- script: lua

local _ENV = require 'std.strict' (_G)


asteroids = {}
NUM_ASTEROIDS = 10
ASTEROID_NUM_POINTS = 10
ASTEROID_RAD = 15
ASTEROID_RAD_PLUS = 4
ASTEROID_RAD_MINUS = 6
ASTEROID_MAX_VEL = 0.35
ASTEROID_MIN_VEL = 0.05
ASTEROID_MAX_ROT = 0.08
ASTEROID_COLOR = 12


BULLET_DURATION = 5
BULLET_SIZE = 10
BULLET_COLOR = 3
BULLET_SPEED = 2
BULLET_MAX = 5

SCREEN_MAX_X = 240
SCREEN_MAX_Y = 136

--------------------------
-- Vector functions
--------------------------


function flr(a) return math.floor(a) end
function rou(x) return x + 0.5 - (x + 0.5) % 1 end

pi2 = math.pi*2.0

function getVectorComponents(vector)

	local xComp = vector.speed
		* math.cos(vector.direction)
	
	local yComp = vector.speed
		* math.sin(vector.direction)
		
	local components = {
		xComp = xComp,
		yComp = yComp
	}
	
	return components

end -- getVectorComponents

-- gets a vector of given length
-- oriented on the given angle
function vector(length, angle)
 -- this could actually be optimized 
 -- since the X is always 0, to avoid
 -- two sin/cos calls.
 return rotate(0, -length, angle)
end

-- rotate a vector by a certain angle
function rotate(x,y,a)
 return 
  x*math.cos(a)-y*math.sin(a),
  x*math.sin(a)+y*math.cos(a)
end

-- gives the angle of a given vector
function angle(x,y)
 return math.pi - math.atan2(x,y)
end

-- give the angle from a certain point
-- to another point
function angle2(fromx,fromy, tox, toy)
 return angle(tox-fromx, toy-fromy)
end

-- calculates if an angle is closer
-- to a given angle in the positive
-- direction rather than the negative
-- returns -1, 0 or +1
function angleDir(from, to)
 local diff = to-from
 if math.abs(diff) < 0.00001 then return 0 end -- avoid rounding errors that will prevent settling
 if diff > math.pi then 
   return -1 
 elseif diff < -math.pi then
   return 1 
 else 
   return diff>0 and 1 or -1
 end
end

-- return the length of a vector
function vecLen(x,y)
  return math.sqrt(x ^ 2 + y ^ 2)
end

-- adds two angles ensuring the
-- result is in the 0..2pi range
function angleAdd(a, d)
 a=a+d
 -- ensure angle is in 0..2pi range
 if a<0 then 
   a=a+pi2
 elseif a>=pi2 then 
   a=a-pi2
 end
 return a
end


----------------


TURN_RADIUS = 0.05    -- how much the ship turn when pressing left or right
ACCEL_VALUE = 0.02    -- acceleration when pressing z
FRICTION = 0.985       -- how much the ship decelerates
ALIGNEMENT = 0.02     -- how fast the velocity catch up with direciton

local class = require 'middleclass'
local Ship = class('Ship')

function Ship:initialize (x, y, vx, vy, a)
  self.x = x;
  self.y = y;
  self.vx = vx;
  self.vy = vy;
  self.a = a;
  self.spinning = false;
end

function Ship:update ()

  -- if self.spinning then self.vx,self.vy=rotate(self.vx, self.vy, ALIGNEMENT * -1) self.vx=0 self.vy=0 end
  if self.spinning then self.vx=self.vx-0.01 self.vy=self.vy-0.01 end

  -- apply friction
  self.vx = self.vx * FRICTION
  self.vy = self.vy * FRICTION

  -- slowly rotate velocity to match car direction
  local v = angle(self.vx, self.vy) -- v is the angle of the velocity
  local d = angleDir(v, self.a) -- direction to go to align (-1 or 1)
  self.vx, self.vy = rotate(self.vx, self.vy, ALIGNEMENT * d)
  
  -- add velocity to car, modulo for double torus implementation
  self.x=(self.x+self.vx) % 240
  self.y=(self.y+self.vy) % 136
	
  drawShip(self)

end

function Ship:move (forwards, backwards, left, right)

  -- rotate our direction
  if left then self.a=angleAdd(self.a,-TURN_RADIUS) end
  if right then self.a=angleAdd(self.a,TURN_RADIUS) end
      
  if forwards then
    local ax,ay = vector(ACCEL_VALUE,self.a)
    self.vx=self.vx+ax -- change velocity this time
    self.vy=self.vy+ay
  elseif backwards then
    local ax,ay = vector(ACCEL_VALUE,self.a)
    self.vx=self.vx-ax -- change velocity this time
    self.vy=self.vy-ay
  end

end

function collide (c1, c2)
    -- return true if the two cars (c1,c2) are overlapping, false otw
    local d = (c1.x - c2.x)^2 + (c1.y - c2.y)^2
    return d < 64
end


function generateAsteroids()
 asteroids = {}
	local asteroid
	for count = 1,NUM_ASTEROIDS do
		asteroid = spawnAsteroid(1)
		
												
		if math.random(1,2) == 1 then
			-- start at top of screen
			asteroid.position = {
				x = math.random(0,(239)),
				y = 0
			}
		else
		 -- start at left of screen
			asteroid.position = {
				x = 0,
				y = math.random(0,(135))
			}
			end -- if
			
			table.insert(asteroids, asteroid)
	end -- for

end -- generateAsteroids

function spawnAsteroid(scale)

	local asteroid = {
		position = {
			x = 0,
			y = 0
		},
		velocity = {
			speed = 0,
			direction = 0
		},
		acceleration = 0.05,
		deceleration = 0.01,
		rotation = 0,
		rotationSpeed = 0.07,
		scale = scale,
		radius = 
			(ASTEROID_RAD + ASTEROID_RAD_PLUS) / scale,
		points = {}
	}
	
	-- generate points
	-- first point at default radius
	table.insert(asteroid.points,
		{
			x = ASTEROID_RAD/scale,
			y = 0,
			colour = ASTEROID_COLOR
		}
	)
	
	local angle = 0
	local radius = 0
	local vector = {}
	
	for point=1, (ASTEROID_NUM_POINTS - 1) do
		-- create a random radius
		radius = math.random(
			ASTEROID_RAD - ASTEROID_RAD_MINUS,
			ASTEROID_RAD + ASTEROID_RAD_PLUS
		) / scale
		-- angles are evenly spaced
		angle = ((math.pi * 2) / ASTEROID_NUM_POINTS)
			 * point 
		
		vector = {
			speed = radius,
			direction = angle
		}
		
		local components = getVectorComponents(vector)
		table.insert(asteroid.points,
			{
				x = components.xComp,
				y = components.yComp,
				colour = ASTEROID_COLOR 
			}
		)
		
	end -- for
	
	-- last point same as first
	table.insert(asteroid.points,
		{
			x = ASTEROID_RAD/scale,
			y = 0,
			colour = ASTEROID_COLOR
		}
	)
	
  	asteroid.velocity = {
			speed = (math.random()
												* (ASTEROID_MAX_VEL - ASTEROID_MIN_VEL))
												+ ASTEROID_MIN_VEL,
			direction = math.random() * math.pi * 2
		}
		asteroid.rotationSpeed = (math.random()
												* (2 * ASTEROID_MAX_ROT))
												- ASTEROID_MAX_ROT

	return asteroid

end -- spawnAsteroid


function spawnBullet(angle)

	local bullet = {
		position = {
			x = ship.x-4,
			y = ship.y-3
		},
		velocity = {
			speed = BULLET_SPEED,
			direction = angle
		},
		acceleration = 0.05,
		deceleration = 0.01,
		radius = BULLET_SIZE,
		time = time()
	}

	return bullet

end -- fireBullet


function drawAsteroids()

	for index, asteroid in ipairs(asteroids) do	
		drawVectorShape(asteroid)
	end -- for

end -- drawAsteroids


function moveAsteroids()

	for index, asteroid in ipairs(asteroids) do
		asteroid.rotation = asteroid.rotation
		 + asteroid.rotationSpeed
			
		asteroid.position = 
		movePointByVelocity(asteroid)
		
		asteroid.position = 
		wrapPosition(asteroid.position)
	end -- for

end -- moveAsteroids



function drawVectorShape(shape)

	local firstPoint = true
	local lastPoint = 0
	local rotatedPoint = 0
	for index, point in ipairs(shape.points) do
	
		rotatedPoint = rotatePoint(point,shape.rotation)
	
		if firstPoint then
			lastPoint = rotatedPoint
			firstPoint = false
		else
			line(lastPoint.x + shape.position.x,
			 lastPoint.y + shape.position.y,
				rotatedPoint.x + shape.position.x,
				rotatedPoint.y + shape.position.y,
				point.colour)
				lastPoint = rotatedPoint
		end
	
	end -- for

end -- drawVectorShape

function rotatePoint(point, rotation)

	local rotatedX =
		(point.x * math.cos(rotation))
		- (point.y * math.sin(rotation))
		
	local rotatedY =
		(point.y * math.cos(rotation))
		+ (point.x * math.sin(rotation))
		
	return {x=rotatedX, y=rotatedY}

end -- rotatePoint

function movePointByVelocity(object)

	local components =
		getVectorComponents(object.velocity)
	
	local newPosition = {
		x = object.position.x 
						+ components.xComp,
		y = object.position.y 
						+ components.yComp
	}
	
	return newPosition

end -- movePointByVelocity

function wrapPosition(position)

	if (position.x >= SCREEN_MAX_X) then
		position.x = 0
	elseif (position.x < 0) then
		position.x = SCREEN_MAX_X - 1
	end
	
	if (position.y >= SCREEN_MAX_Y) then
		position.y = 0
	elseif (position.y < 0) then
		position.y = SCREEN_MAX_Y - 1
	end
	
	return position

end -- wrapPosition




function drawShip(c)
 	-- with sprites:
	local idx = rou(c.a*16/pi2) % 16
	spr(256 + (idx % 4), flr(c.x)-4, flr(c.y)-4,3, 1,0, idx // 4) 

	--with circle and arrow:

  --   (x, y,  radius, color)
  -- circb(c.x, c.y, 2, 5)

  -- local xTip,yTip = vector(5,c.a)

  -- local xLeft,yLeft = vector(7,c.a-2.82743)
  -- local xRight,yRight = vector(7,c.a+2.82743)

  -- --  (x, y, xEnd, yEnd, color)
  -- line(c.x+xTip, c.y+yTip, c.x+xLeft, c.y+yLeft, 2)
  -- line(c.x+xTip, c.y+yTip, c.x+xLeft, c.y+yRight, 9)
end


ship = Ship:new(120, 68, 0, 0 ,0)

function initGame()
	-- (screen is 240 x 136 pixels)
	generateAsteroids()
end

bullets = {}

function controlShip(fire)
	ship:move(btn(0), btn(1), btn(2), btn(3))
	local bullet = {}

	if fire and #bullets < BULLET_MAX then
		table.insert(bullets, spawnBullet(ship.a))
	end

	for index, bullet in ipairs(bullets) do
		local idx = rou(bullet.velocity.direction*16/pi2) % 16
		local x, y = vector(9, bullet.velocity.direction)
		spr(272 + (idx % 4), bullet.position.x + x, bullet.position.y + y, 3, 1, 1, idx//4)
	end

	ship:update()
end

function moveBullets()
	local newBullets = bullets

	for index, bullet in ipairs(bullets) do

		local time = time()
		if time - bullet.time > 1750 then
			table.remove(newBullets,1)
		end

		local idx = rou(bullet.velocity.direction*16/pi2) % 16
		local x, y = vector(BULLET_SPEED, bullet.velocity.direction)
		bullet.position.x = (bullet.position.x + x) % 240
		bullet.position.y = (bullet.position.y + y) % 136
	end
	
	bullets = newBullets
end

function playGame() 

	cls(0)

	controlShip(btnp(4))
	drawAsteroids()

	moveAsteroids()
	moveBullets()


end









initGame()



function TIC()
  
 	playGame()

  
	
end


-- <SPRITES>
-- 000:333c3333333c333333c3c33333c3c3333c333c333c333c33c33333c3c33333c3
-- 001:333333c333333cc33333c3c3333c33c333c333c33c3333c3c33333c3333333c3
-- 002:3333333333333cc3333cc3c33cc33c33c3333c333333c3333333c333333c3333
-- 003:33333333cccccccc333333c333333c333333c333333c333333c333333c333333
-- 016:3333333333333333333363333333633333336333333363333333633333333333
-- 017:3333333333333333333633333336333333336333333363333333333333333333
-- 018:3333333333333333336333333336333333336333333336333333333333333333
-- 019:3333333333333333333333333366333333336633333333333333333333333333
-- </SPRITES>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

