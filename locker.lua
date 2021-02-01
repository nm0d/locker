
g = grid.connect()



----begin libraries/inculdes
local ui =  include('lib/ui')
MusicUtil = require "musicutil"


--- end libraries/includes


data = {}
standard_values = {}
for j = 1,4 do
   standard_values[j] = {
      gate = 0,
      gate_length = 6,
      cv = 0,
      note_numbers = 13,--49,
      octave = 4,
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
      cv_range = 1,
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
-- 6 focus_track
-- 7 trig held in focus_track state
-- 8 set length in focus_track state 
-- 9 set mult in focus_track state
-- 10 set mute in focus_track state
-- 11 set seq_type in focus_track state



focus_state = 0 -- nothing focused
-- i track i focus for i = 1,..,4




play_state  = false


note_names = {}
for i = 0,127 do
   note_names[i+1] = MusicUtil.note_num_to_name(i, true)
end

function get_keyboard_index(num)
   return((num -1)  % 24) + 1
end

      

keyboard_octave = 0
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
   -- {15,5}, --c#
   -- {16,6}, --d
   -- {16,5}, --d#
}

function crow_set_pitch(channel, note_number, octave)
   crow.output[channel].volts = util.clamp(((note_number -1)/12) + octave, 0,10)
end


cv_list_bi = {}
for i = -15,-1 do
   table.insert(cv_list_bi, i * 5/15)
end
table.insert(cv_list_bi, 0)
for i = 1,15 do
   table.insert(cv_list_bi, i * 5/15)
end

function cv_bi_to_index(v)
   for i =1,30 do
      if cv_list_bi[i] <= v and v <= cv_list_bi[i+1] then
	 if v <= (cv_list_bi[i] + cv_list_bi[i+1]) /2 then
	    return i
	 else
	    return i+1
	 end
      end
   end
end


cv_list_un = {}
for i = 0,30 do
   table.insert(cv_list_un, i * 10/30)
end


function cv_un_to_index(v)
   for i =1,30 do
      if cv_list_un[i] <= v and v <= cv_list_un[i+1] then
	 if v <= (cv_list_un[i] + cv_list_un[i+1]) /2 then
	    return i
	 else
	    return i+1
	 end
      end
   end
end


attack_list = {}
decay_list= {}
sustain_list= {}
release_list= {}
max_attack = 2.5
max_decay = 2.5
max_sustain = 10.0
max_release = 2.5

for i = 0,14 do
   table.insert(attack_list, i * max_attack/14)
   table.insert(decay_list, i * max_decay/14)
   table.insert(sustain_list, i * max_sustain/14)
   table.insert(release_list, i * max_release/14)
end


function find_index(list, v)
   for i = 1, (#list -1) do
      if list[i] <= v and v <= list[i+1] then
	 if v <= (list[i] + list[i+1]) /2 then
	    return i
	 else
	    return i+1
	 end
      end
   end
end
select_SR = false





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




seq_type_names = {"Gate", "CV", "V/8", "Env"}
gate_length_multipliers = {1/32,1/16,1/8, 1/4, 1/2, 1,2,3,4,5,6,7,8,16,32,64}
cv_range_names = {"bipolar", "unipolar"}




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

pressed_trigger = {}
for position = 1,64 do
   pressed_trigger[position] = {}
   for track = 1,4 do
      pressed_trigger[position][track] = false
   end
end

   


--display_lock = {}
--display_lock[step] = 1
--display_lock[track] = 1


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
set_down = {}
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


local grid_octave_0  = {x =1, y=7}
local grid_octave_2  = {x =2, y=7}
local grid_octave_4  = {x =3, y=7}
local grid_octave_6  = {x =4, y=7}
local grid_octave_8  = {x =5, y=7}
grid_octaves = {grid_octave_0, grid_octave_2, grid_octave_4,grid_octave_6, grid_octave_8 }



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
		     crow.output[j].action = "{ to(5,0), to(5," .. gate_length_multipliers[data[j].gate_length[pos]] * (clock.get_beat_sec()/(params:get("step_div"))) .. "),to(0,0) }"
		     crow.output[j]()
		  end
	       elseif data[j].seq_type == 2 then --cv sequence
		  if data[j].gate[pos] > 0 then
		     crow.output[j].slew = (data[j].slew_time[pos] -1) * (clock.get_beat_sec()/(params:get("step_div")))
		     -- old cv stuff
		     --if data[j].cv[pos] == 16 then
		     --	crow.output[j].volts = 0
		     --elseif data[j].cv[pos] < 16 then
		     --	crow.output[j].volts = (16 - data[j].cv[pos]) * -5/15
		     --else
		     --	crow.output[j].volts = (data[j].cv[pos]-16) * 5/15
		     --end
		     crow.output[j].volts = data[j].cv[pos]
		     
		  end
	       elseif data[j].seq_type == 3 then -- v/8 sequence
		  if data[j].gate[pos] > 0 then
		     --  crow.output[j].volts =  (data[j].note_numbers[pos] + (data[j].octave[pos] * 12) )/12
		     -- crow.output[j].volts = (data[j].note_numbers[pos]-60)/12
		     -- crow.output[j].volts = util.clamp(((data[j].note_numbers[pos]/12) + data[j].octave[pos] -4 ), 0,10)
		     crow_set_pitch(j, data[j].note_numbers[pos], data[j].octave[pos])
		     
		  end
	       elseif data[j].seq_type == 4 then -- envelope
		  if data[j].gate[pos] > 0 then
		     local max = 10
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
      
      params:add{type = "option", id= j .."_cv_range", name= j .." cv range",
		 options= cv_range_names, default = 1,
		 action = function(x) data[j].cv_range = x end }

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


      params:add{type = "option",
		 id = j.. "_note_numbers",
		 name = j .." note",
		 options = note_names,
		 default = standard_values[j].note_numbers,
		 action=function(x)
		    standard_values[j].note_numbers = x
		    for i = 1,64 do
		       if data[j].gate[i] == 0 then
			  data[j].note_numbers[i] = x
		       end
		    end
		 end
      }
      -- todo octave param

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

      params:add{type = "control",
		 id = j.. "_cv",
		 name = j .." cv",
		 controlspec = controlspec.new(-5,10,'lin',0,standard_values[j].cv,''),
		 action=function(x)
		    standard_values[j].cv = x
		    for i = 1,64 do
		       if data[j].gate[i] == 0 then
			  data[j].cv[i] = x
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
	 --old cv stuff
	 --	 if standard_values[j].cv == 16 then
	 --	    crow.output[j].volts = 0
	 --	 elseif standard_values[j].cv < 16 then
	 --	    crow.output[j].volts = (16 - standard_values[j].cv) * -5/15
	 --	 else
	 --	    crow.output[j].volts = (standard_values[j].cv-16) * 5/15
	 --	 end
	 crow.output[j].volts = standard_values[j].cv

	 
      elseif data[j].seq_type == 3 then


	 crow_set_pitch(j,standard_values[j].note_numbers, standard_values[j].octave)

      end
      
   end
   
   -- end standard values

   
end

function enc(n,d)
   if grid_state == 1 or grid_state == 7 then
      for j = 1,4 do
	 for i = 1,16 do
	    if pressed[i][j] then
	       local track = j
	       local position = i + 16 * math.floor((data[j].pos-1)/16)
	       if grid_state == 7 then
		  track = focus_state
		  position = 16 * (j-1) + i
	       end

	       if data[track].seq_type == 2 then
		  if n == 2 then data[track].cv[position] = util.clamp(data[track].cv[position] + d/50, -5, 5) end
		  if n == 3 then data[track].slew_time[position] = util.clamp(data[track].slew_time[position] + d, 1, 16) end
	       elseif data[j].seq_type == 4 then
		  if n == 2 then
		     if not select_SR then 
			data[track].attack[position] = util.clamp(data[track].attack[position] + d/50, 0, 2.5)
		     else
			data[track].sustain[position] = util.clamp(data[track].sustain[position] + d/50, 0, 10)
		     end
		  elseif n == 3 then
		     if not select_SR then 
			data[track].decay[position] = util.clamp(data[track].decay[position] + d/50, 0, 2.5)
		     else
			data[track].release[position] = util.clamp(data[track].release[position] + d/50, 0, 2.5)
		     end
		  end
	       end
	    end
	 end
      end
   end
end

function key(n, z)
   if grid_state == 1 then
      for j = 1,4 do
	 for i = 1,16 do
	    if pressed[i][j] then
	       if data[j].seq_type == 2 then
	       elseif data[j].seq_type == 4 then
		  if n == 2 and z == 1 then
		     select_SR = not select_SR
		  end
	       end
	    end
	 end
      end
   end
   
end


function redraw()
   screen.clear()
   if not crow.connected() and not DEBUG then
      ui_crow_disconnected()
   else
      if grid_state == 1 or grid_state == 7 then -- lock
	 local break_it = false
	 for track =1,4 do
	    for position =1,64 do
	       if pressed_trigger[position][track] then
		  if data[track].seq_type == 1 then
		     ui_gate_lock(position,track)
		  elseif data[track].seq_type == 2 then
		     ui_cv_lock(position, track)
		  elseif data[track].seq_type == 3 then
		     ui_keyboard_lock(position,track)
		  elseif data[track].seq_type == 4 then
		     ui_env_lock(position,track)
		  end
		  break_it = true
		  break
	       end
	    end
	    if break_it then
	       break
	    end
	 end
      elseif grid_state == 0 then --standard
	-- ui_highlight_mode()

	 for j =1,4 do
	    --ui_length_info(40,(j-1) *16 +9, j)
	    ui_page_indicator(34,(j-1) * 16 + 5,j)
	    if data[j].mute == 0 then
	       ui_mult_indicator(35,(j-1) * 16 + 11,j)
	    else
	       ui_mute_indicator(35,(j-1) * 16 + 11,j)
	    end
	    
	    if data[j].seq_type == 1 then
	       ui_gate_graphic(1 ,(j-1) *16 +1, j)
	    elseif data[j].seq_type == 2 then
	       ui_cv_graphic(1 ,(j-1) *16 +1,j)
	    elseif data[j].seq_type == 3 then
	       if data[j].gate[data[j].pos] == 0 then
		  ui_keys_graphic(1 ,(j-1) *16 +1, 0,1)
	       else
		  ui_keys_graphic(1,
				  (j-1) *16 +1,
				  ((data[j].note_numbers[data[j].pos]-1) % 12)+1,
				  1
		  )
	       end
	    elseif data[j].seq_type == 4 then
	       ui_cv_graphic(1 ,(j-1) *16 +1,j)
	    end
	 end
      elseif grid_state == 5 or grid_state == 11 then -- seq type state
	 ui_set_type()
	   for j =1,4 do
	    --ui_length_info(40,(j-1) *16 +9, j)
	    if data[j].seq_type == 1 then
	       ui_gate_graphic(1 ,(j-1) *16 +1, j)
	    elseif data[j].seq_type == 2 then
	       ui_cv_graphic(1 ,(j-1) *16 +1,j)
	    elseif data[j].seq_type == 3 then
	       if data[j].gate[data[j].pos] == 0 then
		  ui_keys_graphic(1 ,(j-1) *16 +1, 0,1)
	       else
		  ui_keys_graphic(1,
				  (j-1) *16 +1,
				  ((data[j].note_numbers[data[j].pos]-1) % 12)+1,
				  1
		  )
	       end
	    elseif data[j].seq_type == 4 then
	       ui_cv_graphic(1 ,(j-1) *16 +1,j)
	    end
	 end
      elseif grid_state == 6 then -- focus track state
	 for j = 1,4 do
	    
	    if j == focus_state then
	       ui_focus_track(j)
	       y_pos = 22
	       ui_page_indicator(34,y_pos + 5,j)
	       if data[j].mute == 0 then
		  ui_mult_indicator(35,y_pos + 11,j)
	       else
		  ui_mute_indicator(35,y_pos + 11,j)
	       end
	       
	       if data[j].seq_type == 1 then
		  ui_gate_graphic(1 ,y_pos +1, j)
	       elseif data[j].seq_type == 2 then
		  ui_cv_graphic(1 ,y_pos +1,j)
	       elseif data[j].seq_type == 3 then
		  if data[j].gate[data[j].pos] == 0 then
		     ui_keys_graphic(1 ,y_pos +1, 0,1)
		  else
		     ui_keys_graphic(1,
				  y_pos +1,
				  ((data[j].note_numbers[data[j].pos]-1) % 12)+1,
				  1
		     )
		  end
	       elseif data[j].seq_type == 4 then
		  ui_cv_graphic(1 ,y_pos +1,j)
	       end
	    end
	 end
      elseif grid_state == 2 or grid_state == 8 then -- set length
	 for j =1,4 do
	    if pressed[grid_set_length[j].x][grid_set_length[j].y] then
	       ui_set_length(j)
	       ui_page_indicator(34,(j-1) * 16 + 5,j,true)
	    else
	       ui_page_indicator(34,(j-1) * 16 + 5,j,false)
	    end
	 end
      elseif grid_state == 3 or grid_state == 9 then -- set mult
	 for j = 1,4 do
	    ui_mult_indicator(35,(j-1) * 16 + 11,j)
	 end
	 ui_set_mult()
      elseif grid_state == 4 or grid_state == 10 then -- set mute
	 ui_set_mute()
      end
      

   end
   --end
   screen.update()
end

function gridredraw()
   g:all(0)

   
   if grid_state == 0 or grid_state == 1 then
      for j= 1,4 do
	 -- page indicators
	 if data[j].length > 16 and data[j].length <=32 then
	    if data[j].pos <= 16 then
	       for i = 1,8 do
		  g:led(i,j,2)
	       end
	    else
	       for i = 9,16 do
		  g:led(i,j,2)
	       end
	    end
	 elseif data[j].length > 32 and data[j].length <=48 then
	    if data[j].pos <= 16 then
	       for i = 1,5 do
		  g:led(i,j,2)
	       end
	    elseif data[j].pos > 16 and data[j].pos <= 32 then
	       for i = 6,10 do
		  g:led(i,j,2)
	       end
	    elseif data[j].pos > 32  and data[j].pos <= 48 then
	       for i = 11,16 do
		  g:led(i,j,2)
	       end
	    end
	 elseif data[j].length > 48  then
	    if data[j].pos <= 16 then
	       for i = 1,4 do
		  g:led(i,j,2)
	       end
	    elseif data[j].pos > 16 and data[j].pos <= 32 then
	       for i = 5,8 do
		  g:led(i,j,2)
	       end
	    elseif data[j].pos > 32  and data[j].pos <= 48 then
	       for i = 9,12 do
		  g:led(i,j,2)
	       end
	    elseif data[j].pos > 48 then
	       for i = 13,16 do
		  g:led(i,j,2)
	       end
	    end
	 end
	 
	 for i = 1,16 do
	    local i_page = i + 16 * math.floor((data[j].pos-1)/16)
	    if data[j].gate[i_page] > 0  then
	       g:led(i,j,10)
	    end
	 end
	 
      
      end
   end


   for track = 1,4 do
      for position = 1,64 do
	 if pressed_trigger[position][track] and (grid_state == 1 or grid_state == 7) then
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
	       local index = cv_bi_to_index(data[track].cv[position]) -- TODO REFACTOR
	       if  index % 2 == 1 then
		  g:led((index +1)/2   ,5,14)
	       else
		  g:led(index /2  ,5,7)
		  g:led(index /2 +1  ,5,7)
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

	       for k = 0,4 do
		  if data[track].octave[position] == 2 * k then
		     g:led(grid_octaves[k + 1].x, grid_octaves[k + 1].y, 14)
		  else
		     g:led(grid_octaves[k + 1].x, grid_octaves[k + 1].y, 5)
		  end
	       end
	       
	    elseif data[track].seq_type == 4 then -- evelope stuff

	       for k =1,16 do
		  for l = 5,6 do
		     g:led(k,l,3)
		  end
	       end
	       local a_index = find_index(attack_list, data[track].attack[position])
	       local d_index = find_index(decay_list, data[track].decay[position])
	       local s_index = find_index(sustain_list, data[track].sustain[position])
	       local r_index = find_index(release_list, data[track].release[position])

	       
	       if  a_index % 2 == 1 then
		  g:led((a_index +1)/2   ,5,14)
	       else
		  g:led(a_index /2  ,5,7)
		  g:led(a_index /2 +1  ,5,7)
		  --g:led(data[j].cv[i],5,14)
	       end

	       if  d_index % 2 == 1 then
		  g:led((d_index +1)/2 + 8 ,5,14) 
	       else
		  g:led(d_index /2  +8,5,7)
		  g:led(d_index /2 +9 ,5,7)
		  --g:led(data[j].cv[i],5,14)
	       end


	       if  s_index % 2 == 1 then
		  g:led((s_index +1)/2   ,6,14)
	       else
		  g:led(s_index /2  ,6,7)
		  g:led(s_index /2 +1  ,6,7)
		  --g:led(data[j].cv[i],5,14)
	       end

	       if  r_index % 2 == 1 then
		  g:led((r_index +1)/2 +8,6,14)
	       else
		  g:led(r_index /2  +8,6,7)
		  g:led(r_index /2 +9,6,7)
		  --g:led(data[j].cv[i],5,14)
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

	 if pressed[grid_transport.x][grid_transport.y] or not play_state then
	    g:led(grid_transport.x, grid_transport.y,13)
	 else
	    g:led(grid_transport.x, grid_transport.y,5)
	 end
	 
      end


      if grid_state == 2 or grid_state == 8 then -- length state
	 for j =1,4 do
	    if pressed[grid_set_length[j].x][grid_set_length[j].y] then
	       g:led(grid_set_length[j].x,grid_set_length[j].y,13)
	       local length = data[j].length
	       for k=1,length do
		  g:led(((k-1) %16 ) +1  ,math.floor((k-1)/16) +1,3)
	       end
	    end
	 end
	 
      elseif grid_state == 3 or grid_state == 9 then -- mult state
	 g:led(grid_set_mult.x,grid_set_mult.y,13)
	 for j = 1,4 do
	    for i = 1,16 do
	       if i > data[j].mult then g:led(i,j,3) end
	    end
	    g:led(data[j].mult,j,10)
	 end
      elseif grid_state == 4 or grid_state == 10 then --  mute state
	 g:led(grid_set_mute.x,grid_set_mute.y,13)
	 for j = 1,4 do
	    for i = 1,16 do
	       if data[j].mute == 0 then g:led(i,j,3) end
	    end
	 end
      elseif grid_state == 5 or grid_state == 11 then --seq_type state
	 g:led(grid_set_seq_type.x,grid_set_seq_type.y,13)
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
      
      if data[track].mute == 0 then -- current sequencer position
	 if not (grid_state == 2 or grid_state == 6 or grid_state == 7 or grid_state == 8) then
	    g:led(((data[track].pos-1) % 16) +1 , track, 4)
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
      if (y == 5 or y == 6) and n_index > 0 then
	 if n_index == x then
	    press_lock[x][y] = n_index
	    press_lock[x+1][y] = n_index
	 elseif      n_index == x-1 then
	    press_lock[x][y] = n_index
	    press_lock[x-1][y] = n_index
	 end
      end
   else
      if (y == 5 or y == 6)  and n_index > 0  then
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
      local position = x + 16 * math.floor((data[y].pos-1)/16)
      local track = y
      if grid_state == 6 or grid_state == 7 then
	 position = x + 16 * (y-1)
	 track = focus_state
      end
      if z == 1 then
	 down_time = util.time()
	 pressed_trigger[position][track] = true
	 if grid_state == 0 then
	    grid_state = 1 -- set locking state
	 elseif grid_state == 6 then -- focus track mode
	    grid_state = 7 -- locking in focus track mode
	 end
	 if data[track].gate[position] == 0 then
	    data[track].gate[position] =1
	    set_down[track][position] = true
	 end
      else
	 hold_time = util.time() - down_time
	 pressed_trigger[position][track] = false
	 if not trig_held() then
	    if grid_state == 1 then
	       grid_state = 0 -- set nothing pressed state
	    elseif grid_state == 7 then 
	       grid_state = 6
	    end	    
	 end
	 if hold_time < 0.3 and data[track].gate[position] == 1 and not set_down[track][position] then
	    data[track].gate[position] =0
	    remove_locks(position,track)
	 end
	 set_down[track][position] =false
      end


      -- lock lock       
   elseif y == 5 and (grid_state == 1 or grid_state == 7) then
      for track=1,4 do
	 for position = 1,64 do
	    if pressed_trigger[position][track] then
	       if data[track].seq_type == 1 then -- gate  length locks
		  data[track].gate_length[position] = x
	       elseif data[track].seq_type == 2 then --cv level locks
		  if n_index == 0 then
		     data[track].cv[position] = cv_list_bi[2 * x -1]	--single pressed key
		  else
		     data[track].cv[position] = cv_list_bi[2 * n_index]	--two neighboring keys
		  end
	       elseif data[track].seq_type == 3 then --v/8
	       elseif data[track].seq_type == 4 then -- envelope
		  select_SR = false
		  if n_index == 0 then -- single pressed key
		     if x <= 8 then
			data[track].attack[position] = attack_list[2 * x -1]
		     else
			data[track].decay[position] = decay_list[2 * (x-8) -1]
		     end
		  else
		     if n_index < 8 then
			data[track].attack[position] = attack_list[2 * n_index]
		     elseif n_index == 8 then
			data[track].attack[position] = attack_list[15]
			data[track].decay[position] = decay_list[1]
		     else
			data[track].decay[position] = decay_list[2 * (n_index - 8)]
		     end
		  end
	       end
	    end
	 end
      end

   elseif y == 6 and (grid_state == 1 or grid_state == 7)then
      for track=1,4 do
	 for position = 1,64 do
	    if pressed_trigger[position][track] then
	       if data[track].seq_type == 1 then -- gate
	       elseif data[track].seq_type == 2 then --cv slew time locks
		  data[track].slew_time[position] = x
		  
	       elseif data[track].seq_type == 3 then --v/8 -- octave locks

	       elseif data[track].seq_type == 4 then -- envelope locks
		  select_SR = true
		  if n_index == 0 then -- single pressed key
		     if x <= 8 then
			data[track].sustain[position] = sustain_list[2 * x -1]
		     else
			data[track].release[position] = release_list[2 * (x-8) -1]
		     end
		     
		  else
		     if n_index < 8 then
			data[track].sustain[position] = sustain_list[2 * n_index]
		     elseif n_index == 8 then
			data[track].sustain[position] = sustain_list[15]
			data[track].release[position] = release_list[1]
		     else
			data[track].release[position] = release_list[2 * (n_index - 8)]
		     end
		     
		  end

		  
	       end
	    end
	 end
      end
   end
   


   
   if grid_state ==1 or grid_state == 7 then -- keyboard locks
      for track=1,4 do
	 for position = 1,64 do
	    if pressed_trigger[position][track] and data[track].seq_type == 3 then -- chromatic track
	       if keyboard_index ~= 0  then
		  data[track].note_numbers[position] = keyboard_index
	       elseif x == grid_octave_0.x and y == grid_octave_0.y and z == 1 then
		  data[track].octave[position] =  0
	       elseif x == grid_octave_2.x and y == grid_octave_2.y and z == 1 then
		  data[track].octave[position] =  2
	       elseif x == grid_octave_4.x and y == grid_octave_4.y and z == 1 then
		  data[track].octave[position] =  4
	       elseif x == grid_octave_6.x and y == grid_octave_6.y and z == 1 then
		  data[track].octave[position] =  6
	       elseif x == grid_octave_8.x and y == grid_octave_8.y and z == 1 then
		  data[track].octave[position] =  8
	       end
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
