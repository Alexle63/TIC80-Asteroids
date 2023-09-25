-- title:  Asteroids
-- author: Bob Grant
-- desc:   Destroy the asteroids to stay alive.
-- script: lua

-- game state control
STATE_INIT = 5
STATE_START = 8
STATE_PLAY = 10
STATE_SHIP_KILLED = 12
STATE_SHIP_KILL_DELAY = 14
STATE_WAIT_RESPAWN = 16
STATE_NEW_LEVEL_DELAY = 18
STATE_END = 20

gameState = STATE_INIT

SCREEN_MAX_X = 240
SCREEN_MAX_Y = 136

playerShip = {
	position = {
		x = 100,
		y = 60
	},
	velocity = {
		speed = 0,
		direction = 0
	},
	acceleration = 0.05,
	deceleration = 0.01,
	rotation = 0,
	rotationSpeed = 0.07,
	radius = 10,
	points = {
		{x=8,y=0, colour = 6},
		{x=-8,y=6, colour = 6},
		{x=-4,y=0, colour = 6},
		{x=-8,y=-6, colour = 6},
		{x=8,y=0, colour = 6}
	}
}

playerScore = 0
playerLives = 3
playerLevel = 0
playerBullets = {}
MAX_PLAYER_BULLETS = 4
PLAYER_BULLET_SPEED = 2
PLAYER_BULLET_TIME = 60
playerBulletOffset = {
	x=8,
	y=0
}
playerThrustOffset = {
	x=-5,
	y=0
}
MIN_RESPAWN_DIST = 30

asteroids = {}
NUM_ASTEROIDS = 10
ASTEROID_NUM_POINTS = 10
ASTEROID_RAD = 15
ASTEROID_RAD_PLUS = 4
ASTEROID_RAD_MINUS = 6
ASTEROID_MAX_VEL = 0.5
ASTEROID_MIN_VEL = 0.1
ASTEROID_MAX_ROT = 0.03

particles = {}
explosionColours = {6,9,14}
smokeColours = {3,7,10,15}

alienShip = {}
alienBullets = {}
MAX_ALIEN_BULLETS = 1
ALIEN_BULLET_SPEED = 2
ALIEN_BULLET_TIME = 60
ALIEN_BULLET_AIM = math.pi / 3

delayTimer = 0

function TIC()

	if gameState == STATE_INIT then
		initGame()
		gameState = STATE_START
	elseif gameState == STATE_START then
		doStartScreen()
	elseif gameState == STATE_PLAY then
		doPlayGame()
	elseif gameState == STATE_NEW_LEVEL_DELAY then
		doNewLevelDelay()
	elseif gameState == STATE_SHIP_KILLED then
		doShipKilled()
	elseif gameState == STATE_SHIP_KILL_DELAY then
		doShipKillDelay()
	elseif gameState == STATE_WAIT_RESPAWN then
		doShipRespawn()
	elseif gameState == STATE_END then
		doEndScreen()
	end

end

function doStartScreen()

	doNoShipDisplay()
	
	print ("ASTEROIDS", 55,40,6,false,2)
	print ("press Z to start", 60,60)
	if btnp(4) then
		initGame()
		gameState = STATE_PLAY		
	end

end -- doStartScreen()

function doEndScreen()

	doNoShipDisplay()
	
	print ("GAME OVER", 80,40)
	print ("press Z to start", 60,60)
	if btnp(4) then
		initGame()
		gameState = STATE_PLAY
	end

end -- doEndScreen()

function doPlayGame()

	cls()
	
	-- update
	checkPlayerButtons()
	movePlayerShip()
	moveAlienShip()
	moveAsteroids()
	if checkShipCrash() then
		gameState = STATE_SHIP_KILLED
	end -- if
	movePlayerBullets()
	moveAlienBullets()
	checkBulletHits()
	moveParticles()
	
	-- draw
	drawVectorShape(playerShip)
	drawAsteroids()
	drawAlienShip()
	drawPlayerBullets()
	drawAlienBullets()
	drawParticles()
	drawGameInfo()
	
	if (#asteroids == 0) and not alienShip.active then
		-- end of level
		gameState = STATE_NEW_LEVEL_DELAY
		playerLevel = playerLevel + 1
		playerShip.spawnTimer = math.random(600, 1800)
		delayTimer = 180
	end -- if

end -- doPlayGame()

function doShipKilled()
	-- do explosion
 sfx(2,10,30,3,15)
	
	particleExplosion(playerShip, 500, 2,
		90, explosionColours, 3, 0.015)
	
	playerLives = playerLives -1
	delayTimer = 180
	gameState = STATE_SHIP_KILL_DELAY
end -- doShipKilled

function doNewLevelDelay()
	delayTimer = delayTimer - 1
	cls()
	-- update
	checkPlayerButtons()
	movePlayerShip()
	movePlayerBullets()
	moveAlienBullets()
	checkBulletHits()
	moveParticles()
	
	-- draw
	drawVectorShape(playerShip)
	drawPlayerBullets()
	drawAlienBullets()
	drawParticles()
	drawGameInfo()

	if delayTimer == 0 then
		-- delay finished
		generateAsteroids()
		gameState = STATE_PLAY
	end -- if
end -- doNewLevelDelay

function doShipKillDelay()

	doNoShipDisplay()

	-- wait for explosion to finish
	delayTimer = delayTimer - 1
	if delayTimer == 0 then
		-- delay finished
		if playerLives == 0 then
			-- game over
			gameState = STATE_END
		else
			-- respawn playerShip
			resetPlayerShip()
			gameState = STATE_WAIT_RESPAWN
		end -- if
	end -- if
	
end -- doShipKillDelay

function doShipRespawn()

	doNoShipDisplay()
	
	local asteroidTooClose = false
	index = 1
	while(index <= #asteroids) and
		(not asteroidTooClose) do
		if checkSeparation(playerShip.position,
			asteroids[index].position,
			MIN_RESPAWN_DIST) then
			asteroidTooClose = true
		end --if
		index = index + 1
	end -- while

	if not asteroidTooClose then
		gameState = STATE_PLAY
	end -- if

end -- doShipRespawn

function doNoShipDisplay()

	cls()
	
	-- update
	moveAsteroids()
	movePlayerBullets()
	moveAlienBullets()
	checkBulletHits()
	moveParticles()
	moveAlienShip()
	
	-- draw
	drawAsteroids()
	drawPlayerBullets()
	drawAlienBullets()
	drawAlienShip()
	drawParticles()
	drawGameInfo()
	
end -- do NoShipDisplay

function initGame()
	playerScore = 0
	playerLives = 3
	playerLevel = 1
	resetPlayerShip()
	generateAsteroids()
	initAlienShip()
	
end -- initGame

function resetPlayerShip()
	playerShip.position = {
		x = 100,
		y = 60
	}
	playerShip.velocity = {
		speed = 0,
		direction = 0
	}
	playerShip.rotation = 0
		
end -- resetPlayerShip()

function drawGameInfo()
	local width = 0
	width = print("Score : ",0,0,14)
	width = width + print(playerScore, width,0,11)
	width = width + print(" Level : ",width,0,14)
	width = width + print(playerLevel, width,0,11)
	
	for count = 0,playerLives-2 do
		spr(1,230-(count * 6),0,0)
	end

end -- drawGameInfo

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

function checkPlayerButtons()
	
	-- thrust
	if btn(0) then -- up key
		playerShipThrust()
	end -- if
	
	if btn(2) then -- left
		playerShip.rotation = playerShip.rotation
			- playerShip.rotationSpeed
	end
	if  btn(3) then -- right
		playerShip.rotation = playerShip.rotation
			+ playerShip.rotationSpeed
	end
	
	playerShip.rotation = 
		keepAngleInRange(playerShip.rotation)
		
	if btnp(4) then -- fire Z
		firePlayerBullet()
	end

end -- checkPlayerButtons

function keepAngleInRange(angle)

	if angle < 0 then
		while angle < 0 do
			angle = angle + (2 * math.pi)
		end
	end
	if angle > (2 * math.pi) then
		while angle > (2 * math.pi) do
			angle = angle - (2 * math.pi)
		end
	end
	
	return angle

end -- keepAngleInRange

function movePointByVelocity(object)

	components =
		getVectorComponents(object.velocity)
	
	local newPosition = {
		x = object.position.x 
						+ components.xComp,
		y = object.position.y 
						+ components.yComp
	}
	
	return newPosition

end -- movePointByVelocity

function 	movePlayerShip()
	
	playerShip.velocity.speed = 
		playerShip.velocity.speed - 
			playerShip.deceleration
	
	if playerShip.velocity.speed < 0 then
		playerShip.velocity.speed = 0
	end

	playerShip.position = 
		movePointByVelocity(playerShip)
		
	playerShip.position = 
		wrapPosition(playerShip.position)

end -- movePlayerShip

function playerShipThrust()

	local acceleration = {
		speed = playerShip.acceleration,
		direction = playerShip.rotation
	}
	
	playerShip.velocity = 
		addVectors(playerShip.velocity,
			acceleration)
			
	sfx(3,10,10,3,-8,1)
	
	local particleVelocity = {}
	local direction = 0
	local relSpawnPosition =
			rotatePoint(playerThrustOffset,
				playerShip.rotation)
	local spawnPosition = {
		x = relSpawnPosition.x + playerShip.position.x,
		y = relSpawnPosition.y + playerShip.position.y
	}
	for particle = 1, 5 do
		direction = playerShip.rotation + math.pi
			+ (math.random() * math.pi / 6) - (math.pi / 12)
		direction = keepAngleInRange(direction)
		particleVelocity = {
			speed = math.random() * 2,
			direction = direction
		}
		spawnParticle(spawnPosition,
			particleVelocity,30, smokeColours,
			1, 0.01, math.random(1,2))
	end -- for 

end -- playerShipThrust

function firePlayerBullet()
	local bullet = {}
	if #playerBullets <= MAX_PLAYER_BULLETS then
		-- ok to fire
		local relSpawnPosition =
			rotatePoint(playerBulletOffset,
				playerShip.rotation)
		bullet = {
			position = {
				x = relSpawnPosition.x
					+ playerShip.position.x,
				y = relSpawnPosition.y
					+ playerShip.position.y 
			},
			velocity = {
				speed = PLAYER_BULLET_SPEED,
				direction = playerShip.rotation
			},
			timer = PLAYER_BULLET_TIME
		}
		table.insert(playerBullets, bullet)
		sfx(0,40,20,0,15,1)
	end
end -- firePlayerBullet

function movePlayerBullets()
	for index, bullet in ipairs(playerBullets) do
		bullet.timer = bullet.timer - 1
		if bullet.timer < 0 then
			-- kill bullet
			table.remove(playerBullets, index)
		else
			-- move bullet
			bullet.position = 
				movePointByVelocity(bullet)
		
			bullet.position = 
				wrapPosition(bullet.position)
				
		end -- if
	end -- for
end

function drawPlayerBullets()
	for index, bullet in ipairs(playerBullets) do
		spr(0,
			bullet.position.x,
			bullet.position.y, 0)
	end -- for
end -- drawPlayerBullets

function checkBulletHits()
	
	local bulletHasHit = false
	for bIndex, bullet in ipairs(playerBullets) do
		for aIndex, asteroid in ipairs(asteroids) do	
			-- course check
			if(checkSeparation(bullet.position,
				asteroid.position,
				ASTEROID_RAD + ASTEROID_RAD_PLUS)) then
				
				if pointInPolygon(bullet.position, asteroid) then
				 -- kill this bullet
					table.remove(playerBullets, bIndex)
					explodeAsteroid(aIndex, asteroid)
					break
				end -- if pointInPolygon
				
			end -- if checkSeparation
			
			
		end -- for asteroid
	end -- for bullet
	
	-- check alienShip
	if alienShip.active then
		for bIndex, bullet in ipairs(playerBullets) do
			-- course check
			if(checkSeparation(bullet.position,
				alienShip.position,
				alienShip.radius)) then
				
				if pointInPolygon(bullet.position, alienShip) then
				 -- kill this bullet
					table.remove(playerBullets, bIndex)
					explodeAlienShip()
					break
				end -- if pointInPolygon
				
			end -- if checkSeparation
		
		end -- for bullet
	end -- if active

end -- checkBulletHits()

function checkShipCrash()

	-- asteroids
	local index = 1 -- set to first asteroid
	local shipCrashed = false
	while (index <= #asteroids) and (not shipCrashed) do
		shipCrashed =
			polygonInPolygon(playerShip, asteroids[index])
		index = index + 1
	end -- while
	
	-- check ship / alien ship
	if (not shipCrashed) and alienShip.active then
	 shipCrashed =
			polygonInPolygon(playerShip, alienShip)
	end -- if
	
	-- alien bullets
	index = 1 -- set to first bullet
	while (index <= #alienBullets) and (not shipCrashed) do
		shipCrashed =
			pointInPolygon(alienBullets[index].position, playerShip)
		if shipCrashed then
			table.remove(alienBullets, index)
		end
		index = index + 1
	end -- while
	
	return shipCrashed
end -- checkShipCrash()

function polygonInPolygon(shape1, shape2)

	local testPoint = {}
	local rotatedPoint = {}
	
	if(checkSeparation(shape1.position,
				shape2.position,
				shape1.radius + shape2.radius)) then
	
		-- first shape points in second shape?
		for index,point in ipairs(shape1.points) do
			rotatedPoint = rotatePoint(point,shape1.rotation)
			testPoint = {
				x = rotatedPoint.x + shape1.position.x,
				y = rotatedPoint.y + shape1.position.y
			}
			if pointInPolygon(testPoint, shape2) then
				return true
			end -- if
		end -- for
	
		-- second shape points in first shape?
		for index,point in ipairs(shape2.points) do
			rotatedPoint = rotatePoint(point,shape2.rotation)
			testPoint = {
				x = rotatedPoint.x + shape2.position.x,
				y = rotatedPoint.y + shape2.position.y
			}
			if pointInPolygon(point, shape1) then
				return true
			end -- if
		end -- for
	end -- if
	return false
	
end -- polygonInPolygon

function pointInPolygon(point, shape)

	local firstPoint = true
	local lastPoint = 0
	local rotatedPoint = 0
	local onRight = 0
	local onLeft = 0
	local xCrossing = 0
	
	for index,shapePoint in ipairs(shape.points) do
	
		rotatedPoint = rotatePoint(shapePoint,shape.rotation)
	
		if firstPoint then
			lastPoint = rotatedPoint
			firstPoint = false
		else
			startPoint = {
				x = lastPoint.x + shape.position.x,
			 y = lastPoint.y + shape.position.y
			}
			endPoint = {
				x = rotatedPoint.x + shape.position.x,
				y = rotatedPoint.y + shape.position.y
			}
			if ((startPoint.y >= point.y) and (endPoint.y < point.y))
				or ((startPoint.y < point.y) and (endPoint.y >= point.y)) then
				-- line crosses ray
				if (startPoint.x <= point.x) and (endPoint.x <= point.x) then
					-- line is to left
					onLeft = onLeft + 1
				elseif (startPoint.x >= point.x) and (endPoint.x >= point.x) then
					-- line is to right
					onRight = onRight + 1
				else
					-- need to calculate crossing x coordinate
					if (startPoint.y ~= endPoint.y) then
						-- filter out horizontal line
						xCrossing = startPoint.x +
							((point.y - startPoint.y)
							* (endPoint.x - startPoint.x)
							/ (endPoint.y - startPoint.y))
						if (xCrossing >= point.x) then
							onRight = onRight + 1
						else
							onLeft = onLeft + 1
						end -- if
					end -- if horizontal
				end -- if
			end -- if crosses ray
				
			lastPoint = rotatedPoint
		end
	
	end -- for

	-- only need to check on side
	if (onRight % 2) == 1 then
		-- odd = inside
		return true
	else
		return false
	end

end -- pointInPolygon

function checkSeparation(point1, point2, separation)
	-- leaving as squares removes need
	-- to do a sqrt
	local separationSq = separation * separation
	local distanceSq =
		((point1.x - point2.x) * (point1.x - point2.x))
		+ ((point1.y - point2.y) * (point1.y - point2.y))
	return (distanceSq <= separationSq)
end -- getDistance

function explodeAsteroid(index, asteroid)
	-- get position of exploded asteroid
	local position = asteroid.position
	local orgScale = asteroid.scale
	
	playerScore =
		playerScore + (50 * orgScale)
	sfx(1, 1, 50, 1, 15)
	
	particleExplosion(asteroid, 60, 1,
		30, explosionColours, 3, 0.01)
	
	-- delete exploded asteroid
	table.remove(asteroids, index)
	
	if orgScale < 4 then
	
		local newScale = orgScale * 2
	
		-- generate 2 new asteroids
		local asteroid
		for count = 1,2 do
			asteroid = spawnAsteroid(newScale)
			asteroid.velocity = {
				speed = (math.random()
												* (ASTEROID_MAX_VEL - ASTEROID_MIN_VEL))
												+ ASTEROID_MIN_VEL,
				direction = math.random() * math.pi * 2
			}
			asteroid.rotationSpeed = (math.random()
												* (2 * ASTEROID_MAX_ROT))
												- ASTEROID_MAX_ROT
												
			asteroid.position = position
			
			table.insert(asteroids, asteroid)
		end -- for
	end -- if

end -- explodeAsteroid

function particleExplosion(object, numParticles, maxSpeed,
	maxLifetime, colours, maxSize, deceleration)
	local particleVelocity = {}
	for particle = 1, numParticles do
		particleVelocity = {
			speed = math.random() * maxSpeed,
			direction = math.random() * math.pi * 2
		}
		spawnParticle(object.position,
			particleVelocity,maxLifetime, colours,
			maxSize, deceleration, math.random(1,3))
	end -- for 
end

function addVectors(vector1, vector2)

	v1Comp = getVectorComponents(vector1)
	v2Comp = getVectorComponents(vector2)
	resultantX = v1Comp.xComp + v2Comp.xComp
	resultantY = v1Comp.yComp + v2Comp.yComp

	local resVector =
		compToVector(resultantX, resultantY) 

	return resVector
	
end -- addVectors

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

function compToVector(x, y)

	local magnitude = 
		math.sqrt( (x * x) + (y * y))
	local direction = 
		math.atan2(y, x)
	direction = keepAngleInRange(direction)
		
	local vector = {
		speed = magnitude,
		direction = direction
	}
	
	return vector

end -- compToVector

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
			colour = 15
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
		
		components = getVectorComponents(vector)
		table.insert(asteroid.points,
			{
				x = components.xComp,
				y = components.yComp,
				colour = 15
			}
		)
		
	end -- for
	
	-- last point same as first
	table.insert(asteroid.points,
		{
			x = ASTEROID_RAD/scale,
			y = 0,
			colour = 15
		}
	)
	
	return asteroid

end -- spawnAsteroid

function generateAsteroids()
 asteroids = {}
	local asteroid
	for count = 1,NUM_ASTEROIDS do
		asteroid = spawnAsteroid(1)
		asteroid.velocity = {
			speed = (math.random()
												* (ASTEROID_MAX_VEL - ASTEROID_MIN_VEL))
												+ ASTEROID_MIN_VEL,
			direction = math.random() * math.pi * 2
		}
		asteroid.rotationSpeed = (math.random()
												* (2 * ASTEROID_MAX_ROT))
												- ASTEROID_MAX_ROT
												
		if math.random(1,2) == 1 then
			-- start at top of screen
			asteroid.position = {
				x = math.random(0,(SCREEN_MAX_X - 1)),
				y = 0
			}
		else
		 -- start at left of screen
			asteroid.position = {
				x = 0,
				y = math.random(0,(SCREEN_MAX_Y - 1))
			}
			end -- if
			
			table.insert(asteroids, asteroid)
	end -- for

end -- generateAsteroids

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

function spawnParticle(position, velocity, maxLifetime,
	colours, maxSize, deceleration, type)

	local particle = {
		position = {
			x = position.x,
			y = position.y
		},
		velocity = {
			speed = velocity.speed,
			direction = velocity.direction
		},
		lifeTimer = (maxLifetime / 2) + 
			(math.random() * maxLifetime / 2),
		colours = colours,
		size = math.random(1, maxSize),
		deceleration = deceleration,
		type = type
	}
	table.insert(particles, particle)
	
end -- spawnParticle

function moveParticles()

	for index, particle in ipairs(particles) do
		particle.lifeTimer = particle.lifeTimer - 1
		if particle.lifeTimer < 0 then
			table.remove(particles, index)
		else
			particle.position = 
		 movePointByVelocity(particle)
		end --if
		particle.velocity.speed = 
		 	particle.velocity.speed - particle.deceleration
		if particle.velocity.speed < 0 then
			particle.velocity.speed = 0
		end
	end -- for
end

function drawParticles()

	local particleColour = 0
	
 for index, particle in ipairs(particles) do
	
		particleColour = particle.colours[
			math.random(1, #particle.colours)
		]
	
		if particle.type == 2 then
			circ(particle.position.x,
		 		particle.position.y,
					particle.size, particleColour)
		elseif particle.type == 1 then
			pix(particle.position.x,
		 		particle.position.y, particleColour)
		else
			rect(particle.position.x,
		 		particle.position.y,
					particle.size,
					particle.size,
					particleColour)
		end -- if
	end -- for

end

function initAlienShip()

  alienShip = {
    position = {
      x = 0,
      y = 0
    },
    velocity = {
      speed = 0,
      direction = 0
    },
    rotation = 0,
    radius = 10,
    points = {
      {x=8,y=0, colour = 8},
      {x=-8,y=6, colour = 8},
      {x=-4,y=0, colour = 8},
      {x=-8,y=-6, colour = 8},
      {x=8,y=0, colour = 8}
    },
    active = false,
    changeDirectionTimer = 0,
    direction = 0,
    spawnTimer = math.random(600, 1800)
  }

end -- function initAlienShip


function moveAlienShip()

	if not alienShip.active then
		alienShip.spawnTimer =
	 	alienShip.spawnTimer - 1
		if alienShip.spawnTimer <= 0 then
			spawnAlienShip()
		end
	end -- if

	if alienShip.active then
		alienShip.position = 
		movePointByVelocity(alienShip)
		
		local xPos = alienShip.position.x
		alienShip.position = 
		wrapPosition(alienShip.position)
		-- don't wrap x position
		alienShip.position.x = xPos
		
		if alienShip.direction == 0 then
			-- left to right
			if alienShip.position.x > SCREEN_MAX_X then
				endAlienShip()
			end -- if
		else
			-- right to left
			if alienShip.position.x < 0 then
				endAlienShip()
			end -- if
		end
		
		if #alienBullets < MAX_ALIEN_BULLETS then
			fireAlienBullet()
		end -- if
		
		alienShip.changeDirectionTimer = 
		 alienShip.changeDirectionTimer - 1
		if alienShip.changeDirectionTimer <= 0 then
			-- change direction
			local direction = math.random() *
				math.pi * 5 / 6
			direction = direction - (math.pi * 5 / 12)
			if alienShip.direction == 1 then
				-- right to left
				direction = direction + math.pi
			end
			direction = keepAngleInRange(direction)
			alienShip.velocity.direction = direction
			alienShip.rotation = direction
			alienShip.changeDirectionTimer = 30
		end -- if
	end -- if
	
end -- moveAlienShip

function drawAlienShip()

	if alienShip.active then
		drawVectorShape(alienShip)
	end -- if

end -- drawAlienShip

function spawnAlienShip()

	local direction = math.random(0,1)
	-- 0 = left to right
	-- 1 = right to left
	local startX = 0
	if direction == 1 then
		startX = SCREEN_MAX_X - 1
	end

	alienShip.position = {
	 x = startX,
		y = math.random(0,SCREEN_MAX_Y)
	}
	alienShip.velocity = {
		speed = 1,
		direction = 0
	}
	alienShip.rotation = 0
	alienShip.active = true
	alienShip.spawnTimer = 0
	alienShip.direction = direction
	alienShip.changeDirectionTimer = 0
	
end  -- spawnAlienShip

function fireAlienBullet()

	local direction = 0
	local angleToShip = math.atan2(
		playerShip.position.y - alienShip.position.y,
		playerShip.position.x - alienShip.position.x
	)
	local angleVariation = math.random() * ALIEN_BULLET_AIM
		- (ALIEN_BULLET_AIM / 2)
	local direction = angleToShip + angleVariation
	direction = keepAngleInRange(direction)
	
	bullet = {
		position = {
			x = alienShip.position.x,
			y = alienShip.position.y 
		},
		velocity = {
			speed = ALIEN_BULLET_SPEED,
			direction = direction
		},
		timer = ALIEN_BULLET_TIME
	}
	table.insert(alienBullets, bullet)
	sfx(0,50,20,0,15,1) 
end -- fireAlienBullet

function moveAlienBullets()
	for index, bullet in ipairs(alienBullets) do
		bullet.timer = bullet.timer - 1
		if bullet.timer < 0 then
			-- kill bullet
			table.remove(alienBullets, index)
		else
			-- move bullet
			bullet.position = 
				movePointByVelocity(bullet)
		
			bullet.position = 
				wrapPosition(bullet.position)
				
		end -- if
	end -- for
end

function drawAlienBullets()
	for index, bullet in ipairs(alienBullets) do
		spr(16,
			bullet.position.x,
			bullet.position.y, 0)
	end -- for
end -- drawPlayerBullets

function explodeAlienShip()
	playerScore = playerScore + 200
	particleExplosion(alienShip, 60, 1,
		30, explosionColours, 3, 0.01)
	sfx(1, 1, 50, 1, 15)
	endAlienShip()
end -- explodeAlienShip

function endAlienShip()
	alienShip.active = false
	alienShip.spawnTimer = math.random(300,1200)
end -- endAlienShip
-- <TILES>
-- 000:6900000096000000000000000000000000000000000000000000000000000000
-- 001:0060000000600000066600006666600060006000000000000000000000000000
-- 016:b50000005b000000000000000000000000000000000000000000000000000000
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- 003:f085e48182b871a67349a52eb26923a0
-- </WAVES>

-- <SFX>
-- 000:c027f07060a5f0d030f3f0f040e2f0c060c0f0b070af809f808f908f907fa07fa06fa06eb05eb05ec04ec04ec03dd03dd02de02de02df02df01df01d317000000000
-- 001:b4007400340004000400040014002400340044005400640074007400840084008400940094009400a400a400b400b400c400c400d400d400e400f400085000000000
-- 002:8400049604b704b704b704b704a704a614a61495249534854484548364727472846194619460a450a45fa45fb44eb44eb43dc43dc42cc42bc41bd40a069000000000
-- 003:040004000400040004000400040004000400040004000400040004000400040004000400040004000400040004000400040004000400040004000400005000000000
-- 004:040004000400040004000400040004000400040004000400040004000400040004000400040004000400040004000400040004000400040004000400005000000000
-- </SFX>

-- <SCREEN>
-- 000:0eeee00ffffff000000000000000000000ee000000bbb000000ee0000000000000000000000ee0000000ee000000bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000060000060000f00
-- 001:eeeffffeeee00eee00eeee000eee000000ee00000bb0bb00000ee00000eee00ee00e00eee00ee0000000ee00000bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000600000600000f0
-- 002:feee00eee000ee00e0ee00e0ee0ee000000000000bbb0b00000ee0000ee0ee0ee00e0ee0ee0ee000000000000000bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000006660006660000f0
-- 003:00eee0eee000eef0e0ee0000eee0000000ee00000bb00b00000ee0000eee0000eee00eee000ee0000000ee000000bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000066666066666000f0
-- 004:eeee000eeee00eee00ee00000eee000000ee000000bbb000000eeeee00eee0000e0000eee000eee00000ee00000bbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000060006060006000f0
-- 005:0000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000000f0
-- 006:0000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000000f0
-- 007:00000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000000f0
-- 008:000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000f0000000000000000000000000f0
-- 009:000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00fff0000000000f00000000000000000000000000f0
-- 010:000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000ff00000000f0000000000000000000000000f00
-- 011:000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000fffffffffffff000000000000000000000f00
-- 012:000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000f00f000000000000000000000f00
-- 013:0000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000f0f00000000000000000000f000
-- 014:0000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000f0f0000000000000000000f000
-- 015:0000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000ff0000000000000000000f000
-- 016:0000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000000f0000000000000000000f000
-- 017:0000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000000ff00000000000000000f0000
-- 018:0000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000000f0f0000000000000000f0000
-- 019:000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000000000f0f000000000000000f0000
-- 020:000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000000000f0f000000000000000f0000
-- 021:000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000000000f00f0000000000000f00000
-- 022:0000000000000000fff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000000000f0000f00000000000ff00000
-- 023:000000000000ffff0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000000000f00000f00000000ff0000000
-- 024:000000000fff00000f00ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000000f000000f00000fff000000000
-- 025:00000000f0000000f00000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000000f00000000f00ff000000000000
-- 026:00000000f0000000f000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000000f0000000000ff00000000000000
-- 027:0000000f000000ff00000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000000f00000000000000000000000000
-- 028:0000000f00000f00000000000ff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000f000000000000000000000000000
-- 029:000000f00000f00000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000f0000000000000000000000000000
-- 030:000000f000ff0000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000f0000000000000000000000000000
-- 031:ffff0f000f0000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000f00000000000000000000000000000
-- 032:0000fffff000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff0000000000000000000f00000000000000000000000000000
-- 033:0000000f00000000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff0000000000000000f000000000000000000000000000000
-- 034:00000000f0000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000f000000000000000000000000000000
-- 035:00000000f00000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff000000000000f0000000000000000000000000000000
-- 036:000000000f00000000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff0000000000f0000000000000000000000000000000
-- 037:0000000000f00000000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffff00000f00000000000000000000000000000000
-- 038:00000000000f0000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fff00f00000000000000000000000000000000
-- 039:00000000000f000000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff000000000000000000000000000000000
-- 040:00000000000f000000000000000000000f00000000000000000000000666666000000666666660066666666006666666666006666666600000066666600006666666600666666660000006666666600000000000000000000000fff000000000000000000000000000000000000000000000000000000000
-- 041:00000000000f00000000000000000000f000000000000000000000000666666000000666666660066666666006666666666006666666600000066666600006666666600666666660000006666666600000000000000000000000f00fffff0000000000000000000000000000000000000000000000000000
-- 042:00000000000f00000000000000000000f000000000000000000000066660000660066666600000000666600006666000000006666000066006666000066000066660000666600006600666666000000000000000000000000000f0000000ffff000000000000000000000000000000000000000000000000
-- 043:00000000000f0000000000000000000f0000000000000000000000066660000660066666600000000666600006666000000006666000066006666000066000066660000666600006600666666000000000000000000000000000f00000000000ff0000000000000000000000000000000000000000000000
-- 044:00000000000f00000000fff00000000f0000000000000000000000066660000660000666666000000666600006666666600006666000066006666000066000066660000666600006600006666660000000000000000000000000f0000000000000ff00000000000000000000000000000000000000000000
-- 045:0000000000f0000000ff000fffff00f00000000000000000000000066660000660000666666000000666600006666666600006666000066006666000066000066660000666600006600006666660000000000000000000000000f000000000000000ff000000000000000000000000000000000000000000
-- 046:0000000000f000000f0000000000fff00000000000000000000000066666666660000006666660000666600006666000000006666666600006666000066000066660000666600006600000066666600000000000000000000000f00000000000000000ff0000000000000000000000000000000000000000
-- 047:0000000000f00ffffff0000000000000000000000000000000000006666666666ff0000666666000066660000666600000000666666660000666600006600006666000066660000660000006666660000000000000000000000f00000000000000000000f000000000000000000000000000000000000000
-- 048:0000000000fff0f0000fffff000000000000000000000000000000066660000660f6666666600000066660000666666666600666600006600006666660000666666660066666666000066666666000000000000000000000000f000000000000000000000f00000000000000000000000000000000000000
-- 049:00000000fff00f0000000000ff00000000000000000000000000000666600ff66006666666600000066660000666666666600666600006600006666660000666666660066666666000066666666000000000000000000000000f0000000000000000000000f0000000000000000000000000000000000000
-- 050:000000ff00fff0000000000000ff0000000000000000000000000000000ff000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000f000000000000000000000000000000000000
-- 051:000000f000f00000000000000000ff000000000000000000000000000ff00000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000000f00000000000000000000000000000000000
-- 052:00000f000000000000000000000000f000000000000000000000fffff0000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000000f0000000000000000000000000000000000
-- 053:00000f000000000000000000000000f0000000000000000fffff0000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000000f000000000000000000000000000000000
-- 054:00000f0000000000000000000000000f00000000000000f000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000000f0000000000000000000000000000000000
-- 055:00000f0000000000000000000000000f0000000000000f0000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000000f0000000000000000000000000000000000
-- 056:0000f00000000000000000000000000f000000000000f00000000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000000f00000000000000000000000000000000000
-- 057:0000f000000000000000000000000000f00000000000f000000000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000000f000000000000000000000000000000000000
-- 058:0000f000000000000000000000000000f0000000000f0000000000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000000f000000000000000000000000000000000000
-- 059:000f0000000000000000000000000000f000000000f000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000f0000000000000000000000000000000000000
-- 060:000f00000000000000000000000000000f0000000f00000000000000000000000000000f0000000000000000000000fffff000000ff00000000000000000000ff0000000000000000ff00000000000000000000000000000000f000000000000000000000f00000000000000000000000000000000000000
-- 061:000f00000000000000000000000000000f000000f0000000000000000000ffff00ffff00ffff000ffff00ffff0000000ff000000fffff00fff0000000ffff0fffff00ffff0ffff00fffff000000000000000000000000000000f000000000000000000000f00000000000000000000000000000000000000
-- 062:000f00000000000000000000000000000f000000f0000000000000000000ff00f0ff00f0ff0ff0fff000fff00000000ff00000000ff000ff00f00000fff0000ff000f00ff0ff00f00ff000000000000000000000000000000000f0000000000000000000f000000000000000000000000000000000000000
-- 063:0000f000000000000000000000000000f00000000f000000000000000000ff00f0ff0000fff00000fff000fff00000ff000000000ff000ff00f0000000fff00ff000f00ff0ff00000ff000000000000000000000000000000000f0000000000000000000f000000000000000000000000000000000000000
-- 064:0000f000000000000000000000000000f00000000f000000000000000000ffff00ff00000fff00ffff00ffff000000fffff0000000fff00fff000000ffff0000fff00ffff0ff000000fff00000000000000000000000000000000f00000000000000000f0000000000000000000000000000000000000000
-- 065:0000f000000000000000000000000000f000000000f00000000000000000ff0000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000f0000000000000000000000000000000000000000
-- 066:0000f00000000000000000000000000f0000000000f0000000000000000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000f0000000000000000000000000000000000000000
-- 067:00000f0000000000000000000000000f00000000000f000000000000000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000f0000000000000000000000000000000000000000
-- 068:00000f000000000000000000000000f000000000000f00000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000f00000000000000000000000000000000000000000
-- 069:00000f00000000000000000000000ff0000000000000f0000000000000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000f00000000000000000000000000000000000000000
-- 070:000000f0000000000000000000fff000000000000000f000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff0000000000f00000000000000000000000000000000000000000
-- 071:0000000f0000000000000000ff0000000000000000000ff0000000000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffff000000f00000000000000000000000000000000000000000
-- 072:0000000f00000000000000ff00000000000000000000000fff000000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffff0f000000000000000000000000000000000000000000
-- 073:00000000f00000000000ff0000000000000000000000000000ff0000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff000000000000000000000000000000000000000000
-- 074:000000000fff000000ff00000000000000000000000000000000ffffff00000000fffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 075:0000000ff0f0fff00f0000000000000000000000000000000000000000ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 076:00000ff000f0000ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 077:000ff000000f0ff00fff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 078:fff000000000f0000000ff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 079:000000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000000
-- 080:00000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff00f0000000000000000000000000000000000000000
-- 081:00000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff00000f000000000000000000000000000000000000000
-- 082:0000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000f00000000000000000000000000000000000000
-- 083:0000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffff0000000000f00000000000000000000000000000000000000
-- 084:000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffff0000000000000000f0000000000000000000000000000000000000
-- 085:000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff0000000000000000000000f000000000000000000000000000000000000
-- 086:00000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fff0000000000000000000000000f00000000000000000000000000000000000
-- 087:00000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000f0000000000000000000000000000000000
-- 088:0000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff000000000000000000000000000000f00000000000000000000000000000000000
-- 089:0000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000000000000f000000000000000000000000000000000000
-- 090:0000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000000000f0000000000000000000000000000000000000
-- 091:0000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000000000f00000000000000000000000000000000000000
-- 092:0000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000000000f00000000000000000000000000000000000000
-- 093:0000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000000f000000000000000000000000000000000000000
-- 094:0000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000000f0000000000000000000000000000000000000000
-- 095:0000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000f00000000000000000000000000000000000000000
-- 096:0000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000f000000000000000000000000000000000000000000
-- 097:0000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000f000000000000000000000000000000000000000000
-- 098:f00000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000f000000000000000000000000000000000000000000
-- 099:f0000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000f000000000000000000000000000000000000000000
-- 100:0ff0000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000f0000000000000000000000000000000000000000000
-- 101:000f000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000f0000000000000000000000000000000000000000000
-- 102:0000ff000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000f0000000000000000000000000000000000000000000
-- 103:000000f0000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000f0000000000000000000000000000000000000000000
-- 104:0000000ff0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000ff00000000000000000000000000000000000000000000
-- 105:000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000ff0000000000000000000000000000000000000000000000
-- 106:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000ff000000000000000000000000000000000000000000000000
-- 107:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffffffff00000000000000000000000000000000000000000000000000
-- 119:00000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 120:00000000000000000000000000000000000000000000000000f0ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 121:0000000000000000000000000000000000000000000000000f0000fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 122:0000000000000000000000000000000000000000000000000f0000000ff000000fffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 123:000000000000000000000000000000000000000000000000f0000000000ffffff0000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 124:000000000000000000000000000000000000000000000000f00000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 125:00000000000000000000000000000000000000000000000f000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 126:00000000000000000000000000000000000000000000000f000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 127:0000000000000000000000000000000000000000000000f00000000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 128:0000000000000000000000000000000000000000000000f00000000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 129:000000000000000000000000000000000000000000000f000000000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 130:000000000000000000000000000000000000000000000f000000000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 131:000000000000000000000000000000000000000000000f000000000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 132:00000000000000000000000000000000000000000000f00000000000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 133:00000000000000000000000000000000000000000000f00000000000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 134:00000000000000000000000000000000000000000000f000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 135:00000000000000000000000000000000000000000000f000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </SCREEN>

-- <PALETTE>
-- 000:140c1c44243430346d4e4a4e854c30346524d04648757161597dced27d2c8595a16daa2cd2aa996dc2cadad45edeeed6
-- </PALETTE>

