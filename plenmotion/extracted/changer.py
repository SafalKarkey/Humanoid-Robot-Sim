# Original list of arrays
arrays = [
[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
[-65.7, 1.6, 1.9, 65.8, -3.6, -5.5, 0.0, 0.0, -69.9, -10.5, -28.2, 0.0, 0.0, 0.0, 73.4, 4.4, 21.7, 0.0],
[-65.7, -1.6, 32.9, 65.7, 1.6, -32.9, 0.0, 0.0, -69.9, -10.5, -28.2, 0.0, 0.0, 0.0, 69.9, 10.5, 28.2, 0.0],
[-64.1, -1.6, 32.9, 64.1, 1.6, -32.9, 0.0, 0.0, -69.9, 7.5, -35.1, 0.0, 0.0, 0.0, 69.9, -7.5, 35.1, 0.0],
[-62.1, -1.6, 32.9, 62.1, 1.6, -32.9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
]

# Function to change signs
def change_signs(arrays):
    result = []
    for array in arrays:
        modified_array = []
        for i, num in enumerate(array):
            if i == 1 or i == 3 or i == 4 or i == 7 or i == 10 or i == 13 or i == 14 or i == 15:  
                modified_array.append(-num)
            else:
                modified_array.append(num)
        result.append(modified_array)
    return result

# Apply the function
modified_arrays = change_signs(arrays)

# Print the result with curly braces and commas
# for arr in modified_arrays:
#     print(f"{{{', '.join(map(str, arr))}}},")

for arr in modified_arrays:
    formatted_str = []
    for i, value in enumerate(arr, start=1):
        formatted_str.append(str(value) + ',')
        if i in {3, 6, 12}:
            formatted_str.append('\n')
    print(f"{{{' '.join(formatted_str)}}},")
    # print(f"{{formatted_str}}")