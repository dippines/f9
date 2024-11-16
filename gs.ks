SET spot TO LATLNG(latitude,longitude).
parameter landingsite is latlng(spot:LAT,spot:LNG).
set radarOffset to 31. // Ajustez selon la hauteur du vaisseau.
lock trueRadar to alt:radar - radarOffset.
lock g to constant:g * body:mass / body:radius^2.
lock maxDecel to (ship:availablethrust / ship:mass) - g.
lock stopDist to (ship:verticalspeed^2 / (2 * maxDecel)) * 2.
lock idealThrottle to stopDist / trueRadar.
lock errorScaling to 1.
lock gravityForce to ship:mass * g.
set targetSpeed to -10.
lock speedError to targetSpeed - ship:verticalspeed.
lock throttleAdjustment to (speedError * ship:mass) / (ship:availablethrust + gravityForce).
lock ApproachThrottle to throttleAdjustment.

function getImpact {
    if addons:tr:hasimpact { return addons:tr:impactpos. }
    return ship:geoposition.
}

function lngError {
    return getImpact():lng - landingsite:lng.
}

function latError {
    return getImpact():lat - landingsite:lat.
}

function errorVector {
    return getImpact():position - landingsite:position.
}

function getDynamicAOA {

    local errorVector is getimpact():position - landingsite:position.
    local horizontalError is errorVector:mag.

    if horizontalError < 400 { 
        if throttle > 0 {
            set factor to 1.
            print"F".
        } else {
            set factor to -1.
            print"P".
        }
    } else {
        set factor to 1.
        print"F".
    }   
    
        if alt:radar > 50000 {
        set maxAOA to 75*factor.
    } else if alt:radar > 20000 {
        set maxAOA to 20*factor.
    } else if alt:radar > 15000 {
        set maxAOA to 15*factor.
    } else if alt:radar > 5000 {
        set maxAOA to 15.
    } else if alt:radar > 1000 {
        set maxAOA to -10.
    } else {
        set maxAOA to -2.5.
    }

    local dynamicAOA is min(horizontalError, maxAOA).

    return dynamicAOA.
}

function getSteering {

    local errorVector is errorVector().
    local velVector is -ship:velocity:surface.
    local correctionVector to errorVector() * errorScaling.
    local result is velVector + correctionVector.
    local aoa is getDynamicAOA(). 

    if vang(result, velVector) > aoa {
        set result to velVector:normalized + tan(aoa) * correctionVector:normalized.
    }

    return lookdirup(result, facing:topvector).
}

lock steering to ship:up.
wait until alt:radar >=22000.
lock steering to ship:up.
rcs on.
wait until apoapsis.
brakes on.
lock steering to getSteering().
wait until alt:radar <= stopDist.
lock throttle to idealThrottle.
wait until alt:radar <= 200.
gear on.
toggle ag1.
wait until alt:radar <= 50.
lock steering to up.
lock throttle to 0.2.
wait until ship:verticalspeed >= 0.
lock throttle to 0.
rcs off.
lights off.
brakes off.
set ship:control:roll to 0.
set ship:control:pitch to 0.
set ship:control:yaw to 0.
shutdown.