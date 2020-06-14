g = grid.connect()



----begin UI stuff
local ui =  include('lib/ui')
--- end UI stuff


data = {}
for j = 1,4 do
   data[j] = {
      gate = {},
      gate_length = {},
      cv = {},
      note_numbers = {},
      octave = {},
      slew_time = {},
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
      table.insert(data[j].gate, 0)
      table.insert(data[j].gate_length, 1)
      table.insert(data[j].cv, 16)
      table.insert(data[j].note_numbers,13)
      table.insert(data[j].octave,0)
      table.insert(data[j].slew_time, 1)
   end
end





grid_state = 0 -- nothing pressed
-- 1 trig held
-- 2 set length
-- 3 set mult
-- 4 set mute
-- 5 set seq_type
-- 6 set focus_track

play_state = 0 -- not playing




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
local set_down = false
DEBUG = true



-- begin{positions of functions on grid}
local grid_set_seq_type = {x = 13, y = 8}
local grid_set_mult = {x = 14, y = 8}
local grid_set_mute = {x = 15, y = 8}
local grid_resync = {x = 16, y= 7}
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
	 if data[j].mult_pos % data[j].mult == 0 then
	    if data[j].mute == 0 then
	       if data[j].seq_type == 1 then -- gate sequence
		  if data[j].gate[data[j].pos] > 0 then
		     crow.output[j].action = "{ to(5,0), to(0," .. gate_length_multipliers[data[j].gate_length[data[j].pos]] * (clock.get_beat_sec()/(params:get("step_div"))) .. ") }"
		     crow.output[j]()
		  end
	       elseif data[j].seq_type == 2 then --cv sequence
		  if data[j].gate[data[j].pos] > 0 then
		     crow.output[j].slew = (data[j].slew_time[data[j].pos] -1) * (clock.get_beat_sec()/(params:get("step_div")))
		     if data[j].cv[data[j].pos] == 16 then
			crow.output[j].volts = 0
		     elseif data[j].cv[data[j].pos] < 16 then
			crow.output[j].volts = (16 - data[j].cv[data[j].pos]) * -5/15
		     else
			crow.output[j].volts = (data[j].cv[data[j].pos]-16) * 5/15
		     end
		  end
	       elseif data[j].seq_type == 3 then -- v/8 sequence
		  if data[j].gate[data[j].pos] > 0 then
		     crow.output[j].volts =  (data[j].note_numbers[data[j].pos] + (data[j].octave[data[j].pos] * 12) )/12
		  end
	       end
	    end
	    data[j].pos = (data[j].pos % data[j].length) + 1
	 end
	 data[j].mult_pos = (data[j].mult_pos % data[j].mult) + 1
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



function init()
   params:add{type = "number", id = "step_div", name = "step division", default = 16}

   clock.run(step)
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


      params:add_separator()
   end




   params:default()


   ----- TESTING
   data[2].seq_type = 3
   data[3].seq_type = 2

   ------------

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
	 if pressed[i][j] and (grid_state == 0 or grid_state == 1) then
	    if data[j].seq_type == 1 then -- gate
	       for k =1,16 do
		  g:led(k,5,3)
	       end
	       g:led(data[j].gate_length[i],5,14)
	    elseif data[j].seq_type == 2 then -- cv stuff
	       -- cv level
	       for k =1,16 do
		  g:led(k,5,3)
	       end
	       if data[j].cv[i] % 2 == 1 then
		  g:led((data[j].cv[i] +1)/2   ,5,14)
	       else
		  g:led(data[j].cv[i] /2  ,5,7)
		  g:led(data[j].cv[i] /2 +1  ,5,7)
		  --g:led(data[j].cv[i],5,14)
	       end
	       -- slew time
	       for k =1,16 do
		  g:led(k,6,3)
	       end
	       g:led((data[j].slew_time[i]),6,14)

	    elseif data[j].seq_type == 3 then -- v/8 stuff


	       for k = 1,#keyboard_indices do
		  if keyboard_indices[k][2] == 5 then
		     g:led(keyboard_indices[k][1],keyboard_indices[k][2], 3) --black keys
		  else
		     g:led(keyboard_indices[k][1],keyboard_indices[k][2], 5) --white keys
		  end

	       end
	       -- mark locked note note
	       g:led(keyboard_indices[data[j].note_numbers[i]][1],
		     keyboard_indices[data[j].note_numbers[i]][2], 14 )

	       -- draw octave switches
	       if data[j].octave[i] == 0 then
		  g:led(grid_octave_down.x,grid_octave_down.y,4)
		  g:led(grid_octave_up.x,grid_octave_up.y,4)
	       elseif data[j].octave[i] > 0 then
		  g:led(grid_octave_down.x,grid_octave_down.y,2)
		  g:led(grid_octave_up.x,grid_octave_up.y ,2 + 8 * (math.floor(clock.get_beats()) %2)) -- blink
	       elseif data[j].octave[i] <0  then
		  g:led(grid_octave_down.x,grid_octave_down.y,2 + 8 * (math.floor(clock.get_beats()) %2))
		  g:led(grid_octave_up.x,grid_octave_up.y,2)
	       end
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
	    for i = 1,3 do
	       g:led(i,j,3)
	    end
	    g:led(data[j].seq_type,j,10)
	 end
      elseif grid_state == 6 then --focus_track
	 for j =1,4 do
	    if pressed[grid_focus_track[j].x][grid_focus_track[j].y] then
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
	 
	 if not (grid_state == 2 or grid_state == 6) then
	    g:led(((data[j].pos-1) % 16) +1 , j, 4)
	 else
	    for j = 1,4 do
	       if pressed[grid_set_length[j].x][grid_set_length[j].y] or pressed[grid_focus_track[j].x][grid_focus_track[j].y] then
		  g:led(((data[j].pos-1) %16 ) +1  ,math.floor((data[j].pos-1)/16) +1,10)
	       end
	    end	    
	 end
      end
      
   end
   g:refresh()
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


   if y <=4 and (grid_state == 0 or grid_state == 1) then
      -- set on playheads current page
      local x_page = x + 16 * math.floor((data[y].pos-1)/16)
      if z == 1 then
	 down_time = util.time()
	 grid_state = 1 -- set locking state
	 if data[y].gate[x_page] == 0 then
	    data[y].gate[x_page] =1
	    set_down = true
	 end
      else
	 hold_time = util.time() - down_time
	 grid_state = 0 -- set nothing pressed state
	 if hold_time < 0.3 and data[y].gate[x_page] == 1 and not set_down  then
	    data[y].gate[x_page] =0
	 elseif set_down then
	    set_down =false
	 end
      end
   elseif y == 5 and grid_state == 1 then
      for j=1,4 do
	 for i = 1,16 do
	    if pressed[i][j] then
	       if data[j].seq_type == 1 then -- gate  length locks
		  data[j].gate_length[i] = x

	       elseif data[j].seq_type == 2 then --cv level locks

		  if n_index == 0 then
		     data[j].cv[i] = 2 * x -1	--single pressed key
		  else

		     data[j].cv[i] = 2 * n_index	--two neighboring keys
		  end


	       elseif data[j].seq_type == 3 then --v/8
	       end
	    end
	 end
      end

   elseif y == 6 and grid_state == 1 then
      for j=1,4 do
	 for i = 1,16 do
	    if pressed[i][j] then
	       if data[j].seq_type == 1 then -- gate
	       elseif data[j].seq_type == 2 then --cv slew time locks
		  data[j].slew_time[i] = x
		  
	       elseif data[j].seq_type == 3 then --v/8 -- octave locks
	       end
	    end
	 end
      end
   end
   


   
   if grid_state ==1 then -- keyboard locks
      for j=1,4 do
	 for i = 1,16 do
	    if keyboard_index ~= 0  then
	       if pressed[i][j] and data[j].seq_type == 3 then
		  data[j].note_numbers[i] = keyboard_index
	       end
	    elseif x == grid_octave_up.x and y == grid_octave_up.y and z == 1 then
	       data[j].octave[i] = data[j].octave[i] +1
	    elseif x == grid_octave_down.x and y == grid_octave_down.y and z == 1 then
	       data[j].octave[i] = data[j].octave[i] -1
	    end
	 end
      end
   end
   

   --- begin set track lengths/multipliers/mutes
   if y>=5 and (grid_state == 0 or grid_state == 2 or grid_state == 3 or grid_state == 4 or grid_state == 5 or grid_state == 6) then
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
	 elseif (x == grid_focus_track[1].x and y== grid_focus_track[1].y) or
	    (x == grid_focus_track[2].x and y== grid_focus_track[2].y) or
	    (x == grid_focus_track[3].x and y== grid_focus_track[3].y) or
	 (x == grid_focus_track[4].x and y== grid_focus_track[4].y) then
	    grid_state = 6
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
   if y <= 4 and x <= 3 and grid_state == 5 then
      if z == 1 then
	 data[y].seq_type = x
      end
   end


   
   --- end set track lengths/multipliers/mutes


   --- begin transport
   if x == grid_resync.x and y == grid_resync.y and z == 1 and grid_state == 0 then
      resync()
   end
   -- end transport


   gridredraw()
   redraw()
end
