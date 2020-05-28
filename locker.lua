g = grid.connect()



----begin UI stuff
local ui =  include('lib/ui')



--- end UI stuff


data = {}
for i = 1,4 do
   data[i] = {
      pos = 0,
      length =16,
      gate =        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
      gate_length = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
      seq_type =1,
      cv = {16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16},
      cv_bipolar = true,
      note_numbers = {13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13},
      octave = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
      slew_time=  {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
      
   }
end




keyboard_indices = {
   {1,8}, --c
   {1,7}, --c#
   {2,8}, --d
   {2,7}, --d#
   {3,8}, --e
   {4,8},  --f
   {4,7},  --f#
   {5,8},  --g
   {5,7},  --g#
   {6,8},  --a
   {6,7},  --a#
   {7,8},  --b
   {8,8},  --c
   {8,7},  --c#
   {9,8},  --d
   {9,7},  --d#   
   {10,8}, --e
   {11,8}, --f
   {11,7}, --f#
   {12,8}, --g
   {12,7}, --g#
   {13,8}, --a
   {13,7}, --a#
   {14,8}, --b
   {15,8}, --c
   {15,7}, --c#
   {16,8}, --d
   {16,7}, --d#
}


crow_out_voltages = {0,0,0,0}

 queue_length = 30
-- Todo: implement queue of last voltages

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




function add_pattern_params()


  
end


function step()
   while true do
      clock.sync(1/params:get("step_div"))
      for j=1,4 do
	 data[j].pos = (data[j].pos % data[j].length) + 1
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
      
      
      if g then
	 gridredraw()
      end
      redraw()      
   end
end

function init()
   params:add{type = "number", id = "step_div", name = "step division", default = 4}
   
   clock.run(step)
   params:add_separator()


   --- begin UI stuff
   ui_init()


   

   
   --- end UI stuff
   
   for j = 1,4 do
      params:add{type = "number", id = j.. "_length", name = j .." length", min =1, max = 16, default = data[j].length,
		 action=function(x) data[j].length = x end }

      params:add{type = "option", id= j .."_seq_type", name= j .." seq type",
	      options= seq_type_names, default = 1,
	      action = function(x) data[j].seq_type = x end }
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
   for j =1,4 do
      for i =1,16 do
	 if pressed[i][j] then
	    if data[j].seq_type == 1 then
	       ui_gate_lock(data, i,j)
	    elseif data[j].seq_type == 2 then
	       ui_cv_lock(data, i, j)
	    elseif data[j].seq_type == 3 then
	    end
	    break
	 end
      end
   end
   -- TODO: if nothing is pressed then
   -- begin
   for j =1,4 do
      if data[j].seq_type == 1 then
	 ui_gate(1 ,(j-1) *16 +1, data[j].gate[data[j].pos])
      elseif data[j].seq_type == 2 then
	 ui_cv(1 ,(j-1) *16 +1, data,j)
      elseif data[j].seq_type == 3 then
	 if data[j].gate[data[j].pos] == 0 then
	    ui_keys(1 ,(j-1) *16 +1, 0)
	 else
	    ui_keys(1 ,(j-1) *16 +1, math.random(1,12))
	 end	 
      end
   end
   --end
   screen.update()   
end
   
function gridredraw()
   g:all(0)

   
   for j= 1,4 do
      for i = 1,16 do
	 if data[j].gate[i] > 0 then
	    g:led(i,j,10)
	 end
      end
   end
   
   
   
   for j = 1,4 do
      for i = 1,16 do
	 if pressed[i][j] then
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
		  if keyboard_indices[k][2] == 7 then
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
		  g:led(15,6,4)
		  g:led(16,6,4)
	       elseif data[j].octave[i] > 0 then
		  g:led(15,6,2)
		  g:led(16,6,2 + 8 * (math.floor(clock.get_beats()) %2)) -- blink
	       elseif data[j].octave[i] <0  then
		  g:led(15,6,2 + 8 * (math.floor(clock.get_beats()) %2))
		  g:led(16,6,2) 
	       end
	       
	    end
	       
	 end
	 
      end
      g:led(data[j].pos, j, 4) 
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
	 elseif	    n_index == x-1 then
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

   
   if y <=4 then
      if z == 1 then
	 down_time = util.time() 

	 
	 if data[y].gate[x] == 0 then
	    data[y].gate[x] =1
	    set_down = true
	 end
      else
	 hold_time = util.time() - down_time
	 
	 if hold_time < 0.3 and data[y].gate[x] == 1 and not set_down  then
	    data[y].gate[x] =0
	 elseif set_down then
	    set_down =false
	 end
	 
	    

      end
      
      
      
   elseif y == 5 then
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

   elseif y == 6 then 
            for j=1,4 do
	 for i = 1,16 do
	    if pressed[i][j] then
	       if data[j].seq_type == 1 then -- gate
	       elseif data[j].seq_type == 2 then --cv slew time locks
		  data[j].slew_time[i] = x
		  
	       elseif data[j].seq_type == 3 then --v/8 -- octave locks
		  if x == 15 then
		     data[j].octave[i] = data[j].octave[i] -1
		  elseif x==16 then
		     data[j].octave[i] = data[j].octave[i] +1
		  end
	       end
	    end
	 end
      end
   elseif keyboard_index ~= 0 then -- keyboard locks
       for j=1,4 do
	  for i = 1,16 do
	     if pressed[i][j] then
		data[j].note_numbers[i] = keyboard_index
	     end
	  end
       end
       
      
   end
   gridredraw()
   redraw()
end




	