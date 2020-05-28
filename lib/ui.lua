-- ui stuff

local gate_length_multipliers_text = {"1/32","1/16","1/8","1/4","1/2","1","2","3","4","5","6","7","8","16","32","64"}

function ui_init()
   screen.aa(1)
end


function ui_lock(x, y)
   screen.level(15)
   screen.rect(x,  y, 12, 12)
   screen.fill()

   screen.level(0)
   screen.circle(x+6, y+4, 3)
   screen.fill()
   
   screen.level(0)
   screen.rect(x+4,  y+4,4 , 6)
   screen.fill()

   screen.level(15)
   screen.arc(x+6, y-3,4, math.pi , 0)
   screen.stroke()
   
   screen.level(15)
   screen.move(x+10, y-3)
   screen.line(x+10, y)
   screen.stroke()
   screen.move(x+2, y-3)
   screen.line(x+2, y)
   screen.stroke()
end


function ui_keys(x,y,n)
   screen.level(15)
   local key_positions = {}
   
   key_positions[1] = 0
   key_positions[2] = 2
   key_positions[3] = 4
   key_positions[4] = 6
   key_positions[5] = 8
   key_positions[6] = 12
   key_positions[7] = 15
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
      screen.rect(x + 4 * i,  y, 3, 14)
   end
   screen.fill()


   
   if white_keys[n] then
      for i = 1,13 do
	 screen.level(14-i)
	 screen.rect(x+ key_positions[n],  y+i, 3, 1)
	 screen.fill()
      end
   end

   
   -- black keys
   local black_key_pos = {2,6,14,18,22}
   
   screen.level(0)
   for i = 1,5 do
      screen.rect(x+ black_key_pos[i],y, 3, 10)
   end
   screen.fill()
   
   if black_keys[n] then
      for i = 1,9 do
	 screen.level(i)
	 screen.rect(x+ key_positions[n],  y+i, 3, 1)
	 screen.fill()
      end
   end
   
end

function ui_gate(x,y,n)
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
   
   if n ==0 then
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

function ui_cv(x,y,data, j)
   crow.output[j].query()

   screen.level(13)
   
   --screen.move(x,y -math.floor(crow_out_voltages[j]/5 * 7)+7)
   --screen.line(x+30,y -math.floor(crow_out_voltages[j] /5 *7)+7)
   for i =1,queue_length do
      screen.pixel(x+queue_length -i,y -math.floor(crow_out_voltage_hist[j][i]/5 * 7)+7)
   end
   
   
   screen.fill()
end





function ui_gate_lock(data, i,j)
   ui_lock(0,9)
   
   screen.level(15)
   screen.move(15, 10)
   screen.text("gate")
   screen.move(15, 20)
   screen.text("length")
   
   screen.move(55, 10)
   screen.text(gate_length_multipliers_text[data[j].gate_length[i]])
   
   screen.move(55, 20)
   if data[j].gate_length[i] > 6 then
      screen.text("steps")
   else
      screen.text("step")
   end
   screen.fill()
end

function ui_cv_lock(data, i, j)
   ui_lock(0,9)
   screen.level(15)

   screen.move(15, 10)
   screen.text("control")
   screen.move(15, 20)
   screen.text("voltage")
   
   screen.move(55, 10)

   if data[j].cv[i] == 16 then
      screen.text(0)
   elseif data[j].cv[i] < 16 then
      screen.text((math.floor((16- data[j].cv[i]) * -5/15 *1000) )/1000  )
   else
      screen.text(math.floor( (data[j].cv[i]-16) * 5/15 *1000)/1000 ) 

   end


   screen.move(55, 20)

   screen.text("volts")
   screen.fill()
end



   
