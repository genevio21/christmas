import sys

for component in sys.argv[1].split(","):
    if(component in sys.argv[2]):
        print("True") 
        exit(0)
print("False")