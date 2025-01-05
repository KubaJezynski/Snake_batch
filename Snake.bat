@ECHO OFF
SETLOCAL enabledelayedexpansion

GOTO :start_app

REM %~1 - array name
:array_struct
IF "%~1" == "" EXIT /b
SET %~1=%~1
SET /a %~1.length=0
EXIT /b

REM %~1 - array name
REM %~2 - item
:array_struct_add
IF "%~1" == "" EXIT /b
IF "%~2" == "" EXIT /b
SET %~1[!%~1.length!]=%~2
SET /a %~1.length+=1
EXIT /b

REM %~1 - array name
REM %~2 - index
:array_struct_remove
IF "%~1" == "" EXIT /b
SET /a max_length=!%~1.length!-1
IF %~2 gtr %max_length% EXIT /b
IF %~2 lss 0 EXIT /b
SET /a index=%~2
FOR /l %%i IN (%~2,1,!%~1.length!) DO (
  SET %~1[!index!]=!%~1[%%i]!
  SET /a index=%%i
)
SET /a %~1.length-=1
CALL SET %~1[%%%~1.length%%]=
EXIT /b

REM %~1 - array name
REM %~2 - index
REM %~3 - item
:array_struct_replace
IF "%~1" == "" EXIT /b
SET /a max_length=!%~1.length!-1
IF %~2 gtr %max_length% EXIT /b
IF %~2 lss 0 EXIT /b
IF "%~3" == "" EXIT /b
SET %~1[%~2]=%~3
EXIT /b

REM %~1 - array name
REM %~2 - index
REM %~3 - item
:array_struct_insert
IF "%~1" == "" EXIT /b
SET /a max_length=!%~1.length!-1
IF %~2 gtr %max_length% (
  CALL :array_struct_add %~1 %~3
  EXIT /b
)
IF %~2 lss 0 EXIT /b
IF "%~3" == "" EXIT /b
SET current_item=%~3
SET next_item=!%~1[%~2]!
FOR /l %%i IN (%~2,1,%max_length%) DO (
  SET next_item=!%~1[%%i]!
  CALL SET %~1[%%i]=!current_item!
  SET current_item=!next_item!
)
SET %~1[!%~1.length!]=!current_item!
SET /a %~1.length+=1
EXIT /b

REM %~1 - first array name
REM %~2 - second array name, array to copy
:array_struct_copy
SET /a max_length=!%~2.length!-1
FOR /l %%i IN (0,1,!max_length!) DO (
  CALL :array_struct_add %~1 !%~2[%%i]!
)
EXIT /b

REM %~1 - position name
REM %~2 - position x
REM %~3 - position y
:position_struct
IF "%~1" == "" EXIT /b
IF "%~2" == "" EXIT /b
IF "%~3" == "" EXIT /b
SET /a %~1.position.x=%~2
SET /a %~1.position.y=%~3
SET %~1.position=[!%~1.position.x!:!%~1.position.y!]
EXIT /b

REM %~1 - game object name
REM %~2 - game object body
:game_object_struct
IF "%~1" == "" EXIT /b
IF "%~2" == "" EXIT /b
SET %~1=%~1
SET /a %~1.health=1
CALL :position_struct %~1 0 0
SET %~1.body=%~2
EXIT /b

REM %~1 - camera name
REM %~2 - camera width
REM %~3 - camera height
:camera_struct
SET /a min_width=3
SET /a min_height=3
SET /a camera_width=%~2
SET /a camera_height=%~3
IF "%~1" == "" EXIT /b
IF !camera_width! lss !min_width! SET /a camera_width=!min_width!
IF "%~2" == "" EXIT /b
IF !camera_height! lss !min_height! SET /a camera_height=!min_height!
IF "%~3" == "" EXIT /b
SET %~1=%~1
SET /a %~1.width=!camera_width!
SET /a %~1.height=!camera_height!
CALL :position_struct %~1 0 0
EXIT /b

REM %~1 - variable to assign
REM %~2 - string to wrap
:wrap_string
IF "%~1" == "" EXIT /b
IF "%~2" == "" EXIT /b
SET %~1=!%~2!
EXIT /b

:update
CALL :spawn_point
CALL :update_last_player_body_last_position
CALL :update_player_position
CALL :check_collision
EXIT /b

:draw
CALL :write_camera_view camera
CLS
CALL :read_camera_view camera
EXIT /b

REM %~1 - camera name
:write_camera_view
IF "%~1" == "" EXIT /b
break>%~1_view.txt
CALL :array_struct temp_array
CALL :array_struct_copy temp_array player_body_array
CALL :array_struct_copy temp_array game_objects
SET /a max_length=!temp_array.length!-1
IF !temp_array.length! lss 1 EXIT /b
SET row_to_write=
SET /a camera_width=%~1.width %% 2
SET /a camera_height=%~1.height %% 2
SET /a camera_position_x=!%~1.position.x!
SET /a camera_position_y=!%~1.position.y!
IF !camera_width! == 0 (SET /a camera_width=%~1.width+1)
IF NOT !camera_width! == 0 (SET /a camera_width=%~1.width)
IF !camera_height! == 0 (SET /a camera_height=%~1.height+1)
IF NOT !camera_height! == 0 (SET /a camera_height=%~1.height)
SET /a iteration_start_width=!camera_position_x!-(!camera_width!-1)/2
SET /a iteration_end_width=!camera_position_x!+(!camera_width!-1)/2
SET /a iteration_start_height=!camera_position_y!-(!camera_height!-1)/2
SET /a iteration_end_height=!camera_position_y!+(!camera_height!-1)/2
SET /a height_index=%iteration_end_height%
FOR /l %%i IN (!iteration_start_height!,1,!iteration_end_height!) DO (
  FOR /l %%j IN (!iteration_start_width!,1,!iteration_end_width!) DO (
    SET /a game_object_index=-1
    SET position_to_find=[%%j:!height_index!]
    CALL :find_game_object temp_array !position_to_find! game_object_index
    IF !game_object_index! lss 0 (CALL SET row_to_write=!row_to_write!!background_body!)
    IF NOT !game_object_index! lss 0 (
      SET game_object=temp_array[!game_object_index!]
      CALL :wrap_string game_object !game_object!
      SET game_object_body=!game_object!.body
      CALL :wrap_string game_object_body !game_object_body!
      CALL SET row_to_write=!row_to_write!!game_object_body!
    )
  )
  ECHO !row_to_write!>>%~1_view.txt
  SET row_to_write=
  SET /a height_index-=1
)
EXIT /b

REM %~1 - camera name
:read_camera_view
FOR /f "tokens=*" %%i in (%~1_view.txt) DO (
  ECHO %%i
)
EXIT /b

REM %~1 - array name
REM %~2 - game object position to find in array
REM %~3 - variable to assign game object index
:find_game_object
IF "%~1" == "" EXIT /b
IF "%~2" == "" EXIT /b
IF "%~3" == "" EXIT /b
SET /a max_length=!%~1.length!-1
FOR /l %%i IN (0,1,%max_length%) DO (
  SET game_object_position=!%~1[%%i]!.position
  CALL :wrap_string game_object_position !game_object_position!
  IF !game_object_position! == %~2 (
    SET /a %~3=%%i
    EXIT /b
  )
)
EXIT /b

:initiate_player
CALL :game_object_struct player Q
CALL :position_struct player !map_width!/2 !map_height!/2
CALL :array_struct_add player_body_array player
EXIT /b

REM %~1 - map width
REM %~1 - map height
:initiate_map
IF "%~1" == "" EXIT /b
IF "%~2" == "" EXIT /b
SET /a map_width_max=20
SET /a map_width_min=3
SET /a map_height_max=20
SET /a map_height_min=3
SET /a map_width=%~1
SET /a map_height=%~2
IF !map_width! gtr !map_width_max! (SET /a map_width=!map_width_max!)
IF !map_width! lss !map_width_min! (SET /a map_width=!map_width_min!)
IF !map_height! gtr !map_height_max! (SET /a map_height=!map_height_max!)
IF !map_height! lss !map_height_min! (SET /a map_height=!map_height_min!)
FOR /l %%i IN (0,1,!map_height!) DO (
  FOR /l %%j IN (0,1,!map_width!) DO (
    SET /a is_outside=0
    IF %%i == 0 (SET /a is_outside=1)
    IF %%i == !map_height! (SET /a is_outside=1)
    IF %%j == 0 (SET /a is_outside=1)
    IF %%j == !map_width! (SET /a is_outside=1)
    IF !is_outside! == 1 (
        CALL :game_object_struct obstacle_body%%j%%i !obstacle_body!
        CALL :position_struct obstacle_body%%j%%i %%j %%i
        CALL :array_struct_add game_objects obstacle_body%%j%%i
    )
  )
)
EXIT /b

REM %~1 - game object name
REM %~2 - game object body
:spawn_game_object
CALL :array_struct temp_array
SET /a iterations_max_width = !map_width! - 1
SET /a iterations_max_height = !map_height! - 1
FOR /l %%i IN (1,1,!iterations_max_height!) DO (
  FOR /l %%j IN (1,1,!iterations_max_width!) DO (
    SET /a game_object_index=-1
    SET position_to_find=[%%j:%%i]
    CALL :find_game_object game_objects !position_to_find! game_object_index
    IF !game_object_index! lss 0 (
      CALL :position_struct temp_position%%j%%i %%j %%i
      CALL :array_struct_add temp_array temp_position%%j%%i
    )
  )
)
IF !temp_array.length! lss 1 EXIT /b
SET /a random_index = %random% %% !temp_array.length!
SET temp_position=temp_array[!random_index!]
CALL :wrap_string temp_position !temp_position!
SET /a temp_position_x=-1
SET /a temp_position_y=-1
CALL :wrap_string temp_position_x !temp_position!.position.x
CALL :wrap_string temp_position_y !temp_position!.position.y
CALL :game_object_struct %~1 %~2
CALL :position_struct %~1 !temp_position_x! !temp_position_y!
CALL :array_struct_add game_objects %~1
EXIT /b

:spawn_point
IF !is_point_spawned! == 0 (
  CALL :spawn_game_object point !point_body!
  SET /a is_point_spawned=1
)
EXIT /b

:check_collision
CALL :array_struct temp_array
CALL :array_struct_copy temp_array player_body_array
CALL :array_struct_copy temp_array game_objects
SET /a max_length=!temp_array.length!-1
IF !temp_array.length! lss 1 EXIT /b
FOR /l %%i IN (1,1,%max_length%) DO (
  SET game_object=!temp_array[%%i]!
  SET game_object_position=!game_object!.position
  CALL :wrap_string game_object_position !game_object_position!
  IF !player.position! == !game_object_position! (
    SET game_object_body=!game_object!.body
    CALL :wrap_string game_object_body !game_object_body!
    IF !game_object_body! == !obstacle_body! (
      SET /a player.health-=1
      CALL :check_player_health
      EXIT /b
    )
    IF !game_object_body! == !snake_body! (
      SET /a player.health-=1
      CALL :check_player_health
      EXIT /b
    )
    IF !game_object_body! == !point_body! (
      SET /a score+=1
      SET player_body_name=player!player_body_array.length!
      CALL :game_object_struct !player_body_name! !snake_body!
      CALL :position_struct !player_body_name! !last_player_body_last_position.position.x! !last_player_body_last_position.position.y!
      CALL :array_struct_add player_body_array !player_body_name!
      SET /a game_object_index=-1
      SET position_to_find=!game_object_position!
      CALL :find_game_object game_objects !position_to_find! game_object_index
      IF NOT !game_object_index! lss 0 (CALL :array_struct_remove game_objects !game_object_index!)
      SET /a is_point_spawned=0
      EXIT /b
    )
  )
)
EXIT /b

:check_player_health
IF !player.health! lss 1 GOTO :post_game
EXIT /b

:update_player_position
IF !player_body_array.length! gtr 1 (
  SET /a max_length=!player_body_array.length!-1
  SET /a current_index=%max_length%
  SET /a previous_index=%max_length%-1
  FOR /l %%i IN (1,1,%max_length%) DO (
    SET current_player_body=player_body_array[!current_index!]
    CALL :wrap_string current_player_body !current_player_body!
    SET previous_player_body=player_body_array[!previous_index!]
    CALL :wrap_string previous_player_body !previous_player_body!
    SET previous_player_body_position_x=!previous_player_body!.position.x
    SET previous_player_body_position_y=!previous_player_body!.position.y
    CALL :wrap_string previous_player_body_position_x !previous_player_body_position_x!
    CALL :wrap_string previous_player_body_position_y !previous_player_body_position_y!
    CALL :position_struct !current_player_body! !previous_player_body_position_x! !previous_player_body_position_y!
    SET /a current_index-=1
    SET /a previous_index-=1
  )
)
set /p key_listener=<KeyStroke.txt
IF !key_listener! == w (CALL :position_struct player !player.position.x! !player.position.y!+1)
IF !key_listener! == s (CALL :position_struct player !player.position.x! !player.position.y!-1)
IF !key_listener! == a (CALL :position_struct player !player.position.x!-1 !player.position.y!)
IF !key_listener! == d (CALL :position_struct player !player.position.x!+1 !player.position.y!)
EXIT /b

:update_last_player_body_last_position
SET /a last_index=!player_body_array.length!-1
SET last_player_body=player_body_array[!last_index!]
CALL :wrap_string last_player_body !last_player_body!
SET /a last_player_body_last_position_x=0
SET /a last_player_body_last_position_y=0
CALL :wrap_string last_player_body_last_position_x !last_player_body!.position.x
CALL :wrap_string last_player_body_last_position_y !last_player_body!.position.y
CALL :position_struct last_player_body_last_position !last_player_body_last_position_x! !last_player_body_last_position_y!
EXIT /b

:start_KeyListener
START "" KeyListener.bat
EXIT /b

:start_app
SET key_listener=
SET point_body=0
SET snake_body=O
SET obstacle_body=X
SET background_body=+
SET /a is_point_spawned=0
SET /a score=0
SET /a map_width=5
SET /a map_height=5
CALL :array_struct game_objects
CALL :array_struct player_body_array
CALL :camera_struct camera !map_width!+2 !map_height!+2
CALL :position_struct camera !map_width!/2 !map_height!/2
CALL :initiate_player
CALL :position_struct last_player_body_last_position !player.position.x! !player.position.y!
CALL :initiate_map !map_width! !map_height!

:pre_game
CLS
ECHO WITAJ W GRZE SNAKE
ECHO\
ECHO wybierz operacje:
ECHO 1-zagraj
ECHO 2-wyjdz
SET /a choice=0
SET /p "choice=numer:"
IF %choice% == 1 (
  CALL :start_KeyListener
  GOTO :in_game
)
IF %choice% == 2 GOTO :end_app
GOTO :pre_game

:in_game
CALL :update
CALL :draw
GOTO :in_game

:post_game
CLS
ECHO ---GAME OVER---
ECHO twoj wynik = %score%
PAUSE
GOTO :start_app

:end_app
EXIT