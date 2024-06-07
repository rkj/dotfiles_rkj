import System.IO
import Data.Monoid
import XMonad hiding (Tall)
import XMonad.Config.Gnome
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks hiding (L)
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
import XMonad.Layout.Circle
import XMonad.Layout.Decoration
import XMonad.Layout.DwmStyle
import XMonad.Layout.Gaps hiding (L)
import XMonad.Layout.GridVariants
import XMonad.Layout.HintedTile
import XMonad.Layout.LayoutScreens
import XMonad.Layout.NoBorders
import XMonad.Layout.NoFrillsDecoration
import XMonad.Layout.Reflect
import XMonad.Layout.SimpleDecoration
import XMonad.Layout.Spiral
import XMonad.Layout.SubLayouts
import XMonad.Layout.Tabbed hiding (L)
import XMonad.Layout.ThreeColumns
import XMonad.Layout.TwoPane
import XMonad.StackSet ( Stack (..) )
import XMonad.Util.EZConfig
import XMonad.Util.Run(spawnPipe)

import qualified XMonad.StackSet as W

-- https://wiki.haskell.org/Xmonad/Config_archive/ivy-foster-xmonad.hs
doBottomLeftFloat :: ManageHook
doBottomLeftFloat = ask
                    >>= \w -> doF . W.float w . position . snd
                    =<< liftX (floatLocation w)
    where
    position (W.RationalRect _ _ w h) = W.RationalRect 0 (1-h) w h

myDoFullFloat :: ManageHook
myDoFullFloat = doF W.focusDown <+> doFullFloat

manageHangouts :: ManageHook
manageHangouts = composeAll
   [ className =? "crx_knipolnnllmklapflnccelgolnpehhpl" --> doBottomLeftFloat <+> doShift "1:web"
   , stringProperty "WM_NAME" =? "Hangouts - rkj@google.com" --> doBottomLeftFloat <+> doShift "1:web"
   -- only the last one works when LG3D is set :/
   , stringProperty "WM_WINDOW_ROLE" =? "app" --> doBottomLeftFloat <+> doShift "1:web"
   ]

myManageHook :: ManageHook
myManageHook = composeAll
   [ manageDocks
   , manageHangouts
   , isFullscreen --> myDoFullFloat
   , className =? "Xmessage"  --> doFloat
   , className =? "Screenruler"  --> doFloat
   , className =? "tkdiff.tcl"  --> doFloat
   , className =? "Unity-2d-panel"    --> doIgnore
   , className =? "Unity-2d-shell" --> doIgnore
   , className =? "Workrave" --> doIgnore
   ]

myDWConfig = defaultTheme { inactiveBorderColor = "gray"
                           , inactiveTextColor = "gray"
                           , activeTextColor = "black"
                           , activeBorderColor = "red"
                          }
-- main = xmonad gnomeConfig
-- myLayout = ThreeCol 1 (3/100) (1/2) ||| ThreeColMid 1 (3/100) (1/2)
-- myLayout = gaps [(U, 24)] $ hintedTile Tall ||| Circle ||| ThreeColMid 1 (3/100) (1/2) ||| tabbed shrinkText defaultTheme
-- myLayout = hintedTile Tall ||| Circle ||| threeCol ||| tabbed shrinkText defaultTheme
-- myLayout = hintedTile Tall ||| hintedTile Wide ||| Circle ||| spiral ratio ||| tabbed shrinkText defaultTheme
-- myLayout = reflectHoriz $ hintedTile Tall ||| hintedTile Wide ||| tabbed shrinkText defaultTheme
myLayout = hintedTile Wide ||| hintedTile Tall ||| tabbed shrinkText defaultTheme ||| SplitGrid L 2 2 ratio (16/9) delta
  where
    hintedTile = HintedTile nmaster delta ratio TopLeft
    threeCol   = ThreeColMid nmaster delta ratio
    nmaster    = 1
    -- ratio      = 1/2
    ratio      = 2/5
    delta      = 3/100

noStructs = avoidStruts $ smartBorders $ myLayout
myLayoutHook = noFrillsDeco shrinkText myDWConfig (noStructs)

myLogHook :: Handle -> X ()
myLogHook h = do
    dynamicLogWithPP xmobarPP
          { ppOutput = hPutStrLn h
          , ppTitle = xmobarColor "green" ""
          , ppOrder = \(ws:_:t:_) -> [ws,t]
          }

myHandleEventHook :: Event -> X Data.Monoid.All
myHandleEventHook = fullscreenEventHook -- from ewmh

myStartupHook :: X ()
myStartupHook = do
    setWMName "LG3D"
    startupHook gnomeConfig
    spawn "gnome-panel"
    spawn "workrave"
    spawn "clipit"
    spawn "gtimelog"
    spawn "xscreensaver"
    rescreen
    layoutSplitScreen 2 (TwoPane 0.55 0.45)
--    layoutSplitScreen 3 (SplitGrid T 2 2 (1/2) (16/9) (5/100))
    -- layoutSplitScreen 3 (ThreeCol 1 (3/100) (1/3))
--    layoutSplitScreen 4 (SplitGrid T 2 2 (1/2) (16/9) (5/100))

myKeys = [
     ("C-M1-l", spawn "xscreensaver-command --lock")
     , ("M-a", withFocused $ windows . W.sink)
   ]
   ++ -- setup the fourth screen
   [ (mask ++ "M-" ++ [key], screenWorkspace scr >>= flip whenJust (windows . action))
     | (key, scr)  <- zip "wert" [0,1,2,3]
     , (action, mask) <- [ (W.view, "") , (W.shift, "S-")]
   ]

main = xmonad $ gnomeConfig
   {
     workspaces = ["1:web","2:term","3:chat","4","5","6:personal","7","8"]
     , manageHook = myManageHook
     , modMask = mod4Mask
     , layoutHook = myLayoutHook
     , startupHook = myStartupHook
     , handleEventHook = myHandleEventHook
     -- breaks text input in dartium
     -- , logHook = myLogHook xmproc
   } `additionalKeysP` myKeys
