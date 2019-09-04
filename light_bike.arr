#|
   
 LLLL           IIIIIIIIIIIIII GGGGGGGGGGGG   HHHH      HHHH TTTTTTTTTTTTTT
 LLLL           IIIIIIIIIIIIII GGGGGGGGGGGG   HHHH      HHHH TTTTTTTTTTTTTT
 LLLL           IIIIIIIIIIIIII GGGGGGGGGGGG   HHHH      HHHH TTTTTTTTTTTTTT
 LLLL                IIII      GGGG           HHHH      HHHH      TTTT     
 LLLL                IIII      GGGG           HHHH      HHHH      TTTT     
 LLLL                IIII      GGGG  GGGGGGGG HHHHHHHHHHHHHH      TTTT     
 LLLL                IIII      GGGG  GGGGGGGG HHHHHHHHHHHHHH      TTTT     
 LLLL                IIII      GGGG    GGGG   HHHH      HHHH      TTTT     
 LLLL                IIII      GGGG    GGGG   HHHH      HHHH      TTTT     
 LLLLLLLLLLLLLL IIIIIIIIIIIIII GGGGGGGGGGGG   HHHH      HHHH      TTTT     
 LLLLLLLLLLLLLL IIIIIIIIIIIIII GGGGGGGGGGGG   HHHH      HHHH      TTTT     
 LLLLLLLLLLLLLL IIIIIIIIIIIIII GGGGGGGGGGGG   HHHH      HHHH      TTTT     
 
 BBBBBBBBBBBBBB IIIIIIIIIIIIII KKKK      KKKK EEEEEEEEEEEEEE
 BBBBBBBBBBBBBB IIIIIIIIIIIIII KKKK      KKKK EEEEEEEEEEEEEE
 BBBBBBBBBBBBBB IIIIIIIIIIIIII KKKK      KKKK EEEEEEEEEEEEEE
 BBBB      BBBB      IIII      KKKK      KKKK EEEE          
 BBBB      BBBB      IIII      KKKK      KKKK EEEE          
 BBBBBBBBBB          IIII      KKKKKKKKKK     EEEEEEEEEE    
 BBBBBBBBBB          IIII      KKKKKKKKKK     EEEEEEEEEE    
 BBBB      BBBB      IIII      KKKK      KKKK EEEE          
 BBBB      BBBB      IIII      KKKK      KKKK EEEE          
 BBBBBBBBBBBBBB IIIIIIIIIIIIII KKKK      KKKK EEEEEEEEEEEEEE
 BBBBBBBBBBBBBB IIIIIIIIIIIIII KKKK      KKKK EEEEEEEEEEEEEE
 BBBBBBBBBBBBBB IIIIIIIIIIIIII KKKK      KKKK EEEEEEEEEEEEEE
   
   By: Thomas Del Vecchio
|#

include image
include image-structs
include reactors
include string-dict
import either as EI

####################################
#########  BROKEN IMPORTS  #########
####################################

fun empty-color-scene(
    width :: Number,
    height :: Number,
    shadow color :: Color)
  -> Image:
  overlay(
    rectangle(width, height, "outline", black),
    rectangle(width, height, "solid", color))
end

####################################
######### DATA DEFINITIONS #########
####################################

data Player:
  | player(
      name :: String,
      sprite-color :: Color,
      trails :: List<Trail>,
      position :: Point,
      direction :: Direction,
      alive :: Boolean,
      controls :: StringDict<Direction>)
end

data Point:
  | point(
      x :: Number,
      y :: Number)
end

data Trail:
  | trail(
      p-start :: Point,
      p-end :: Point) with:
    method intersects(self, other :: Trail) -> Boolean:
      doc: ```Checks if two trails intersect.```
      self-vertical = self.p-start.x == self.p-end.x
      other-vertical = other.p-start.x == other.p-end.x
      
      if self-vertical and other-vertical:
        (self.p-start.x == other.p-start.x)
        and not(num-max(self.p-start.y, self.p-end.y) 
            < num-min(other.p-start.y, other.p-end.y))
        and not(num-min(self.p-start.y, self.p-end.y) 
            > num-max(other.p-start.y, other.p-end.y))
      else if not(self-vertical) and not(other-vertical):
        (self.p-start.y == other.p-start.y)
        and not(num-max(self.p-start.x, self.p-end.x) 
            < num-min(other.p-start.x, other.p-end.x))
        and not(num-min(self.p-start.x, self.p-end.x) 
            > num-max(other.p-start.x, other.p-end.x))
      else if self-vertical and not(other-vertical):
        not(self.p-start.x < num-min(other.p-start.x, other.p-end.x))
        and not(self.p-start.x > num-max(other.p-start.x, other.p-end.x))
        and not(other.p-start.y < num-min(self.p-start.y, self.p-end.y))
        and not(other.p-start.y > num-max(self.p-start.y, self.p-end.y))
      else:
        not(other.p-start.x < num-min(self.p-start.x, self.p-end.x))
        and not(other.p-start.x > num-max(self.p-start.x, self.p-end.x))
        and not(self.p-start.y < num-min(other.p-start.y, other.p-end.y))
        and not(self.p-start.y > num-max(other.p-start.y, other.p-end.y))
      end
    end
end

data Direction:
  | north with:
    method dx(self): 0 end,
    method dy(self): -1 end
  | east with:
    method dx(self): 1 end,
    method dy(self): 0 end
  | south with:
    method dx(self): 0 end,
    method dy(self): 1 end
  | west with:
    method dx(self): -1 end,
    method dy(self): 0 end
sharing:
  method perpendicular(self, other :: Direction) -> Boolean:
    doc: ```Checks if two directions are perpendicular.```
    ((self.dx() * other.dx()) + (self.dy() * other.dy())) == 0
  end
end

data GameCommand:
  | pause
  | quit
end

####################################
############  CONSTANTS ############
####################################

BOARD-SIZE :: Point = point(1000, 600)
# The following needs to be defined after DATA HELPER FUNCTIONS
# DEFAULT-PLAYERS :: List<Player> = range(1, 5).map(new-default-player)
TICKS-PER-SECOND :: Number = 60
SPEED :: Number = 5

####################################
######  DATA HELPER FUNCTIONS ######
####################################

fun new-player(
    name :: String,
    sprite-color :: Color,
    start-pos :: Point,
    start-dir :: Direction,
    controls :: StringDict<Direction>)
  -> Player:
  doc: ```Creates a new custom player.```
  player(
    name, 
    sprite-color, 
    [list: trail(start-pos, start-pos)], 
    start-pos, 
    start-dir, 
    true,
    controls)
end

fun new-default-player(
    player-num :: Number)
  -> Player:
  doc: ```Creates a new default player.```
  ask:
    | player-num == 1 then: new-player("Player 1", red, 
        point(BOARD-SIZE.x * (1 / 4), BOARD-SIZE.y * (1 / 4)),
        east, 
        [string-dict:
          "w", north,
          "a", west,
          "s", south,
          "d", east])
    | player-num == 2 then: new-player("Player 2", blue, 
        point(BOARD-SIZE.x * (3 / 4), BOARD-SIZE.y * (3 / 4)),
        west, 
        [string-dict:
          "up", north,
          "left", west,
          "down", south,
          "right", east])
    | player-num == 3 then: new-player("Player 3", green, 
        point(BOARD-SIZE.x * (3 / 4), BOARD-SIZE.y * (1 / 4)),
        south, 
        [string-dict:
          "y", north,
          "g", west,
          "h", south,
          "j", east])
    | player-num == 4 then: new-player("Player 4", yellow, 
        point(BOARD-SIZE.x * (1 / 4), BOARD-SIZE.y * (3 / 4)),
        north, 
        [string-dict:
          "p", north,
          "l", west,
          ";", south,
          "'", east])
    | otherwise: raise("Default player can only be integer 1-4")
  end
end

DEFAULT-PLAYERS :: List<Player> = range(1, 5).map(new-default-player)

####################################
############ GAME LOGIC ############
####################################

## State definition

data State:
  | menu
  | starting(
      players :: List<Player>,
      time-left :: Number)
  | playing(
      players :: List<Player>)
  | exit
end


## on-tick

fun check-collision(
    players :: List<Player>) 
  -> (Player -> Player):
  doc: ```Handles killing players that collide with a wall.```
  
  lam(p :: Player) -> Player:
    doc: ```Updates the player appropriately if they collided with anyone.```
    
    # The trail that we are checking collision for
    trail-to-draw :: Trail = trail(p.trails.first.p-end, p.position)
    
    # Go through the players and check if any collisions
    killed-by :: Option<Player> = 
      lists.fold-while({(killed-by :: Option<Player>, other-p :: Player):
          # If we're checking against self, we need to drop up to the
          # two most recent trails to avoid trivial collisions
          to-drop :: Number = num-min(p.trails.length(),
            if p == other-p: 2
            else: 0
            end)

          # Go through trails of other player
          result :: Boolean = 
            lists.fold-while({(killed :: Boolean, curr-trail :: Trail):
                if trail-to-draw.intersects(curr-trail):
                  EI.right(true)
                else:
                  EI.left(false)
                end}, 
              false, 
              other-p.trails.drop(to-drop))

          # Return the other player, which might be used in future for killfeed
          if result:
            EI.right(some(other-p))
          else:
            EI.left(none)
          end}, none, players)
    
    # Out of bounds
    out-of-bounds :: Boolean = 
      (p.position.x < 0)
    or (BOARD-SIZE.x < p.position.x)
    or (p.position.y < 0)
    or (BOARD-SIZE.y < p.position.y)
    
    if p.alive and (out-of-bounds or is-some(killed-by)):
      player(
        p.name,
        p.sprite-color,
        p.trails,
        p.position,
        p.direction,
        false,
        p.controls)
    else: 
      p
    end
  end
end

fun move-player(
    p :: Player)
  -> Player:
  doc: ```Moves the given player.```
  if not(p.alive):
    p
  else:
    new-position :: Point = point(
      p.position.x + (p.direction.dx() * SPEED),
      p.position.y + (p.direction.dy() * SPEED))

    player(
      p.name,
      p.sprite-color,
      p.trails.set(0, trail(p.trails.first.p-start, new-position)),
      new-position,
      p.direction,
      p.alive,
      p.controls)
  end
end

fun on-tick(
    state :: State)
  -> State:
  doc: ```The on-tick function for reactor.```
  cases (State) state:
    | exit => state
    | menu => state
    | starting(players, time-left) =>
      new-time-left :: Number = time-left - (1 / TICKS-PER-SECOND)
      if new-time-left <= 0:
        playing(players)
      else:
        starting(players, new-time-left)
      end
    | playing(players) =>
      new-players :: List<Player> = players
        ^ _.map(check-collision(players))
        ^ _.map(move-player)
      
      if new-players.any(_.alive):
        playing(new-players)
      else:
        menu
      end
  end
end


## on-mouse

fun on-mouse(
    state :: State, 
    x :: Number, 
    y :: Number, 
    action :: String) 
  -> State:
  doc: ```The on-mouse function for reactor.```
  state
end

## on-key
  
fun turn-player(
    p :: Player,
    new-direction :: Direction)
  -> Player:
  doc: ```Turns a player to new-direction, if it is a valid turn.```
  if p.direction.perpendicular(new-direction):
    player(
      p.name,
      p.sprite-color,
      p.trails.push(trail(p.position, p.position)),
      p.position,
      new-direction,
      p.alive,
      p.controls)
  else:
    p
  end
end

fun handle-key(
    players :: List<Player>,
    key :: String)
  -> State:
  doc: ```Handles key presses for a state of playing.```
  new-players :: List<Player> = players.map({(p):
      cases (Option<Direction>) p.controls.get(key):
        | none => p
        | some(dir) => turn-player(p, dir)
      end})
  
  playing(new-players)
end

fun on-key(
    state :: State, 
    key :: String) 
  -> State:
  doc: ```The on-key function for reactor.```
  cases (State) state:
    | exit => state
    | starting(_, _) => state
    | menu => # eventually will return state
      cases (Option<Number>) string-to-number(key):
        | none => state
        | some(num-players) =>
          if (2 <= num-players) and (num-players <= 4):
            starting(DEFAULT-PLAYERS.take(num-players), 5)
          else:
            state
          end
      end
    | playing(players) => handle-key(players, key)
  end
end

## to-draw

fun update-cache(
    players :: List<Player>, 
    cache :: Image) 
  -> Image:
  doc: ```Creates a new image updated with the current player positions.```
  players.foldl({(p, img): 
      if not(p.alive):
        img
      else:
        add-line(
          img,
          p.trails.first.p-start.x, p.trails.first.p-start.y,
          # Handle not drawing out of bounds
          num-max(num-min(p.position.x, BOARD-SIZE.x), 0), 
          num-max(num-min(p.position.y, BOARD-SIZE.y), 0),
          p.sprite-color)
      end}, 
      cache)
end

fun draw-player(
    p :: Player, 
    img :: Image) 
  -> Image:
  doc: ```Adds a given player sprite onto the board.```
  WIDTH :: Number = 10
  LENGTH :: Number = 10
  
  side-length :: Number = num-sqrt(num-sqr(LENGTH) + num-sqr(WIDTH / 2))
  
  # Create player sprite and rotate appropriately
  sprite :: Image = 
    triangle-sss(side-length, side-length, WIDTH, "solid", p.sprite-color)
    ^ rotate(
    cases (Direction) p.direction:
      | north => 180
      | east => 90
      | south => 0
      | west => 270
    end,
    _)
  
  # Find tip of sprite
  tip :: Point = 
    cases (Direction) p.direction:
      | north => point(WIDTH / 2, 0)
      | east => point(WIDTH, LENGTH / 2)
      | south => point(WIDTH / 2, LENGTH)
      | west => point(0, LENGTH / 2)
    end
  
  # Add to image if still alive
  if not(p.alive):
    img
  else:
    overlay-xy(
      sprite,
      0 - (p.position.x - tip.x), 0 - (p.position.y - tip.y),
      img)
  end
end

fun draw-controls(
    p :: Player,
    img :: Image)
  -> Image:
  doc: ```Writes the controls for the given player during starting phase.```
  controls :: Image = text(
    p.controls.keys().fold({(a,  b): a + "  " + b}, ""),
    20,
    p.sprite-color)
    
  # Draw above player
  overlay-xy(controls,
    (0 - (p.position.x - (image-width(controls) / 2))),
    (0 - (p.position.y - 30)),
    img)
end

fun draw-starting(
    players :: List<Player>, 
    time-left :: Number,
    background :: Image) 
  -> Image:
  doc: ```Helps to-draw for state of starting. Adds players to cache
       and draws count-down timer.```
  background
  
  # Add player triangles
    ^ players.foldl(draw-player, _)
  
  # Add controls
    ^ players.foldl(draw-controls, _)
  
  # Add time left text
    ^ overlay-align(
    "center", "center",
    text(num-to-string-digits(time-left, 3), 20, white),
    _)
end

fun draw-playing(
    players :: List<Player>,
    cache :: Image) 
  -> Image:
  doc: ```Helps to-draw for state of playing. Adds players to cache
       and (TODO) draws killfeed.```
  cache
  
  # Add player triangles
    ^ players.foldl(draw-player, _)
  
  # TODO: Add killfeed
end

fun to-draw-init() 
  -> (State -> Image):
  doc: ```Creates the to-draw function. Used to store a cached image of
       the board in order to prevent redrawing all the trails every frame.```

  blank :: Image = empty-color-scene(BOARD-SIZE.x, BOARD-SIZE.y, black)
  var cache :: Image = blank
  
  fun to-draw(
      state :: State)
    -> Image:
    doc: ```The to-draw function for reactor.```
    cases (State) state block:
      | exit => empty-image
      | menu => overlay-align("center", "center",
          text("Press 2, 3, or 4 for number of players.", 20, white),
          blank)
        
      | starting(players, time-left) =>
        cache := update-cache(players, blank)
        draw-starting(players, time-left, cache)
        
      | playing(players) => 
        cache := update-cache(players, cache)
        draw-playing(players, cache)
    end
  end
  
  to-draw
end

## reactor

r = reactor:
  title: "Neon Rider",
  
  init: menu,
  
  on-tick: on-tick,
  seconds-per-tick: 1 / TICKS-PER-SECOND,
  
  on-mouse: on-mouse,
  on-key: on-key,
  
  to-draw: to-draw-init(),
  
  stop-when: is-exit,
  close-when-stop: true
end

interact(r)
