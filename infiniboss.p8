pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
-- infiniboss
debugtext = ""
seed = 6
pi = 3.14159265359
timer = 0

-- boss
boss = {}

boss.x = 10
boss.y = 10
boss.width = 7
boss.height = 7
boss.block_density = 2
boss.wep_quantity = 5
boss.tiles = {}
boss.tiles.blocks = {}
boss.tiles.weps = {}
boss.dx = 0
boss.dy = 0
boss.accel = 0.2
boss.deccel = 0.7
boss.maxspd = 3
boss.defaultblockhp = 10
boss.bullets = {}
boss.bulletmax = 100
boss.bulletspd = 2
boss.bulletdmg = 10
boss.missiles = {}
boss.missilemax = 50
boss.missilespd = 1
boss.missiledmg = 50
boss.destroyedblockspr = 146

shotmaxdist = 200

-- player
player =  {}

player.x = 64
player.y = 70
player.dx = 0
player.dy = 0
player.deccel = 0.82
player.accel = 0.5
player.maxspd = 4
player.spr = 128
player.wep1 = {}
player.wep1.offsetx=7
player.wep1.offsety=4
player.wep1.y2 = 0
player.wep1.shooting=false
player.wep2 = {}
player.wep2.offsetx=7
player.wep2.offsety=12
player.wep2.x2 = 0
player.wep2.y2 = 0
player.wep2.shooting=false
player.hp = 100
player.colbox = {}
player.colbox.x1 = 0
player.colbox.y1 = 0
player.colbox.x2 = 0
player.colbox.y2 = 0

-- camera
cam = {}
cam.x = 0
cam.y = 0
cam.dx = 0
cam.dy = 0
cam.deccel = 0.8
cam.accel = 0.6
cam.offsetx = 54
cam.offsety = 90
cam.leeway = 5

starfield = {}
sparks = {}
explosions = {}
movedust = {}
movedust_width = 6
movedust_height = 6
movedust_length_multiplier = 10
movedust_spacing = 20

function _init()
	settestboss("medium")

	init_timers()
	
	camera(cam.x,cam.y)
	srand(seed)
	
	initbossmatrix()
	generateboss()
	initstarfield()
	initmovedust()
end

function _update()
	timer=time()
	update_timers()
	
	moveplayer()
	movecamera()
	moveboss()
	blinkstars()
	playershoot()
 bossshoot()
 movebossshots()
 
 cleanupshots()
 checkcollisions()
 debugtext = "hp: "..player.hp
end

function _draw()
	cls()
	drawstarfield()
	--rectfill(0,0,50,50,3)
	drawmovedust()
	drawboss()
	drawplayer()
	drawplayershots()
	drawbossshots()
	drawexplosions()
		
	drawstats()
	drawdebug()
end

-- init stuff

function initstarfield()
	index=1
	spacing=18
	camoffset=-64
	colors = {0,1,2}
	for i=0,8 do
		for j=0,8 do
			x=i*spacing+(flr(rnd(14))-7)+camoffset
			y=j*spacing+(flr(rnd(14))-7)+camoffset
			randcol = flr(rnd(3))+1
			starfield[index] = {x,y,colors[randcol]}
			index+=1
		end
	end

end

function initbossmatrix()
	for i=1,boss.height do
		boss.tiles.blocks[i] = {}
		boss.tiles.weps[i] = {}
		for j=1,boss.width do
			boss.tiles.blocks[i][j] = {}
			boss.tiles.weps[i][j] = {}
			
			boss.tiles.blocks[i][j].spr = 0
		 boss.tiles.blocks[i][j].hp = 0
		 boss.tiles.weps[i][j].spr = 0
		 boss.tiles.weps[i][j].hp = 0
		end
	end
end

function initmovedust()
	for i=1,movedust_width do
		movedust[i] = {}
		for j=1,movedust_height do
			dust = {}
			dust.x1 = i*movedust_spacing + flr(rnd(10)-5)
			dust.y1 = j*movedust_spacing + flr(rnd(10)-5)
			dust.x2 = dust.x1
			dust.y2 = dust.y1
		 movedust[i][j] = dust
		end
	end
end

-- draw functions

function drawboss()
 -- blocks
	for colk,colv in pairs(boss.tiles.blocks) do
		for cellk=1,boss.height do
			cellv=colv[cellk]
			if ( cellv.spr != 0 ) then
				spr(cellv.spr, boss.x+8*colk, boss.y+8*cellk)
			end
		end
	end
 -- weps
	for colk,colv in pairs(boss.tiles.weps) do
		for cellk=1,boss.height do
			cellv=colv[cellk]
			if ( cellv.spr != 0 ) then
				spr(cellv.spr, boss.x+8*colk, boss.y+8*cellk)
			end
		end
	end

end

function drawplayer()
	spr(player.spr,player.x,player.y,2,2)	
end

function drawstarfield()
	for star in all(starfield) do
		x = star[1]+cam.x
		y = star[2]+cam.y
		col = star[3]
		rectfill(x,y,x,y,col)
	end
end

function drawplayershots()
	if player.wep1.shooting then
	 x1=player.x+player.wep1.offsetx
	 y1=player.y+player.wep1.offsety
	 x2=x1
	 y2=player.wep1.y2
		line(x1,y1,x2,y2,10)
		line(x1+1,y1,x2+1,y2,9)
	 drawsparks()
	end
	if player.wep2.shooting then
		x1=player.x+player.wep2.offsetx
		y1=player.y+player.wep2.offsety
		x2=player.wep2.x2
		y2=player.wep2.y2
		line(x1,y1,x2,y2,10)
		line(x1+1,y1,x2+1,y2,9)
	end
end

function drawbossshots()
	-- boss.bullets,
	-- boss.beams,
	-- boss.missiles
	for bullet in all(boss.bullets) do
		spr(132,bullet.x,bullet.y)
	end
	for missile in all	(boss.missiles) do
		spr(134,missile.x,missile.y)
	end
end

function drawsparks()
	if (sparks[1] != nil) then
		spr(131,sparks[1],sparks[2])
	end
end

function drawexplosions()
	for expl in all(explosions) do
		if expl.size > 0 then
	 	-- main ball and interior glow
	 	circfill(expl.x,expl.y,expl.size,expl.col1)
	 	circfill(expl.x,expl.y,expl.size/2,expl.col2)
	 	-- secondary ball and interior glow
	 	circfill(expl.randx1,expl.randy1,expl.size/2,expl.col2)
	 	circfill(expl.randx1,expl.randy1,expl.size/4,expl.col3)
	 	-- tertiary ball and interior glow
	 	circfill(expl.randx2,expl.randy2,expl.size/2,expl.col2)
	 	circfill(expl.randx2,expl.randy2,expl.size/4,expl.col3)

	 	expl.size -= 1
	 else
	 	del(explosions,expl)
	 end
	end
end

function drawmovedust()
	length_x = flr(-player.dx*movedust_length_multiplier)
	length_y = flr(-player.dy*movedust_length_multiplier)
	for i=1,movedust_width do
		for j=1,movedust_height do
		 x1=movedust[i][j].x1 + cam.x - cam.offsetx
		 y1=movedust[i][j].y1 + cam.y - cam.offsety
		 x2=movedust[i][j].x2 + cam.x - cam.offsetx + length_x
		 y2=movedust[i][j].y2 + cam.y - cam.offsety + length_y
 
 		--debugtext = length_x.." "..length_y
			colors={1,2,5,13}
			if (abs(length_x) <= 2) and
				(abs(length_y) <= 2) then
				col = colors[flr(rnd(2))]
			elseif (abs(length_x) <= 25) and
				(abs(length_y) <= 25) then
				col = colors[flr(rnd(3))]
			else
				col = colors[flr(rnd(5))]
			end 
			
			line(x1,y1,x2,y2,col)
		end
	end
end

-- update functions

function moveplayer()
 -- always deccelerate
 player.dx *= player.deccel
 player.dy *= player.deccel
 
 -- right
 if (btn(1) 
 and player.dx < player.maxspd) then 
		player.dx+=player.accel
	end
	-- left
 if (btn(0) 
 and player.dx > -player.maxspd) then 
		player.dx-=player.accel
	end
 -- down
 if (btn(3) 
 and player.dy < player.maxspd) then 
		player.dy+=player.accel
	end
	-- up
 if (btn(2) 
 and player.dy > -player.maxspd) then 
		player.dy-=player.accel
	end	
	
	-- apply accel to position
	player.x=round(player.x+player.dx)			
	player.y=round(player.y+player.dy)

	-- move collision box
	player.colbox.x1 = player.x + 3
	player.colbox.y1 = player.y + 3
	player.colbox.x2 = player.x + 13
	player.colbox.y2 = player.y + 13
end

function movecamera()
	-- always deccelerate
 cam.dx *= cam.deccel
 cam.dy *= cam.deccel
 
	-- change spd relative to player position
	if (cam.x > player.x+cam.leeway) then
		cam.dx-=cam.accel
	elseif (cam.x < player.x-cam.leeway) then
		cam.dx+=cam.accel
	end
	if (cam.y > player.y+cam.leeway) then
		cam.dy-=cam.accel
	elseif(cam.y < player.y-cam.leeway) then
		cam.dy+=cam.accel
	end
	
	cam.x=round(cam.x+cam.dx)
	cam.y=round(cam.y+cam.dy)
	
	camera(cam.x-cam.offsetx,cam.y-cam.offsety)
		
end

function moveboss()
	centerx=boss.x+boss.width*8
	centery=boss.y+boss.height*8
	
		-- always deccelerate
 boss.dx *= boss.deccel
 boss.dy *= boss.deccel
	
	if (boss_is_far_from_player()) then
		-- approach player
		if (centerx < player.x 
			and boss.dx < boss.maxspd) then
			boss.dx += boss.accel
		elseif (centerx >= player.x
			and boss.dx > -boss.maxspd) then
			boss.dx -= boss.accel
		end
		if (centery < player.y
			and boss.dy < boss.maxspd) then
			boss.dy += boss.accel
		elseif (centery >= player.y
			and boss.dy > -boss.maxspd) then
			boss.dy -= boss.accel
		end
			
	else
		-- roam randomly
		-- todo?
	end
	
	-- apply deltas to position
	boss.x=round(boss.x+boss.dx)			
	boss.y=round(boss.y+boss.dy)
end

function boss_is_far_from_player()
	centerx=boss.x+boss.width*4
	centery=boss.y+boss.height*4
	
	max_distance=8*boss.width
	
	if (abs(centerx-player.x) > max_distance
		or abs(centery-player.y) > max_distance) then
		return true
	else
		return false
	end
end

function playershoot()
	if (btn(4)) then
		player.wep1.shooting=true
		playerwepcollisions()
	else
		player.wep1.shooting=false
	end
	if (btn(5)) then
		player.wep2.shooting=true
	else
		player.wep2.shooting=false
	end
end

function bossshoot()
	for i=1,boss.width do
		for j=1,boss.height do
			wep = boss.tiles.weps[i][j]
			wepx = boss.x+i*8
			wepy = boss.y+j*8
			if wep.spr != 0
				and wep.hp > 0 then
					-- wep types
					if wep.spr == 112 then
						-- bossshootbeam()
					elseif wep.spr == 113 then
						if nsec(1) then
							bossshootbullet(wepx,wepy)
						end
					elseif wep.spr == 114 then
						if nsec(1) then
							bossshootmissile(wepx,wepy)
						end
					end
					
			end		
		end
	end
end

function bossshootbullet(wepx,wepy)
 	-- create bullet with direction
	bullet = {}
	bullet.x = wepx
	bullet.y = wepy
	bullet.destx = player.x
	bullet.desty = player.y
	bullet.angle = 0
	bullet.prox = 0.2
	bullet.orig_angle = get_angle(bullet.x,bullet.y,bullet.destx,bullet.desty)
 
 
	if #boss.bullets <= boss.bulletmax then
		add(boss.bullets, bullet)
	end
end

function bossshootmissile(wepx,wepy)
	missile = {}
	missile.x = wepx
	missile.y = wepy
	missile.destx = player.x
	missile.desty = player.y
	missile.angle = 0
	missile.prox = 0.2

	if #boss.missiles <= boss.missilemax then
		add(boss.missiles, missile)
	end
end

function movebossshots()

	for bullet in all(boss.bullets) do
 	bullet.angle = get_angle_lerp(bullet.angle,bullet.orig_angle,bullet.prox)
		bullet.x += boss.bulletspd * cos(bullet.angle)
		bullet.y += boss.bulletspd * sin(bullet.angle)
	end
	
	for missile in all(boss.missiles) do
		angle = get_angle(missile.x,missile.y,player.x,player.y)
		missile.angle = get_angle_lerp(missile.angle,angle,missile.prox)
		missile.x += boss.missilespd * cos(missile.angle)
		missile.y += boss.missilespd * sin(missile.angle)
	end
		
end

function cleanupshots()
	for bullet in all(boss.bullets) do
		if abs(bullet.x-player.x) > shotmaxdist
			or abs(bullet.y-player.y) > shotmaxdist then
			del(boss.bullets, bullet)
		end
	end
end

function blinkstars()
	if nsec(0.5) then
		for star in all(starfield) do
			star[3] = get_rand_star_br(star[3])
		end
	end		
end

function damage_block(col,row,dmg)
	-- check for wep
	if boss.tiles.weps[col][row].spr != 0 then
		boss.tiles.weps[col][row].hp -= dmg
		if boss.tiles.weps[col][row].hp <= 0 then	
			destroy_wep(col,row)
		end
	else	
		boss.tiles.blocks[col][row].hp -= dmg
		if boss.tiles.blocks[col][row].hp <= 0 then
			destroy_block(col,row)
		end
	end
end

function destroy_block(col,row)
	blockspr = boss.tiles.blocks[col][row].spr

 block_x=boss.x + (col*8) + 4
 block_y=boss.y + (row*8) + 4
	boss.tiles.blocks[col][row].spr = boss.destroyedblockspr
	
	if get_block_type(blockspr) == "core" then
	 generate_explosion(block_x,block_y,15,2,8,14)	
	 generate_explosion(block_x-10,block_y,12,2,8,14)
	 generate_explosion(block_x+10,block_y,12,2,8,14)
		--todo: trigger next level?
	else
 	generate_explosion(block_x,block_y,10,9,10,7)
	end
end

function destroy_wep(col,row)
	boss.tiles.weps[col][row].spr = 0
 block_x=boss.x + (col*8) + 4
 block_y=boss.y + (row*8) + 4
 
 generate_explosion(block_x,block_y,7,8,14,7)
end

-- collisions

function checkcollisions()
	for bullet in all(boss.bullets) do
		if collideswithplayer(bullet.x,bullet.y) then
		 generate_explosion(bullet.x,bullet.y,8,2,8,14)
			player.hp -= boss.bulletdmg
			del(boss.bullets,bullet)
		end	
	end
end

function collideswithplayer(x,y)
	if x >= player.colbox.x1 and
		x <= player.colbox.x2 and
		y >= player.colbox.y1 and
		y <= player.colbox.y2 then
		return true
	else
		return false
	end
end

function playerwepcollisions()
 x1=player.x+player.wep1.offsetx
 y1=player.y+player.wep1.offsety

	--default laser destination
	player.wep1.y2=cam.y-cam.offsety
	
	tilew=8
	tileh=8
	
	damagedblock=nil
	dmgx=0
	dmgy=0
	
 for i=1,boss.width do
 	for j=1,boss.height do
 		if boss.tiles.blocks[i][j].spr == 0 then
 		 --nothing
 		elseif boss.tiles.blocks[i][j].spr != boss.destroyedblockspr then
 			tilex=boss.x-1+i*8
 			tiley=boss.y-1+j*8
 			if (x1 >= tilex 
 				and x1 <= tilex+tilew
 				and y1 >= tiley+tileh) then
 				-- block i,j is being shot!
 				--debugtext = "i,j: "..i..","..j
 				player.wep1.y2=tiley+tileh
 				damagedblock={i,j}
 				dmgx=x1-3
 				dmgy=tiley+4
 				
 				end
 		
 		end
 	end
 end
	
	if damagedblock then
		sparks = {dmgx,dmgy}
		damage_block(damagedblock[1],damagedblock[2],1)
	else
		sparks = {nil,nil}
	end
	
end

-- boss generation

function generateboss()
	midcol = flr(boss.width/2)+1
	midrow = flr(boss.height/2)+1
	
	-- add core
	boss.tiles.blocks[midcol][midrow].spr = 1	

 -- add filler blocks
 boss.tiles.blocks[midcol][midrow-1].spr = get_rand_block("filler")
 boss.tiles.blocks[midcol][midrow+1].spr = get_rand_block("filler")
 boss.tiles.blocks[midcol-1][midrow].spr = get_rand_block("filler")
 
 -- add more fillers randomly
 for i=1,boss.block_density do
	 add_rand_filler_blocks()
 end
			
		-- change terminations
	change_border_blocks()
	
	-- remove floating blocks
	remove_floating_blocks()

	-- add more terminations randomly
 add_rand_term_blocks()

	-- add weapons
	add_boss_weps()

	-- mirror boss tiles
	mirror_boss_tiles()

	-- give tiles initial hp
	give_initial_tile_hp()
end

function add_rand_filler_blocks()
	halfw = flr(boss.width/2)+1
	rand_offsets = {-1,0,1}
	
	for col=1,halfw do
		for row=1,boss.height do
			if (boss.tiles.blocks[col][row].spr != 0) then
				rand_offset_x = rand_offsets[flr(rnd(3))+1]
				rand_offset_y = rand_offsets[flr(rnd(3))+1]
				newcol = col + rand_offset_x
				newrow = row + rand_offset_y
	   if (newcol >=1 and 
	   	newcol <= halfw and
	   	newrow >= 1 and
	   	newrow <= boss.height and
	   	boss.tiles.blocks[newcol][newrow].spr == 0) then
					boss.tiles.blocks[newcol][newrow].spr = get_rand_block("filler")	   
	   end		 
			end
		end
	end
end

function add_rand_term_blocks()
	halfw = flr(boss.width/2)+1

	for col=1,halfw do
		for row=1,boss.height do
			left = false
			right = false
			top = false
			bottom = false

			if (boss.tiles.blocks[col][row].spr == 0) then
								-- if right block is filler...
				if (col < halfw and get_block_type(boss.tiles.blocks[col+1][row].spr) == "filler") then
				 left = true
				end
				-- if left block is filler...
				if (col > 1 and col < halfw and get_block_type(boss.tiles.blocks[col-1][row].spr) == "filler") then
				 right = true
				end
				-- if bottom block is filler...
				if (row < boss.height and get_block_type(boss.tiles.blocks[col][row+1].spr) == "filler") then
					top = true
				end
			 -- if top block is filler...
				if (row > 1 and get_block_type(boss.tiles.blocks[col][row-1].spr) == "filler") then
					bottom = true
				end
				
				if (left and right) then		
					boss.tiles.blocks[col][row].spr = get_rand_block("leftright")
				elseif (top and bottom) then		
					boss.tiles.blocks[col][row].spr = get_rand_block("topbottom")
				elseif (left and bottom) then
					boss.tiles.blocks[col][row].spr = get_rand_block("bottoml")
				elseif (right and bottom) then		
					boss.tiles.blocks[col][row].spr = get_rand_block("bottomr")
				elseif (left) then		
					boss.tiles.blocks[col][row].spr = get_rand_block("left")
				elseif (right) then		
					boss.tiles.blocks[col][row].spr = get_rand_block("right")
				elseif (top) then		
					boss.tiles.blocks[col][row].spr = get_rand_block("top")
				elseif (bottom) then		
					boss.tiles.blocks[col][row].spr = get_rand_block("bottom")
				end				
			end	 
	 end
	end
end

function remove_floating_blocks()
	for col=1,boss.width do
		for row=1,boss.height do
			if ( boss.tiles.blocks[col][row].spr != 0 and not has_adjacent_blocks(col,row) ) then
				boss.tiles.blocks[col][row].spr = 0
			end
		end
	end
end

function has_adjacent_blocks(col,row)
	result = false
	if (col-1 > 0 and boss.tiles.blocks[col-1][row].spr != 0) then
  result = true
 end
	if (col+1 < boss.width+1 and boss.tiles.blocks[col+1][row].spr != 0) then
  result = true
 end
	if (row-1 > 0 and boss.tiles.blocks[col][row-1].spr != 0) then
  result = true
 end
	if (row+1 < boss.height+1 and boss.tiles.blocks[col][row+1].spr != 0) then
  result = true
 end
 return result
end

function change_border_blocks()
	halfw = flr(boss.width/2)+1
	
	for col=1,halfw do
		for row=1,boss.height do
			if (boss.tiles.blocks[col][row].spr != 0) then
			
				if (col == 1) then
					if (get_block_type(boss.tiles.blocks[col][row].spr) == "filler") then
			 		boss.tiles.blocks[col][row].spr = get_rand_block("left")
			 	end	
				elseif (row == 1) then
					if (get_block_type(boss.tiles.blocks[col][row].spr) != "top") then
			 		boss.tiles.blocks[col][row].spr = get_rand_block("top")
			 	end	
				elseif (row == boss.height) then
					if (get_block_type(boss.tiles.blocks[col][row].spr) != "bottom") then
			 		boss.tiles.blocks[col][row].spr = get_rand_block("bottom")
			 	end	
				end
			
			end
		end
	end
end

function mirror_boss_tiles()
	halfw = flr(boss.width/2)+1
	
	for col=1,halfw do
		for row=1,boss.height do
			blockspr = boss.tiles.blocks[col][row].spr
			blocknewcol = boss.width+1-col
			if (blockspr != 0) then
				blocktype = get_block_type(blockspr)
				
				if (blocktype == "left"
					or blocktype == "bottoml") then 
					blockspr+=8
				elseif (blocktype == "right"
					or blocktype == "bottomr") then
					blockspr-=8					
				end
		
				boss.tiles.blocks[blocknewcol][row].spr = blockspr
		 
		 	-- mirror weapons too!
		 	wepspr = boss.tiles.weps[col][row].spr
		 	if (wepspr != 0) then
		 		boss.tiles.weps[blocknewcol][row].spr = wepspr
		 	end
		 end
		end
	end
end

function give_initial_tile_hp()
	for i=1,boss.width do
		for j=1,boss.height do
			if boss.tiles.blocks[i][j].spr != 0 then
				boss.tiles.blocks[i][j].hp = boss.defaultblockhp
			end
			if boss.tiles.weps[i][j].spr != 0 then
				boss.tiles.weps[i][j].hp = boss.defaultblockhp
			end
		end
	end
end


function add_boss_weps()
	halfw = flr(boss.width/2)+1
	filler_count = 0
	
	-- first, count filler blocks
	for col=1,halfw do
		for row=1,boss.height do
			if (get_block_type(boss.tiles.blocks[col][row].spr) == "filler") then
				filler_count+=1
			end
		end
	end

	wep_spacing = flr(filler_count/boss.wep_quantity)+1
	filler_count = 0
	
	-- populate with weps, spaced
	for col=1,halfw do
		for row=1,boss.height do
			if (get_block_type(boss.tiles.blocks[col][row].spr) == "filler") then
				filler_count+=1
				if (filler_count%wep_spacing == 0) then
					boss.tiles.weps[col][row].spr = get_rand_wep()
				end				
			end
		end
	end	
	
end

function get_rand_wep()
	return 112+flr(rnd(3))
end

function get_rand_block(blocktype)
	start=0
	len=1
	if (blocktype == "filler") then
		start=2
		len=15
	elseif (blocktype == "top") then
		start=64
		len=6
	elseif (blocktype == "left") then
		start=80
		len=8
	elseif (blocktype == "bottom") then
		start=72
		len=8
	elseif (blocktype == "right") then
		start=88
		len=8
	elseif (blocktype == "bottoml") then
		start=96
		len=8
	elseif (blocktype == "bottomr") then
		start=104
		len=8
	elseif (blocktype == "bottomlr") then
		start=24
		len=2
	elseif (blocktype == "leftright") then
		start=40
		len=4
	elseif (blocktype == "topbottom") then
		start=44
		len=4
 end
 
	return start+flr(rnd(len))

end

function get_block_type(num)
	if (num == 1) then
		return "core"
	end
	if (num>=2 and num<=23) then
		return "filler"
	end
	if (num>=24 and num<=31) then
		return "bottomlr"
	end
	if (num>=40 and num<=43) then
		return "leftright"
	end
	if (num>=44 and num<=47) then
		return "topbottom"
	end
	if (num>=64 and num<=71) then
		return "top"
	end
	if (num>=72 and num<=79) then
		return "bottom"
	end
	if (num>=80 and num<=87) then
		return "left"
	end
	if (num>=88 and num<=95) then
		return "right"
	end
	if (num>=96 and num<=103) then
		return "bottoml"
	end
	if (num>=104 and num<=111) then
		return "bottomr"
	end
	return "unknown"
end

function get_rand_star_br(col)
 colors = {{0,5,6},{0,1,6},{0,2,13}}
	blink=flr(rnd(10))
	
	if blink==1 then
		for list in all(colors) do
			if col==list[1] then	
				col=list[2]
			elseif col==list[2] then	
				col=list[3]
			elseif col==list[3] then	
				col=list[1]
			end
		end
	end
	return col
end

function generate_explosion(x,y,size,col1,col2,col3)
	explosion = {}
	explosion.x = x
	explosion.y = y
	explosion.size = size
	explosion.col1 = col1
	explosion.col2 = col2
	explosion.col3 = col3
	explosion.randx1 = x + flr(rnd(10)-5)
	explosion.randy1 = y + flr(rnd(10)-5)
	explosion.randx2 = x + flr(rnd(10)-5)
	explosion.randy2 = y + flr(rnd(10)-5)
	
	add(explosions, explosion)
end

function drawstats()
 mem = truncdecimals(stat(0),2)
 cpu = truncdecimals(stat(1)*100,2)
 memtxt = "mem: "..mem.." mb"
 cputxt = "cpu: "..cpu.."%"
 x = cam.x-cam.offsetx
 y = cam.y-cam.offsety
 print(memtxt, x, y, 11)
 print(cputxt, x, y+6, 11)
end

function drawdebug()
	x = cam.x-cam.offsetx
	y = cam.y-cam.offsety+122
	print(debugtext, x, y, 7)
end

function settestboss(size)
	if size == "small" then
		boss.width = 5
		boss.height = 5
		boss.block_density = 1
		boss.wep_quantity = 2
	elseif size == "medium" then
		boss.width = 9
		boss.height = 9
		boss.block_density = 4
		boss.wep_quantity = 8
	elseif size == "big" then
		boss.width = 17
		boss.height = 17
		boss.block_density = 10
		boss.wep_quantity = 15
	elseif size == "huge" then
		boss.width = 31
		boss.height = 31
		boss.block_density = 15
		boss.wep_quantity = 25
	end
end

function get_angle(x1,y1,x2,y2)
	dx = x2 - x1
	dy = y2 - y1
	return atan2(dx, dy)-- * 180 / pi
end

function get_angle_lerp(angle1,angle2,t)
	angle1=angle1%1
	angle2=angle2%1
	
	if abs(angle1-angle2) > 0.5 then
		if angle1 > angle2 then
			angle2+=1
		else
			angle1+=1
		end
	end
	
	return ((1-t)*angle1 + t*angle2) %1
end

function truncdecimals(n,d)
	return flr(n).."."..flr(n%1 * 10^d)
end

function round(n)
	unsigned = abs(n)
	decimals = unsigned%1
	rounded = flr(unsigned)
	
	if decimals > 0.5 then
		rounded+=1
	end
	
	return rounded*sgn(n)
end

function nsec(n)
	if timer%n==0 then
		return true
	else
		return false
	end
end

-- timers api
local timers = {}
local last_time = nil

function init_timers ()
  last_time = time()
end

function add_timer (name,
    length, step_fn, end_fn,
    start_paused)
  local timer = {
    length=length,
    elapsed=0,
    active=not start_paused,
    step_fn=step_fn,
    end_fn=end_fn
  }
  timers[name] = timer
  return timer
end

function update_timers ()
  local t = time()
  local dt = t - last_time
  last_time = t
  for name,timer in pairs(timers) do
    if timer.active then
      timer.elapsed += dt
      local elapsed = timer.elapsed
      local length = timer.length
      if elapsed < length then
        if timer.step_fn then
          timer.step_fn(dt,elapsed,length,timer)
        end  
    else
        timer.active = false
        if timer.end_fn then
          timer.end_fn(dt,elapsed,length,timer)
        end
      end
    end
  end
end

function pause_timer (name)
  local timer = timers[name]
  if (timer) timer.active = false
end

function resume_timer (name)
  local timer = timers[name]
  if (timer) timer.active = true
end

function restart_timer (name, start_paused)
  local timer = timers[name]
  if (not timer) return
  timer.elapsed = 0
  timer.active = not start_paused
end
__gfx__
50000005566dd66555d66d5506667770d676676d5d5555d50555555006667770d6d66d6d55555555000d5000d006600d557dd755066666605d6dd6d55d6dd6d5
0500005065d55d565dd56dd576dddd66d66dd66dd6dddd6d55dddd557ddd66d65dd66dd555dddd55000d500000dddd00556dd6556756565d5d6556d55d7dd7d5
005005006d5885d65d5665d57d6556d6d6d67d6d656767565dd66dd57d6d77d6d6d55d6dd600006d00766d000d5665d0556dd655656560dd5d7dd7d55d7dd7d5
00055000d589a85d5d5665d57d5d75d6dd65d7dd667dd6665d6d76d57ddd77d65dd55dd55d5555d5dd6dd5dd6d6d76d655d55d5566560d0d5d7557d55d7dd7d5
00055000d588985d5d5665d56d57d5d7dd7d56dd666dd7665d67d6d56dd77dd7d6d55d6dd600006d556dd5556d67d6d6dd5555dd6560d05d5d7557d55d7dd7d5
005005006d5885d65d5665d56d6556d7d6d76d6d657676565dd66dd56d77ddd75dd55dd55d5555d500d555000d5665d075577557660d050d5d7dd7d55d7dd7d5
0500005065d55d565dd65dd566dddd67d66dd66dd6dddd6d55dddd556d66d6d7d6d66d6dd600006d000d500000dddd007657656765d0505d5d6556d55d7dd7d5
50000005566dd66555d66d5507776660d676676d5d5555d555555555077766605dd66dd555dddd55000d5000d006600dddd76ddd0dddddd05d6dd6d55d6dd6d5
07d66d505000000550000005500000055000000550000005500000055000000567dddd76dd5765dd500000055000000550000005500000055000000550000005
76666d6505000050050000500500005005000050050000500500005005000050667dd7667d5765d7050000500500005005000050050000500500005005000050
76d6dd65005005000050050000500500005005000050050000500500005005006567766676555567005005000050050000500500005005000050050000500500
7666d66500055000000550000005500000055000000550000005500000055000566666657dd55dd7000550000005500000055000000550000005500000055000
76d6d66500055000000550000005500000055000000550000005500000055000d556655dd7dddd7d000550000005500000055000000550000005500000055000
7666d66500500500005005000050050000500500005005000050050000500500ddd55ddd557dd755005005000050050000500500005005000050050000500500
76d6d665050000500500005005000050050000500500005005000050050000505dd55dd5dd5555dd050000500500005005000050050000500500005005000050
0766d650500000055000000550000005500000055000000550000005500000050555555000dddd00500000055000000550000005500000055000000550000005
500000055000000550000005500000055000000550000005500000055000000500000000000000000000000000000000000d500000dd55000ddd55500d55dd50
05000050050000500500005005000050050000500500005005000050050000500000000000000000d000000dd666666d000d500000065000006dd50006500650
005005000050050000500500005005000050050000500500005005000050050000766d00d000000dd666666d5555555500766d0000065000006dd50006500650
0005500000055000000550000005500000055000000550000005500000055000dd6dd5ddd666666ddddddddd50000005006dd50000065000006dd50006500650
0005500000055000000550000005500000055000000550000005500000055000556dd555555555555dddddd5d000000d006dd50000065000006dd50006500650
005005000050050000500500005005000050050000500500005005000050050000d555005000000555555555d666666d00d5550000065000006dd50006500650
050000500500005005000050050000500500005005000050050000500500005000000000000000005000000555555555000d500000065000006dd50006500650
500000055000000550000005500000055000000550000005500000055000000500000000000000000000000000000000000d500000dd55000ddd55500d55dd50
d577d77d556dd655d77d775d5dd77d7777d77dd55555555555555555500000055000000550000005500000055000000550000005500000055000000550000005
6677d77d556dd655d77d77665dd77d7777d77dd555d5666556665d55050000500500005005000050050000500500005005000050050000500500005005000050
d677d77d556dd655d77d776d5dd7dd7dd7dd7dd5d6d6666666666d6d005005000050050000500500005005000050050000500500005005000050050000500500
6677d77d55d55d55d77d77665d77d77dd77d77d55dd6555665556dd5000550000005500000055000000550000005500000055000000550000005500000055000
d677dd77dd5555dd77dd776d5d77d77dd77d77d5d6dd757dd757dd6d000550000005500000055000000550000005500000055000000550000005500000055000
66677dd7755775577dd776665d77d77dd77d77d55ddd7d7dd7d7ddd5005005000050050000500500005005000050050000500500005005000050050000500500
566d77dd76576567dd77d6655d77d77dd77d77d5d6d77d7777d77d6d050000500500005005000050050000500500005005000050050000500500005005000050
5dddd77dddd76dddd77dddd55d77d77dd77d77d555577d7777d77555500000055000000550000005500000055000000550000005500000055000000550000005
00000000000000000005500000000000000000000000000050000005500000055d6666d5dd6766d55d6666d50d66666d05d66d50555555550666dd500d5d5d50
00000000000070000057650000000000000000000000000005000050050000505dd66dd5ddd76d555dd66dd50dd666dd05dddd5055d66d55766d6dd500766d00
0000000000008000005765000000000000d00d0000000000005005000050050055dddd550dd76d5005dddd5000dd6dd0005dd5005d6776d57666dd5500766d00
000000000000d000005765000000000000d00d00000700000005500000055000055dd5500dd76d50005dd500000d6d00000000005d6766d5076d6d5000766d00
00766d000000d000055765500000000006d00d60000800000005500000055000005dd50000d7650000000000000060000000000055d66d550766dd5000000000
00766d000000d00005d76d500006d00006500560000d00000050050000500500000dd00000d76500000000000000600000000000055dd5500766d55000000000
00766d000000d000055765500076d50006500560000d000005000050050000500766667000d76500000000000000800000000000005555000076550000000000
0d5d5d50000dd500555dd555055555500555555000dd50005000000550000005000550000006d000000000000000700000000000000000000007500000000000
00000000000000000000d55600000000000000d50000000000000000000000000000000000000000655d0000000000005d000000000000000000000000000000
0006d5507d5d5d500006d56500000000000006d5000000000000000000006665055d600005d5d5d7565d6000000000005d600000000000000000000056660000
00076dd576ddddd50076d556ddd55555000076d5000000000000000000ddd5555dd670005ddddd67655d670055555ddd5d6700000000000000000000555ddd00
000076dd0766dddd007dd5657666dddd00007dd50000000d0766ddd500000005dd670000dddd6670565dd700dddd66675dd70000d00000005ddd667050000000
0000076d0076666d006dd5560777666d00006dd500078ddd0077666d00000005d6700000d6666700655dd600d66677705dd60000ddd87000d666770050000000
00000076000077760066d56500007776000066d5000000050000777600ddd5556700000067770000565d6600677700005d6600005000000067770000555ddd00
00000007000000070006d55600000007000006d50000000000000007000066657000000070000000655d6000700000005d600000000000007000000056660000
00000000000000000000d56500000000000000d50000000000000000000000000000000000000000565d0000000000005d000000000000000000000000000000
005555d55d65666505ddd66605d66665d5dd66775d666d655677d77d05d676555d555500566656d5666ddd5056666d507766dd5d56d666d5d77d776555676d50
005566665dd65666055d575605dd66650d5666d75dd6dd655677d77d0dd676d56666550066656dd56575d5505666dd507d6665d056dd6dd5d77d77655d676dd0
00d556d605dd6565005dd666055dd6650d556ddd55ddd6605677dd7705dd67656d655d005656dd50666dd500566dd550ddd655d0066ddd5577dd77655676dd50
000d5566005dd655005d57560055ddd500d555dd055dd60005677dd7005dd6756655d000556dd5006575d5005ddd5500dd555d00006dd5507dd77650576dd500
0000d5560005d65d005dd66600055d65000dd55d0055d600005677dd005ddd60655d0000d56d5000666dd50056d55000d55dd000006d5500dd77650006ddd500
00000d55000055550005555600005dd500000d550005d60000056777005d5d5055d0000055550000655550005dd5000055d00000006d50007776500005d5d500
000000d5000000550000005500005565000000dd00055d0000005677005d0d505d000000550000005500000056550000dd00000000d550007765000005d0d500
0000000d000000000000000000000555000000000000000000000555000d0d00d000000000000000000000005550000000000000000000005550000000d0d000
00000000000000000000000000000000500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005
050dd05005066050050dd05005085050050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050
00d88d000067760000eee800007e8500005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500
0d8e78d0067e87600de882d008e88850000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000
0d88e8d0067887600de882d0058885d0000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000
00d88d00006776000082220000585d00005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500
050dd05005066050050dd0500505d050050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050
00000000000000000000000000000000500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005
0000700000070000000000000000000000000000000a900000009000500000055000000550000005500000055000000550000005500000055000000550000005
0000e000000e0000000000000000000000000000000820000000a000050000500500005005000050050000500500005005000050050000500500005005000050
0000e000000e000000099000000aa000000220000006500000008000005005000050050000500500005005000050050000500500005005000050050000500500
0000800000080000009aa90000a77a00002e82000006500000005000000550000005500000055000000550000005500000055000000550000005500000055000
0000820000280000040a904000a77a00002882000006500000005000000550000005500000055000000550000005500000055000000550000005500000055000
000782044028700000900900000aa000000220000008200000005000005005000050050000500500005005000050050000500500005005000050050000500500
000f82477428f0000400004000000000000000000008200000006000050000500500005005000050050000500500005005000050050000500500005005000050
000a84fccf48a0000000000000000000000000000000800000008000500000055000000550000005500000055000000550000005500000055000000550000005
00faa2adda2aaf000001200000055000500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005
009a989dd989a9000011110000004000050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050
00294291192492000150011000000000005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500
082227e99e7222802105201154004005000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000
e88a2fe88ef2a88e1102101250040045000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000
9aa94a8aa8a49aa90110011000000000005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500
09944929929449900011110000040000050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050
00000492294000000002100000055000500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005
50000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005
05000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050
00500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500
00055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000
00055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000
00500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500
05000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050
50000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005
50000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005
05000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050
00500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500
00055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000
00055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000
00500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500
05000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050
50000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005
50000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005
05000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050
00500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500
00055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000
00055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000
00500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500
05000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050050000500500005005000050
50000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005500000055000000550000005
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d00000d0d0d000d0d0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000d0424142d0d0d0d0d0000000000000000000000000000000002700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000004003070340e0d0d0d000000000d0d0d0d0000000000000020c040e0e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000002c0e010f2ce0d0d0d000000000d0d0d0d0d000000000090414082b2e1700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000520b0c0d5ae0d0000000000000d0d0d0d0d0000000000012271f05040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0080810000d0511959d0e00000000000000000d0d0d00000000000000500000a180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00909100000000d0d0d0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000040424000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000063046b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000402c4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000032808010928030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004a500e060f584a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000003280b0c0d28030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004a0064196c004a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000080810000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000090910000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

