function main {
  doSystemsCheck().
  doCountdown().
  doLaunch().
  doAscent().
  doThrottleDown().
   until apoapsis > 75000 {
    doAutoStage().
    doFairingSep().
  }
  doShutdown().
  doCircularization().
  doPayloadSeperation().
  doDeorbit().
  doHoverSlam().
}

function doSystemsCheck{

  Print "Phoenix Flight Ready".
  Wait 2.
  clearscreen.
  Print "Please press 'Return' to intiate Terminal Sequence".
  set ch to terminal:input:getchar().
  Wait until terminal:input:Return.
  wait 1.
  doTerminalSeuqence().
}

function doTerminalSeuqence {
    Print "Strongback Seperation in...".
  Wait 1.
  Print "3".
  Wait 1.
  Print "2".
  Wait 1.
  Print "1".
  Wait 1.
  Print "...".
  Stage.
  Wait 2.
  Print "Strongback Seperation Confirmed".
  Wait 5.
  clearscreen.
  Print "Phoenix is on Internal Power".
  Wait 3.
  Print "All Systems are GO".
  wait 1.
  Print "Initiating Terminal Count...".
  Wait 5.
}

function doCountdown{  
    clearscreen.  
    PRINT "Igniters On, Counting down:".
    Stage.

    FROM {local countdown is 5.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO { //This is our countdown loop, which cycles from 5 to 0

        PRINT "T- " + countdown.
        Wait 1.

        }

        Stage.
        Print "Ignition".
    
    
    
}

function doLaunch {
  AG9 OFF.
  Wait 0.1.
  lock throttle to 1.
  wait 3.
  doSafeStage().
  Print "Liftoff".
}

function doAscent {
  clearscreen.
  Print "Ascent in Progress.".
  lock targetPitch to 90 - .67 * alt:radar^0.409511.
  set targetDirection to 90.
  lock steering to heading(targetDirection, targetPitch).

}

function doThrottleDown {
    Wait until SHIP:ALTITUDE > 10000.
    Lock throttle to 0.75.
    Print "Throttling down for Max-Q".
    Wait until SHIP:ALTITUDE > 18000.
    Lock throttle to 0.46.
    Print "Throttling down to 45%".
}

function doAutoStage {
  if not(defined oldThrust) {
    global oldThrust is ship:availablethrust.
  }
  if ship:availablethrust < (oldThrust - 10) {
    doSafeStage(). wait 1.
    Print "Staging...".
    doSafeStage().
    global oldThrust is ship:availablethrust.
  }
}

function doShutdown {
  Print "MECO".
  lock throttle to 0.
  lock steering to prograde.
}

function doFairingSep {
  Set X to False.
    if SHIP:ALTITUDE > 50000 {
    Set X to true.
    }
    If x = True {
      wait 5.
      AG5 ON.
    }
}

function doSafeStage {
  wait until stage:ready.
  wait 1.5.
  stage.
}

function doCircularization {
  clearscreen.
  Print "Circularizing Orbit".
  local circ is list(0).
  set circ to improveConverge(circ, eccentricityScore@).
  wait until altitude > 70000.
  executeManeuver(list(time:seconds + eta:apoapsis, 0, 0, circ[0])).
}

function eccentricityScore {
  parameter data.
  local mnv is node(time:seconds + eta:apoapsis, 0, 0, data[0]).
  addManeuverToFlightPlan(mnv).
  local result is mnv:orbit:eccentricity.
  removeManeuverFromFlightPlan(mnv).
  return result.
}

function improveConverge {
  parameter data, scoreFunction.
  for stepSize in list(100, 10, 1) {
    until false {
      local oldScore is scoreFunction(data).
      set data to improve(data, stepSize, scoreFunction).
      if oldScore <= scoreFunction(data) {
        break.
      }
    }
  }
  return data.
}

function improve {
  parameter data, stepSize, scoreFunction.
  local scoreToBeat is scoreFunction(data).
  local bestCandidate is data.
  local candidates is list().
  local index is 0.
  until index >= data:length {
    local incCandidate is data:copy().
    local decCandidate is data:copy().
    set incCandidate[index] to incCandidate[index] + stepSize.
    set decCandidate[index] to decCandidate[index] - stepSize.
    candidates:add(incCandidate).
    candidates:add(decCandidate).
    set index to index + 1.
  }
  for candidate in candidates {
    local candidateScore is scoreFunction(candidate).
    if candidateScore < scoreToBeat {
      set scoreToBeat to candidateScore.
      set bestCandidate to candidate.
    }
  }
  return bestCandidate.
}

function executeManeuver {
  parameter mList.
  local mnv is node(mList[0], mList[1], mList[2], mList[3]).
  addManeuverToFlightPlan(mnv).
  local startTime is calculateStartTime(mnv).
  wait until time:seconds > startTime - 15.
  lockSteeringAtManeuverTarget(mnv).
  wait until time:seconds > startTime.
  lock throttle to 1.
  until isManeuverComplete(mnv) {
    doAutoStage().
  }
  lock throttle to 0.
  unlock steering.
  removeManeuverFromFlightPlan(mnv).
}

function addManeuverToFlightPlan {
  parameter mnv.
  add mnv.
}

function calculateStartTime {
  parameter mnv.
  return time:seconds + mnv:eta - maneuverBurnTime(mnv) / 2.
}

function maneuverBurnTime {
  parameter mnv.
  local dV is mnv:deltaV:mag.
  local g0 is 9.80665.
  local isp is 0.

  list engines in myEngines.
  for en in myEngines {
    if en:ignition and not en:flameout {
      set isp to isp + (en:isp * (en:maxThrust / ship:maxThrust)).
    }
  }

  local mf is ship:mass / constant():e^(dV / (isp * g0)).
  local fuelFlow is ship:maxThrust / (isp * g0).
  local t is (ship:mass - mf) / fuelFlow.

  return t.
}

function lockSteeringAtManeuverTarget {
  parameter mnv.
  lock steering to mnv:burnvector.
}

function isManeuverComplete {
  parameter mnv.
  if not(defined originalVector) or originalVector = -1 {
    declare global originalVector to mnv:burnvector.
  }
  if vang(originalVector, mnv:burnvector) > 90 {
    declare global originalVector to -1.
    return true.
  }
  return false.
}

function removeManeuverFromFlightPlan {
  parameter mnv.
  remove mnv.
}

function doPayloadSeperation {
    wait 3.
    AG9 ON.
    Wait 1.
    Stage.
    wait 2.
    Print "Payload Seperation Confirmed".
    Wait 1.
}

function doDeorbit {
    wait 1.
    RCS ON.
    wait 0.5.
    Lock steering to up.
    wait 5.
    Lock steering to srfretrograde.
    wait 20.
    Lock throttle to 0.75.
    Print "De-Orbit Burn Started".
    Wait until periapsis < 41000.
    Lock throttle to 0.
    Print "De-Orbit Burn Complete".
    Wait 3.
    Print "Preppring for Entry".
    wait 3.
    clearscreen.
    Print "Entry Phase".
    Brakes On.
}

function doHoverSlam {
    wait until ship:altitude < 15000.
    clearscreen.
    set radarOffset to 16.	 				// The value of alt:radar when landed (on gear)
    lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
    lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
    lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
    lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
    lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
    lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear


    WAIT UNTIL ship:verticalspeed < -1.
        print "Preparing for hoverslam...".
        rcs on.
        brakes on.
        lock steering to srfretrograde.
        when impactTime < 3 then {gear on.}

    WAIT UNTIL trueRadar < stopDist.
        print "Landing Burn Started - " + time:clock.
        lock throttle to idealThrottle.

    WAIT UNTIL ship:verticalspeed > -0.01.
        CLEARSCREEN.
        print "Phoenix has Landed " + time:clock.
        set ship:control:pilotmainthrottle to 0.
        rcs off.
            Brakes off.
            AG2 on.
           
}

main().