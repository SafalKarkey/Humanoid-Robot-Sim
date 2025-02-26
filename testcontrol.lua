-- sim = require('sim')
require('init')
require('move_angles')

-- Global state variables:
-- robotState: "scanning", "objectDetected", "rotating", "aligned", "moving"
robotState = "scanning"
chosenRotateMotion = nil  -- "rotate" (left) or "rotate_right" (right)
lastNeckPos = 0           -- To store the neck angle when object is first detected.
moveType = nil            -- "side", "forward", or "pick" (for moving phase)
sensorDetectedPoint = nil -- Latest sensor-detected point

-----------------------------------------------------

function scan_environment()
    sim.wait(0.3, false)
    local current_angle = sim.getJointTargetPosition(neck)

    if current_angle <= -45 then
        headMovingRight = true -- Change direction
        scanPassCount = scanPassCount + 1
    elseif current_angle >= 45 then
        headMovingRight = false -- Change direction
        scanPassCount = scanPassCount + 1
    end

    if headMovingRight then
        sim.setJointTargetPosition(neck, current_angle + 10)
    else
        sim.setJointTargetPosition(neck, current_angle - 10)
    end

    -- If two full passes are complete and no object detected, rotate the body
    if scanPassCount >= 2 then
        print("No object found after full scan. Rotating body.")
        scanPassCount = 0 -- Reset scan counter
        robotState = "bodyRotating"
    end
end

-----------------------------------------------------
-- Motion executor for a given motion state.
function move(angles, frames, loopEndFrame, currentFrameIndex, nextFrameIndex, firstExecutionComplete)
    local simulationTime = sim.getSimulationTime()
    local elapsedTime = simulationTime - frameStartTime
    local currentFrame = angles[currentFrameIndex]
    local nextFrame = angles[nextFrameIndex]
    local transitionTime = frames[currentFrameIndex]

    local transitionRatio = math.min(elapsedTime / transitionTime, 1)

    for i, jointName in ipairs(jointNames) do
        local jointHandle = joints[jointName]
        if jointHandle then
            local targetAngle = math.rad(nextFrame[i])
            local initialTargetAngle = math.rad(currentFrame[i])
            local newPosition = initialTargetAngle + transitionRatio * (targetAngle - initialTargetAngle)
            sim.setJointTargetPosition(jointHandle, newPosition)
        end
    end

    -- print("First exec complete?....", firstExecutionComplete)
    if transitionRatio >= 1 then
        -- print("Frame transition complete: ", currentFrameIndex, " -> ", nextFrameIndex)
        currentFrameIndex = nextFrameIndex
        nextFrameIndex = nextFrameIndex + 1

        if not firstExecutionComplete then
            if nextFrameIndex > #angles then
                nextFrameIndex = loopStartFrame
                firstExecutionComplete = true -- Completed one full cycle.
            end
        else
            if nextFrameIndex > loopEndFrame then
                nextFrameIndex = loopStartFrame
            end
        end

        frameStartTime = simulationTime
    end

    return currentFrameIndex, nextFrameIndex, firstExecutionComplete
end

-----------------------------------------------------
function executeMotion(motion)
    motion.index, motion.nextIndex, motion.firstExecutionComplete =
        move(motion.angles, motion.frames, motion.endFrame, motion.index, motion.nextIndex, motion
            .firstExecutionComplete)
end

-----------------------------------------------------
function sysCall_init()
    detected        = 0
    sensorHandle    = sim.getObjectHandle('../Proximity_sensor')
    -- visionHandle    = sim.getObjectHandle('../Vision_sensor')
    aligned_threshold = 5  
    cube_dummy      = sim.getObjectHandle('../cube_dummy')
    head_dummy      = sim.getObjectHandle('../head_dummy')
    gyro = sim.getObjectHandle('../gyro_dummy')

    distance_to_obj = math.huge
    getJoints()

    -- Motion states from your definitions.
    motionStates = {
        forward      = { index = 1, nextIndex = 2, angles = fwd_angles, frames = fwd_frames, endFrame = fwd_end_frame, firstExecutionComplete = false },
        side         = { index = 1, nextIndex = 2, angles = lside_angles, frames = lside_frames, endFrame = lside_end_frame, firstExecutionComplete = false },
        rside        = { index = 1, nextIndex = 2, angles = rside_angles, frames = rside_frames, endFrame = rside_end_frame, firstExecutionComplete = false },
        pick         = { index = 1, nextIndex = 2, angles = pick_angles, frames = pick_frames, endFrame = pick_end_frame, firstExecutionComplete = false },
        rotate       = { index = 1, nextIndex = 2, angles = lturn_angles, frames = lturn_frames, endFrame = lturn_end_frame, firstExecutionComplete = false },
        rotate_right = { index = 1, nextIndex = 2, angles = rturn_angles, frames = rturn_frames, endFrame = rturn_end_frame, firstExecutionComplete = false },
        getup = { index = 1, nextIndex = 2, angles = getup_angles, frames = getup_frames, endFrame = getup_end_frame, firstExecutionComplete = false }
    }

    frameStartTime = sim.getSimulationTime()
    loopStartFrame = 2
    pick_flag = 0
    turn_counter = 0

    robotState = "scanning" -- Start scanning.
    moveType = nil
    sensorDetectedPoint = nil
    scanPassCount = 0 -- Track full head rotation passes

    default = 0
    fall = 0
    fall_threshold = math.rad(-45)

end

function detect_fall()
    gyro_angle = sim.getObjectOrientation(gyro)
    -- print("Gyro: ", gyro_angle[1])
    if(gyro_angle[1] < fall_threshold) then
        print("Robot has fallen")
    return 1
    else
        return 0
    end
end


-----------------------------------------------------
-- Sensor reading. In "scanning", "aligned", or "moving" states we update sensor data.
function sysCall_sensing()
    isFall = detect_fall()
    if robotState == "scanning" or robotState == "aligned" or robotState == "moving" then
        -- Read proximity sensor
        local result, distance, detectedPoint, detectedObjectHandle, detectedSurfaceNormal = sim.readProximitySensor(sensorHandle)
        if result > 0 then
            detected = 1
            distance_to_obj = distance
            sensorDetectedPoint = detectedPoint
        else
            detected = 0
            sensorDetectedPoint = nil
        end
    end

end


-----------------------------------------------------
function sysCall_actuation()
    -- local isFall = detect_fall()
    -- print("Fallen?....", isFall)
    if(isFall == 1) then
        robotState = "recovering"
    end
    
    local neck_pos = sim.getJointTargetPosition(neck)
    print("State:", robotState, "| Neck pos:", neck_pos, "| Detected points: ", sensorDetectedPoint, "| Dist: ",
        distance_to_obj)

    if robotState == "scanning" then
        if detected == 1 then
            -- Store the head angle upon detection.
            lastNeckPos = neck_pos
            print("Object detected. Switching to objectDetected state.")
            robotState = "objectDetected"
        else
            scan_environment()
        end
    elseif robotState == "objectDetected" then
        -- Force head to 0.
        sim.setJointTargetPosition(neck, 0)
        if math.abs(neck_pos) < 0.1 then
            print("Head reset to 0. Switching to rotating state.")
            -- Decide rotation direction using stored lastNeckPos.
            if lastNeckPos > 0 then
                chosenRotateMotion = "rotate"       -- left rotation.
            else
                chosenRotateMotion = "rotate_right" -- right rotation.
            end
            robotState = "rotating"
            -- Reset rotation motion state.
            if chosenRotateMotion == "rotate" then
                motionStates.rotate.index = 1
                motionStates.rotate.nextIndex = 2
                motionStates.rotate.firstExecutionComplete = false
            else
                motionStates.rotate_right.index = 1
                motionStates.rotate_right.nextIndex = 2
                motionStates.rotate_right.firstExecutionComplete = false
            end
            frameStartTime = sim.getSimulationTime()
        end
    elseif robotState == "rotating" then
        if chosenRotateMotion == "rotate" then
            executeMotion(motionStates.rotate)
            if motionStates.rotate.firstExecutionComplete then
                print("Rotation complete. Switching to aligned state.")
                robotState = "aligned"
                sim.setJointTargetPosition(neck, 0)
            end
        elseif chosenRotateMotion == "rotate_right" then
            executeMotion(motionStates.rotate_right)
            if motionStates.rotate_right.firstExecutionComplete then
                print("Rotation complete. Switching to aligned state.")
                robotState = "aligned"
                sim.setJointTargetPosition(neck, 0)
            end
        end
    elseif robotState == "aligned" then
        -- In the aligned state the head is fixed at 0.
        sim.setJointTargetPosition(neck, 0)
        if detected == 1 and sensorDetectedPoint then
            -- Assume sensorDetectedPoint is in sensor coordinates.
            -- We'll use the second coordinate as lateral offset.
            local lateralOffset = math.abs(sensorDetectedPoint[1])
            ------------------------------------------------------
            print("Lateral Offset: ", lateralOffset)
            if lateralOffset > 0.05 then
                if sensorDetectedPoint[1] < 0 then
                    print("Object to the right. Moving right.")
                    moveType = "rside"
                else
                    print("Object to the left. Moving left.")
                    moveType = "side"
                end
                robotState = "moving"
                -- Reset motion state accordingly.
                motionStates[moveType].index = 1
                motionStates[moveType].nextIndex = 2
                motionStates[moveType].firstExecutionComplete = false
                frameStartTime = sim.getSimulationTime()
            else
                -- If object is centered:
                if distance_to_obj > 0.17 then
                    print("Object centered but far. Initiating forward motion.")
                    moveType = "forward"
                    robotState = "moving"
                    motionStates.forward.index = 1
                    motionStates.forward.nextIndex = 2
                    motionStates.forward.firstExecutionComplete = false
                    frameStartTime = sim.getSimulationTime()
                else
                    print("Object centered and within 0.15. Initiating pick motion.")
                    moveType = "pick"
                    robotState = "moving"
                    motionStates.pick.index = 1
                    motionStates.pick.nextIndex = 2
                    motionStates.pick.firstExecutionComplete = false
                    frameStartTime = sim.getSimulationTime()
                    -- moveType = "grabbing"
                    -- robotState = "grabbing"
                end
            end
        else
            -- If no detection, return to scanning.
            robotState = "scanning"
        end
    elseif robotState == "moving" then
        if moveType then
            executeMotion(motionStates[moveType])
            if motionStates[moveType].firstExecutionComplete then
                if (moveType == "pick") then
                    sim.pauseSimulation()
                end
                print("Motion", moveType, "complete. Returning to aligned state.")
                robotState = "aligned"
            end
        end
        -- end
    elseif robotState == "bodyRotating" then
        executeMotion(motionStates.rotate) -- Execute full body rotation motion

        if motionStates.rotate.firstExecutionComplete then
            print("Body rotation complete. Resetting head to 0.")
            motionStates.rotate.firstExecutionComplete = false -- Reset rotation motion

            -- Reset head and wait until it reaches position 0
            sim.setJointTargetPosition(neck, 0)
            sim.wait(0.5, false) -- Give some time for the head to reset

            -- Ensure it is actually at 0 before scanning
            local head_pos = sim.getJointPosition(neck)
            if math.abs(head_pos) < 0.1 then
                print("Head successfully reset. Restarting scan.")
                scanPassCount = 0 -- Reset scan count
                robotState = "scanning"
            else
                print("Head did not reset properly. Forcing reset again.")
                sim.setJointTargetPosition(neck, 0)
            end
        end
    elseif robotState == "recovering" then
        executeMotion(motionStates.getup)

        -- if motionStates.getup.firstExecutionComplete then
        --     motionStates.getup.firstExecutionComplete = false
        --     print("Recovery complete...")
        --     robotState = "scanning"
        -- end
        -- print("First exec complete?...", motionStates.getup.firstExecutionComplete)

        if motionStates.getup.firstExecutionComplete  then
            motionStates.getup.firstExecutionComplete = false
            print("Recovery complete...")
            robotState = "scanning"
        end
    end
end

-----------------------------------------------------
function sysCall_cleanup()
    -- simIK.eraseEnvironment(ikEnv)
end