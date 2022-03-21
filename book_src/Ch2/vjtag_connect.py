import socket
 
host = 'localhost'
port = 2323
size = 1024
 
def Open(host, port):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(( host,port))
    return s
 
def Write_LED(conn,intValue):
    size = 7
    bStr_LEDValue = bin(intValue).split('0b')[1].zfill(size) #Convert from int to binary string
    conn.send(bStr_LEDValue + '\n') #Newline is required to flush the buffer on the Tcl server
 
conn = Open(host, port)
 
for val in range(0, 2**7):
    Write_LED(conn, val)
 
conn.close()
