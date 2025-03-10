import json

# Load the JSON data
file_path = "../0C_Pick_Up_Low.json"
with open(file_path, "r") as f:
    data = json.load(f)

# Desired format for joint angles
angle_order = [
    "right_shoulder_pitch", "right_shoulder_roll", "right_elbow_roll",
    "left_shoulder_pitch", "left_shoulder_roll", "left_elbow_roll",
    "right_thigh_yaw", "right_thigh_roll", "right_thigh_pitch", "right_knee_pitch", "right_foot_pitch", "right_foot_roll",
    "left_thigh_yaw", "left_thigh_roll", "left_thigh_pitch", "left_knee_pitch", "left_foot_pitch", "left_foot_roll"
]

# Extract frames from JSON
frames = data["frames"]
mapped_angles = []

# Process each frame
for frame in frames:
    frame_outputs = {output["device"]: output["value"] for output in frame["outputs"]}
    # Divide each angle by 10 while mapping
    ordered_angles = [frame_outputs.get(joint, 0.0) / 10 for joint in angle_order]
    mapped_angles.append(ordered_angles)

# Print or save the mapped angles
for idx, angles in enumerate(mapped_angles):
    formatted_angles = ", ".join(f"{angle:.1f}" for angle in angles)
    print(f"{{{formatted_angles}}},")

