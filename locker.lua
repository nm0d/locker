g = grid.connect()



----begin UI stuff
local ui =  include('lib/ui')
--- end UI stuff






data = {}
standard_values = {}
for j = 1,4 do
   standard_values[j] = {
      gate = 0,
      gate_length = 1,
      cv = 16,
      note_numbers = 13,
      octave = 0,
      slew_time = 1,
      attack = 0.0,
      decay = 1.0,
      sustain = 0.0,
      release = 0.0,
   }
   data[j] = {
      gate = {},
      gate_length = {},
      cv = {},
      note_numbers = {},
      octave = {},
      slew_time = {},
      attack = {},
      decay = {},
      sustain = {},
      release = {},
      pos = 1,
      length =16,
      seq_type =1,
      cv_bipolar = true,
      mult = 4,
      mult_pos = 1,
      mute = 0,
      seq_page =1
   }
   for i = 1,64 do
      table.insert(data[j].gate, standard_values[j].gate)
      table.insert(data[j].gate_length, standard_values[j].gate_length)
      table.insert(data[j].cv, standard_values[j].cv)
      table.insert(data[j].note_numbers, standard_values[j].note_numbers)
      table.insert(data[j].octave, standard_values[j].octave)
      table.insert(data[j].slew_time, standard_values[j].slew_time)
      table.insert(data[j].attack, standard_values[j].attack)
      table.insert(data[j].decay, standard_values[j].decay)
      table.insert(data[j].sustain, standard_values[j].sustain)
      table.insert(data[j].release, standard_values[j].release)            
   end
end





grid_state = 0 -- nothing pressed
-- 1 trig held
-- 2 set length
-- 3 set mult
-- 4 set mute
-- 5 set seq_type
-- 6 set focus_track
-- 7 set trig held in focus_track state

focus_state = 0 -- nothing focused
-- i track i focus for i = 1,..,4




play_state  = false


keyboard_indices = {
   {1,6}, --c
   {1,5}, --c#
   {2,6}, --d
   {2,5}, --d#
   {3,6}, --e
   {4,6},  --f
   {4,5},  --f#
   {5,6},  --g
   {5,5},  --g#
   {6,6},  --a
   {6,5},  --a#
   {7,6},  --b
   {8,6},  --c
   {8,5},  --c#
   {9,6},  --d
   {9,5},  --d#
   {10,6}, --e
   {11,6}, --f
   {11,5}, --f#
   {12,6}, --g
   {12,5}, --g#
   {13,6}, --a
   {13,5}, --a#
   {14,6}, --b
   {15,6}, --c
   {15,5}, --c#
   {16,6}, --d
   {16,5}, --d#
}


crow_out_voltages = {0,0,0,0}
queue_length = 30
crow_out_voltage_hist = {{},{},{},{}}

for i = 1, queue_length do
   for j =1,4 do
      table.insert(crow_out_voltage_hist[j], 0)
   end
end

for j = 1,4 do
   crow.output[j].receive =
      function(v)
	 crow_out_voltages[j] = v
	 table.remove(crow_out_voltage_hist[j])
	 table.insert(crow_out_voltage_hist[j],1,v)
      end
end





function get_keyboard_index(i,j)
   for k = 1, #keyboard_indices do
      if i == keyboard_indices[k][1] and j == keyboard_indices[k][2] then
	 return k
      end
   end
   return 0
end




local seq_type_names = {"Gate", "CV", "V/8"}
local gate_length_multipliers = {1/32,1/16,1/8, 1/4, 1/2, 1,2,3,4,5,6,7,8,16,32,64}




pressed = {}
press_lock = {}
for x = 1,16 do
   pressed[x] = {}
   press_lock[x] = {}
   for y = 1,8 do
      pressed[x][y] = false
      press_lock[x][y] = 0
   end
end


function trig_held()
   for x = 1,16 do
      for y = 1,4 do
	 if pressed[x][y] then
	    return true
	 end
      end
   end
   return false
end





function neighbor_index(row_index)
   for k =1,15 do
      if (pressed[k][row_index] and pressed[k+1][row_index]) or
      (press_lock[k][row_index] > 0 and press_lock[k+1][row_index] > 0) then
	 return k
      end
   end
   return 0
end




local hold_time = 0
local down_time = 0
local set_down = {}
for j = 1,4 do
   table.insert(set_down, {})
   for i = 1,16 do
      table.insert(set_down[j], false)
   end
end
DEBUG = true



-- begin{positions of functions on grid}
local grid_set_seq_type = {x = 13, y = 8}
local grid_set_mult = {x = 14, y = 8}
local grid_set_mute = {x = 15, y = 8}
local grid_resync = {x = 16, y= 7}
local grid_transport = {x = 15, y= 7}

local grid_octave_down = {x = 15, y= 7}
local grid_octave_up = {x = 16, y= 7}

local grid_set_length = {}
local grid_focus_track = {}
for j = 1,4 do
   grid_set_length[j] = {x= j, y = 7}
   grid_focus_track[j] = {x= j, y = 8}
end
-- end{positions of functions on grid}





function add_pattern_params()

end


function step()
   while true do
      clock.sync(1/params:get("step_div"))
      for j=1,4 do
	 data[j].mult_pos = (data[j].mult_pos % data[j].mult) + 1 -- count before playing stuff? goes **
	 if data[j].mult_pos % data[j].mult == 0 then
	    data[j].pos = (data[j].pos % data[j].length) + 1 -- count before playing stuff? goes *
	    if data[j].mute == 0 then
	       local pos = data[j].pos
	       if data[j].seq_type == 1 then -- gate sequence
		  if data[j].gate[pos] > 0 then
		     crow.output[j].action = "{ to(5,0), to(0," .. gate_length_multipliers[data[j].gate_length[pos]] * (clock.get_beat_sec()/(params:get("step_div"))) .. ") }"
		     crow.output[j]()
		  end
	       elseif data[j].seq_type == 2 then --cv sequence
		  if data[j].gate[pos] > 0 then
		     crow.output[j].slew = (data[j].slew_time[pos] -1) * (clock.get_beat_sec()/(params:get("step_div")))
		     if data[j].cv[pos] == 16 then
			crow.output[j].volts = 0
		     elseif data[j].cv[pos] < 16 then
			crow.output[j].volts = (16 - data[j].cv[pos]) * -5/15
		     else
			crow.output[j].volts = (data[j].cv[pos]-16) * 5/15
		     end
		  end
	       elseif data[j].seq_type == 3 then -- v/8 sequence
		  if data[j].gate[pos] > 0 then
		     crow.output[j].volts =  (data[j].note_numbers[pos] + (data[j].octave[pos] * 12) )/12
		  end
	       elseif data[j].seq_type == 4 then -- envelope
		  if data[j].gate[pos] > 0 then
		     local max = 5
		     local min = 0


		     local adsr = "{to(" .. min .. ",0), " ..
			"to(" .. max ..", " .. data[j].attack[pos] .. "), " ..
			"to(" ..data[j].sustain[pos] ..", " .. data[j].decay[pos] .. "), " ..
			"to(" ..data[j].sustain[pos] ..", " .. data[j].gate_length[pos] .. "), " ..
			"to(" ..min ..", " .. data[j].release[pos] .. ")}"
		     
		     crow.output[j].action = adsr
		     crow.output[j]()
		  end
	       end
	    end

	 end

      end
      if g then
	 gridredraw()
      end
      redraw()
   end
end


function resync()
   for j = 1,4 do
      data[j].pos = 1
      data[j].mult_pos = 1
   end
end


function clock.transport.start()
  print("start")

  id = clock.run(step)
  play_state = true
end

function clock.transport.stop()
   print("stop")
   clock.cancel(id)
   play_state = false
end



function init()
   params:add{type = "number", id = "step_div", name = "step division", default = 16}

   --   clock.run(step)
   clock.transport.start()
   
   params:add_separator()


   --- begin UI stuff
   ui_init()





   --- end UI stuff

   for j = 1,4 do
      params:add{type = "option", id= j .."_seq_type", name= j .." seq type",
		 options= seq_type_names, default = 1,
		 action = function(x) data[j].seq_type = x end }

      params:add{type = "number",
		 id = j.. "_length",
		 name = j .." length",
		 min =1, max = 64,
		 default = data[j].length,
		 action=function(x) data[j].length = x end }

      params:add{type = "number",
		 id = j.. "_multiplier",
		 name = j .." multiplier",
		 min =1, max = 16,
		 default = data[j].mult,
		 action=function(x) data[j].mult = x end }


      params:add{type = "control",
		 id = j.. "_attack",
		 name = j .." attack",
		 controlspec = controlspec.new(0,2.5,'lin',0,standard_values[j].attack,''),
		 action=function(x)
		    standard_values[j].attack = x
		    for i = 1,64 do
		       if data[j].gate[i] == 0 then
			  data[j].attack[i] = x
		       end
		    end
		 end
      }

      params:add{type = "control",
		 id = j.. "_decay",
		 name = j .." decay",
		 controlspec = controlspec.new(0,2.5,'lin',0,standard_values[j].decay,''),
		 action=function(x)
		    standard_values[j].decay = x
		    for i = 1,64 do
		       if data[j].gate[i] == 0 then
			  data[j].decay[i] = x
		       end
		    end
		 end
      }
      params:add{type = "control",
		 id = j.. "_sustain",
		 name = j .." sustain",
		 controlspec = controlspec.new(0,10,'lin',0,standard_values[j].sustain,''),
		 action=function(x)
		    standard_values[j].sustain = x
		    for i = 1,64 do
		       if data[j].gate[i] == 0 then
			  data[j].sustain[i] = x
		       end
		    end
		 end
      }
      params:add{type = "control",
		 id = j.. "_release",
		 name = j .." release",
		 controlspec = controlspec.new(0,2.5,'lin',0,standard_values[j].release,''),
		 action=function(x)
		    standard_values[j].release = x
		    for i = 1,64 do
		       if data[j].gate[i] == 0 then
			  data[j].release[i] = x
		       end
		    end
		 end
      }

      
      
      params:add_separator()
   end




   params:default()


   ----- TESTING
   data[2].seq_type = 3
   data[3].seq_type = 2
   data[4].seq_type = 4

   ------------



   
   -- begin standard values
   for j = 1,4 do
      if data[j].seq_type == 2 then
	 if standard_values[j].cv == 16 then
	    crow.output[j].volts = 0
	 elseif standard_values[j].cv < 16 then
	    crow.output[j].volts = (16 - standard_values[j].cv) * -5/15
	 else
	    crow.output[j].volts = (standard_values[j].cv-16) * 5/15
	 end
      elseif data[j].seq_type == 3 then
	 crow.output[j].volts =  (standard_values[j].note_numbers + (standard_values[j].octave * 12) )/12
      end
      
   end
   
   -- end standard values

   
end


function redraw()
   screen.clear()
   if not crow.connected() and not DEBUG then
      ui_crow_disconnected()
   else
      if grid_state == 1 then
	 for j =1,4 do
	    for i =1,16 do
	       if pressed[i][j] then
		  if data[j].seq_type == 1 then
		     ui_gate_lock(i,j)
		  elseif data[j].seq_type == 2 then
		     ui_cv_lock(i, j)
		  elseif data[j].seq_type == 3 then
		  end
		  break
	       end
	    end
	 end
      end

      if grid_state ~= 1 then
	 ui_highlight_mode()

	 for j =1,4 do
	    ui_length_info(40,(j-1) *16 +9, j)
	    if data[j].seq_type == 1 then
	       ui_gate_graphic(1 ,(j-1) *16 +1, j)
	    elseif data[j].seq_type == 2 then
	       ui_cv_graphic(1 ,(j-1) *16 +1,j)
	    elseif data[j].seq_type == 3 then
	       if data[j].gate[data[j].pos] == 0 then
		  ui_keys_graphic(1 ,(j-1) *16 +1, 0)
	       else
		  ui_keys_graphic(1,
				  (j-1) *16 +1,
				  ((data[j].note_numbers[data[j].pos]-1) % 12)+1)
	       end
	    elseif data[j].seq_type == 4 then
	       ui_cv_graphic(1 ,(j-1) *16 +1,j)
	    end
	 end
      end

   end
   --end
   screen.update()
end

function gridredraw()
   g:all(0)

   if grid_state == 0 or grid_state == 1 then
      for j= 1,4 do
	 for i = 1,16 do
	    local i_page = i + 16 * math.floor((data[j].pos-1)/16)
	    if data[j].gate[i_page] > 0  then
	       g:led(i,j,10)
	    end
	 end
      end
   end


   for j = 1,4 do
      for i = 1,16 do
	 if pressed[i][j] and (grid_state == 1 or grid_state == 7) then
	    local track = j
	    local position = i
	    if grid_state == 7 then
	       track = focus_state
	       position = 16 * (j-1) + i
	    end
	    
	    if data[track].seq_type == 1 then -- gate
	       for k =1,16 do
		  g:led(k,5,3)
	       end

	       g:led(data[track].gate_length[position],5,14)
	    elseif data[track].seq_type == 2 then -- cv stuff
	       -- cv level
	       for k =1,16 do
		  g:led(k,5,3)
	       end
	       if data[track].cv[position] % 2 == 1 then
		  g:led((data[track].cv[position] +1)/2   ,5,14)
	       else
		  g:led(data[track].cv[position] /2  ,5,7)
		  g:led(data[track].cv[position] /2 +1  ,5,7)
		  --g:led(data[j].cv[i],5,14)
	       end
	       -- slew time
	       for k =1,16 do
		  g:led(k,6,3)
	       end
	       g:led((data[track].slew_time[position]),6,14)

	    elseif data[track].seq_type == 3 then -- v/8 stuff


	       for k = 1,#keyboard_indices do
		  if keyboard_indices[k][2] == 5 then
		     g:led(keyboard_indices[k][1],keyboard_indices[k][2], 3) --black keys
		  else
		     g:led(keyboard_indices[k][1],keyboard_indices[k][2], 5) --white keys
		  end

	       end
	       -- mark locked note note
	       g:led(keyboard_indices[data[track].note_numbers[position]][1],
		     keyboard_indices[data[track].note_numbers[position]][2], 14 )

	       -- draw octave switches
	       if data[track].octave[position] == 0 then
		  g:led(grid_octave_down.x,grid_octave_down.y,4)
		  g:led(grid_octave_up.x,grid_octave_up.y,4)
	       elseif data[track].octave[position] > 0 then
		  g:led(grid_octave_down.x,grid_octave_down.y,2)
		  g:led(grid_octave_up.x,grid_octave_up.y ,2 + 8 * (math.floor(clock.get_beats()) %2)) -- blink
	       elseif data[track].octave[position] <0  then
		  g:led(grid_octave_down.x,grid_octave_down.y,2 + 8 * (math.floor(clock.get_beats()) %2))
		  g:led(grid_octave_up.x,grid_octave_up.y,2)
	       end
	    elseif data[track].seq_type == 4 then -- evelope stuff
	       
	    end
	 end
      end

      if grid_state == 0 then
	 g:led(grid_set_seq_type.x,grid_set_seq_type.y,5)
	 g:led(grid_set_mult.x,grid_set_mult.y,5)
	 g:led(grid_set_mute.x,grid_set_mute.y,5)
	 for j = 1,4 do
	    g:led(grid_set_length[j].x,grid_set_length[j].y,5)
	    g:led(grid_focus_track[j].x,grid_focus_track[j].y,5)
	    
	 end
	 if pressed[grid_resync.x][grid_resync.y] then
	    g:led(grid_resync.x, grid_resync.y,13)
	 else
	    g:led(grid_resync.x, grid_resync.y,5)
	 end

	 if pressed[grid_transport.x][grid_transport.y] or not play_state then
	    g:led(grid_transport.x, grid_transport.y,13)
	 else
	    g:led(grid_transport.x, grid_transport.y,5)
	 end
	 
      end


      if grid_state == 2 then -- length state
	 for j =1,4 do
	    if pressed[grid_set_length[j].x][grid_set_length[j].y] then
	       g:led(grid_set_length[j].x,grid_set_length[j].y,13)
	       local length = data[j].length
	       for k=1,length do
		  g:led(((k-1) %16 ) +1  ,math.floor((k-1)/16) +1,3)
	       end
	    end
	 end
	 
      elseif grid_state == 3 then -- mult state
	 g:led(3,5,13)
	 for j = 1,4 do
	    for i = 1,16 do
	       if i > data[j].mult then g:led(i,j,3) end
	    end
	    g:led(data[j].mult,j,10)
	 end
      elseif grid_state == 4 then --  mute state
	 g:led(4,5,13)
	 for j = 1,4 do
	    for i = 1,16 do
	       if data[j].mute == 0 then g:led(i,j,3) end
	    end
	 end
      elseif grid_state == 5 then --seq_type state
	 g:led(1,5,13)
	 for j = 1,4 do
	    for i = 1,4 do
	       g:led(i,j,3)
	    end
	    g:led(data[j].seq_type,j,10)
	 end
      elseif grid_state == 6 or grid_state == 7 then --focus_track
	 for j =1,4 do
	    g:led(grid_focus_track[j].x,grid_focus_track[j].y,5)
	    if focus_state == j then
	       g:led(grid_focus_track[j].x,grid_focus_track[j].y,13)
      

	       for k=1,64 do
		  if data[j].gate[k] == 1 then
		     g:led(((k-1) %16 ) +1  ,math.floor((k-1)/16) +1,10)
		  end
	       end
	    end
	 end
      end
      
      if data[j].mute == 0 then -- current sequencer position
	 
	 if not (grid_state == 2 or grid_state == 6 or grid_state == 7) then
	    g:led(((data[j].pos-1) % 16) +1 , j, 4)
	 else
	    for j = 1,4 do
	       if pressed[grid_set_length[j].x][grid_set_length[j].y] or focus_state == j then
		  g:led(((data[j].pos-1) %16 ) +1  ,math.floor((data[j].pos-1)/16) +1,8)
	       end
	    end	    
	 end
      end
      
   end
   g:refresh()
end

function remove_locks(x,y)
   data[y].gate_length[x] = standard_values[y].gate_length
   data[y].cv[x] = standard_values[y].cv
   data[y].note_numbers[x] = standard_values[y].note_numbers
   data[y].octave[x] = standard_values[y].octave
   data[y].slew_time[x] = standard_values[y].slew_time
   data[y].attack[x] = standard_values[y].attack
   data[y].decay[x] = standard_values[y].decay
   data[y].sustain[x] = standard_values[y].sustain
   data[y].release[x] = standard_values[y].release
end





function g.key(x,y,z)
   local keyboard_index = get_keyboard_index(x,y)
      

   
   if z == 1 then
      pressed[x][y] = true
   else
      pressed[x][y] = false
   end
   local n_index =  neighbor_index(y)

   if z == 1 then -- handle double press locking of cv values
      if y == 5 and n_index > 0 then
	 if n_index == x then
	    press_lock[x][y] = n_index
	    press_lock[x+1][y] = n_index
	 elseif      n_index == x-1 then
	    press_lock[x][y] = n_index
	    press_lock[x-1][y] = n_index
	 end
      end
   else
      if y == 5 and n_index > 0  then
	 if n_index == x then
	    if not pressed[x+1][y] then
	       press_lock[x][y] =0
	       press_lock[x+1][y] =0
	    end
	 elseif n_index == x-1 then
	    if not pressed[x-1][y] then
	       press_lock[x][y] =0
	       press_lock[x-1][y] =0
	    end
	 end
      end
   end


   if y <=4 and (grid_state == 0 or grid_state == 1 or grid_state == 6 or grid_state == 7) then
      -- set on playheads current page
      local x_page = x + 16 * math.floor((data[y].pos-1)/16)
      
      
      
      if z == 1 then
	 down_time = util.time()
	 if grid_state == 0 then
	    grid_state = 1 -- set locking state
	 elseif grid_state == 6 then
	    grid_state = 7
	 end
	 
	 if grid_state == 0 or grid_state == 1 then
	    if data[y].gate[x_page] == 0 then
	       data[y].gate[x_page] =1
	       set_down[y][x] = true
	    end
	 elseif grid_state == 6 or grid_state == 7 then
	    if data[focus_state].gate[x + 16 * (y-1)] == 0 then
	       data[focus_state].gate[x + 16 * (y-1)] =1
	       set_down[focus_state][x + 16 * (y-1)] = true
	    end
	 end
      
      else
	 hold_time = util.time() - down_time
	 if not trig_held() then
	    if grid_state == 1 then
	       grid_state = 0 -- set nothing pressed state
	    elseif grid_state == 7 then 
	       grid_state = 6
	    end	    
	 end
	 if grid_state == 0 or grid_state == 1 then
	    if hold_time < 0.3 and data[y].gate[x_page] == 1 and not set_down[y][x]  then
	       data[y].gate[x_page] =0
	       remove_locks(x_page,y)
	    elseif set_down then
	       set_down[y][x] =false
	    end
	 elseif grid_state == 6 or grid_state == 7 then
	    if hold_time < 0.3 and data[focus_state].gate[x + 16 * (y-1)] == 1 and not set_down[focus_state][x + 16 * (y-1)]  then
	       data[focus_state].gate[x + 16 * (y-1)] =0
	       remove_locks(x+16 * (y-1), focus_state)
	    elseif set_down then
	       set_down[focus_state][x + 16 * (y-1)] =false
	    end
	 end
      end


      -- lock lock       
   elseif y == 5 and grid_state == 1 or grid_state == 7 then
      for j=1,4 do
	 for i = 1,16 do
	    if pressed[i][j] then
	       local track = j
	       local position = i
	       if grid_state == 7 then
		  track = focus_state
		  position = 16 * (j-1) + i

	       end
	       --print( "track" .. track .. "  pos=  " .. position .. " x=" .. x)
	       if data[track].seq_type == 1 then -- gate  length locks
		  data[track].gate_length[position] = x


	       elseif data[track].seq_type == 2 then --cv level locks

		  if n_index == 0 then
		     data[track].cv[position] = 2 * x -1	--single pressed key
		  else

		     data[track].cv[position] = 2 * n_index	--two neighboring keys
		  end


	       elseif data[track].seq_type == 3 then --v/8
	       end
	    end
	 end
      end

   elseif y == 6 and (grid_state == 1 or grid_state == 7)then
      for j=1,4 do
	 for i = 1,16 do
	    local track = j
	    local position = i
	    if grid_state == 7 then
	       track = focus_state
	       position = 16 * (j-1) + i
	       
	    end
	    if pressed[i][j] then
	       if data[track].seq_type == 1 then -- gate
	       elseif data[track].seq_type == 2 then --cv slew time locks
		  data[track].slew_time[position] = x
		  
	       elseif data[track].seq_type == 3 then --v/8 -- octave locks
	       end
	    end
	 end
      end
   end
   


   
   if grid_state ==1 or grid_state == 7 then -- keyboard locks
      for j=1,4 do
	 for i = 1,16 do
	    local track = j
	    local position = i
	    if grid_state == 7 then
		  track = focus_state
		  position = 16 * (j-1) + i
	    end
	    if keyboard_index ~= 0  then
	       if pressed[i][j] and data[track].seq_type == 3 then
		  data[track].note_numbers[position] = keyboard_index
	       end
	    elseif x == grid_octave_up.x and y == grid_octave_up.y and z == 1 then
	       data[track].octave[position] = data[track].octave[position] +1
	    elseif x == grid_octave_down.x and y == grid_octave_down.y and z == 1 then
	       data[track].octave[position] = data[track].octave[position] -1
	    end
	 end
      end
   end
   

   --- begin set track lengths/multipliers/mutes
   if y>=5 and (grid_state == 0 or grid_state == 2 or grid_state == 3 or grid_state == 4 or grid_state == 5) then
      if z == 1 then
	 if x == grid_set_seq_type.x and y== grid_set_seq_type.y then
	    grid_state =5 -- set seq_type state
	 elseif x == grid_set_mult.x and y== grid_set_mult.y then
	    grid_state =3 -- set mult state
	 elseif x == grid_set_mute.x and y== grid_set_mute.y then
	    grid_state =4 -- set mute state
	 elseif (x == grid_set_length[1].x and y== grid_set_length[1].y) or
	    (x == grid_set_length[2].x and y== grid_set_length[2].y) or
	    (x == grid_set_length[3].x and y== grid_set_length[3].y) or
	 (x == grid_set_length[4].x and y== grid_set_length[4].y) then
	    grid_state = 2
	 end
      else
	 grid_state = 0 -- set normal state
      end
   end
   
   if y <= 4 and grid_state == 2 then
      if z == 1 then
	 for j = 1,4 do
	    if pressed[grid_set_length[j].x][grid_set_length[j].y] then
	       data[j].length = (y-1) * 16 + x
	    end
	 end
      end
   end
   
   if y <= 4 and grid_state == 3 then
      if z == 1 then
	 data[y].mult = x
      end
   end
   if y <= 4 and grid_state == 4 then
      if z == 1 then
	 data[y].mute = 1 - data[y].mute
      end
   end
   if y <= 4 and x <= 4 and grid_state == 5 then
      if z == 1 then
	 data[y].seq_type = x
      end
   end
      
   --- end set track lengths/multipliers/mutes


   -- begin focus selection
   if z == 1 and (grid_state == 0 or grid_state == 6) then

      for j = 1,4 do
	 if (x == grid_focus_track[j].x and y== grid_focus_track[j].y)  then

	    if focus_state == j then
	       grid_state = 0
	       focus_state = 0

	    else
	       grid_state = 6
	       focus_state = j
	       
	       
	    end
	 end
      end
   end
   

   --- end focus selection

   

   --- begin transport
   if x == grid_resync.x and y == grid_resync.y and z == 1 and grid_state == 0 then
      resync()
   end

   if x == grid_transport.x and y == grid_transport.y and z == 1 and grid_state == 0 then
      if play_state then
	 clock.transport.stop()
      else
	 clock.transport.start()
      end
      
      
   end
   
   -- end transport


   gridredraw()
   redraw()
end
