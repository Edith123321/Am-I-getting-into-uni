import sys
print("Python path:", sys.executable)
print("\nModule search paths:")
for path in sys.path:
    print(path)

try:
    import seaborn
    print("\nSUCCESS: seaborn imported from:", seaborn.__file__)
except ImportError as e:
    print("\nERROR:", e)