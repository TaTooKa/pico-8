pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
-- infiniboss
cartdata("tatooka_infiniboss")
debugtext = ""
seed = 2
pi = 3.14159265359
timer = 0
leveltimer = 0

state = "menu"
waiting = false
level = 1
level_msgs = {}

highscore={level=0,score=0}

-- boss
boss = {}
function initboss()
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
	boss.roamingmult = 1
	boss.defaultblockhp = 20
	boss.bullets = {}
	boss.bulletmax = 80
	boss.bulletspd = 1
	boss.bulletdmg = 10
	boss.s_bullets = {}
	boss.s_bulletmax = 100
	boss.s_bulletspd = 1
	boss.missiles = {}
	boss.missilemax = 20
	boss.missileaccel = 0.05
	boss.missilemaxspd = 2
	boss.missiledmg = 50
	boss.destroyedblockspr = 146
	boss.smoke = {}
	boss.smokeballs = {}
end

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
player.bombs = 3
player.bombsused = 0
player.bombx = 0
player.bomby = 0
player.bombgrowspd = 2
player.bombradius = 1
player.bombmaxradius = 40
player.bombactive = false
player.hp = 100
player.lvlstarthp = 0
player.colbox = {}
player.colbox.x1 = 0
player.colbox.y1 = 0
player.colbox.x2 = 0
player.colbox.y2 = 0
player.trails = {}

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

score = 0
score_missile = 1
score_block = 3
score_wep = 10
score_core = 15

starfields = {}
background = {}
sparks = {}
explosions = {}

trails = {}

function _init()
	--settestboss("big")
	load_highscore()

	init_timers()
	--srand(seed)
	
	initlevel(level)
	--music(4)	
end

function _update()
	timer=time()
	update_timers()
	
	if state == "menu" then
		blinkstars()
		menuscreen()
		updatebackground()
	elseif state == "maingame" then
		if not waiting then		
			leveltimer += 1
			moveplayer()
			movecamera()
			moveboss()
			blinkstars()
			updatebackground()
			playershoot()
		 growbomb()
		 updatesmoke()
		 updateplayertrails()
		 bossshoot()
		 movebossshots()
		 
		 cleanupshots()
		 checkcollisions()
		
			check_gameover()
		end
	elseif state == "gameover" then
		gameover_screen()		
	end
	
end

function _draw()
	if state == "menu" then
		cls()
		drawbackground()
		drawmenuscreen()
	elseif state == "maingame" then
		cls()
		drawbackground()
		drawplayertrails()
		drawboss()
		drawsmoke()
		drawbomb()
		drawplayer()
		drawplayershots()
		drawtrails()
		drawbossshots()
		drawexplosions()
	
		drawhud()
			
		--drawstats()
		drawdebug()

		drawlevelmsgscreen()
	elseif state == "gameover" then
		drawlevelmsgscreen()
	end
	
end

-- init stuff

function load_highscore()
	highscore.level = dget(0)
	highscore.score = dget(1)
end

function initlevel(level)
	
	initboss()
	leveltimer=0
	level_msgs = {}
	player.bombsused=0
	if player.bombs < 3 then
		player.bombs += 1
	end
	
	player.lvlstarthp = player.hp
	
	player.wep1.shooting=false

	resetposition()
	
	--level = 15
	size_inc = level + level%2
	
	boss.width = 9 + size_inc
	boss.height = 9 + size_inc
	boss.block_density = 1 + flr(level*0.75)
	boss.wep_quantity = 2 + flr(level/3)

	boss.y = player.y - boss.height*8 - 100
	boss.x = player.x + rnd(300)-150

	initbossmatrix()
	generateboss()
	resetbossweapons()
	initstarfield()
	initbackground()
	levelstart_screen()
end

function initstarfield()
	for i=1,9 do
		starfields[i] = {}
	end
	
	index=1
	spacing=18
	colors = {0,1,2}
	for i=0,8 do
		for j=0,8 do
			x=i*spacing+(flr(rnd(14))-7)
			y=j*spacing+(flr(rnd(14))-7)
			randcol = flr(rnd(3))+1
			for k=1,9 do
				starfields[k][index] = {x,y,colors[randcol]}
			end
			index+=1
		end
	end
end

function initbackground()
	background[1] = {x=-128,y=-128}
	background[2] = {x=0,y=-128}
	background[3] = {x=128,y=-128}
	background[4] = {x=-128,y=0}
	background[5] = {x=0,y=0}
	background[6] = {x=128,y=0}
	background[7] = {x=-128,y=128}
	background[8] = {x=0,y=128}
	background[9] = {x=128,y=128}	
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

function resetbossweapons()
	boss.bullets = {}
	boss.s_bullets = {}
	boss.missiles = {}
end

function resetplayer()
	player.hp = 100
	player.x = 64
	player.y = 70
	player.dx = 0
	player.dy = 0
	player.bombs = 3
	score = 0
end

function resetposition()
	player.x = 0	
	player.y = 0
	cam.x = 0
	cam.y = 0
	player.trails = {}
	camera(cam.x-cam.offsetx,cam.y-cam.offsety)
end

-- game state stuff

function goto_nextlevel()
	waiting = true
	levelcomplete_screen()
	add_timer("wait3",5,nil,
		function()
			level += 1
			initlevel(level)
		end
	)
end

function check_gameover()
	if player.hp <= 0 then
		player.hp = 0
		sfx(1)
		generate_explosion(player.x+8,player.y+8,10,8,9,10)
		generate_explosion(player.x-2,player.y+8,7,8,9,10)
		generate_explosion(player.x+18,player.y+8,7,8,9,10)

		if nsec(0.5) then
			state = "gameover"
			goto_gameover_screen()
		end
	end
end

function levelstart_screen()
	if state != "maingame" then
		return
	end
	msg = {text="level "..level.." start",x=37,y=35,c=7}
	add(level_msgs,msg)
	sfx(11)

	add_timer("levels1",1,nil,
		function()
			msg = {text="ready!",x=52,y=45,c=7}
			add(level_msgs,msg)
		end
	)
	add_timer("levels2",1.5,nil,
		function()
			waiting=false
			level_msgs={}
			music(7)
		end
	)

end

function levelcomplete_screen()
	msg = {text="core destroyed",x=35,y=35,c=7}
	add(level_msgs,msg)
	music(-1)

	extralife=0
	
	seconds = leveltimer/30
	if flr(seconds) < 30 then
		timebonus = 30 - flr(seconds)
		extralife+=10
	else
		timebonus = 0
	end
	
	add_timer("levelc1",0.5,nil,
		function()
			msg = {text="time: "..seconds.." sec",x=5,y=45,c=7}
			add(level_msgs,msg)
			sfx(8)
		end
	)
	add_timer("levelc2",1,nil,
		function()
			msg = {text="time bonus: "..timebonus.." points",x=5,y=55,c=7}
			add(level_msgs,msg)
			sfx(8)
			score+=timebonus
		end
	)
	add_timer("levelc3",1.5,nil,
		function()
			if player.bombsused == 0 then
				text="no bombs used: 25 points"
				score+=25
				extralife+=10
			else
				text="bombs used, no bonus"
			end
			msg = {text=text,x=5,y=65,c=7}
			add(level_msgs,msg)
			sfx(8)
		end
	)
	add_timer("levelc4",2,nil,
		function()
			if player.lvlstarthp == player.hp then
				text="no damage received: 25 points"
				score+=25
			else
				text="damage received, no bonus"
			end
			msg = {text=text,x=5,y=75,c=7}
			add(level_msgs,msg)
			sfx(8)
		end
	)
	add_timer("levelc5",2.5,nil,
		function()
			player.hp+=extralife
			if player.hp > 100 then
				extrascore=player.hp-100
				player.hp = 100
				text="extra hp over max: "..extrascore.." points"
			else
				text=extralife.." extra hp gained"
			end
			msg = {text=text,x=5,y=85,c=7}
			add(level_msgs,msg)
			sfx(8)
			update_highscore(score)
		end
	)


end

function goto_gameover_screen()
	update_highscore(score)
	x=cam.x-cam.offsetx
	y=cam.y-cam.offsety
	camera(x,y)
	sfx(12)
	music(-1)
	
	msg={text="game over",x=47,y=40,c=8}
	add(level_msgs,msg)

	add_timer("gos1",1,nil,
		function()		
			sfx(8)
			msg={text="level: "..level,x=47,y=55,c=7}
			add(level_msgs,msg)
		end
	)
	add_timer("gos2",1.5,nil,
		function()		
			sfx(8)
			msg={text="score: "..score,x=47,y=70,c=7}
			add(level_msgs,msg)
		end
	)
end

function gameover_screen()
	if btnp(4) or btnp(5) then
		add_timer("wait2",1,nil,
			function()
				state = "menu"
			end
		)
	end
end

-- draw functions

function drawmenuscreen()
	cam.x=50
	cam.y=50

	spr(192,30,36,8,2) -- danmaku
	spr(224,30,52,8,2) -- uchusen
	spr(200,30,30,5,1) -- eternal
	spr(216,47,67,6,1) -- challenge

	print("top score: "..highscore.score.." (level "..highscore.level..")",10,2,5)	
	print("press Ž/— to start",23,85,12)
	print("art and code by",15,115,5)
	print("@",78,115,12)
	print("tatooka",82,115,7)
	
end

function drawlevelmsgscreen()
	x=cam.x-cam.offsetx
	y=cam.y-cam.offsety
	for msg in all(level_msgs) do
		--rectfill(x,y+msg.y-2,x+128,y+msg.y+6,5)
		for i=0,15 do
			spr(142, x+i*8, y+msg.y-2)
		end

		print(msg.text,x+msg.x,y+msg.y,msg.c)
	end
end

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

function drawbackground()	
	screen=128
	for i=1,9 do
		--rectfill(background[i].x,background[i].y,background[i].x+screen,background[i].y+screen,i%2+1)
		for star in all(starfields[i]) do
			x = star[1]+background[i].x
			y = star[2]+background[i].y
			col = star[3]
			rectfill(x,y,x,y,col)
		end
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
end

function drawplayertrails()
	for trail in all(player.trails) do
		d=rnd(3)-1
		
		circfill(trail.x-2+d,trail.y,trail.size,8)
		circfill(trail.x+4-d,trail.y,trail.size,8)
		
	end
end

function drawbomb()
	if player.bombactive then
		colors = {8,9,10,7,7,7}
		for i=0,5 do
			circfill(player.bombx,player.bomby,player.bombradius-i*5,colors[i+1])
		end
	end
end

function drawbossshots()
	for bullet in all(boss.bullets) do
		spr(132,bullet.x,bullet.y)
	end
	
	for s_bullet in all(boss.s_bullets) do
		spr(148,s_bullet.x,s_bullet.y)
	end
	
	for missile in all	(boss.missiles) do
		drawmissile(missile)
	end
end

function drawmissile(missile)
	spr(missile.sprdata.spr,missile.x,missile.y,1,1,missile.sprdata.flipx,missile.sprdata.flipy)
end

function rotatemissile(missile)
	turnspd = 1
	dirx = "center"
	diry = "center"
	if abs(missile.spdx) < turnspd then
		if missile.x <= player.x then
			dirx = "right"			
		else
			dirx = "left"	
		end			
	end
	if abs(missile.spdy) < turnspd then
		if missile.y <= player.y then
			diry = "down"
		else
			diry = "up"
		end			
	end
	
	rotatemissilespr(missile,dirx,diry)
		
end

function rotatemissilespr(missile,dirx,diry)
	angledsprs = {
		{136,false,false,"center","down"},
		{135,true,false,"left","down"},
		{134,true,false,"left","center"},
		{135,true,true,"left","up"},
		{136,false,true,"center","up"},
		{135,false,true,"right","up"},
		{134,false,false,"right","center"},
		{135,false,false,"right","down"}	
	}
	
	targetindex=0
	for k,v in pairs(angledsprs) do
		if v[4] == dirx and
			v[5] == diry then
			targetindex=k
		end
	end
	
	curindex=missile.sprdata.index
	length=count(angledsprs)
	loopdist=length-abs(curindex-targetindex)
	dirdist=abs(curindex-targetindex)
	
	if loopdist > dirdist then			
		missile.sprdata.index += 1
		if missile.sprdata.index == 9 then
			missile.sprdata.index = 1
		end
	else
		missile.sprdata.index -= 1
		if missile.sprdata.index == 0 then
			missile.sprdata.index = 8
		end
	end
	
	missile.sprdata.spr = angledsprs[missile.sprdata.index][1]
	missile.sprdata.flipx = angledsprs[missile.sprdata.index][2]
	missile.sprdata.flipy = angledsprs[missile.sprdata.index][3]
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

function drawsmoke()
	colors={13,6,7}
	colors2={1,5,13}
	for ball in all(boss.smokeballs) do
		circfill(ball.x+1,ball.y+1,ball.size+1,colors2[ball.num])
		circfill(ball.x,ball.y,ball.size,colors[ball.num])
	end
end

function drawtrails()
	for trail in all(trails) do
		size = flr(trail.size/5)
		col = 4
		if trail.size > 3 then col = 9 end
		if trail.size > 8 then col = 10 end
		circfill(trail.x,trail.y,size,col)
		trail.size -= 1
		
		if trail.size < 0 then
			del(trails,trail)
		end		
	end
end

function drawhud()
	x = cam.x-cam.offsetx-12
	y = cam.y-cam.offsety+120
	hud = {184,185,186,187,188,138,139,170,186,187,188,154,155,185,186,188,189}
	hud2 = {184,185,186,187,188,189,141,141,141,141,141,184,185,186,187,188,189}
	for k,v in pairs(hud) do
		spr(v,x+k*8,y)
	end
	for k,v in pairs(hud2) do
		spr(v,x+k*8,y-120,1,1,false,true)
	end
	hp_width = player.hp/10+1
	hp_x=x+49
	hp_y=y+5
	line(hp_x,hp_y,hp_x+hp_width,hp_y,10)
	print("‡ "..player.hp,x+20,y+2,10)
	print(score,x+69,y+2,10)
	for i=1,player.bombs do
		print("",x+108+i*6,y+2,10)
	end
	print("lvl "..level,x+109,y-119,10)
	print("t "..sub(leveltimer/30,1,4),x+20,y-119,10)
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
	player.colbox.x1 = player.x + 6
	player.colbox.y1 = player.y + 6
	player.colbox.x2 = player.x + 11
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
 
 displacement = 50
 if level%2 == 0 then
 	displacement=-displacement
 end
	
	if (boss_is_far_from_player()) then
		-- approach player
		if (centerx < player.x+displacement 
			and boss.dx < boss.maxspd) then
			boss.dx += boss.accel
		elseif (centerx >= player.x+displacement
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
		if rnd(10) > 9 then
			boss.roamingmult *= -1
		end
		boss.dx += boss.accel * boss.roamingmult
	end
	
	-- apply deltas to position
	boss.x=round(boss.x+boss.dx)			
	boss.y=round(boss.y+boss.dy)
end

function boss_is_far_from_player()
	centerx=boss.x+boss.width*4
	centery=boss.y+boss.height*4
	
	max_distance=10*boss.width
	
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
	if (btnp(5)) then
		if not player.bombactive then
			usebomb()
		end
	end
end

function usebomb()
	if player.bombs > 0 then
		player.bombactive = true
		player.bombs -= 1
		player.bombsused += 1
		player.bombx = player.x+8
		player.bomby = player.y+8
		player.bombradius = 1
		sfx(1)
		sfx(13)
	else
		player.bombactive = false
	end
end

function growbomb()
	if player.bombactive then
		if player.bombradius < player.bombmaxradius then
			player.bombradius += player.bombgrowspd
			-- check collisions and destroy stuff
			for bullet in all(boss.bullets) do
				if get_distance(bullet.x,bullet.y,player.bombx,player.bomby) < player.bombradius then
					del(boss.bullets, bullet)
					generate_explosion(bullet.x,bullet.y,6,5,6,7)
				end
			end
			for s_bullet in all(boss.s_bullets) do
				if get_distance(s_bullet.x,s_bullet.y,player.bombx,player.bomby) < player.bombradius then
					del(boss.s_bullets, s_bullet)
					generate_explosion(s_bullet.x,s_bullet.y,6,5,6,7)
				end
			end
			for missile in all(boss.missiles) do
				if get_distance(missile.x,missile.y,player.bombx,player.bomby) < player.bombradius then
					del(boss.missiles, missile)
					generate_explosion(missile.x,missile.y,6,5,6,7)
					score += score_missile
				end
			end
			for i=1,boss.width do
				for j=1,boss.height do
					wep = boss.tiles.weps[i][j]
					wepx = boss.x+i*8
					wepy = boss.y+j*8
					if wep.spr != 0
					and wep.hp > 0 then
						if get_distance(wepx,wepy,player.bombx,player.bomby) < player.bombradius then
							destroy_wep(i,j)
						end
					end
				end
			end

		else
			player.bombactive = false
		end
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
						if nsec(1) then
							bossshootspray(wepx,wepy)
						end
					elseif wep.spr == 113 then
						if nsec(0.5) then
							bossshootbullet(wepx,wepy)
						end
					elseif wep.spr == 114 then
						if nsec(2) then
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
	bullet.desty = player.y+4
	bullet.angle = 0
	bullet.prox = 0.2
	bullet.orig_angle = get_angle(bullet.x,bullet.y,bullet.destx,bullet.desty)
 
 
	if #boss.bullets <= boss.bulletmax then
		add(boss.bullets, bullet)
		sfx(9)
	end
end

function bossshootspray(wepx,wepy)
	-- create eight s_bullets
	spd = boss.s_bulletspd
	if #boss.s_bullets <= boss.s_bulletmax+9 then
		sb={x=wepx,y=wepy,spdx=spd,spdy=spd/4}
		add(boss.s_bullets, sb)
		sb={x=wepx,y=wepy,spdx=spd*0.9,spdy=spd/2}
		add(boss.s_bullets, sb)
		sb={x=wepx,y=wepy,spdx=spd*0.7,spdy=spd*0.8}
		add(boss.s_bullets, sb)
		sb={x=wepx,y=wepy,spdx=spd*0.3,spdy=spd*1.1}
		add(boss.s_bullets, sb)
		sb={x=wepx,y=wepy,spdx=0,spdy=spd*1.2}
		add(boss.s_bullets, sb)
		sb={x=wepx,y=wepy,spdx=-(spd*0.3),spdy=spd*1.1}
		add(boss.s_bullets, sb)
		sb={x=wepx,y=wepy,spdx=-(spd*0.7),spdy=spd*0.8}
		add(boss.s_bullets, sb)
		sb={x=wepx,y=wepy,spdx=-(spd*0.9),spdy=spd/2}
		add(boss.s_bullets, sb)
		sb={x=wepx,y=wepy,spdx=-(spd),spdy=spd/4}
		add(boss.s_bullets, sb)
		sfx(9)
	end	

end

function bossshootmissile(wepx,wepy)
	missile = {}
	missile.x = wepx
	missile.y = wepy
	missile.spdx = 0
	missile.spdy = 0
	missile.sprdata = {}
	missile.sprdata.index = 1
	missile.sprdata.spr = 136
	missile.sprdata.flipx = false
	missile.sprdata.flipy = false
	
	if #boss.missiles <= boss.missilemax then
		add(boss.missiles, missile)
		sfx(10)
	end
end

function movebossshots()

	for bullet in all(boss.bullets) do
 	bullet.angle = get_angle_lerp(bullet.angle,bullet.orig_angle,bullet.prox)
		bullet.x += boss.bulletspd * cos(bullet.angle)
		bullet.y += boss.bulletspd * sin(bullet.angle)
	end
	
	for s_bullet in all(boss.s_bullets) do
		s_bullet.x += s_bullet.spdx
		s_bullet.y += s_bullet.spdy
	end
	
	for missile in all(boss.missiles) do
		movemissile(missile)
	end
		
end

function movemissile(missile)
	lastx = missile.x
	lasty = missile.y
	
	if (missile.x <= player.x+8) then
		missile.spdx += boss.missileaccel
	else
	 missile.spdx -= boss.missileaccel
	end
	
	if (missile.y <= player.y+8) then
		missile.spdy += boss.missileaccel
	else
		missile.spdy -= boss.missileaccel
	end
	
	if abs(missile.spdx) > boss.missilemaxspd then
		missile.spdx = boss.missilemaxspd * sgn(missile.spdx)
	end
	if abs(missile.spdy) > boss.missilemaxspd then
		missile.spdy = boss.missilemaxspd * sgn(missile.spdy)
	end
		
	missile.x += missile.spdx
	missile.y += missile.spdy
	if nsec(0.25) then
		rotatemissile(missile)
	end
	generate_trail(missile.x,missile.y,lastx,lasty)
	
end

function cleanupshots()
	for bullet in all(boss.bullets) do
		if abs(bullet.x-player.x) > shotmaxdist
			or abs(bullet.y-player.y) > shotmaxdist then
			del(boss.bullets, bullet)
		end
	end
	for s_bullet in all(boss.s_bullets) do
		if abs(s_bullet.x-player.x) > shotmaxdist
			or abs(s_bullet.y-player.y) > shotmaxdist then
			del(boss.s_bullets, s_bullet)
		end
	end

end

function blinkstars()
	if nsec(0.5) then
		for starfield in all(starfields) do
			for star in all(starfield) do
				star[3] = get_rand_star_br(star[3])
			end
		end
	end		
end

function updatebackground()
	cur_tile_i = get_cur_bg_tile(cam.x,cam.y) 
	
	if cur_tile_i != 5 then
		if cur_tile_i == 1 then
			mod_x = -128 mod_y = -128
		elseif cur_tile_i == 2 then
			mod_x = 0 mod_y = -128
		elseif cur_tile_i == 3 then
			mod_x = 128 mod_y = -128
		elseif cur_tile_i == 4 then
			mod_x = -128 mod_y = 0
		elseif cur_tile_i == 6 then
			mod_x = 128 mod_y = 0
		elseif cur_tile_i == 7 then
			mod_x = -128 mod_y = 128
		elseif cur_tile_i == 8 then
			mod_x = 0 mod_y = 128
		elseif cur_tile_i == 9 then
			mod_x = 128 mod_y = 128
		end
		
		for i=1,9 do
			background[i].x += mod_x
			background[i].y += mod_y
		end

	end
end

function get_cur_bg_tile(cam_x,cam_y)
	for i=1,9 do
		if cam.x >= background[i].x
			and cam.x < background[i].x+128
			and cam.y >= background[i].y
			and cam.y < background[i].y+128 then
			return i
		end
	end
	return 0
end

function updatesmoke()
	for smoke in all(boss.smoke) do
		smoke.x=boss.x + (smoke.col*8) + 3
	 smoke.y=boss.y + (smoke.row*8) + 3
	end
	
	for ball in all(boss.smokeballs) do
		ball.x = 2+ball.smoke.x-(ball.num%2)*2
		ball.y = -5+ball.smoke.y+ball.num*ball.life
		ball.size = 5-ball.life-ball.num/2
		ball.life -= 0.5
		if ball.life <= 0 then
			ball.life = 5
		end
	end
end

function updateplayertrails()
	for trail in all(player.trails) do
		trail.y+=2
		trail.size-=0.5
		if trail.size <= 0 then
			del(player.trails,trail)
		end
	end
	
	trail = {
		x=player.x+7,
		y=player.y+13,
		size=2
	}
	add(player.trails,trail)
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
	 sfx(3)
		core_explosion(block_x,block_y)
		add_timer("ce1",1,nil,
			function()
				core_explosion(block_x,block_y)
			end
		)		
		score += score_core
		goto_nextlevel()
	else
 	sfx(1)
 	generate_explosion(block_x,block_y,10,9,10,7)
		create_smoke(col,row)
		score += score_block
	end
end

function core_explosion(block_x,block_y)
	 generate_explosion(block_x,block_y,15,2,8,14)	
	 generate_explosion(block_x-10,block_y,12,2,8,14)
	 generate_explosion(block_x+10,block_y,12,2,8,14)
end

function destroy_wep(col,row)
	boss.tiles.weps[col][row].spr = 0
 block_x=boss.x + (col*8) + 4
 block_y=boss.y + (row*8) + 4
 
 sfx(2)
 generate_explosion(block_x,block_y,10,8,14,7)
	score += score_wep
end

function menuscreen()
	resetplayer()
	camera(0,0)
	if btnp(4) or btnp(5) then
		sfx(0)
		--music(-1)
		add_timer("wait",1,nil,
			function()
				level=1
				state="maingame"
				initlevel(level)
			end
		)
	end
end

-- collisions

function checkcollisions()
	for bullet in all(boss.bullets) do
		if collideswithplayer(bullet.x+4,bullet.y+4) then
		 sfx(7)
		 generate_explosion(bullet.x,bullet.y,8,14,15,7)
			player.hp -= boss.bulletdmg
			del(boss.bullets,bullet)
		end	
	end

	for s_bullet in all(boss.s_bullets) do
		if collideswithplayer(s_bullet.x+4,s_bullet.y+4) then
		 sfx(7)
		 generate_explosion(s_bullet.x,s_bullet.y,8,2,8,14)
			player.hp -= boss.bulletdmg
			del(boss.s_bullets,s_bullet)
		end	
	end

	for missile in all(boss.missiles) do
		if collideswithplayer(missile.x+4,missile.y+4) then
			sfx(4)
			sfx(7) 
		 generate_explosion(missile.x+4,missile.y+4,12,4,9,10)
			player.hp -= boss.missiledmg
			del(boss.missiles,missile)
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
	wep1_y2=player.wep1.y2
	
	tilew=8
	tileh=8
	
	damagedblock=nil
	sparks={nil,nil}
	missilehit=false
	blockhit=false
	mis_i=nil
	dmgx=0
	dmgy=0
	
	-- check hit to missiles
	for missile in all(boss.missiles) do
		if missile.x+2 <= x1 and
			missile.x+6 >= x1 and
			missile.y+6 <= y1 and
			missile.y > player.wep1.y2 then
			
			missilehit=true
			wep1_y2=missile.y
			mis_i=missile
 		
		end				
	end
	
 -- check hit to boss blocks
 for i=1,boss.width do
 	for j=1,boss.height do
 		if boss.tiles.blocks[i][j].spr == 0 then
 		 --nothing
 		elseif boss.tiles.blocks[i][j].spr != boss.destroyedblockspr then
 			tilex=boss.x-1+i*8
 			tiley=boss.y-1+j*8
 			if (x1 >= tilex 
 				and x1 <= tilex+tilew
 				and y1 >= tiley+tileh
 				and y1 <= tiley+110) then
 				-- block i,j is being shot!
 				if missilehit == false
 					or (missilehit == true 
 					and wep1_y2 < tiley+tileh) then
						blockhit=true
						wep1_y2=tiley+tileh
						damagedblock={i,j}
						dmgx=x1-3
						dmgy=tiley+4
 				end
 			end
 		end
 	end
 end
	
	if blockhit == true then
		sfx(5)
		sparks = {dmgx,dmgy}
		damage_block(damagedblock[1],damagedblock[2],1)
	elseif missilehit == true then
		sfx(4)
		generate_explosion(mis_i.x,mis_i.y,7,9,4,5)
		del(boss.missiles,mis_i)
		score += score_missile
	else
		sfx(6)
	end
	
	player.wep1.y2 = wep1_y2
	
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
			if boss.tiles.blocks[i][j].spr == 1 then
				boss.tiles.blocks[i][j].hp = boss.defaultblockhp*2
			end
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

function create_smoke(block_col,block_row)
	smoke = {}
	smoke.col=block_col
	smoke.row=block_row
	add(boss.smoke,smoke)
	for i=1,3 do
		smokeball = {num=i,smoke=smoke,x=0,y=0,life=5}
		add(boss.smokeballs,smokeball)
	end
end

function generate_trail(x,y,lastx,lasty)
	trail = {}
	trail.x = x+4
	trail.y = y+4
	trail.size = 10
	
	add(trails, trail)
	
	trail.x = lastx+4
	trail.y = lasty+4
	
	add(trails, trail)
end

function update_highscore(sc)
	if (sc > highscore.score) then
		highscore.level = level
		highscore.score = score
		dset(0,level)
		dset(1,score)
	end
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
	y = cam.y-cam.offsety+112
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

function get_distance(x1,y1,x2,y2)
	return sqrt((x2-x1)*(x2-x1)+(y2-y1)*(y2-y1))
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
0000700000070000000000000000000000000000000a900000000000000000000000000000000000000000000000000000000000000000007777777777777777
0000e000000e00000000000000000000000000000008200000000000000000000000000000000000000000000000000000000000000000006666666666666665
0000e000000e000000099000000aa000000ee000000650000000000000880000000000000000000000000000000000000000000000000000dddddddddddddd65
0000800000080000009aa90000a77a0000e7fe00000650000008656800865000000880000000005559555555555555555500000000000000ddddddddddddddd5
0000820000280000040a904000a77a0000effe0000065000000865680006560000066000000159dd5477b7bbbbbbbbdddd95100000000000ddddddddddddddd5
000782044028700000900900000aa000000ee000000820000000000000005680000550000055d4d644b1111111111b6d6d4d550000000000dddddddddddddd51
000f82477428f0000400004000000000000000000008200000000000000008800006600001dd644656333333335355666446dd10000000005555555555555551
000a84fccf48a0000000000000000000000000000000800000000000000000000008800005d66646156666666666666664666d50000000001111111111111111
00faa2adda2aaf000001200000055000000000000000000000000000000000005000000500000000000000000000000000000000500000055000000550000005
0a9a949dd949a9a0001111000000400000000000000dd00000000000000000000500005000000000000000000000000000000000050000500500005005000050
a94942911924949a01500110000000000008800000dccd0000011000000220000050050007766969676967766776967696976550005005000050050000500500
00420049940024002105201154004005008fe8000dc7ccd0001cd100002e82000005500007ddd4d4ddd4dddddddd4ddd4d4ddd50000550000005500000055000
00800428824008001102101250040045008ee8000dccccd0001dd100002882000005500006dd6464dd545555555545dd4646dd10000550000005500000055000
000009877890000001100110000000000008800000dccd0000011000000220000050050006dd6464d55111111111155d4646dd10005005000050050000500500
0000009009000000001111000004000000000000000dd00000000000000000000500005006556455551000000000015555465510050000500500005005000050
00000000000000000002100000055000000000000000000000000000000000005000000506111411110000000000001111411110500000055000000550000005
00007000000700005000000550000005500000055000000550000005500000055000000500000000007666966966750000000000500000055000000550000005
0000e000000e0000050000500500005005000050050000500500005005000050050000500000000007ddbbbbbbbbdd5000000000050000500500005005000050
0000e000000e000000500500005005000050050000500500005005000050050000500500077669697ddb33333333bdd596966770005005000050050000500500
00008000000800000005500000055000000550000005500000055000000550000005500007ddd4d4ddb3333333333bdd4d4ddd70000550000005500000055000
00008200002800000005500000055000000550000005500000055000000550000005500006dd6464d5b3333333333b5d4646dd60000550000005500000055000
00078204402870000050050000500500005005000050050000500500005005000050050006dd6464d5b3333333333b5d4646dd60005005000050050000500500
000f82477428f000050000500500005005000050050000500500005005000050050000500655645555b3333333333b5555465560050000500500005005000050
000a84fccf48a0005000000550000005500000055000000550000005500000055000000506111411111bbbbbbbbbb11111411160500000055000000550000005
00faa2adda2aaf005000000550000005500000055000000550000005500000050000000000766696666666966966666669667500000000005000000550000005
009a989dd989a900050000500500005005000050050000500500005005000050000000000766bbbbbbbbbbbbbbbbbbbbbbbb6650000000000500005005000050
00294291192492000050050000500500005005000050050000500500005005000000000076db333333333333333333333333bd65000000000050050000500500
082227e99e722280000550000005500000055000000550000005500000055000000000096db33333333333333333333333333bd5900000000005500000055000
e88a2fe88ef2a88e000550000005500000055000000550000005500000055000000070746db33333333333333333333333333bd1450600000005500000055000
9aa94a8aa8a49aa90050050000500500005005000050050000500500005005000000676444b33333333333333333333333333b44456500000050050000500500
09944929929449900500005005000050050000500500005005000050050000500000566d55b33333333333333333333333333b51155100000500005005000050
000004922940000050000005500000055000000550000005500000055000000500000511111bbbbbbbbbbbbbbbbbbbbbbbbbb111111000005000000550000005
01111100000011111100111001110111001110011111100011000110111001100011101111100111011100100100111010000000000000000000000000000000
1d7766100001d7776611d7611d761d7611d7611d7776610176111761d761d76101ccc1ccccc11ccc1ccc11c11c11ccc1c1000000000000000000000000000000
1dd776100001dd777611d7611d761d7611d7611dd777611d761d7761d761d7611c111011c111c1111c11c1cc1c1c11c1c1000000000000000000000000000000
16666661001d66ddd66166661d6616661d6661d66ddd6616661d6611d661d6611cc10000c101cc101c1c11c1cc1c1cc1c1000000000000000000000000000000
01dddd61001dd6111d61ddd61dd61ddd6ddd61dd6111d61dd61d6101dd61dd611c111000c101c1111c1c11c11c1c11c1c1110000000000000000000000000000
01ddddd6101dd6111d61dddd6dd61ddddddd61dd6111d61dd61d6101dd61dd611cccc100c101cccc1c11c1c11c1c11c1cccc1000000000000000000000000000
01dd61d6111ddd6ddd61ddddddd61ddddddd61dd66ddd61dd6dd6111dd61dd610111100010001111010010100101001011110000000000000000000000000000
01666116611d66ddd661666d66661666666661d66ddd661666666611d661d6610000000000000000000000000000000000000000000000000000000000000000
01776117761d7611d7617761d77617d7776761d7611d761776d67711d761d7610011101000100111010000100000111010010011100111000000000000000000
01226112261d2611d2612261d226122d226261d2611d2612261d2611d261d26101ccc1c101c11ccc1c1001c10001ccc1c11c11ccc11ccc100000000000000000
01226112261d2611d26122611d261226d6d261d2611d2612261d2261d261d2611c1111c111c1c11c1c1001c1001c1110cc1c1c1111c111000000000000000000
01226112261d2611d26122611d26122611d261d2611d26122600d261d261d2611c1001c1ccc1c1cc1c1001c1001cc100c1cc1c1011cc10000000000000000000
1d888dd8611d8611d86188611d86188611d861d8611d86188600d861d866d8611c1111c111c1c11c1c1111c1111c1110c11c1c11c1c111000000000000000000
1deeeee6101de6101e11ee611de11ee611de61de6101e11ee1001e611deeee6101ccc1c101c1c11c1cccc1cccc1cccc1c11c11ccc1cccc100000000000000000
1ffffff1001df1000101fff11d101ff1001ff1df1000101ff1001f101dfffff10011101000101001011110111101111010010011101111000000000000000000
01111110000110000000111001000110000110110000000110000100011111100000000000000000000000000000000000000000000000000000000000000000
01110011000111111001110001110111001100011111101111111101110011100099009000000000000000000900000000000000000000000000000000000000
1d761d76101d7777611d76101d761d761d76101d777761d77777661d7611d76109aa99a900900090099000999a90000000000000000000000000000000000000
1d761d7611d77777611d76101d761d761d7611d6d67611ddd677761d7611d7619a999aaa09a909a99aa909aa9a90000000000000000000000000000000000000
1d661d6611d661d6661d66101d661d661d661d6d111101d6111111166661d6619aa909a99a9a9a9a9a9a9a9a9a90000000000000000000000000000000000000
1dd61dd61dd6101dd61dd6111dd61dd61dd616d1111101dd1111101ddd61dd619a9999a99aa99a999a9a9a9a9a90000000000000000000000000000000000000
1dd61dd61dd61001111dd6666dd61dd61dd61d66666611ddd666101dddd6dd619aaaa9aa09aa9a909a9a99aa9aa9000000000000000000000000000000000000
1dd61dd61dd61000001dd6ddddd61dd61dd611dddddd61ddddd6101ddddddd610999909900990900090900990990000000000000000000000000000000000000
1d661d661d661000001d66111d661d661d6610111d6661d61111001666d666610000000000000000000000000000000000000000000000000000000000000000
1d761d761d761000001d76101d761d761d76100001d761d710000017761d77610099909000000009009000000000009000000000000000000000000000000000
1d261d261d261000001d26101d261d261d26100001d261d210000012261d226109aaa9a90000990a09a90090099009a900900000000000000000000000000000
1d261d261d261001111d26101d261d261d26100001d261d2100000122611d2619a9999a90009aa9a09a909a99aa99a9a99a90000000000000000000000000000
1d261d261d26101d261d26101d260d261d26111001d261d2100000122611d2619a9009aa909a9a9a09a99a9a9a9a99aa9a9a9000000000000000000000000000
1d866d86118861d8861d86101d710d866d861d611d8861d8111110188611d8619a9999a9a99a9a9a99a99aa99a9a999a9aa90000000000000000000000000000
11deeee611deeeee611de6101de101deeee611deeeee61deeeee611ee611de1109aaa9a9a909aa9aa9aa99aa9a9a9aa999aa9000000000000000000000000000
01dfffff1011dfff611df1001f1001dfffff101dfff611ddfffff61fff11d1000099909090009909909900990909099000990000000000000000000000000000
00111111000011111001100001000011111100011111001111111101110010000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000898c000000898a8b8c000000898c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfbcbd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000c8c9cacbcc000000cfcfcfcfcfcf00000000000000000000000000002700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cfcfc0c1c2c3c4c5c6c7cfcfcfcfcfcf0000d0d0d0d0000000000000020c040e0e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cfcfd0d1d2d3d4d5d6d70000000000000000000000d0d000000000090414082b2e1700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cfcfe0e1e2e3e4e5e6e7cfcfcfcf00000000d0d0d0d0d0000000000012271f05040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cfcff0f1f2f3f4f5f6f7cfcfcfcfcfcfac0000d0d0d00000000000000500000a180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cfcfcfcfd8d9dadbdcddcfcfcfcfcfcf8c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000cfcfcfcfcfcfcfcfcfcfcfcfcfbbbcbd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cfcf4000000000cfcfcfcf0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000063046b000000b8b9babbbcbd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
000400000f0500f050020001b0501b0502d0002705027050200000b0000b000190001b0001b0001b0001b00020000200002000004000040000400004000040000400000000000000000000000000000000000000
00100000046200967007660026400263002620026100e6000f6001060012600136000d6000e6000e6001060013600006000060000600006000060000600006000060000600006000060000600006000060000600
0010000004620356500462035650336402d630256201f610006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
00100000056202c6300a64008660216701f67006670076702c6702066003650206501263007620056200262001610016100160001600000000000000000000000000000000000000000000000000000000000000
001000000466004630016200161000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000952001510015000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
001000000212002100026000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00040000251601d170171600f15008130021100010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000800001e1202d130391500c1000d1000b1000b10000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000800002d12324123241131f103161030010316103161031610316103001030010322103221031f1031610300103161030010316103161031610316103001030010300103001030010300103001030010300103
0004000022624356341a625146150a6041b6041460425004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004
000c0000260551b6051f605290551b605206052b05500005000052805526055240552400500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
001000001d0500d750180500d750130500d7500905009047090270901700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000124504265042750427504275042650425504225042150420503205002050020500205002050020500205002050020500205002050020500205002050020500205002050020500205002050020500205
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000095551554521535155250955515545215351552507555135451f5351352507555135451f5351352504555105451c5351052504555105451c5351052505555115451d5351152505555115451d53511525
0110000004153046052a6250461504605041132a6250461504153041532a6250461504605041532a6250461504153046052a6250461504605041532a6250461504153041532a62504615041532a6252a6252a625
0110000021724007002172028720287202872021720007001f724007001f7202672026720267201f720007001c724007001c7202372023720237201c720007001d7241d7001d7202d7202b720287202672024720
011000002102021020210202302023020230202402024020280202802028020260202602026020240202402023020230202302024020240202402023020230201f0201f0201f0202102021020210202302023020
0110000021020210202102023020230202302024020240202b0222b0222b022290202902029020280202802028022280202802024020240202402028020280202602026020260202302023020230202602026025
011000002102515025210232102228032280222801228015280232b0022802328023290001c0531c053180531f025130251f0231f02226032260222601226015260232b002260232602329000260532605323053
011000002102515025210232102228032280222801228015280232b0022802328023290001c0531c053180532b0322b0351f12529032290351d12526042260322602226022281021a0061a006260532605323053
011000001303413030130201302013010130101301013015150051600500000150051500015000000000000018034180301802018020180101801018010180150000000000000000000000000000000000000000
01100000091550915500105091550910509155001050915507155091050715500105091550b1050a1550010509155091550010509155001050915500105091550715500105071550010503155001050015500105
011000000951409520095300954209552095420953009525005000050000500005000050000500005000050010514105201053010542105521054210530105250050000500005000050000500005000050000500
011000000b5140b5200b5300b5420b5520b5420b5300b52500500005000050000500005000050000500005000c5140c5200c5300c5420c5520c5420c5300c5250050000500005000050000500005000050000500
011000000060304313106350412300603041530415304103043131060510635041230410304153041530410300603043131063504123006030415304153006030431310605106350412304103041530415304103
011000000060304313106350412300603041530415304103043131060510635041230410304153106350412304103041530415304103043131060510635041230430304313106350412300603041530415304103
011000000415304303043030431310635041230410304153041030415304303043131063504123041030410304153043030430304313106350412304103041530410304153043030431310635041230410304103
0110000021032000021503221002150321303213033210322803210002210320900221032130331d0321f0321f0021f033130321f0321d0021f032130321f0331d032110331d0321f0021f0321f0331303223002
0110000021032000001503221002150321302213023210322803210023260320e002260320e0232403226032180330c024260320e0241a0330e03224032240232b032290321d02429033280321a0242603228023
0110000028032240322803224032280322403228032260322603224032260322403226032240322603224032240322103224032210322403221032240321f0321f0351f0321f0321f03221032240322603228032
011000000415300000106350000004153041531063500000041530000010635000000415304153106350000004153000001063500000041530415310635000000415300000106350000004153041531063500000
011000000476510765047651076504765107650476510765027650e765027650e765027650e765027650e765007650c765007650c765007650c765007650c7650776513765077651376507765137650776513765
011000002803224032280322403228032240322803229032290322603229032260322903226032290322b0322b032280322b032280322b032280322b03230032300323003230032180332d0322b0322403324033
01100000280322403228032240322803224032180331803318033240332803226032260022403218033240332b0322400318033240332903228002280322903218033280321803324032210020c0331803328002
011000002b0322100218033240332903228002280322903200000280322903228032290322b03218033240332b0321800318033180332903228002280322903200000280321f0022403218033180331803324033
011000002b03221002180332403329032280022803229032000002803200000260322603224002240321803318033180330000000000000000000000000000001803318033240333003330033300330000000000
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
00 14424344
01 14161544
00 14155617
00 14155618
00 14151944
02 14151a44
02 191b4344
01 1c424344
00 1c1d2144
00 1c1e2144
01 1c5d2122
02 1c5e2123
01 25242644
00 25272644
00 25282644
00 25292644
02 252a2644
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
01 1c424344
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
02 25292644
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

