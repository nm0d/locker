

-- ui stuff

local gate_length_multipliers_text = {"1/32","1/16","1/8","1/4","1/2","1","2","3","4","5","6","7","8","16","32","64"}



function ui_init()
   screen.aa(0)


   -- The EnvGraph class is used for creating common envelope graphs. Passing nil means it will use a default value.
   -- EnvGraph.new_adsr(x_min, x_max, y_min, y_max, attack, decay, sustain, release, level, curve)


   EnvGraph = require "envgraph"
   env_graph = nil

   env_c = -4
   env_graph = EnvGraph.new_adsr(0, 8, nil, nil,
				 0,
				 0,
				 0,
				 0,
				 1, env_c)
   env_graph:set_position_and_size(66, 11, 58, 42)

   
end


function ui_lock(x, y)
   screen.level(4)
   screen.rect(x,  y, 12, 12)
   screen.fill()

   screen.aa(1)
   screen.level(0)
   screen.circle(x+6, y+4, 2)
   screen.fill()
   screen.aa(0)
   
  
   
   screen.level(1)
   screen.rect(x+4, y+7,4,1)
   screen.fill()
   
   screen.level(0)
   screen.rect(x+5,  y+4,2 , 4)
   screen.fill()

   screen.level(15)
   screen.line_width(2)
   screen.arc(x+6, y-3,4, math.pi , 0)
   screen.stroke()

   
   screen.level(15)
   screen.move(x+10, y-3)
   screen.line(x+10, y)
   screen.stroke()
   screen.move(x+2, y-3)
   screen.line(x+2, y)
   screen.stroke()

   screen.line_width(1)
end


function ui_keys_graphic(x,y,n,s)
   screen.level(15)
   local key_positions = {}

   key_positions[1] = 0 
   key_positions[2] = 2
   key_positions[3] = 4
   key_positions[4] = 6
   key_positions[5] = 8
   key_positions[6] = 12
   key_positions[7] = 14
   key_positions[8] = 16
   key_positions[9] = 18
   key_positions[10] =20
   key_positions[11] =22
   key_positions[12] =24
      
   

      
   local white_keys = {}
   white_keys[1] = true -- C
   white_keys[3] = true -- D
   white_keys[5] = true
   white_keys[6] = true
   white_keys[8] = true
   white_keys[10] = true
   white_keys[12] = true
   
   local black_keys = {}
   black_keys[2] = true -- C#
   black_keys[4] = true
   black_keys[7] = true
   black_keys[9] = true
   black_keys[11] = true
   
   local white_key_pos = {0,4,8,12,16,20,24}

   
   
    -- white keys
   for i = 0,6 do
      screen.rect(x + 4 * i * s,  y, 3 * s, 14 * s)
   end
   screen.fill()


   
   if white_keys[n] then
      for i = 1,13 do
	 screen.level(14-i)
	 screen.rect(x+ key_positions[n] * s,  y+i * s, 3 * s, 1 * s)
	 screen.fill()
      end
   end

   
   -- black keys
   local black_key_pos = {2,6,14,18,22}
   
   screen.level(0)
   for i = 1,5 do
      screen.rect(x+ black_key_pos[i] *s,y, 3 *s, 10 *s)
   end
   screen.fill()
   
   if black_keys[n] then
      screen.level(2)
      screen.rect(x+ key_positions[n] *s,  y, 3 *s, 10 * s)
      screen.fill()
     -- for i = 1,9 do

     --	 screen.rect(x+ key_positions[n],  y+i, 3, 1)
     --	 screen.fill()
     -- end
   end
   
end

function ui_gate_graphic(x,y,j)
   
   local dark = 1
   local middle = 3
   local bright = 4
   

   for i = 0,3 do
      if i % 2 == 0 then screen.level(bright)else screen.level(dark)end
      screen.rect(x,  y+12-(2*i), 2, 2)
      screen.fill()
      screen.rect(x+13,  y+12-(2*i), 2, 2)
      screen.fill()
   end
   
   screen.level(bright)

   screen.rect(x+1,  y+4, 2, 2)
   screen.rect(x+3,  y+1, 3, 1)
   screen.rect(x+9,  y+1, 3, 1)
   screen.rect(x+12,  y+4, 2, 2)


   
   screen.fill()

   
   
   screen.level(dark)
   screen.rect(x+2,  y+2, 2, 2)
   screen.rect(x+11,  y+2, 2, 2)
   screen.rect(x+6,  y, 3, 2)
   screen.fill()
   
   screen.level(middle)
   screen.pixel(x+5,y)
   screen.pixel(x+9,y)
   screen.fill()

   local bar_vert = 15
   local bar_hor = 13

   crow.output[j].query()
   if crow_out_voltage_hist[j][1] < 0.05 then
      screen.level(bar_hor)
      screen.rect(x+2, y+6, 11,1)
      screen.rect(x+2, y+11, 11,1)
      screen.fill()
      
      screen.level(bar_vert)
      screen.rect(x+3, y+4, 1,10)
      screen.rect(x+5, y+2, 1,12)
      screen.rect(x+7, y+2, 1,12)
      screen.rect(x+9, y+2, 1,12)
      screen.rect(x+11, y+4, 1,10)
      screen.fill()
   else
      screen.level(bar_hor)
      screen.rect(x+4, y+3, 7,1)
      screen.fill()
      
      screen.level(bar_vert)
      screen.rect(x+3, y+4, 1,1)
      screen.rect(x+5, y+2, 1,3)
      screen.rect(x+7, y+2, 1,3)
      screen.rect(x+9, y+2, 1,3)
      screen.rect(x+11, y+4, 1,1)
      screen.fill()
   end
end

function ui_mult_indicator(x,y,j)
   screen.level(15)
   screen.font_size(8)
   screen.move(x+53, y)
   screen.text_right(data[j].mult/4)
   screen.move(x+55, y)
   screen.text("x")
end

function ui_mute_indicator(x,y,j)

   screen.level(15)
   screen.rect(x+36,y-6, 25,8)
   screen.fill()
   screen.level(0)
   screen.font_size(8)
   screen.move(x+53, y)
   screen.text_right(data[j].mult/4)
   screen.move(x+55, y)
   screen.text("m")
end




function ui_page_indicator(x,y,j,reverse_colors)
      
   if reverse_colors then
      screen.level(15)
      screen.rect(x-2,y-2,39,12)
      screen.fill()
      screen.level(5)
      
   else
      screen.level(3)
   end
   
   for k = 0, math.floor((data[j].length -1) / 16) do
   screen.rect(x + k * 9,y,9,9)
   end
   screen.stroke()
   if reverse_colors then
      screen.level(1)
   else
      screen.level(5)
   end
   for k = 1,data[j].length do
      if k <= data[j].pos then
	 local x_offset = ((k-1)%4 * 2) + math.floor((k-1)/16) * 9
	 local y_offset = (math.floor((k-1) / 4) * 2) % 8
	 screen.rect(x + x_offset, y + y_offset, 2,2)
      end
   end
   screen.fill()
   if reverse_colors then
      screen.level(0)
   else
      screen.level(15)
   end
   screen.rect(x + math.floor((data[j].pos-1)/16) * 9, y, 9,9)
   screen.stroke()
end


function ui_focus_track(track)
   screen.level(15)
   screen.rect(99,0,28,24)
   screen.fill()
   screen.level(0)
   screen.font_size(8)
   screen.move(100,7)
   screen.text("track")
   screen.font_size(21)
   screen.move(111,22)
   screen.text_center(track)

  -- screen.level(15)
  -- screen.font_size(8)
  -- screen.move(100,33)
  -- screen.text("focus")
   
   screen.level(15)
   screen.rect(1,40,27,10) 
   screen.fill()
   screen.level(0)
   screen.font_size(8)
   screen.move(3,47)
   screen.text(seq_type_names[data[track].seq_type])

   screen.level(15)
   screen.rect(33,40,37,10) 
   screen.fill()
   screen.level(0)
   screen.font_size(8)
   screen.move(34,47)
   screen.text(data[track].length)
   screen.move(68,47)
   screen.text_right("steps")

   screen.level(15)
   screen.rect(72,40,22,10) 
   screen.fill()
   screen.level(0)
   screen.font_size(8)
   screen.move(75,47)
   screen.text("mult")


end


function ui_set_length(j)
   screen.level(15)
   screen.rect(99,0,28,24)
   screen.fill()
   screen.level(0)
   screen.font_size(8)
   screen.move(100,7)
   screen.text("track")
   screen.font_size(21)
   screen.move(111,22)
   screen.text_center(j)

   screen.level(15)
   screen.font_size(8)
   screen.move(100,33)
   screen.text("length")
   

   screen.level(15)
   screen.rect(99,38,28,26)
   screen.fill()
   
   screen.level(0)
   screen.font_size(21)
   screen.move(100,53)
   screen.text(data[j].length)
   screen.font_size(8)
   screen.move(100,60)
   screen.text("steps")
end



function ui_set_type()
      screen.font_size(8)
   for track = 1,4 do
      screen.level(15)
      screen.rect(99,(track-1) * 16+4 ,28,9)
      screen.fill()
      screen.level(0)
      screen.move(102,(track-1) * 16 + 11)
      screen.text(seq_type_names[data[track].seq_type])
   end
end

function ui_set_mute()
   screen.level(15)
   for j=1,4 do
      if data[j].mute == 1 then
	 screen.move(90, (j-1) * 16 + 11)
	 screen.text("muted")
	 screen.rect(71, (j-1) * 16 + 5, 25,8)
	 screen.fill()
	 screen.level(0)
	 screen.move(90, (j-1) * 16 + 11)
	 screen.text("m")
	 screen.level(15)
--	 screen.rect(44, (j-1) * 16 + 2, 72,13)
	 screen.rect(4, (j-1) * 16 + 2, 112,13)
	 screen.stroke()
	 screen.move(30, (j-1) * 16 + 15)
	 screen.font_size(21)
	 screen.text(j)
	 screen.font_size(8)
	 screen.move(5, (j-1) * 16 + 11)
	 screen.text("track")
      else
	 screen.level(15)
	 --	 screen.rect(44, (j-1) * 16 + 2, 55,13)
	 screen.rect(4, (j-1) * 16 + 2, 112,13)
	 screen.fill()
	 screen.level(0)
	 screen.move(30, (j-1) * 16 + 15)
	 screen.font_size(21)
	 screen.text(j)
	 screen.font_size(8)
	 screen.move(5, (j-1) * 16 + 11)
	 screen.text("track")
	 screen.move(45, (j-1) * 16 + 11)
	 screen.text("active")
	 screen.rect(71, (j-1) * 16 + 5, 25,8)
	 screen.fill()
	 screen.level(15)
	 screen.move(90, (j-1) * 16 + 11)
	 screen.text("x")
      end
   end
--   screen.level(15)
--   screen.rect(99,0,28,60)
--   screen.fill()
end

function ui_set_mult()
   screen.level(15)
   screen.rect(99,0,28,60)
   screen.fill()

   
end





function lightning(x,y) -- not used, but pretty
   local dark =4
   
   for i = 0, 7 do
      screen.level(15)
      screen.rect(x+7-i, y+i, 8,1)
   end
   for i = 0, 7 do
      screen.level(15)
      screen.rect(x+7-i, y+i+5, 8,1)

   end
   screen.rect(x, y+13, 7,1)
   screen.fill()
end

function ui_cv_graphic(x,y, j)
   crow.output[j].query()

   screen.level(15)
   
   for i =2,queue_length do
      screen.move(x +queue_length -i, y -math.floor(crow_out_voltage_hist[j][i]/5 * 7)+7)
      screen.line(x +queue_length - (i+1), y -math.floor(crow_out_voltage_hist[j][i-1]/5 * 7)+7)
      
      if i % 3 == 0 then
	 
      end
   end
   --  screen.fill()
   screen.stroke()
end


function ui_gate_lock(i,j)
   draw_header("track " .. j,"step ".. i, "gate")
   
--   ui_lock(0,9)
   
   screen.level(15)
   screen.move(15, 40)
   screen.text("gate")
   screen.move(15, 50)
   screen.text("length")
   
   screen.move(55, 40)
   screen.font_size(21)
   screen.text(gate_length_multipliers_text[data[j].gate_length[i]])
   screen.font_size(8)
   screen.move(55, 50)
   if data[j].gate_length[i] > 6 then
      screen.text("steps")
   else
      screen.text("step")
   end

   
   screen.fill()
end


function ui_cv_lock(i, j)
   draw_header("track " .. j,"step ".. i, "voltage")

--[[
   screen.level(15)
   screen.move(5, 20)
   screen.text("control voltage")
   screen.move(5, 40)
   screen.font_size(21)
   screen.text(math.floor(data[j].cv[i]*1000)/1000 ) 
   screen.font_size(8)
   screen.move(5, 50)
   screen.text("volts")
   screen.move(80, 20)
   screen.text("slew time")
   screen.move(80, 40)
   screen.font_size(21)
   screen.text(data[j].slew_time[i]-1)
   screen.font_size(8)
   screen.move(80, 50)
   screen.text("steps")
   screen.fill()
]]--
   screen.level(15)
   screen.move(0, 20)
   screen.font_size(16)
   screen.text(math.floor(data[j].cv[i]*1000)/1000 ) 
   screen.font_size(8)
   screen.move(0, 30)   
   screen.text("volts")

   screen.move(0, 50)
   screen.font_size(16)
   screen.text(data[j].slew_time[i]-1)
   screen.font_size(8)
   screen.move(0, 60)
   if data[j].slew_time[i] ~= 2 then
      screen.text("steps slew")
   else
      screen.text("step slew")
   end
  
   screen.move(62,38)
   screen.text_right("0v")
   screen.move(62,12)
   screen.text_right("+5v")
   screen.move(62,63)
   screen.text_right("-5v")


   
   screen.level(5)
   for k = 0,15 do
      screen.pixel(65 +k * 4, 35)
   end
   for k = -5,5 do
      screen.pixel(65, 35 + k * 5)
   end
   screen.fill()
   screen.level(10)
   
   screen.move(66,35 -math.floor(data[j].cv[previous_active_trigger(i,j)] * 5)+1)
   screen.line_cap("butt")
   screen.line(66 + (data[j].slew_time[i]-1) * 4, 35 - math.floor(data[j].cv[i]*5 ) +1)
   screen.stroke()

   screen.level(15)
   screen.rect(65 + (data[j].slew_time[i]-1) * 4, 35 - math.floor(data[j].cv[i]*5 ) ,2,2)
   screen.stroke()
   screen.level(0)
   screen.pixel(65 + (data[j].slew_time[i]-1) * 4, 35 - math.floor(data[j].cv[i]*5 ))
   screen.fill()
   
end
function mod(x,m)
   return (x % m + m) % m
end


function previous_active_trigger(i,j)
   prev = i
   for k = 1,data[j].length do
      if data[j].gate[mod(i-k -1, data[j].length) +1 ] == 1 then
	 prev = mod(i-k -1, data[j].length)+ 1
	 break
      end
   end
   return prev
end



function draw_header(left, mid, right)
   screen.level(8)
   screen.rect(0,0,128,7)
   screen.fill()
   screen.level(0)
   screen.move(1,6)
   screen.text(left)
   screen.move(64,6)
   screen.text_center(mid)
   screen.move(127,6)
   screen.text_right(right)

--   ui_lock(64, 10)
   
end



function ui_keyboard_lock(i,j)
   draw_header("track " .. j,"step ".. i, "chromatic")
   crow.output[j].query()
   screen.level(8)
   screen.move(60,52)
   screen.font_size(21)
--   screen.text(MusicUtil.note_num_to_name((data[j].note_numbers[i]-1  + data[j].octave[i] * 12) ,true))
   screen.text(MusicUtil.note_num_to_name((data[j].note_numbers[i]-1  + data[j].octave[i] * 12) , true))
   screen.font_size(8)
   screen.move(60,60)
   screen.text(util.round(util.clamp((data[j].note_numbers[i]-1)/12 + data[j].octave[i],0,10), 0.01) .. "v")


   ui_keys_graphic(60, 10, ((data[j].note_numbers[i]-1) % 12)+1,2)

   

   

   
end


function ui_env_lock(i,j)
   draw_header("track " .. j,"step ".. i, "envelope")
    if select_SR then screen.level(3) else screen.level(15) end
    screen.move(1, 14)
    screen.text("A " .. util.round(data[j].attack[i], 0.01) .."s")
    screen.move(34, 14)
    screen.text("D " .. util.round(data[j].decay[i], 0.01) .."s")
    if select_SR then screen.level(15) else screen.level(3) end
    screen.move(1, 24)
    screen.text("S " .. util.round(data[j].sustain[i], 0.01))
    screen.move(34, 24)
    screen.text("R " .. util.round(data[j].release[i], 0.01) .."s")

   

   env_graph:edit_adsr(data[j].attack[i],
		       data[j].decay[i],
		       data[j].sustain[i]/10,
		       data[j].release[i],
		       1, env_c)
      screen.aa(1)
   env_graph:redraw()
   screen.aa(0)
end






function ui_highlight_mode()
   screen.level(1)
   if grid_state == 2 then
      screen.rect(40,1,34,64)
      screen.fill()
   elseif grid_state == 3 then
      screen.rect(91,1,13,64)
      screen.fill()
   elseif grid_state == 4 then
      screen.rect(106,1,21,64)
      screen.fill()
   elseif grid_state == 5 then
      screen.rect(1,1,30,64)
      screen.fill()     
   end
   
   
end
function ui_crow_disconnected()
   if math.floor(clock.get_beats()) %4  == 1 then
      screen.display_png("home/we/dust/code/locker/lib/crow_disconnected_2.png", 0, 0)
   else
      screen.display_png("home/we/dust/code/locker/lib/crow_disconnected_1.png", 0, 0)
   end
   screen.level(13)
   screen.move(0,20)
   screen.text("crow")
   screen.move(0,30)
   screen.text("disconnected")
end
   
