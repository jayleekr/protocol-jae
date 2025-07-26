"""Sample code with various quality issues for demonstrating Jae workflow."""

# Poor naming and no type hints
def calc(x, y, op):
    if op == "+":
        return x + y
    elif op == "-":
        return x - y
    elif op == "*":
        return x * y
    elif op == "/":
        return x / y  # No zero division check
    else:
        return None


class DataProcessor:
    def __init__(self):
        self.data = []
    
    # Method too complex and doing too many things
    def process_data(self, file_path):
        try:
            with open(file_path, 'r') as f:
                content = f.read()
                lines = content.split('\n')
                for line in lines:
                    if line:  # Empty line check
                        parts = line.split(',')
                        if len(parts) >= 3:
                            # Magic numbers and no validation
                            item = {
                                'id': int(parts[0]),
                                'name': parts[1],
                                'value': float(parts[2])
                            }
                            # Duplicate check with inefficient loop
                            exists = False
                            for existing in self.data:
                                if existing['id'] == item['id']:
                                    exists = True
                                    break
                            if not exists:
                                self.data.append(item)
        except Exception as e:  # Too broad exception
            print(f"Error: {e}")  # Poor error handling
            return False
        return True
    
    # SQL injection vulnerability
    def find_by_name(self, name):
        # Simulated SQL query (vulnerable)
        query = f"SELECT * FROM items WHERE name = '{name}'"
        # In real code, this would execute the query
        results = []
        for item in self.data:
            if item['name'] == name:
                results.append(item)
        return results


# Global variable (bad practice)
counter = 0

def increment_counter():
    global counter
    counter += 1
    return counter


# Unused function
def unused_function():
    pass


# Function with side effects and poor structure
def save_and_print(data, filename):
    print("Saving data...")  # Side effect
    # No validation
    with open(filename, 'w') as f:
        f.write(str(data))  # Poor serialization
    print("Data saved!")  # Side effect
    return True