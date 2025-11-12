def hello():
    """Test function that prints a greeting message."""
    print("Hello from libs package!")

def test_print(message="Test message"):
    """Test function that prints a custom message."""
    print(f"[TEST] {message}")

def debug_info():
    """Test function that prints debug information."""
    print("Debug: libs package is working correctly")
    print(f"Function called from: {__file__}")
