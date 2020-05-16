sword = {
  curanim="idle",--currently playing animation
  curframe=1,--curent frame of animation.
  animtick=0,--ticks until next frame should show.
  anims=
    {
      ["idle"]=
      {
          ticks=5,--how long is each frame shown.
          frames={147},--what frames are shown.
      },
      ["attack"]=
      {
          ticks=5,--how long is each frame shown.
          frames={144,145,146,147},--what frames are shown.
      }
    },

  --request new animation to play.
  set_anim=function(self,anim)
    if(anim==self.curanim)return--early out.
    local a=self.anims[anim]
    self.animtick=a.ticks--ticks count down.
    self.curanim=anim
    self.curframe=1
  end,

  attack=function(self,dir)
    sword:set_anim("attack")
    local result = {}
    local dist_x = 0
    local dist_y = 2
    if (dir == "right") dist_x = 7
    if (dir == "left") dist_x = -8
    DEBUGX = player.x + dist_x
    DEBUGY = player.y + dist_y
    result = board.in_board(player.x + dist_x, player.y + dist_y)
    DEBUG = result.inside
    if result.inside then

    end
  end,

  draw=function(self, p)
    --anim tick
    local animFinished = false
    self.animtick-=1
    if self.animtick<=0 then
      self.curframe+=1
      local a=self.anims[self.curanim]
      self.animtick=a.ticks--reset timer
      if self.curframe>#a.frames then
          animFinished = true
          self.curframe=1--loop
      end
    end

    if (animFinished and sword.curanim=="attack") then
       self:set_anim("idle")
    end
    --
    local a=self.anims[self.curanim]
    local frame=a.frames[self.curframe]
    local sword_pos = p.x-(p.w/2)+6
    if (p.flipx) sword_pos -= 12
    spr(frame,
      sword_pos,
      p.y-(p.h/2),
      p.w/8,p.h/8,
      p.flipx,
      false)
  end
}

--make the player
function m_player(x,y)
  
  --todo: refactor with m_vec.
  local p=
  {
    x=x,
    y=y,

    dx=0,
    dy=0,

    w=8,
    h=8,

    max_dx=1,--max x speed
    max_dy=2,--max y speed

    jump_speed=-1.0,--jump veloclity
    acc=0.05,--acceleration
    dcc=0.8,--decceleration
    air_dcc=1,--air decceleration
    grav=0.17,

    --helper for more complex
    --button press tracking.
    --todo: generalize button index.
    jump_button=
    {
        update=function(self)
            --start with assumption
            --that not a new press.
            self.is_pressed=false
            if btn(5) then
                if not self.is_down then
                    self.is_pressed=true
                end
                self.is_down=true
                self.ticks_down+=1
            else
                self.is_down=false
                self.is_pressed=false
                self.ticks_down=0
            end
        end,
        --d
        is_pressed=false,--pressed this frame
        is_down=false,--currently down
        ticks_down=0,--how long down
    },

    attack_button=
    {
        update=function(self, flipx)
            if btnp(4) then
              local direction = "right"
              if (flipx) direction = "left"
              sword:attack(direction)
            end
        end
    },

    jump_hold_time=0,--how long jump is held
    min_jump_press=5,--min time jump can be held
    max_jump_press=15,--max time jump can be held

    jump_btn_released=true,--can we jump again?
    grounded=false,--on ground

    airtime=0,--time since grounded
    
    --animation definitions.
    --use with set_anim()
    anims=
    {
        ["stand"]=
        {
            ticks=1,--how long is each frame shown.
            frames={132},--what frames are shown.
        },
        ["walk"]=
        {
            ticks=10,
            frames={128,129},
        },
        ["jump"]=
        {
            ticks=15,
            frames={130},
        },
        ["slide"]=
        {
            ticks=11,
            frames={131},
        },
    },

    curanim="walk",--currently playing animation
    curframe=1,--curent frame of animation.
    animtick=0,--ticks until next frame should show.
    flipx=false,--show sprite be flipped.

    --request new animation to play.
    set_anim=function(self,anim)
      if(anim==self.curanim)return--early out.
      local a=self.anims[anim]
      self.animtick=a.ticks--ticks count down.
      self.curanim=anim
      self.curframe=1
    end,

    getself=function(self)
      return self
    end,

    --call once per tick.
    update=function(self)

      --track button presses
      local bl=btn(0) --left
      local br=btn(1) --right

      --move left/right
      if bl==true then
        self.dx-=self.acc
        br=false--handle double press
      elseif br==true then
        self.dx+=self.acc
      else
        if self.grounded then
          self.dx*=self.dcc
        else
          self.dx*=self.air_dcc
        end
      end

      --limit walk speed
      self.dx=mid(-self.max_dx,self.dx,self.max_dx)
      
      --move in x
      self.x+=self.dx
      
      --hit walls
      collide_side(self)

      --buttons
      self.jump_button:update()
      self.attack_button:update(self.flipx)

      --jump is complex.
      --we allow jump if:
      --    on ground
      --    recently on ground
      --    pressed btn right before landing
      --also, jump velocity is
      --not instant. it applies over
      --multiple frames.
      if self.jump_button.is_down then
        --is player on ground recently.
        --allow for jump right after 
        --walking off ledge.
        local on_ground=(self.grounded or self.airtime<5)
        --was btn presses recently?
        --allow for pressing right before
        --hitting ground.
        local new_jump_btn=self.jump_button.ticks_down<10
        --is player continuing a jump
        --or starting a new one?
        if self.jump_hold_time>0 or (on_ground and new_jump_btn) then
          if(self.jump_hold_time==0)sfx(snd.jump)--new jump snd
          self.jump_hold_time+=1
          --keep applying jump velocity
          --until max jump time.
          if self.jump_hold_time<self.max_jump_press then
            self.dy=self.jump_speed--keep going up while held
          end
        end
      else
          self.jump_hold_time=0
      end

      --move in y
      self.dy+=self.grav
      self.dy=mid(-self.max_dy,self.dy,self.max_dy)
      self.y+=self.dy

      --floor
      if not collide_floor(self) then
        self:set_anim("jump")
        self.grounded=false
        self.airtime+=1
      end

      --roof
      collide_roof(self)

      --handle playing correct animation when
      --on the ground.
      if self.grounded then
        if br then
          if self.dx<0 then
              --pressing right but still moving left.
              self:set_anim("slide")
          else
              self:set_anim("walk")
          end
        elseif bl then
          if self.dx>0 then
            --pressing left but still moving right.
            self:set_anim("slide")
          else
            self:set_anim("walk")
          end
        else
          self:set_anim("stand")
        end
      end

      --flip
      if br then
        self.flipx=false
      elseif bl then
        self.flipx=true
      end

      --anim tick
      self.animtick-=1
      if self.animtick<=0 then
        self.curframe+=1
        local a=self.anims[self.curanim]
        self.animtick=a.ticks--reset timer
        if self.curframe>#a.frames then
            self.curframe=1--loop
        end
      end
    end,

    --draw the player
    draw=function(self)
      local a=self.anims[self.curanim]
      local frame=a.frames[self.curframe]
      spr(frame,
        self.x-(self.w/2),
        self.y-(self.h/2),
        self.w/8,self.h/8,
        self.flipx,
        false)
      -- draw weapon
      sword:draw(self)
    end,
  }
  return p
end