# WarnMe
A Windower 4 addon for Final Fantasy XI

WarnMe was built to prominently print a targeted enemies actions to the players screen.  
Any ability, tp-move or spell is rendered to the center of the window for a few seconds, showing the name of the action, who the actor was and who the action was used on.  

This is for you if you want to:
- see when Pain Sync goes off without having to stare at your log
- react faster to certain monster actions
- learn about a monsters skill set
- focus less on customizing your chat log and having to depend on it
- ignore your chat log altogether

Actions are printed autonomously and do not rely in any way on your chat log or how you have your chat log filtered. This addon does not intend to replace existing addons that might include similar functionality. Instead it is meant to be a very simple and effective solution to the old issue of not reacting to a certain skill or spell because of it flying through the log with the speed of light. Completely built from scratch.   
<br>
## Commands
    //wm toggle [actor/target/spells] : Toggles display of the passed argument
    //wm timeout [seconds] : Sets the duration for which the action will be displayed
    //wm size [ability/details] [size] : Changes the font size of either one
    //wm tune [0.5-1.5] : Tune alignment; lower to push right, raise to push left
    //wm mode : Toogles between allowing own claims or any, even by others
    //wm sticky : Toggles forced visibility for manual positioning on y-axis