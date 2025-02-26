sim = require('sim')

jointNames = {
    'right_shoulder_pitch', 'right_shoulder_roll', 'right_elbow_roll',
    'left_shoulder_pitch', 'left_shoulder_roll', 'left_elbow_roll',
    'right_thigh_yaw', 'right_thigh_roll', 'right_thigh_pitch', 'right_knee_pitch', 'right_foot_pitch', 'right_foot_roll',
    'left_thigh_yaw', 'left_thigh_roll', 'left_thigh_pitch', 'left_knee_pitch', 'left_foot_pitch', 'left_foot_roll'
}

function getJoints()
    neck = sim.getObjectHandle('../Neck')
    joints = {
        right_shoulder_pitch = sim.getObjectHandle('../RShoulderPitch'),
        right_shoulder_roll = sim.getObjectHandle('../RShoulderRoll'),
        right_elbow_roll = sim.getObjectHandle('../RArmRoll'),
        left_shoulder_pitch = sim.getObjectHandle('../LShoulderPitch'),
        left_shoulder_roll = sim.getObjectHandle('../LShoulderRoll'),
        left_elbow_roll = sim.getObjectHandle('../LArmRoll'),
        right_thigh_yaw = sim.getObjectHandle('../RHipYaw'),
        right_thigh_roll = sim.getObjectHandle('../RhipRoll'),
        right_thigh_pitch = sim.getObjectHandle('../RThighPitch'),
        right_knee_pitch = sim.getObjectHandle('../RKneePitch'),
        right_foot_pitch = sim.getObjectHandle('../RAnklePitch'),
        right_foot_roll = sim.getObjectHandle('../RFootRoll'),
        left_thigh_yaw = sim.getObjectHandle('../LHipYaw'),
        left_thigh_roll = sim.getObjectHandle('../LHipRoll'),
        left_thigh_pitch = sim.getObjectHandle('../LThighPitch'),
        left_knee_pitch = sim.getObjectHandle('../LKneePitch'),
        left_foot_pitch = sim.getObjectHandle('../LAnklePitch'),
        left_foot_roll = sim.getObjectHandle('../LFootRoll')
    }
end
